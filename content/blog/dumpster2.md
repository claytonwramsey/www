+++
title = "Garbage collection in Rust got a little better"
date = 2025-12-28
description = "Every language attempts to expand until it can be Java."
template = "post.html"
authors = ["Clayton Ramsey"]
draft = true
+++

> Every language attempts to expand until it can be Java. Those languages which cannot so expand are replaced by ones which can.
>
> <footer><a href="https://en.wikipedia.org/wiki/Jamie_Zawinski#Zawinski's_Law">some smart programmer, probably</a></footer>

A long time ago, I wrote a [garbage collector](/blog/dumpster), called [`dumpster`](https://github.com/claytonwramsey/dumpster), in Rust.
If I may say so myself, it was a delightful garbage collector.
However, I think it was imperfect, so I'm writing up this blog post to write about new improvements coming to `dumpster` after two years in the wild.

## Recap episode

To summarize the 6,000-word article that I wrote last time, `dumpster` is a garbage collection library with an emphasis on performance, flexibility, and correctness.
`dumpster` exposes a `Gc<T>` type, similar to the Rust standard library's [`Rc`](https://doc.rust-lang.org/std/rc/struct.Rc.html) or [`Arc`](https://doc.rust-lang.org/std/sync/struct.Arc.html), that wraps some garbage-collected value of type `T`.
A `Gc` is a garbage-collected pointer, so users can fearlessly create reference cycles in their code.
For instance, a user could make a struct that contains a garbage-collected reference to itself, without causing the same memory leaks arising from using `Rc` for the same goal.

```rust
use std::cell::OnceCell;
use dumpster::{Trace, unsync::Gc};

#[derive(Trace)]
struct Foo {
    /// pointer to this same struct!
    this: OnceCell<Gc<Self>>,
}

let foo = Gc::new(Foo { this: OnceCell::new() });
foo.this.set(foo.clone()); // Were `foo` in an `Rc`, this would leak!

dumpster::unsync::collect(); // still collects foo!
```

## All in on dynamic dispatch

To collect cycles, `dumpster` needs some way of inspecting every garbage collected value for any `Gc`s that they may contain.
We achive our inspection by forcing garbage-collected values to implement a special trait, called `Trace`.
`Trace` borrows the [visitor pattern](https://en.wikipedia.org/wiki/Visitor_pattern): every time we want to do something to a garbage-collected value, we ask that value to accept a visitor, delegate that visitor to its fields, recursively going down until it reaches a `Gc`.

```rust
// details differ from the real implementation,
// but this is close enough

pub trait Trace {
    fn accept<V: Visitor>(&self, visitor: &V);
}

// `dumpster` defines visitors to access fields
pub trait Visitor {
    fn visit<T: Trace>(&self, gc: &Gc<T>);
}
```

Previously, `Trace` was not [`dyn`-compatible](https://doc.rust-lang.org/reference/items/traits.html#dyn-compatibility).
Even though `dumpster` supported dynamically-sized types inside of a `Gc`, we still couldn't stow a trait object inside a `Gc`, such as with `Gc<dyn Any>`.
I find this aesthetically displeasing: we've already filled `dumpster` with Java-isms, so we should find some way to go all the way on dynamic dispatch.

The heart of the problem is that, in Rust, generics and dynamic dispatch don't mix.
When we write `<V: Visitor>` in the signature for `accept`, we declare that we must make a new implementation for `accept` for every type `V` that calls it.
That means everything has to be pinned down at compile time, so we can't just erase type information as `dyn`-compatibility requires.
However, Rust does polymorphism like this for good reasons: having that compile-time information enables loads of optimizations.
So, how do we manage to keep the same flexibility and performance as compile-time generics while gaining the ability to use dynamic dispatch?

I didn't figure this out, but a brilliant contributor to the project by the name of [bluurryy](https://github.com/bluurryy/) did.
They had a great insight: we can pin down an exact list of every `Visitor` that `dumpster` requires for a garbage collected value inside of our library, and with a little trait magic, we can force client code to accept our visitors without ever knowing what they are.
This means that we still get the compile-time performance guarantees, but since the list of visitors is fixed, it's possible to make `Trace` `dyn`-compatible.

To do so, `bluurryy` broke `Trace` into a few traits, augmenting `Trace` with `TraceWith<V>` and `TraceWithV`.
Client code must implement `TraceWith<V>` for all `V: Visitor`, since it's impossible for them to implement `Trace` or `TraceWithV` directly.
Internally, `TraceWithV` has a list of all the possible visitors.

```rust
// again, papering over some details

// main public-facing trait
pub trait Trace: TraceWithV {}

// clients must implement this instead of Trace
pub trait TraceWith<V> {
    fn accept(&self, visitor: &V);
}

mod secret {
    // can update this list of requirements to add more visitors
    pub trait TraceWithV: TraceWith<MyVisitor> {}
    impl<T> TraceWithV for T
    where
      T: ?Sized + TraceWith<MyVisitor>
    {}
}

struct MyVisitor;
impl Visitor for MyVisitor1 { /* ... */ }
```

Since `TraceWithV` and `Trace` have no generics in any of their types or methods, `Trace` is dyn-compatible, so it's finally possible to write (admittedly clunky) dynamic-dispatched code.

```rust
use dumpster::{
    unsync::{coerce_gc, Gc},
    Trace,
};

trait MyTrait: Trace {}
impl<T: Trace> MyTrait for T {}

let gc: Gc<i32> = Gc::new(5);
let gc: Gc<dyn MyTrait> = coerce_gc!(gc);
```

## Making cyclic data structures

If you thought my very first example, creating a self-referential `Gc`, was a little clunky, then you're not alone!
I find it a total pain everywhere from tests to documentation to application code to blog posts.
In order to have a self-reference, each garbage-collected value must contain some sort of interior mutability to smuggle a pointer into itself.
Since the simplest and most common use case is for a garbage-collected value to keep a pointer to itself, there should be an easy way to construct a simple self-referential `Gc` like `Foo` above.

Creativitiy is overrated.
There's already a function that does that in the standard library, called [`Rc::new_cyclic`](https://doc.rust-lang.org/std/rc/struct.Rc.html#method.new_cyclic) (or [`Arc::new_cyclic`](https://doc.rust-lang.org/std/sync/struct.Arc.html#method.new_cyclic)).
In a `new_cyclic` function, client code can construct a `Gc` by passing in a helper function that builds a value out of a pointer to itself.
For example, we could rewrite the construction for `Foo` using a straightforward call to `new_cyclic`.

```rust
use std::cell::OnceCell;
use dumpster::{Trace, unsync::Gc};

#[derive(Trace)]
struct Foo {
    /// pointer to this same struct!
    this: Gc<Self>,
}

let foo = Gc::new_cyclic(|this| Foo { this });
```

However, the standard library's approach (passing around a separately-typed weak pointer) won't work for `Gc`s.
The whole point of a `Gc` is that we guarantee that it is (almost) always valid, even in the face of cycles, so we can't just make up a `WeakGc` type.

I chose to solve my problems by reusing the one good idea I had in this project: abusing the visitor pattern.
When client code calls `new_cyclic` with some constructor `f`, we can lie: instead of having the `this` pointer actually point to an allocation, we'll just pass in a garbage, dead `Gc`.
Then, once the value has been constructed and `f` returns, we'll use our visitor to rehydrate every dead `Gc` into a live one.
This approach is sound since we can just crash the program if client code attempts to dereference a dead `Gc`.

At first, I thought this was only possible in my single-threaded `unsync` implementation of `Gc`.
I had assumed that malicious client code could smuggle out a reference to the value returned from `f`, making the rehydration process for `Gc`s into Undefined Behavior due to the shared-xor-borrow rule.
Howver, the Rust type system came to save me once again: since returning a value from `f` is a move, it necessarily invalidates all borrows against the newly-constructed value.
Since the implementation of `Trace` expressly forbids weird pointer types from being stored in a `Gc`, it's impossible for client code to observe the rehydration process.

## Breadheel

There were actually a lot of big changes to `dumpster` in the last two years!
I have only finite energy and time, so I've only highlighted just two of the coolest ideas.
I had a lot of fun implementing all this, and there's still a lot more to do!
For instance, I want to see if I can get niche-optimization for zero-overhead `Option<Gc>` and, of course, I always want to crank out extra performance.
But for now, I think this is a good place for `dumpster` to be: it's fast, powerful, and as always a little cute.

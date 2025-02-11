+++
title = "Effect polymorphism fixes dependency inversion"
date = 2024-10-05
description = "Local programmer is inconvenienced by error-handling boilerplate, writes uninformed article about experimental programming language features. More at 11."
template = "post.html"
authors = ["Clayton Ramsey"]
+++

TL;DR: Local programmer is inconvenienced by error-handling boilerplate,
writes uninformed article about experimental programming language
features. More at 11.

I've encountered lots of pain points when dependency-inverting things,
especially when working with combinators. Most recently, I've been
thinking about how I might expose Python bindings for a [half-baked
motion planning library](https://github.com/claytonwramsey/rumple) I'm
building. The chief problem is that I want users to provide their own
configuration spaces, samplers, robots, and collision checkers. If those
are implemented in Python, they can throw an exception at any time,
yielding an error in the corresponding PyO3 API. The problem is that all
of my functions which might call into that behavior don't return an
error - what am I to do?

I'm not the only one with this sort of problem!
[boats](https://without.boats/blog/the-problem-of-effects/) has been
writing about this for nearly five years, and [handling iterators of
results is still a pain](https://stackoverflow.com/questions/63798662).
As the `async` story for Rust has improved, we've seen similar results
on the pain (or lack thereof) of [function coloring in
Rust](https://morestina.net/blog/1686/rust-async-is-colored). In short,
crossing control-flow boundaries in statically typed languages is
painful and difficult.

First off, a disclaimer: I am more interested in programming language
theory than the average joe, but I'm still not an expert. I've only
read a little bit on the topic of algebraic effects, so I may get some
things wrong - I'm a roboticist, not a category theorist. The purpose
of this article is not so much to propose a novel contribution as to
draw attention to a common problem and an elegant solution.

## Dependency inversion

For the sake of this post, I'll refer to <dfn>dependency inversion</dfn>
as the practice of taking a subroutine in a procedure and taking it out
as an argument. For example, consider the following Rust code:

```rust
fn my_sum() -> u32 {
    let mut total = 0;
    for i in 0..10 {
        total += magic_number(i);
    }
    total
}

fn magic_number(x: u32) -> u32 { x }
```

This would be a case of an _uninverted_ dependency; that is, `my_sum`
depends on `magic_number` and knows it specifically by name. However, if
we factored out `magic_number` into a user provided file, this would
invert the dependency:

```rust
fn my_sum<N: MagicNumber>() -> u32 {
    let mut total = 0;
    for i in 0..10 {
        total += N::magic_number(i);
    }
    total
}

trait MagicNumber {
    fn magic_number(x: u32) -> u32;
}
```

This has a lot of benefits, mostly for code reuse. We can now use these
generic functions to build simple combinators and compose them into
bigger things!

In fact, this toy example is pretty close to what a simple iterator
combinator (such as
[`std::iterator::Sum`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.sum))
does. For the most part, people are quite happy with it and it gets the
job done.

## My problem

What if a user-provided `magic_number` implementation is fallible?
Perhaps it requires file I/O, or has a chance of dividing by zero, or
maybe it calls out to some FFI code. In current Rust, we have a few
prospects:

- Panic! Whenever `magic_number` encounters an error state, we can
  just crash the program. This works fine until you are woken up at 3
  A.M. with calls about your broken website.
- Panic, but gracefully. Whatever top-level code calls `my_sum` can
  catch the panic using
  [`catch_unwind`](https://doc.rust-lang.org/std/panic/fn.catch_unwind.html).
  The catch with catching is that unwinding is slow and unpredictable.
  In fact, programs compiled with `panic = "abort"` will never catch a
  panic.
- Go nuclear. Make a copy of `MagicNumber` specifically for the case
  of fallible implementations of `magic_number`.

The nuclear option would look something like this.

```rust
fn try_my_sum<N: TryMagicNumber>() -> u32 {
    let mut total = 0;
    for i in 0..10 {
        total += N::try_magic_number(i)?;
    }
    total
}

trait TryMagicNumber {
    type Error;
    fn try_magic_number(x: u32) -> Result<u32, Self::Error>;
}
```

So, with a little bit of brute force, we've come up with an API that
can handle fallibility. It's annoying to maintain, sure, but at least
we've achieved maximum flexibility. But wait! What if we want to make
an implementation of `magic_number` using an unsafe function! Then we'd
have to make a new trait!

```rust
trait UnsafeMagicNumber {
    type Error;
    unsafe fn unsafe_magic_number(x: u32) -> u32;
}
```

And what if we want to use this functionality with a function that was
both unsafe and fallible?

```rust
trait TryUnsafeMagicNumber {
    type Error;
    unsafe fn try_unsafe_magic_number(x: u32) -> Result<u32, Self::Error>;
}
```

Now imagine if we wanted to make a version of `magic_number` that worked
via dynamic-dispatch. To do so, we'd have to make a new trait
`ObjectMagicNumber`, since `MagicNumber` is not object-safe. Then we'd
need to make even more traits for every version of it!

```rust
trait ObectMagicNumber {
    fn object_magic_number(&self, x: u32) -> u32;
}

trait TryObjectMagicNumber { /* ... */ }
trait UnsafeObjectMagicNumber { /* ... */ }
trait TryUnsafeObjectMagicNumber { /* ... */ }
```

Then we have to consider all the many other variations on this
once-simple API: mutability, allocations, I/O, blocking, `const`,
`async`. The list goes on. If we had $n$ such properties, we'd need to
create $2^n$ traits and $2^n$ functions to handle them all. Each one
of these variations is reasonable, but we know that since we can't
accept all of them, we must accept none of them.

## What are effects, anyway?

Intuitively, effects are a way of trying to abstract away all these
possible variations on a function in a clean and generic way. Every
function has some set of effects, and effects are inherited: if $f$ has
effect $E$, and $g$ calls $f$, then $g$ also has effect $E$.

To build some examples, let's make a new fake programming language
called RustE (Rust, with Effects). We'll make only a few syntactic
changes, allowing the creation of effects and for effects to be
annotated with a `can` clause describing their effects.

```rust
effect Bar {}

fn foo() can Bar {
    println!("bar!");
}
```

If we made a new function `baz` which called `foo`, `baz` would also
have to have the effect `Bar`.

```rust
fn baz() {
    foo();
    // compile error! baz() calls foo(), which has effect Bar, but baz() cannot Bar!
}

fn qux() can Bar {
    foo(); // this is ok though
}
```

To avoid the [function
coloring](https://journal.stuffwithstuff.com/2015/02/01/what-color-is-your-function)
problem, we'll also allow for `handle` clauses, which allow a function
_without_ an effect to call a function _with_ an effect.

```{clas="rust"}
fn baz2() {
    handle Bar {} {
        // Bar was handled, so no compile error
        foo();
    }
}
```

We can add some texture by letting effects also call procedures which go
all the way up to their handlers. The handler can choose to resume,
returning execution to the effect caller, or to `break`, escaping from
the handler to the scope outside the handler.

```rust
effect GetWidget {
    fn make_widget() -> u32;
}

fn eat_widgets() can GetWidget {
    loop {
        let w = GetWidget::make_widget();
        println!("mm, tasty {w}");
    }
}

fn feed_widgets() {
    let mut widgets = vec![1, 2, 3];
    handle GetWidget {
        fn make_widget() -> u32 {
            match widgets.pop() {
                Some(w) => w,
                None => break,
            }
        }
    } {
        eat_widgets();
    }
    println!("out of widgets :(");
}

// expected output:
// ----------------
// mm, tasty 3
// mm, tasty 2
// mm, tasty 1
// out of widgets :(
```

Our final wrinkle: effects and their functions may have generic types!

```rust
effect Fail<E> {
    fn fail(e: E) -> !;
}

fn do_my_best(x: u32) can Fail<&'static str> {
    if x == 0 {
        Fail::fail("can't divide by zero");
    } else {
        println!("{}", 1 / x);
    }
}

fn main() {
    handle Fail<&'static str> {
        fn fail(s: &'static str) -> ! {
            println!("{s}");
            break;
        }
    } {
        do_my_best(1);
        do_my_best(0);
    }
}
```

## Effects can model lots of kinds of functions

We can model many language features as special cases pf effects. In
fact, the handling the effect `Fail` in the example above is equivalent
to a `try`-`catch` statement with checked exceptions!

`unsafe` is also pretty trivially an effect - any function which is
unsafe can have the `Unsafe` effect, while any `unsafe` block desugars
to a handler. If you added effects to the original Rust language, it
might be possible to integrate them in a backward-compatible way into
the language.

The same applies for `async`, I/O, and allocations. If you squint hard
enough, you might be able to imagine a case where interior mutability is
a sort of effect handler too. Surprisingly enough, `const` isn't really
an effect, but non-`const` code is! Non-`const` code can call `const`
functions, but not the other way around, so running at runtime is the
effect. I suppose you could alternately come up with \"contravariant\"
effects, by which any function with contravariant effect $E'$
may only call functions which also have the effect $E'$. Then
`const` would be one such contravariant effect, but, honestly, it's not
worth the hassle.

## Effect polymorphism comes in

In the same way that a function could be polymorphic over types (as with
generics), why not have functions be polymorphic over _effects_? If we
return to our original example of `my_sum`, we can fold all the possible
versions of `my_sum` from $2^n$ variants to just one.

```rust
trait MagicNumber {
    effect Effect;
    fn magic_number(x: u32) -> u32 can Self::Effect;
}

fn my_sum<N: MagicNumber>() -> u32 can N::Effect {
    let mut total = 0;
    for i in 0..10 {
        total += N::magic_number(i);
    }
    total
}
```

I'm pretty happy with this! There's very little ceremony involved, and
we get to express vastly more things than we could before!

Of course, once we have something like this system, there are a lot of
obvious questions:

- Is there a complement to `type _ = impl Trait` for effects?
- How should effects compose?
- Can we treat effects like data?
- Can we do introspection or reflection on effects?
- Can we do dynamic-dispatch on effects at runtime?
- If Rust also got linear types, how would they compose with
  cancellation in effect handlers?

For now, though, it would be really nice to just write code which is
polymorphic over its effects.

## I'm no closer to fixing my Python issues

It's one thing to muse about a solution to my problem and another thing
entirely to actually solve it. As much as I would like to go completely
down the rabbit hole and implement a dream language with algebraic
effects, linear types, trait-based polymorphism, and zero-cost
abstraction, I also have to get my projects done some time this century.

There's been a lot of ink spilled about efficiently compiling algebraic
effects, but at the time of writing there's no mainstream programming
language that does so. [Koka](https://github.com/koka-lang/koka) is
probably the closest thing that we have to such a language, but it's
admittedly not production-ready.

For now, I will probably end up just making code that has weird effects
panic. It's not the best choice, but it's good enough for now.

Thanks to [Aedan](https://aedancullen.com/),
[Shreyas](https://shreyasminocha.me/), and [Wisha](https://wisha.page/)
for reviewing this post!

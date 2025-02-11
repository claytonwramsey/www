+++
title = "Solving 20 billion Wordle problems per second"
date = 2024-11-25
description = "Wordle is a mostly-solved problem, but we can mostly-solve it faster."
template = "post.html"
authors = ["Clayton Ramsey"]
+++

Wordle is a mostly-solved problem, but we can mostly-solve it faster.
Every so often, I get caught with the puzzle automation mind virus, and
feel a burning need to write an engine for solving a pointless little
game or puzzle. This time, I got caught by Wordle. To my knowledge,
I've implemented the fastest implementation of a word grader out there.
Of course, I'm nearly three years late to the party, but I had fun
writing all this, which is all that matters to me. If you don't care
about the journey as much as me, you can check out the source code
[here](https://github.com/claytonwramsey/wordle_simd).

## What even is Wordle?

In case you lived under a rock around 3 years ago, Wordle is a little
word-guessing game developed by [Josh
Wardle](https://www.powerlanguage.co.uk/). The goal is to guess a
five-letter English word by sampling different words. Every time you
give a guess, you receive a [grade]{.dfn}, which is an assignment of
five colors to the letters in your guess.

Given some guess $w$ and solution word $s$, the grade $g$ for letter $i$
of a guess is defined as follows:

- If $w_i = s_i$, $g_i$ is green.
- If $w_i \neq s_i$ and there is another letter $s_j = w_i$,
  _and_ $s_j$ has not matched with an earlier letter $w_(< i)$, then
  $g_i$ is yellow.
- Otherwise, $g_i$ is black.

The yellow cases are the trickiest part. Here's an example: if we
guessed `roses` against the solution `horse`, we would find that the `h`
is black, since it appears nowhere in the solution. The `o` would be
green, since it perfectly matches up between the guess and the solution,
but `s` will be more complex. The first `s` in `roses` would be yellow,
since it matches with the fourth letter of `horse`, but the second would
be black, as there are no more `s` left for it to match in `horse` after
satisfying the first `s`.

Lots of people like to go with an unconditional first two guesses - for
instance, no matter the puzzle, my brother always opens with `trace` and
`lions`. A natural question: given knowledge of the set of legal guesses
$W$ and the set of possible solutions $S subset.eq W$, what is the best
unconditional opener?

In practice, this is actually quite difficult to answer, as doing so
would require evaluating every possible sequence of guesses, which would
take enormous amounts of time. However, we can approximate the quality
of an opener using entropy: every time we play an opener, we're given a
pair of grades. There are only so many words which satisfy those grades.
Given that we've received some grade $g$ for our word $w$, let
$c_g(w)$ be number of possible remaining words which could have given
the grade. Then the expected remaining entropy after guessing $w$ is the
average of $c_g(w) log c_g(w)$ for every possible grade $g$.

To keep things simple, I won't go into the gritty details of why this
is so good. There are a billion other articles on it, so go look up your
favorite one if you'd like to learn more about the math. The rest of
this article will be focused on pure performance engineering. In order
to calculate the expected remaining information for every possible
opener, we'll have to construct a grade for every combination of an
opener and the true word. Wordle canonically has 12947 words with 2309
possible solutions, so that means we'd have to compute up to
$12947 * 12946/2 * 2309$ total grades, or about 193 billion grades
total. For the rest of this article, we're going to focus on churning
through grade computation as fast as possible, in the hopes of getting
out our optimal opener.

## The best first word

To start off, any naive solution won't be fast enough for finding the
best two-word opener. In fact, even getting a benchmark for that would
be a fool's errand. As a proxy for that, we'll start by looking at the
best _one_-word opener; that is, the single first guess which minimizes
the expected remaining entropy in the problem. Doing so will require
$12947 * 2309$ or just under 30 million grades.

### The simplest approach

I'll start off with a naive implementation of a grader to give a
baseline for our future improvements. The simplest approach is to take
two passes through the solution. On the first pass, we make note of all
green letters in the grade, and write down any unmatched letters in the
solution. On the second pass, we travel through the guessed word and
mark any letters of the guess whcih correspond to an unmatched letter as
yellow. To be fully general, we could store each word as a `&str`, each
color as one member of an `enum`, and then give grades as a
`Vec<Color>`. To store the set of unmatched letters, the most general
version would be a `HashMap<char, usize>`.

For the rest of this article, I'll call the data structure which stores
the number of unmatched characters in the solution the <dfn>yellow bank</dfn>,
or just <dfn>bank</dfn> for short.

```Rust
use std::collections::HashMap;

#[derive(Clone, Copy, PartialEq, Eq)]
enum Color {
    Black,
    Yellow,
    Green,
}

type Word = str;
type Grade = Vec<Color>;

fn grade(w: &Word, sol: &Word) -> Grade {
    assert_eq!(w.len(), sol.len());
    let mut bank: HashMap<char, usize> = HashMap::new();
    let mut grade = Vec::with_capacity(w.len());

    for (wc, sc) in w.chars().zip(sol.chars()) {
        if wc == sc {
            grade.push(Color::Green);
        } else {
            grade.push(Color::Black);
            *bank.entry(sc).or_default() += 1;
        }
    }


    for (wc, g) in w.chars().zip(&mut grade) {
        if let Some(c) = bank.get_mut(&wc) {
            if *c > 0 && *g == Color::Black {
                *c -= 1;
                *g = Color::Yellow;
            }
        }
    }

    grade
}
```

Without even running this code, it should be apparent that it's quite
slow. Creating a `HashMap` and a `Vec` for every single grading means
calling multiple allocations at each cycle, which is always disastrous
for hot loops. Because of this, I won't even try to use it to calculate
the best two-word opener. Instead, I'll do my comparisons of grading
speed on a slightly smaller task: calculating the best single-word
opener.

To do this calculation, we'll need to compute the entropy after each
possible opening guess, meaning we'll need to grade $2309 * 12947$
words, or about 29 million.

Without further ado, here are my results:

| Method | Runtime (ms) | Mean grading time (ns) | Speedup |
| :----- | -----------: | ---------------------: | ------: |
| Naive  |       3840.0 |                 129.00 |     1.0 |

We'll populate this table with further rows as we implement new methods
to compare against.

And, if you care, the best unconditional single-word opener is `soare`,
with an expected remaining information of 5.29 bits in the puzzle. For
reference, the 2309 possible solutions to a Wordle problem require 11.2
bits of information, so this yields a pretty big jump in your knowledge
of the puzzle! Since all other methods will be computing the same
result, I won't bother reporting that, but instead we'll just
calculate how long it takes them to do the same process.

### A little less naive

The obvious next step is to see if we can avoid the allocations in our
implementation of `grade`. Actually, it's not too hard to do! We'll
make a few key insights:

- Every possible guess and solution has exactly 5 letters.
- Every possible guess and solution is exclusively made from ASCII
  characters.

Since words are only five letters, we can replace variable-length `str`s
and `Vec`s with simple fixed-size arrays, preventing some allocations.
Additionally, since all letters are lowercase ASCII, we can model each
letter of each word as a number from 0 through 255 (inclusive), one for
each ASCII codepoint.

Once our letters are restricted, we can squint a little at our
yellow-bank map. The values no longer need to be `usize`s, since the
bank caps out at 5 letters saved per entry. Likewise, the keys are now
just numbers from 0 through 255, so instead of using an expensive
hash-map, we can just use a 256-element array of `u8` to store all our
unmatched letters.

We can put these insights together to make a very performant and
allocation-free implementation of our grade function. I'll call this
the "sensible" implementation.

```Rust
type Word = [u8; 5];
type Grade = [Color; 5];

fn grade(w: Word, soln: Word) -> Grade {
    let mut bank = [0u8; 256];
    let mut grade = [Color::Black; 5];

    for ((wc, sc), g) in w.into_iter().zip(soln).zip(&mut grade) {
        if wc == sc {
            *g = Color::Green;
        } else {
            bank[sc as usize] += 1;
        }
    }

    for (wc, g) in w.into_iter().zip(&mut grade) {
        if *g == Color::Black && bank[wc as usize] > 0 {
            bank[wc as usize] -= 1;
            *g = Color::Yellow;
        }
    }

    grade
}
```

This implementation gives us a respectable 5x improvement in speed.

| Method   | Runtime (ms) | Mean grading time (ns) | Speedup |
| :------- | -----------: | ---------------------: | ------: |
| Naive    |       3840.0 |                 129.00 |     1.0 |
| Sensible |        659.0 |                  22.00 |     5.8 |

Were I writing standard application code, I think this would have been a
good place to stop. It requires a few assumptions, but they are mostly
reasonable, and the code is in my opinion quite readable.

**Note:** Were I wearing my software-engineer hat, I would be a lot more
systematic about enforcing invariants for all my types. However, this is
only a blog post, and so I play fast and loose with my code quality for
sake of brevity.

### Packing it all down

In the previous step, each `Word` was exactly 5 bytes. Often, if we pack
our data into a single integer, we can get some big performance
improvements, but the 3-byte overhead of a `u64` seems a little too big.
Is there a better way?

Well, maybe. We'll have to start with another restrictive assumption.
Previously, we allowed any letter in a word to be a byte, so all values
of a `u8` were fair game. In our dataset, however, we find that every
word is a lowercase alphabetical string. This takes the number of
possible characters from 256 to just 26. Doing a little bit of math, the
minimum data needed to represent 5 26-letter words is $5 log 26$
bits, or just over 23.5 bits. This is a good sign - that means we can
represent each word as a `u32`.

It's actually even better than that. We only need 5 bits to represent
each letter, so a packed array of 5 letters is only 25 bits. To get down
to the theoretical minimum of 24 bits, we'd need to do
multiplies-and-modulos to pack or extract each letter, but when
representing each letter as its own independent bits, we can use (much
faster) bitshift and masking operations.

But enough talking! Let's get to the code. Let's start by redefining
our `Word`s.

```Rust
type Word = u32;
```

This is a packed representation, so for a word `w`, to get the `i`-th
letter of `w`, we can unpack it with a bit-shift and mask - to extract
out the letter, simply compute `(w >> (5 * i)) & 0b11111`.

Likewise, each `Color` is only one of three values, so we can pack
`Color`s into two bits. With five `Color`s per grade, then we can pack a
`Grade` into a single `u16`.

```rust
type Grade = u16;
```

Finally, each entry in the yellow bank can have a maximum of 5 letters,
so each entry needs only 3 bits. Across all 26 letters, that means we
can fit the entire yellow bank in 78 bits, so we can fit it in a single
`u128`. Putting this all together, we can take the previous sensible
implementation and convert it to use packed integers instead of arrays.

```Rust
const GREEN: u16 = 0b10;
const YELLOW: u16 = 0b01;
const BLACK: u16 = 0b00;

fn grade(guess: Word, soln: Word) -> Grade {
    let mut yellow_bank = 0u128;
    let mut grade = 0u16;
    let mut guess2 = guess;
    let mut soln2 = soln;
    for _ in 0..5 {
        let matches_bottom_5 = (guess2 ^ soln2) & 0x1f == 0;

        if matches_bottom_5 {
            grade |= GREEN << 10;
        } else {
            let sc = soln2 & 0x1f;
            yellow_bank += 1 << (3 * sc);
        }
        grade >>= 2;
        guess2 >>= 5;
        soln2 >>= 5;
    }

    for i in 0..5 {
        let c = (guess >> (5 * i)) & 0x1f;
        if grade & (0b11 << (2 * i)) == BLACK {
            let nyellow = (yellow_bank >> (3 * c)) & 0b111;
            if nyellow > 0 {
                yellow_bank -= 1 << (3 * c);
                grade |= YELLOW << (2 * i);
            }
        }
    }

    grade
}
```

This code is of course far more convoluted than the previous
implementation. However, it comes with a nice bump to performance!

| Method   | Runtime (ms) | Mean grading time (ns) | Speedup |
| :------- | -----------: | ---------------------: | ------: |
| Naive    |       3840.0 |                 129.00 |     1.0 |
| Sensible |        659.0 |                  22.00 |     5.8 |
| Packed   |        309.0 |                  10.34 |    12.4 |

### Going for a squeeze

We're now reaching the point where it's actually quite difficult to
come up with any more optimizations. However, there's one more place
that I thought of to optimize, and it's going to require one last
assumption.

If you scroll through the list of answers, you'll notice that they're
all relatively normal English words. Normal English words tend to have a
nice mix of vowels and consonants, and the list contains no degenerate
onamotopoeia like `aaaaa`. The result: **every word on the answer list
contains no more than 3 duplicate letters.** (This is true for the word
list too, but it's not relevant to the optimization).

We can use that upper bound on duplicate letters to shrink our
yellow-letters bank. We now only need 2 bits per letter to represent
every entry in the yellow bank, so we can fit the whole thing in a
single `u64`. Generally speaking, `u128` arithmetic is quite slow, so
this is a big improvement for our performance. I'll call this
implementation **squeeze**, since we squeeze everything down as tightly
as it can go.

Otherwise, the code is about the same, so I'm hiding the source behind
the spoiler dropdown below.

<details>

<summary>click me for code!</summary>

```rust
fn grade(guess: Word, soln: Word) -> Grade {
    let mut yellow_bank = 0u64;
    let mut grade = 0u16;
    let mut guess2 = guess;
    let mut soln2 = soln;
    for _ in 0..5 {
        let matches_bottom_5 = (guess2 ^ soln2) & 0x1f == 0;

        if matches_bottom_5 {
            grade |= GREEN << 10;
        } else {
            let sc = soln2 & 0x1f;
            yellow_bank += 1 << (2 * sc);
        }
        grade >>= 2;
        guess2 >>= 5;
        soln2 >>= 5;
    }

    for i in 0..5 {
        let c = (guess >> (5 * i)) & 0x1f;
        if grade & (0b11 << (2 * i)) == BLACK {
            let nyellow = (yellow_bank >> (2 * c)) & 0b11;
            if nyellow > 0 {
                yellow_bank -= 1 << (2 * c);
                grade |= YELLOW << (2 * i);
            }
        }
    }

    grade
}
```

</details>

| Method   | Runtime (ms) | Mean grading time (ns) | Speedup |
| :------- | -----------: | ---------------------: | ------: |
| Naive    |       3840.0 |                 129.00 |     1.0 |
| Sensible |        659.0 |                  22.00 |     5.8 |
| Packed   |        309.0 |                  10.34 |    12.4 |
| Squeeze  |        224.0 |                   7.49 |    17.1 |

### Multiple data, multiple problems

We've just about exhausted all of our sequential performance capacity.
However, computers can do a lot more with a lot more than one operation
at a time! If you've seen any of my [real work](/blog/captree), you
might know that I'm a big fan of single-instruction, multiple-data
(SIMD) parallelism.

Using SIMD, we have access to special instructions on our CPU. Ordinary
instructions let us do fine-grained atomic operations, such as adding
two numbers together. SIMD instructions take that one step further: we
use one instruction to do many (typically 4 or 8) of the same operation
on many values. The chief difficulty of using SIMD is that **every unit
of parallelism must be doing the same thing**. In other words, if our
sequential code has an if-else-statement in it, the parallelized version
must execute both branches of that statement. Fortunately for us,
though, our squeezed SIMD parallel algorithm has very few if-statements,
and the bodies that they execute are quite cheap.

The next problem is (once again) the yellow bank. If we are grading `L`
guesses in parallel, then we could represent our guess and solution
words as a vector of `L` `u32`s, but the yellow bank would have to be a
vector of `L` `u64`s. Converting between two different lane widths is
very expensive in SIMD code, so we need to use the same integers for
both the words and the yellow bank. However, if we expand each lane to
use a `u64` for each word, then we've wasted half our parallelism.

My solution: split the bank in half. We'll make two SIMD vectors to
represent the yellow bank. The first vector can hold the entries in the
bank corresponding to the first 16 letters of the alphabet, while the
second vector can hold the entries corresponding to the last 10. The
chief benefit is that we now only need to use `u32`s to represent our
data, so we can dodge all the transfer costs for changing lane sizes.

Of course, this complicates the process of actually fetching and storing
numbers in the yellow bank. To make this all work, we have to construct
a bitmask for each character of the solution, and then mask every single
operation involving the yellow bank with operations like `select`. But
after a little finagling, it's all possible!

```rust
pub fn gradel<const L: usize>(
    words: Simd<Word, L>,
    solns: Simd<Word, L>
) -> Simd<u32, L>
where
    LaneCount<L>: SupportedLaneCount,
{
    // split yellow bank since u128 not supported
    let mut yellows = [Simd::<u32, L>::splat(0); 2];
    let mut grade = Simd::splat(0);
    let mut guess2 = words;
    let mut soln2 = solns;

    let sixteen = Simd::splat(16);
    for _ in 0..5 {
        let matches_bottom_5 = ((guess2 ^ soln2) & Simd::splat(0x1f))
            .simd_eq(Simd::splat(0));
        grade |= matches_bottom_5
            .cast()
            .select(Simd::splat((GREEN as u32) << 10), Simd::splat(BLACK as u32));
        let sc = soln2 & Simd::splat(0x1f);
        let is_first_sixteen = sc.simd_lt(sixteen);
        yellows[0] += (!matches_bottom_5 & is_first_sixteen)
            .select(Simd::splat(1) << (Simd::splat(2) * sc), Simd::splat(0));
        yellows[1] += (!matches_bottom_5 & !is_first_sixteen).select(
            Simd::splat(1) << (Simd::splat(2) * (sc - sixteen)),
            Simd::splat(0),
        );
        grade >>= 2;
        guess2 >>= 5;
        soln2 >>= 5;
    }

    for i in 0..5 {
        let c = ((words >> Simd::splat(5 * i)) & Simd::splat(0x1f)).cast();
        let is_first_sixteen = c.simd_lt(sixteen);
        let offset_c = is_first_sixteen.select(c, c - sixteen);

        let needs_yellow = (grade & Simd::splat(0b11 << (2 * i)))
            .simd_eq(Simd::splat(BLACK as u32))
            .cast();
        let n_yellow = (is_first_sixteen.select(yellows[0], yellows[1])
            >> (Simd::splat(2) * offset_c))
            & Simd::splat(0b11);
        let got_yellow = needs_yellow & (n_yellow.simd_gt(Simd::splat(0)));

        grade |= got_yellow
            .cast()
            .select(Simd::splat((YELLOW as u32) << (2 * i)), Simd::splat(0));

        let subs = Simd::splat(1) << (Simd::splat(2) * offset_c);
        yellows[0] -= (got_yellow & is_first_sixteen).select(subs, Simd::splat(0));
        yellows[1] -= (got_yellow & !is_first_sixteen).select(subs, Simd::splat(0));
    }

    grade
}
```

The above code is as fast as it is incomprehensible. It's polymorphic
over the lane count, so we can run our benchmarks for each lane count to
see which is fastest. My computer supports up to AVX2, so I expected the
8-lane implementation to be the fastest.

And we get great performance boosts! Our final performance for the SIMD
approach runs fifty times faster than the original naive implementation.
However, our numbers for average grading time are no longer truly
meaningful, since I calculated them by dividing the total grades
required by the total time taken, so the average times are a
representation of throughput, not latency.

| Method          | Runtime (ms) | Mean grading time (ns) | Speedup |
| :-------------- | -----------: | ---------------------: | ------: |
| Naive           |       3840.0 |                 129.00 |     1.0 |
| Sensible        |        659.0 |                  22.00 |     5.8 |
| Packed          |        309.0 |                  10.34 |    12.4 |
| Squeeze         |        224.0 |                   7.49 |    17.1 |
| SIMD (1 lane)   |        361.0 |                  12.08 |    10.6 |
| SIMD (2 lanes)  |        370.0 |                  12.38 |    10.4 |
| SIMD (4 lanes)  |         87.4 |                   2.91 |    43.9 |
| SIMD (8 lanes)  |         49.8 |                   1.67 |    77.1 |
| SIMD (16 lanes) |         55.5 |                   1.86 |    69.2 |
| SIMD (32 lanes) |         52.8 |                   1.77 |    72.7 |

### Turbo-parallelism

If going parallel in SIMD worked well for us, then going parallel with
threads will probably work great too. Luckily, selecting the best word
is an embarrasingly parallel problem: at the end of the day, all we're
doing is calculating a minimum.

For our first-word benchmark, we'll divvy up the 12947 guess words into
a chunk for every thread. For instance, if we have 32 threads, each
thread gets either 404 or 405 guess words in its chunk. Each thread
computes the best word in its apportioned chunk, then once all threads
are done, we select the best word from all the chunks.

This code is really easy to implement with `std::thread::scope`.

```rust
let chunk_size = /* some number */;
let words = /* list of possible guesses */;
let answers = /* list of possible answer words */;

scope(|s| {
    let handles: Vec<_> = words
        .chunks(chunk_size)
        .enumerate()
        .map(|(j, c)| {
            s.spawn(move || {
                let mut best_ent = f32::INFINITY;
                let mut best_word_id = usize::MAX;
                for (i, w) in c.iter().enumerate() {
                    // imagine `entropy_after` returns
                    // the expected remaining entropy after
                    // guessing `w`
                    let ent = entropy_after(w, answers);
                    if ent < best_ent {
                        best_ent = ent;
                        best_word_id = i;
                    }
                }
                (best_ent, best_word_id + j * chunk_size)
            })
        })
        .collect();

    let mut best_ent = f32::INFINITY;
    let mut best_id = usize::MAX;
    for handle in handles {
        let (ent, id) = handle.join().unwrap();
        if ent < best_ent {
            best_ent = ent;
            best_id = id;
        }
    }

    (best_ent, best_id)
})
```

My one gripe about this code is I have to manually implement the
minimization loop twice. Normally, I would use `Iterator::min`, but
since floating-point numbers lack total order, we have to roll our own
`min` implementation for floats.

<div class="night-invert">

![Parallel scaling of grading. Here, `L` refers to the number of lanes
used by the SIMD-parallel
version.](scaling.svg)

</div>

When we run the benchmarks, we see pretty good per-thread scaling! The
performance grows linearly with the number of threads until we reach 16
threads. I think the reason for the sudden dropoff is a quirk of
processor architecture. On the 7950X, there are 32 threads on 16 cores,
so the 17th thread has to share a core with another thread. This causes
contention and produces a performance drop. As the thread count
increases, the performance gains slow, and then start to drop at the
very end.

If we want to eke out more performance, though, we'll need to give each
thread a little more flexibility in its schedule. There are currently
two limitations to this method:

1.  We have to wait for the slowest thread. Even though each thread
    theoretically gets the same work, sometimes one thread will take
    extra time. The remaining threads have to sit around waiting for the
    slow thread to finish up instead of contributing meaningful work.
2.  If we want to scale up to finding the best two-word opener, we'll
    have to spawn a bunch of threads thousands of times. The overhead is
    pretty small compared to the grading time, but it adds up when
    we're trying to solve a massive number of problems.

I'll solve both of these issues later, but for now, just know that
there's a better way to go about it - I shall discuss it in detail
shortly. For now, I'll leave you with the final first-round scaling
table.

| Method                         | Runtime (ms) | Mean grading time (ns) |  Speedup |
| :----------------------------- | -----------: | ---------------------: | -------: |
| Naive                          |       3840.0 |                 129.00 |      1.0 |
| Sensible                       |        659.0 |                  22.00 |      5.8 |
| Packed                         |        309.0 |                  10.34 |     12.4 |
| Squeeze                        |        224.0 |                   7.49 |     17.1 |
| SIMD (1 lane)                  |        361.0 |                  12.08 |     10.6 |
| SIMD (2 lanes)                 |        370.0 |                  12.38 |     10.4 |
| SIMD (4 lanes)                 |         87.4 |                   2.91 |     43.9 |
| SIMD (8 lanes)                 |         49.8 |                   1.67 |     77.1 |
| SIMD (16 lanes)                |         55.5 |                   1.86 |     69.2 |
| SIMD (32 lanes)                |         52.8 |                   1.77 |     72.7 |
| Parallel (32 threads, 8 lanes) |          4.8 |                   0.16 | 🏅 798.0 |

## The super-solver

Our grader is now fast enough that we can actually move on to trying to
solve the original problem: finding the best unconditional two-word
opener. However, there are still a few optimizations left! Right now,
checking every possible opener on a single thread would take about 42
minutes, which isn't horrible, but it's more than I have patience for.

### Pruning it down

Not all words are made equal. `salon` and `trice` might be a great
opener, but `qajaq` followed immediately by `qajaq` again is probably
not so good. Ideally, we'd like to avoid doing such a poor job at
grading at all possible.

We can take a branch-and-bound approach: at any point in our search, we
know the best possible opener so far will leave us with expected
remaining entropy $hat(H)_"min"$ after grading the opener. We
also know the initial entropy after no guesses

Hstart, which is a tad over 11 bits for our 2309 opening words. Given a
new opener $w_1, w_2$ we know that the grades from these guesses can yield no more
information than the sum of their independent information $I_(w_1)$ and $I_(w_2)$.
In other words, we can bound the expected remaining entropy
$H_(w_1, w_2)$ with a simple sum.

$$H^*_(w_1, w_2) >= H^*_"start" - I^*_(w_1) - I^*_(w_2)$$

If we find $H_(w_1, w_2) >= H_"min"$, then we know that guessing $w_1, w_2$ will never yield a better result.
That means we can skip the process of grading every possible solution, and simply throw away that
guess.

### The new word order

Once we have this pruning technique, the next step is obvious: we want
to get the best possible value of $H_"start"$ to prune as many guesses as possible.
We can't assume we've
been given the truth, since that would be cheating, but we do already
have an excellent proxy for finding out which guesses might be good. We
can just use the words which minimize the remaing entropy.

In my implementation, I did a triangular search: we work our way
downward in the list of words by remaining entropy. The best three
single-word openers are `soare`, `roate`, and `raise`, so we'd start by
checking `soare, roate`, then `soare, raise`, and finally
`roate, raise`. I decided to skip repeated word pairs as it's pretty
obvious that they wouldn't be any good.

### Parallelism, round 2

Finally, we can circle back around to building a multithreaded solver.
We'd like to build a parallel system which is sufficiently
coarse-grained that each thread doesn't waste time coordinating, but
also ensures that each thread is always fed with work.

The easiest way to do this is with a task queue: at the start of the
program, we spin out all the worker threads. All the threads share a
list of tasks that they need to work on; whenever a thread is done with
its current task, it grabs the next task from the list. In the general
case, the main issue with task queues is that if they are too
fine-grained the contention over the next item in the task queue will
cause slowdowns.

We have a very easy workaround, though. Let's imagine that our program
has been given $|W|$ valid guess words. The number of words is known to us at the start
of the program. We can then represent the next word in the task queue as
a single integer representing the index of the next word. Then each
thread can acquire a new task by incrementing a single number, with no
other coordination required. Once a thread has acquired a word $w$, it can test every single pair of words $w, w'$, which will take a decent chunk of time. The whole queue is quite
easy to implement, since we can just store our task queue state as a
single `AtomicUsize`.

The last problem is sharing our minimum information. If we had atomic
floats, we could use fetch-min operations to update our lower bound on
the expected remaining information. However, most CPU archtectures do
not support such operations. Instead, we can do a cheap trick: convert
every float to a fixed-point number. In my case, I just approximated the
remaining entropy to the nearest one-millionth, then did all the
multithreaded operations with integers.

The final result: we were able to get our unconditional openers in just
15 seconds.

```txt
~/p/wordle (master|✔) $ time ./target/release/wordle answers.txt words.txt
n_threads = 32
Top 10:
clint, soare: 1.5440189
cline, roast: 1.559105
socle, riant: 1.5603062
close, riant: 1.5661579
crine, loast: 1.572707
ceorl, saint: 1.5766429
sonce, trail: 1.5812799
roist, lance: 1.5888369
salon, trice: 1.5888534
clote, sarin: 1.5904317

________________________________________________________
Executed in   14.99 secs    fish           external
    usr time  462.77 secs  402.00 micros  462.77 secs
    sys time    0.34 secs  109.00 micros    0.34 secs
```

Our final answer: `soare`, `clint` is the best unconditional two-word
opener for Wordle. `salon`, `trice` also gets an honorable mention for
being the best opener whose guesses are also possible answers, so you
have a chance at getting a perfect one-guess solution.

One more thing: my brother's favorite guess of (`trace`, `lions`) is
the 197th-best opener, with an expected remaining entropy of 1.687 bits.
That's pretty good overall, given that there are nearly 84 million
possible opening pairs.

## Closing time

I had a lot of fun doing this project! I feel a little bad about taking
so long to write it up - I started working on it about a year ago,
tabled the project, and only recently restarted about 2 months ago.
It's nice to be finally (sort of) finished! If you want to use the
source code, check it out on GitHub here
[here](https://github.com/claytonwramsey/wordle_simd) (AGPL-licensed).

I especially liked the process of building out faster and faster
versions of the grader. The coolest part to me was that there was a
continous gradient between generality and performance: we can keep
adding stronger and stronger assumptions, getting a small performance
bump every time.

I probably didn't save any time working on this: the naive
implementation is only a few hundred times slower than the final
parallel version, so finding the best unconditional opener with the
naive solution would have only required about 3 hours of computation. I
certainly wasted far more than 3 hours optimizing this implementation.

I also have to apologize: the title is a bit of a stretch (sorry for
clickbaiting you). I calculated it approximately by dividing the total
number of checks required by the number time taken. The reason it's not
so accurate is that the pruning process significantly reduces the number
of checks required, so our real grading throughput is more along the
lines of just a few billion grades per second.

If I come back to this project, I want to aim my sights a little higher.
I think it's reasonably possible to calculate a true optimal policy for
solving Wordle in a decent amount of time. The optimal solutions are
known, but I think it would be fun to see if it's possible to bring it
into the range of "check my email" level speed.

---
layout: post
title: "One line of code cost me 9.2% of my matches"
date: 2023-08-26 15:29:00 -0500
tags: rust, chess
---

I can either write a hundred lines of code for one or two Elo or find one or two wrong lines of
code for a hundred Elo.
Such is life.

{% include mathjax.html %}

My long-running slow-burn side project is
[Fiddler, a chess engine](https://github.com/claytonwramsey/fiddler).
The [last time]({% post_url 2023-06-19-fiddler-const-magic %}) I wrote about it, I wrote about 300
lines of code to get a 6 Elo improvement, equivalent to a 1% improvement to its match performance.
This time, I'm writing about a more recent development, when I edited one line of code to get a 64
Elo improvement, for about a 9.2% improvement in match performance.

To avoid clickbaiting you, here's the line in question.

```rust
if best_score >= beta { BoundType::Upper } else { BoundType::Lower }
```

However you'll have to read the rest of this post for a full explanation..

## Learning to sing the alpha-beta

Our story begins with the foundational algorithm of all classical chess engines: alpha-beta search.
It's a small, yet critical improvement to the Minimax algorithm.
By adding a set of bounds parameters, we can reduce the runtime of searching a game tree with
branch factor \\(b\\) and depth \\(d\\) from \\(O(b^d)\\) in Minimax to \\(O(b^{d / 2})\\) in
alpha-beta, subject to some constraints.

The core idea behind alpha-beta is that we never need to search a line that has already been
refuted.
If you try a move and find that it trivially loses the game, there's no point in finding out all the
other ways that playing the move can lose you the game.
Under ideal search heuristics, this means that we only need to check one move (the critical move)
at each depth, which yields a halving in the effective depth of our search.

I'll give a brief pseudocode description of alpha-beta below.

```python
def alpha_beta(game, depth, alpha, beta):
    if depth == 0 or game.is_over():
        return leaf_evaluate(game) # heuristic evaluation of the game

    score = -infinity
    for m in game.moves():
        game.make_move(m)
        score = max(score, -alpha_beta(game, -beta, -alpha))
        game.undo_move()

        alpha = max(alpha, score)
        if score >= beta:
            break

    return score
```

In practice and in my code, most engines use an extension of alpha-beta search called
_principal variation search_; however, we do not need to discuss it for the sake of this post.

## Transposing isn't just for matrices

Those familiar with chess (the kind played by humans) may know the term _transposition_.
Transposition is the process by which two different sequences of moves can reach the same position.
For instance, `e4 e5 Nf3 Nc6` yields the same position as `Nf3 Nc6 e4 e5`.

To take advantage of this, chess engines use a _transposition table_: a glorified hash-map from
positions to useful evaluation data.
If all you care about is the high-level algorithms, you can treat it like a hash-map and call that a
day.
However, since you've bothered to read this far, I think you might like to hear about the internal
details of my transposition table's implementation.
In my engine, every entry in the map stores the evaluation, search depth, best move, and some other
extra data.

```rust
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
/// An entry in the transposition table.
pub struct TTEntry {
    /// A packed tag, containing the entry type and the age.
    /// The high three bits contain the type of the entry (expressed as an [`EntryType`]).
    /// The lower five bits contain the age of the entry.
    tag: u8, // 1 byte
    /// The lower 16 bits of the hash key of the entry.
    key_low16: u16, // 2 bytes
    /// The depth to which this entry was searched.
    /// If the depth is negative, this means that it was a special type of search.
    pub depth: i8, // 1 byte
    /// The best move in the position when this entry was searched.
    pub best_move: Option<Move>, // 2 bytes
    /// The value of the evaluation of this position.
    pub value: Eval, // 2 bytes
} /* total size: 8 bytes */
```

However, just storing a raw evaluation in the transposition table is insufficient.
The core problem is that in an alpha-beta search, the evaluations of a position are not exact:
often, we don't know the exact evaluation of a position, only a lower or upper bound on its value.
If you wanted, you could store a pair containing the upper and lower bound of the evaluation
for each position, but that requires 32 bits - not very efficient.

In my engine, each evaluation is a 16-bit integer.
Meanwhile, there are three possible cases for the type of an evaluation:

- **exact evaluations**, where the value stored in the table is the exact value of the evaluation of
  the position,
- **lower bounds**, where a beta cutoff has occurred, and
- **upper bounds**, where an alpha cutoff has occurred.

If we assume that all values of an `Eval` are used, that means we need to express
\\(16 + \log 3 \approxeq 17.6\\) bits of information in each entry.
To avoid rounding up to 24 bits (for word-alignment), we can squeeze that extra bound-type
information in with the other entry-type information.

```rust
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
/// The types of bounds that an entry can have.
/// These are used to determine whether a bound is binding during a search.
pub enum BoundType {
    /// A lower bound on the evaluation of the position.
    Lower = 1 << 5,
    /// An upper bound on the evaluation of the position.
    Upper = 2 << 5,
    /// An exact bound on the evaluation of the position.
    Exact = 3 << 5,
}

#[repr(u8)]
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
/// The liveness of a transposition table entry.
enum EntryType {
    #[allow(unused)]
    /// An empty entry, with no occupied or deleted entries following it.
    // this is never directly constructed but zeroed memory from `alloc_zeroed` causes it to
    // contain this, so we cannot remove this variant.
    Empty = 0,
    /// An extant entry which is a lower bound on a position evaluation.
    _Lower = BoundType::Lower as u8,
    /// An extant entry which is an upper bound on a position evaluation.
    _Upper = BoundType::Upper as u8,
    /// An extant entry which is an exact bound on a position evaluation.
    _Exact = BoundType::Exact as u8,
    /// A deleted entry, which may have extra data inside it.
    Deleted = 4 << 5,
}
```

Those familiar with open-addressed hashing will understand the need for both an "empty" and a
"deleted" entry type.
We convert back and forth between `BoundType`s (a convenient public API for the transposition
table), `EntryType`s (used internally to discuss whether an entry is full), and `u8` (packing an
entry type with its age) via evil cursed unsafe magic in the implementation.
However, the details of my transposition table implementation are a story for another time.
The takeaway is that entries can be marked with their bounding types.

## When to tag with what

When retrieving from the transposition table, we can use this bounding information to determine
whether we can quickly cause a cutoff.
I'll truncate out most of the pomp and circumstance surrounding retrieval from a transposition
table, but by and large it looks like this:

```rust
let entry = /* probe the transposition table, check if it's there, blah blah blah */;
if entry.depth >= depth {
    let cutoff = match entry.bound_type() {
        BoundType::Exact => true,
        BoundType::Lower => beta <= value,
        BoundType::Upper => value <= alpha,
    };

    if cutoff {
        return Ok(value);
    }
}
```

An exact bound means that the search can quit early (huzzah!), while looser bounds restrict the
search to comparing against alpha and beta.

When inserting into the transposition table, we also need to decide how to tag our evaluations.
We can do this by a pretty simple rule, though:

- If there was a beta-cutoff, this is a lower bound.
- If we never raised the value of `alpha`, this is an upper bound.
- If neither occurred, this is an exact bound.

## Quieting down

Most chess engines also have a search function called _quiescent search_.
Engines only examine captures and promotions during a quiescent search.
The goal of a quiescent search is to reach a quiet position: we want to ensure that our static
evaluation function doesn't assume that sacrificing a queen for a pawn is the best way to finish a
tactical sequence.

Otherwise, a quiescent search is a lot like a regular alpha-beta search, employing most of the same
techniques, including the transposition tables.

## The mistake in itself

When I originally wrote my quiescent search, I had noticed that a quiescent search doesn't visit
every move, much like in a beta-cutoff in an alpha-beta search.
Accordingly, I assumed that most of the time, the quiescent search yielded a lower bound.
However, I also knew that something different should be happening when a beta-cutoff occurred, so I
created this monstrosity:

```rust
// end of the quiescent search procedure
tt_guard.save(
    // search depth
    TTEntry::DEPTH_CAPTURES,
    // best move
    best_move,
    // evaluation
    best_score.step_forward_by(state.depth_since_root),
    // bound type
    if best_score >= beta {
        BoundType::Upper
    } else {
        BoundType::Lower
    },
);
```

I called the version of Fiddler using this approach `fiddler_quiesce_lu`.
You can safely ignore the rest of the ceremony, but remember what we've passed in as a bound type:
if the evaluation is _bigger_ than beta, it's an upper bound.
This criterion makes absolutely no sense, and it really should not have gone undiscovered for this
long.
However, all this bound does is make searches less efficient, rather than incorrect, so none of my
numerous tests failed due to it.

I eventually tried a few fixes.
First, I tried marking every quiescent-searched position as a lower bound.

```rust
tt_guard.save(
    TTEntry::DEPTH_CAPTURES,
    best_move,
    best_score.step_forward_by(state.depth_since_root),
    BoundType::Lower
);
```

I called this version `fiddler_quiesce_lower`.
This yielded a nice improvement from "wrong" to "not quite correct."
In fact, our bounds are much tighter, so I finally settled on getting some exact results, correctly
determining which type of bound we should use.

```rust
tt_guard.save(
    TTEntry::DEPTH_CAPTURES,
    best_move,
    best_score.step_forward_by(state.depth_since_root),
    if best_score >= beta {
        BoundType::Lower
    } else if PV && overwrote_alpha {
        BoundType::Exact
    } else {
        BoundType::Upper
    },
);
```

I called this final version `fiddler_leu`.

## The results

Naturally, I have to provide proof of my bombastic title claims.
Accordingly, I ran a lengthy tournament overnight on my poor little laptop to see just how bad my
original implementation was.
After 3000 hyper-bullet games, here are the final results.

```text
Rank Name                          Elo     +/-   Games   Score    Draw
   1 fiddler_leu                    26      13    2000   53.7%   25.7%
   2 fiddler_quiesce_lower          13      13    2000   51.8%   25.1%
   3 fiddler_quiesce_lu            -38      13    2000   44.5%   24.5%

SPRT: llr 0 (0.0%), lbound -inf, ubound inf
3000 of 3000 games finished
```

The good news is that `fiddler_leu`, the most "theoretically correct" of all the implementations,
also performs the best.
I would have liked to run more matches to get a clear difference between `fiddler_leu` and
`fiddler_quiesce_lower`, but the AC at my apartment isn't working, and I'm not sure how much my poor
little laptop can take.

## Have I learned anything?

I would like to believe that I write fewer bugs now than I ever did before, but that's likely just
because I have yet to find the bugs that I'm writing right now.
However, I'm trying to get better at not introducing easily-avoidable regressions into my chess
engine.
My current workflow now looks like this:

1. Think of a cool new feature.
1. Create a new development branch and implement the feature.
1. Run a tournament between the development branch and master and see if we've improved anything.
1. Only merge the development branch when there's an improvement.

I suspect that somewhere along the way, I'm committing statistical crimes beyond imagination.
However, this workflow has done a lot to help me to make the engine better.
I still think that my engine must have some serious latent logic errors somewhere because it's still
punching far below its weight class.
Currently, it's still not even beating out some simple engines - the kind which haven't even
implemented late move reduction.

This is the chess engine experience: I spend more time catching up with my own mistakes than I do
on making newer, more exciting mistakes.

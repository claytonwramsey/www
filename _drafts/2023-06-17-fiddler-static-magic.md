---
layout: post
title: "Blowing up my compile times for fun and profit"
date: 2023-06-17 09:53:00 -0500
categories: rust, chess
---

{% include mathjax.html %}

For the last two years, I've been building a
[chess engine called Fiddler](https://github.com/claytonwramsey/fiddler).
It's not very good by chess engine standards, but that's not the point - I mostly work on it for
funsies.

As part of my eternal quest for useless optimization, I'm reworking my move generator to more
heavily use static, precomputed data rather than runtime generation.
Most recently, I'm moving from dynamically generating and heap-allocating the magic move generation
table to making it a statically allocated constant.
Along the way, I'll take this opportunity to explain how magic move generation works, and hopefully
have a little fun.

## A crash course in magic moves

Chess engines are usually extremely high-performance pieces of software, and their move generators
are some of the most high-performance parts of them.
Most move generators can generate hundreds of millions of moves, per core, per second.
Mine included!

The majority of moves are made by sliding pieces - the bishop, rook, and queen - so we'll dedicate
most of our effort toward making that fast.
The most naive approach would be to represent a board as an array of pieces, and then, for each
piece, iterate outward along a ray, adding moves until we encounter a blocker.
The problem with that approach is simply that it's far too slow.
In the worst case, finding the set of legal moves for a queen on E4 would require 27 different array
accesses - and that's just the moves for one piece! We're going to need a different approach.

### Bitboards

We can start by representing the occupancy of a board using a _bitboard_: a set of squares
represented by a unique 64-bit integer.
Convention dictates that the least-significant bit should be set if the square A1 is occupied, the
second-least-significant to represent B1, and so on until the most significant bit which represents
H8.

Here's a quick map displaying which bit in a bitboards corresponds to a square, indexed from the
LSB:

```text
8 | 56 57 58 59 60 61 62 63
7 | 48 49 50 51 52 53 54 55
6 | 40 41 42 43 44 45 46 47
5 | 32 33 34 35 36 37 38 39
4 | 24 25 26 27 28 29 30 31
3 | 16 17 18 19 20 21 22 23
2 |  8  9 10 11 12 13 14 15
1 |  0  1  2  3  4  5  6  7
--+------------------------
  |  A  B  C  D  E  F  G  H
```

For example, consider a board with a piece on A2, G3, and C7.
A2 has index 1, G3 has index 22, and C7 has index 50, so the bitboard uniquely representing
{A2, G3, C7} is \\(2^1 + 2^{22} + 2^{50}\\), which is equal to 1125899911036930.

We can use our bitboards to compute setwise operations in \\(O(1)\\) time.
Here's a short (but not exhaustive) list of operations we can do:

| Mathematical representation | Bitboard operation |
| --------------------------- | ------------------ | --- |
| \\(A \\cup B\\)             | `a & b`            |
| \\(A \\cap B\\)             | `a                 | b`  |
| \\(A \\Delta B\\)           | `a ^ b`            |
| \\(\\bar A \\)              | `!A`               |

### Building a lookup table

In order to get an \\(O(1)\\) computation of sliding moves, we can use a lookup table to find
precomputed values of the set of legal moves given the starting square and occupancy bitboard of a
board.
There's just one problem: There are an enormous amount of possible occupancy maps, roughly
\\(\\sum\_{n=3}^{16} {64 \\choose n}\\) possible occupancies containing at least two kings and a
sliding piece, or about 700 trillion total boards.
To store an 8-byte bitboard for every square and occupancy would require roughly 365 PB of data!

We can use a nice trick to reduce our data consumption, though.
In our naive algorithm for sliding move generation, we only needed to examine whether the squares
that we wanted our piece to move to were occupied - other squares not on the same ray were
irrelevant.
We can do the same: we can somehow extract out the relevant occupancies for any square's move
generation.

For example, these are the only relevant squares for the set of legal moves for a rook on E4:

```text
8 |  .  .  .  .  .  .  .  .
7 |  .  .  .  .  x  .  .  .
6 |  .  .  .  .  x  .  .  .
5 |  .  .  .  .  x  .  .  .
4 |  .  x  x  x  .  x  x  .
3 |  .  .  .  .  x  .  .  .
2 |  .  .  .  .  x  .  .  .
1 |  .  .  .  .  .  .  .  .
--+------------------------
  |  A  B  C  D  E  F  G  H
```

For each square, then, we only need to consider a small handful of occupied spots.
All we need to do is store a lookup for every `(square, relevant_occupancy)` pair, which is far
smaller than the previous requirement.

There are at most 9 relevant occupancy bits for a bishop and 12 bits for a rook, so the total memory
requirement for this lookup table is less than 2.4 MB.
If we break out the single master lookup table into a unique lookup table for each attacker type and
starter square, we can get a smaller total memory consumption at only 861 kB.

### Where the magic happens

However, we still have to be able to convert an occupancy bitboard into an index.
What we really want to do is to take our masked out bits and extract them into an index.
On x86 architecturs, the `pext` instruction is exactly designed to do this, but if we want it to
work on any architecture, we'll have to be a little more clever than that.

I'll start with a magic example, and we'll see if that can enlighten us.
Suppose we want to extract the relevant occupancy for a bishop on B2.

Take the original masked occupancy bitboard, \\(O\\).

```
8 |  .  .  .  .  .  .  .  .
7 |  .  .  .  .  .  .  .  .
6 |  .  .  .  .  .  .  b5 .
5 |  .  .  .  .  .  b4 .  .
4 |  .  .  .  .  b3 .  .  .
3 |  .  .  .  b2 .  .  .  .
2 |  .  .  b1 .  .  .  .  .
1 |  .  .  .  .  .  .  .  .
--+------------------------
  |  A  B  C  D  E  F  G  H
```

Observe that \\(O = b_1 2^{10} + b_2 2^{19} + b_3 2^{28} + b_4 2^{37} + b_5 2^{46}\\).

Now, multiply \\(O\\) by the magic number \\(M = 2^{17} + 2^{25} + 2^{33} + 2^{41} + 2^{49}\\).

\\[O * M = b_1 2^{59} + b_2 2^{60} + b_3 2^{61} + b_4 2^{62} + b_5 2^{63} + \\text{garbage on other exponents}\\]

Using simple bitwise masking, we can then manually retrieve those packed bits to use as our index.
We can generate a set of 128 magic numbers (64 for bishops, 64 for rooks) which individually can be
used to map each square and occupancy to extract its bits, and then use that operation to retrieve
a pre-computed set of moves in constant time.

_Side note_: Most of the time, there are actually collisions when using magic numbers.
However, so long as the collisions map the same final moveset, that's OK, so finding magics is
actually pretty easy - brute force search works quite well.

## Getting down to business

Most engines both compute all their magic numbers as part of their startup routines.
Before this week, I included the magic numbers as static constants and computed the entire table of
movesets at startup.
However, due to the limitations of Rust, I ended up using
[`once_cell`](https://docs.rs/once_cell/latest/once_cell/)'s `Lazy` for initializing the move lookup
table.
This had the benefit of being really easy to implement, but it also meant that every time move
generation was required (i.e. millions of times per second) the engine had to check whether the
moves lookup table had already been loaded.

Now, I have to rewrite it from scratch, but in "hard" mode - to make all the constants known at
compile time, everything has to be written in a `const` function.
This means:

- No allocations
- No printing
- No panicking
- No for loops
- No trait methods

Let's get right to it by describing our data layout.
We begin by implementing a `Bitboard` by wrapping `u64`:

```rust
#[derive(Copy, Clone, Debug, PartialEq, Eq)]
#[repr(transparent)]
pub struct Bitboard(u64);
```

For every square and sliding piece type, we'll create a structure called an `AttacksLayout`:

```rust
/// A lookup table for generating attacks via magic bitboard for one piece type and square.
struct AttacksLookup {
    /// A reference to this lookup's section of the magic attacks.
    table: &'static [Bitboard],
    /// The mask for extracting out the relevant occupancy map on a board.
    mask: Bitboard,
    /// The magic multiply constant for converting occupancies to indices.
    magic: u64,
    /// The shift to extract an index from a multiplied constant.
    shift: u8,
}
```

In order for us to have a "ragged" moves-lookup table, we don't have each `AttacksLookup` own its
attack set, since that would result in extremely inefficient space usage and an enormous increase
in what will already be a very large binary.
Instead, we store _all_ of the moves-lookup tables in one giant array, and have each `AttacksLookup`
have a reference to its section of that array.

Let's try to populate that array, staying mindful of our lack of for-loops.

```rust
/// A saved list of magic multiply numbers for bishops, indexed by the square they're used for.
const SAVED_BISHOP_MAGICS: [u64; 64] = [
    /* 64 lines removed */
];

/// Log-base-2 of the number of entries required in the moves-lookup table for each square.
const ROOK_BITS: [u8; 64] = [
    12, 11, 11, 11, 11, 11, 11, 12, // rank 1
    11, 10, 10, 10, 10, 10, 10, 11, // 2
    11, 10, 10, 10, 10, 10, 10, 11, // 3
    11, 10, 10, 10, 10, 10, 10, 11, // 4
    11, 10, 10, 10, 10, 10, 10, 11, // 5
    11, 10, 10, 10, 10, 10, 10, 11, // 6
    10, 9, 9, 9, 9, 9, 9, 10, // 7
    11, 10, 10, 10, 10, 11, 10, 11, // 8
];

/// Compute the number of entries in a magic-movegen table required to store every element, given
/// the number of bits required for each square.
const fn table_size(bits_table: &[u8; 64]) -> usize {
    let mut i = 0;
    let mut total = 0;
    while i < 64 { // POV you don't have iterators
        total += 1 << bits_table[i];
        i += 1;
    }
    total
}

/// The bitwise masks for extracting the relevant pieces for a rook's attacks in a board, indexed
/// by the square occupied by the rook.
const ROOK_MASKS: [Bitboard; 64] = {
    let mut masks = [Bitboard::EMPTY; 64];
    let mut i = 0u8;
    while i < 64 {
        masks[i as usize] = get_rook_mask(unsafe { transmute(i) });
        i += 1;
    }
    masks
};

/// The master table containing every attack that the rook can perform from every square under
/// every occupancy.
/// Borrowed by the individual [`AttacksLookup`]s in [`ROOK_LOOKUPS`].
const ROOK_ATTACKS_TABLE: [Bitboard; table_size(&ROOK_BITS)] = construct_magic_table(
    &ROOK_BITS,
    &SAVED_ROOK_MAGICS,
    &ROOK_MASKS,
    &Direction::ROOK_DIRECTIONS,
);

/// The necessary information for generatng attacks for rook, indexed b the square occupied by
/// said rook.
const ROOK_LOOKUPS: [AttacksLookup; 64] = construct_lookups(
    &ROOK_BITS,
    &SAVED_ROOK_MAGICS,
    &ROOK_MASKS,
    &ROOK_ATTACKS_TABLE,
);

pub fn rook_moves(occupancy: Bitboard, sq: Square) -> Bitboard {
    let magic_data = unsafe { ROOK_LOOKUPS.get_unchecked(sq as usize) };
    let key = compute_magic_key(occupancy & magic_data.mask, magic_data.magic, magic_data.shift);

    unsafe { *magic_data.table.get_unchecked(key) }
}
```

While you weren't looking, I wrote the code for `get_rook_mask` `construct_magic_table`, and
`construct_lookups`.
They all do some relatively simple drudgery, made verbose by the limitations of `const` Rust.

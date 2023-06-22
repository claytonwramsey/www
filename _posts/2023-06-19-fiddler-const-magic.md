---
layout: post
title: "Blowing up my compile times for dubious benefits"
date: 2023-06-19 23:33:00 -0500
tags: rust, chess
---

The tree of useless optimization yields questionable fruit.

{% include mathjax.html %}

For the last two years, I've been building a
[chess engine called Fiddler](https://github.com/claytonwramsey/fiddler).
It's not very good by chess engine standards, but that's not the point - I mostly work on it for
funsies.

Right now, I'm reworking my move generator to more
heavily use static, precomputed data rather than runtime generation.
Most recently, I'm moving from dynamically generating and heap-allocating the magic move generation
table to making it a statically allocated constant.
Along the way, I'll take this opportunity to explain how magic move generation works, and hopefully
have a little fun.

**Update 2023-06-22:** I've added a few updates to handle questions that people in the comments on
the [Orange Website](https://news.ycombinator.com/item?id=36399832) found confusing.

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

For example, consider a board with a piece on B1, G3, and C7.
B1 has index 1, G3 has index 22, and C7 has index 50, so the bitboard uniquely representing
{B1, G3, C7} is \\(2^1 + 2^{22} + 2^{50}\\), which is equal to 1125899911036930.

We can use our bitboards to compute setwise operations in \\(O(1)\\) time.
Here's a short (but not exhaustive) list of operations we can do:

| Mathematical representation | Bitboard operation |
| --------------------------- | ------------------ | --- |
| \\(A \\cup B\\)             | `a & b`            |
| \\(A \\cap B\\)             | `a                 | b`  |
| \\(A \\Delta B\\)           | `a ^ b`            |
| \\(\\bar A \\)              | `!a`               |

**Update 2023-06-22:** I use Rust's notation for `!a`.
In C and C++, one would use `~a` for the bitwise not operation.

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

**Update 2023-06-22**:
We can safely ignore those squares on the edge of the board because they actually don't affect what
our rook can "see."
For instance, the rook will be able to to see H4 if F4 and G4 are empty, but whether H4 is empty
does not affect whether the rook can see H4.
Once we have the set of squares the rook can see, we can convert that to the set of squares the rook
can move to by masking out all pieces of the same color as the rook.

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
On x86 architectures, the `pext` instruction is exactly designed to do this, but if we want it to
work on any architecture, we'll have to be a little more clever than that.

I'll start with a magic example, and we'll see if that can enlighten us.
Suppose we want to extract the relevant occupancy for a bishop on B2.

Take the original masked occupancy bitboard, \\(O\\).

```text
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

Using simple bitwise masking, we can then manually retrieve those packed bits near the MSB to use as
our index.
We can generate a set of 128 magic numbers (64 for bishops, 64 for rooks) which individually can be
used to map each square and occupancy to extract its bits, and then use that operation to retrieve
a pre-computed set of moves in constant time.

_Side note_: Most of the time, there are actually collisions when using magic numbers.
Collisions occur when our magic multiply doesn't perfectly extract the relevant bits, but instead
returns some other, bizarre combination of our relevant bits as the index.
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

For every square and sliding piece type, we'll create a structure called an `AttacksLookup`:

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
First, we'll store our magic numbers:

```rust
/// A saved list of magic multiply numbers for rooks, indexed by the square they're used for.
const SAVED_ROOK_MAGICS: [u64; 64] = [
    /* 64 lines removed */
];
```

These magic numbers can be found offline via trial and error, but there are also public records
of magic numbers.
For example, the Chess Programming wiki
[keeps a record of magic numbers](https://www.chessprogramming.org/Best_Magics_so_far).

Next, we need to know how much storage to allocate for all the rook moves.
We do this by first storing a table of how many entries are needed for each square to calculate our
moves.

```rust
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
```

You may notice something odd happening on ranks 7 and 8: the number of bits required for some of the
squares is 1 lower than their mask.
This is intentional!
As it turns out, certain magic numbers will yield just the right set of hash collisions so that you
can use half as many entries are there are occupancies.
This saves about 18 kB of data.

The size of our table is just the sum of 2 to the power of the number of bits required for each
square:

```rust
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
```

We also need to construct the masks for each square.
`get_rook_masks` takes in a `Square` (hence the call to `transmute`) and builds the relevant
occupancy mask for the square.

```rust
/// The bitwise masks for extracting the relevant pieces for a rook's attacks in a board, indexed
/// by the square occupied by the rook.
const ROOK_MASKS: [Bitboard; 64] = {
    let mut masks = [Bitboard::EMPTY; 64];
    let mut i = 0u8;
    while i < 64 {
        masks[i as usize] = get_rook_mask(unsafe { transmute::<u8, Square>(i) });
        i += 1;
    }
    masks
};

/// Create the mask for the relevant bits in magic of a rook.
/// `sq` is the identifying the square that we want to generate the mask for.
const fn get_rook_mask(sq: Square) -> Bitboard {
    // sequence of 1s down the same row as the piece to move, except on the ends
    let row_mask = 0x7E << (sq as u8 & !0x7);
    // sequence of 1s down the same col as the piece to move, except on the ends
    let col_mask = 0x0001_0101_0101_0100 << (sq as u8 & 0x7);
    // note: pieces at the end of the travel don't matter, which is why the masks aren't uniform

    // in the col mask or row mask, but not the piece to move
    Bitboard::new((row_mask | col_mask) & !(1 << sq as u64))
}
```

We now have enough to actually build the full set of attacks.
We do this via brute force: for every possible occupancy, we calculate the set of legal moves, and
then save the legal moves at the correct index.

```rust
/// The master table containing every attack that the rook can perform from every square under
/// every occupancy.
/// Borrowed by the individual [`AttacksLookup`]s in [`ROOK_LOOKUPS`].
const ROOK_ATTACKS_TABLE: [Bitboard; table_size(&ROOK_BITS)] = construct_magic_table(
    &ROOK_BITS,
    &SAVED_ROOK_MAGICS,
    &ROOK_MASKS,
    &Direction::ROOK_DIRECTIONS,
);

/// Construct the master magic table for a rook or bishop based on all the requisite information.
///
/// # Inputs
///
/// - `bits`: For each square, the number of other squares which are involved in the calculation of
///   attacks from that square.
/// - `magics`: The magic numbers for each square.
/// - `masks`: The masks used for extracting the relevant squares for an attack on each starting
///   square.
/// - `dirs`: The directions in which the piece can move
const fn construct_magic_table<const N: usize>(
    bits: &[u8; 64],
    magics: &[u64; 64],
    masks: &[Bitboard; 64],
    dirs: &[Direction],
) -> [Bitboard; N] {
    let mut table = [Bitboard::EMPTY; N];

    let mut i = 0;
    let mut table_offset = 0;

    while i < 64 {
        let sq: Square = unsafe { transmute(i as u8) };
        let mask = masks[i];
        let magic = magics[i];
        let n_attacks_to_generate = 1 << mask.len();

        let mut j = 0;
        while j < n_attacks_to_generate {
            let occupancy = index_to_occupancy(j, mask);
            let attack = directional_attacks(sq, dirs, occupancy);
            let key = compute_magic_key(occupancy, magic, 64 - bits[i]);
            table[key + table_offset] = attack;
            j += 1;
        }

        table_offset += 1 << bits[i];
        i += 1;
    }

    table
}
```

<details markdown="1">

<summary markdown="span">

`compute_magic_key` and the other helper functions called above can be implemented with some basic
drudgery.

</summary>

```rust
/// Given some mask, create the occupancy [`Bitboard`] according to this index.
///
/// `index` must be less than or equal to 2 ^ (number of ones in `mask`).
/// This is equivalent to the parallel-bits-deposit (PDEP) instruction on x86 architectures.
const fn index_to_occupancy(index: usize, mask: Bitboard) -> Bitboard {
    let mut result = 0u64;
    let num_points = mask.len();
    let mut editable_mask = mask.as_u64();
    // go from right to left in the bits of num_points,
    // and add an occupancy if something is there
    let mut i = 0;
    while i < num_points {
        // make a bitboard which only occupies the rightmost square
        let occupier = 1 << editable_mask.trailing_zeros();
        // remove the occupier from the mask
        editable_mask &= !occupier;
        if (index & (1 << i)) != 0 {
            // the bit corresponding to the occupier is nonzero
            result |= occupier;
        }
        i += 1;
    }

    Bitboard::new(result)
}

/// Construct the squares attacked by the pieces at `sq` if it could move along the directions in
/// `dirs` when the board is occupied by the pieces in `occupancy`.
///
/// This is slow and should only be used for generatic magic bitboards (instead of for move
/// generation.
const fn directional_attacks(
    sq: Square,
    dirs: &[Direction],
    occupancy: Bitboard,
) -> Bitboard {
    // behold: much hackery for making this work as a const fn
    let mut result = Bitboard::EMPTY;
    let mut dir_idx = 0;
    while dir_idx < dirs.len() {
        let dir = dirs[dir_idx];
        let mut current_square = sq;
        let mut loop_idx = 0;
        while loop_idx < 7 {
            let next_square_int: i16 = current_square as i16
                + unsafe {
                    transmute::<Direction, i8>(dir) as i16
                };
            if next_square_int < 0 || 64 <= next_square_int {
                break;
            }
            let next_square: Square = unsafe { transmute(next_square_int as u8) };
            if next_square.chebyshev_to(current_square) > 1 {
                break;
            }
            result = result.with_square(next_square);
            if occupancy.contains(next_square) {
                break;
            }
            current_square = next_square;
            loop_idx += 1;
        }
        dir_idx += 1;
    }

    result
}

/// Use magic hashing to get the index to look up attacks in a bitboard.
const fn compute_magic_key(occupancy: Bitboard, magic: u64, shift: u8) -> usize {
    (occupancy.as_u64().wrapping_mul(magic) >> shift) as usize
}
```

</details>

<br>

Lastly, we build each individual `AttacksLookup` with its references to `ROOK_ATTACKS_TABLE`.

```rust
/// The necessary information for generatng attacks for rook, indexed b the square occupied by
/// said rook.
const ROOK_LOOKUPS: [AttacksLookup; 64] = construct_lookups(
    &ROOK_BITS,
    &SAVED_ROOK_MAGICS,
    &ROOK_MASKS,
    &ROOK_ATTACKS_TABLE,
);

/// Construct the lookup tables for magic move generation by referencing an already-generated
/// attacks table.
const fn construct_lookups(
    bits: &[u8; 64],
    magics: &[u64; 64],
    masks: &[Bitboard; 64],
    attacks_table: &'static [Bitboard],
) -> [AttacksLookup; 64] {
    unsafe {
        let mut table: [MaybeUninit<AttacksLookup>; 64] = MaybeUninit::uninit().assume_init();

        let mut remaining_attacks = attacks_table;
        let mut i = 0;
        while i < 64 {
            let these_attacks;
            (these_attacks, remaining_attacks) = remaining_attacks.split_at(1 << bits[i]);
            table[i] = MaybeUninit::new(AttacksLookup {
                table: these_attacks,
                mask: masks[i],
                magic: magics[i],
                shift: 64 - bits[i],
            });

            i += 1;
        }

        transmute(table)
    }
}
```

In order to compute the moves for the rook, we work backwards, going from the `AttacksLookup` into
the table.
For performance, we perform unchecked array accesses.
We can prove they're always safe because `Square`s can only have values from 0 through 63, and
we know our key generation code is producing a low enough index to not go out of bounds.

```rust
pub fn rook_moves(occupancy: Bitboard, sq: Square) -> Bitboard {
    let magic_data = unsafe { ROOK_LOOKUPS.get_unchecked(sq as usize) };
    let key = compute_magic_key(occupancy & magic_data.mask, magic_data.magic, magic_data.shift);

    unsafe { *magic_data.table.get_unchecked(key) }

}
```

While you weren't looking, I wrote some very similar code for writing the bishop moves-lookup table.
In all, it's about 300 lines of code.

## \<insert Rust compiler speed joke here\>

It's now time to compile our code.
Running `cargo build`, we get to wait about 30 seconds until we encounter this beauty of an output:

```text
~/C/fiddler (static_magic|✚2) $ cargo build
   Compiling fiddler v0.1.0 (/home/clayton/Chess/fiddler)
note: erroneous constant used
   --> src/base/movegen/magic.rs:328:6
    |
328 |     &ROOK_ATTACKS_TABLE,
    |      ^^^^^^^^^^^^^^^^^^

note: erroneous constant used
  --> src/base/movegen/magic.rs:87:33
   |
87 |     get_attacks(occupancy, sq, &ROOK_LOOKUPS)
   |                                 ^^^^^^^^^^^^

note: erroneous constant used
  --> src/base/movegen/magic.rs:87:32
   |
87 |     get_attacks(occupancy, sq, &ROOK_LOOKUPS)
   |                                ^^^^^^^^^^^^^

error: internal compiler error: no errors encountered even though `delay_span_bug` issued

error: internal compiler error: The deny lint should have already errored
   --> /home/clayton/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu/lib/rustlib/src/rust/library/core/src/num/mod.rs:297:5
    |
297 | /     int_impl! {
298 | |         Self = i8,
299 | |         ActualT = i8,
300 | |         UnsignedT = u8,
...   |
315 | |         bound_condition = "",
316 | |     }
    | |_____^
    |
    = note: delayed at compiler/rustc_const_eval/src/const_eval/machine.rs:634:26
               0: <rustc_errors::HandlerInner>::emit_diagnostic
               1: <rustc_errors::Handler>::delay_span_bug::<rustc_span::span_encoding::Span, &str>
               2: <rustc_const_eval::interpret::eval_context::InterpCx<rustc_const_eval::const_eval::machine::CompileTimeInterpreter>>::statement
               3: rustc_const_eval::const_eval::eval_queries::eval_to_allocation_raw_provider
               4: rustc_query_impl::plumbing::__rust_begin_short_backtrace::<rustc_query_impl::query_impl::eval_to_allocation_raw::dynamic_query::{closure#2}::{closure#0}, rustc_middle::query::erase::Erased<[u8; 16]>>
               5: <rustc_query_impl::query_impl::eval_to_allocation_raw::dynamic_query::{closure#2} as core::ops::function::FnOnce<(rustc_middle::ty::context::TyCtxt, rustc_middle::ty::ParamEnvAnd<rustc_middle::mir::interpret::GlobalId>)>>::call_once
               6: <rustc_query_system::query::plumbing::execute_job_incr<rustc_query_impl::DynamicConfig<rustc_query_system::query::caches::DefaultCache<rustc_middle::ty::ParamEnvAnd<rustc_middle::mir::interpret::GlobalId>, rustc_middle::query::erase::Erased<[u8; 32]>>, false, false, false>, rustc_query_impl::plumbing::QueryCtxt>::{closure#2}::{closure#2} as core::ops::function::FnOnce<((rustc_query_impl::plumbing::QueryCtxt, rustc_query_impl::DynamicConfig<rustc_query_system::query::caches::DefaultCache<rustc_middle::ty::ParamEnvAnd<rustc_middle::mir::interpret::GlobalId>, rustc_middle::query::erase::Erased<[u8; 32]>>, false, false, false>), rustc_middle::ty::ParamEnvAnd<rustc_middle::mir::interpret::GlobalId>)>>::call_once
               7: rustc_query_system::query::plumbing::try_execute_query::<rustc_query_impl::DynamicConfig<rustc_query_system::query::caches::DefaultCache<rustc_middle::ty::ParamEnvAnd<rustc_middle::mir::interpret::GlobalId>, rustc_middle::query::erase::Erased<[u8; 16]>>, false, false, false>, rustc_query_impl::plumbing::QueryCtxt, true>
               8: rustc_query_impl::query_impl::eval_to_allocation_raw::get_query_incr::__rust_end_short_backtrace
               9: <rustc_const_eval::interpret::eval_context::InterpCx<rustc_const_eval::const_eval::machine::CompileTimeInterpreter>>::eval_mir_constant
              10: <rustc_const_eval::interpret::eval_context::InterpCx<rustc_const_eval::const_eval::machine::CompileTimeInterpreter>>::push_stack_frame
              11: rustc_const_eval::const_eval::eval_queries::eval_to_allocation_raw_provider
              12: rustc_query_impl::plumbing::__rust_begin_short_backtrace::<rustc_query_impl::query_impl::eval_to_allocation_raw::dynamic_query::{closure#2}::{closure#0}, rustc_middle::query::erase::Erased<[u8; 16]>>
              13: <rustc_query_impl::query_impl::eval_to_allocation_raw::dynamic_query::{closure#2} as core::ops::function::FnOnce<(rustc_middle::ty::context::TyCtxt, rustc_middle::ty::ParamEnvAnd<rustc_middle::mir::interpret::GlobalId>)>>::call_once
              14: <rustc_query_system::query::plumbing::execute_job_incr<rustc_query_impl::DynamicConfig<rustc_query_system::query::caches::DefaultCache<rustc_middle::ty::ParamEnvAnd<rustc_middle::mir::interpret::GlobalId>, rustc_middle::query::erase::Erased<[u8; 32]>>, false, false, false>, rustc_query_impl::plumbing::QueryCtxt>::{closure#2}::{closure#2} as core::ops::function::FnOnce<((rustc_query_impl::plumbing::QueryCtxt, rustc_query_impl::DynamicConfig<rustc_query_system::query::caches::DefaultCache<rustc_middle::ty::ParamEnvAnd<rustc_middle::mir::interpret::GlobalId>, rustc_middle::query::erase::Erased<[u8; 32]>>, false, false, false>), rustc_middle::ty::ParamEnvAnd<rustc_middle::mir::interpret::GlobalId>)>>::call_once
              15: rustc_query_system::query::plumbing::try_execute_query::<rustc_query_impl::DynamicConfig<rustc_query_system::query::caches::DefaultCache<rustc_middle::ty::ParamEnvAnd<rustc_middle::mir::interpret::GlobalId>, rustc_middle::query::erase::Erased<[u8; 16]>>, false, false, false>, rustc_query_impl::plumbing::QueryCtxt, true>
              16: rustc_query_impl::query_impl::eval_to_allocation_raw::get_query_incr::__rust_end_short_backtrace
              17: <rustc_const_eval::interpret::eval_context::InterpCx<rustc_const_eval::const_eval::machine::CompileTimeInterpreter>>::statement
              18: rustc_const_eval::const_eval::eval_queries::eval_to_allocation_raw_provider
              19: rustc_query_impl::plumbing::__rust_begin_short_backtrace::<rustc_query_impl::query_impl::eval_to_allocation_raw::dynamic_query::{closure#2}::{closure#0}, rustc_middle::query::erase::Erased<[u8; 16]>>
              20: <rustc_query_impl::query_impl::eval_to_allocation_raw::dynamic_query::{closure#2} as core::ops::function::FnOnce<(rustc_middle::ty::context::TyCtxt, rustc_middle::ty::ParamEnvAnd<rustc_middle::mir::interpret::GlobalId>)>>::call_once
              21: <rustc_query_system::query::plumbing::execute_job_incr<rustc_query_impl::DynamicConfig<rustc_query_system::query::caches::DefaultCache<rustc_middle::ty::ParamEnvAnd<rustc_middle::mir::interpret::GlobalId>, rustc_middle::query::erase::Erased<[u8; 32]>>, false, false, false>, rustc_query_impl::plumbing::QueryCtxt>::{closure#2}::{closure#2} as core::ops::function::FnOnce<((rustc_query_impl::plumbing::QueryCtxt, rustc_query_impl::DynamicConfig<rustc_query_system::query::caches::DefaultCache<rustc_middle::ty::ParamEnvAnd<rustc_middle::mir::interpret::GlobalId>, rustc_middle::query::erase::Erased<[u8; 32]>>, false, false, false>), rustc_middle::ty::ParamEnvAnd<rustc_middle::mir::interpret::GlobalId>)>>::call_once
              22: rustc_query_system::query::plumbing::try_execute_query::<rustc_query_impl::DynamicConfig<rustc_query_system::query::caches::DefaultCache<rustc_middle::ty::ParamEnvAnd<rustc_middle::mir::interpret::GlobalId>, rustc_middle::query::erase::Erased<[u8; 16]>>, false, false, false>, rustc_query_impl::plumbing::QueryCtxt, true>
              23: rustc_query_impl::query_impl::eval_to_allocation_raw::get_query_incr::__rust_end_short_backtrace
              24: rustc_const_eval::const_eval::eval_queries::eval_to_allocation_raw_provider
              25: rustc_query_impl::plumbing::__rust_begin_short_backtrace::<rustc_query_impl::query_impl::eval_to_allocation_raw::dynamic_query::{closure#2}::{closure#0}, rustc_middle::query::erase::Erased<[u8; 16]>>
              26: <rustc_query_impl::query_impl::eval_to_allocation_raw::dynamic_query::{closure#2} as core::ops::function::FnOnce<(rustc_middle::ty::context::TyCtxt, rustc_middle::ty::ParamEnvAnd<rustc_middle::mir::interpret::GlobalId>)>>::call_once
              27: <rustc_query_system::query::plumbing::execute_job_incr<rustc_query_impl::DynamicConfig<rustc_query_system::query::caches::DefaultCache<rustc_middle::ty::ParamEnvAnd<rustc_middle::mir::interpret::GlobalId>, rustc_middle::query::erase::Erased<[u8; 32]>>, false, false, false>, rustc_query_impl::plumbing::QueryCtxt>::{closure#2}::{closure#2} as core::ops::function::FnOnce<((rustc_query_impl::plumbing::QueryCtxt, rustc_query_impl::DynamicConfig<rustc_query_system::query::caches::DefaultCache<rustc_middle::ty::ParamEnvAnd<rustc_middle::mir::interpret::GlobalId>, rustc_middle::query::erase::Erased<[u8; 32]>>, false, false, false>), rustc_middle::ty::ParamEnvAnd<rustc_middle::mir::interpret::GlobalId>)>>::call_once
              28: rustc_query_system::query::plumbing::try_execute_query::<rustc_query_impl::DynamicConfig<rustc_query_system::query::caches::DefaultCache<rustc_middle::ty::ParamEnvAnd<rustc_middle::mir::interpret::GlobalId>, rustc_middle::query::erase::Erased<[u8; 16]>>, false, false, false>, rustc_query_impl::plumbing::QueryCtxt, true>
              29: rustc_query_impl::query_impl::eval_to_allocation_raw::get_query_incr::__rust_end_short_backtrace
              30: <rustc_const_eval::interpret::eval_context::InterpCx<rustc_mir_transform::const_prop::ConstPropMachine>>::eval_mir_constant
              31: <rustc_mir_transform::const_prop_lint::ConstPropagator as rustc_middle::mir::visit::Visitor>::visit_basic_block_data
              32: <rustc_mir_transform::const_prop_lint::ConstProp as rustc_mir_transform::pass_manager::MirLint>::run_lint
              33: rustc_mir_transform::mir_drops_elaborated_and_const_checked
              34: rustc_query_impl::plumbing::__rust_begin_short_backtrace::<rustc_query_impl::query_impl::mir_drops_elaborated_and_const_checked::dynamic_query::{closure#2}::{closure#0}, rustc_middle::query::erase::Erased<[u8; 8]>>
              35: <rustc_query_impl::query_impl::mir_drops_elaborated_and_const_checked::dynamic_query::{closure#2} as core::ops::function::FnOnce<(rustc_middle::ty::context::TyCtxt, rustc_span::def_id::LocalDefId)>>::call_once
              36: rustc_query_system::query::plumbing::try_execute_query::<rustc_query_impl::DynamicConfig<rustc_query_system::query::caches::VecCache<rustc_span::def_id::LocalDefId, rustc_middle::query::erase::Erased<[u8; 8]>>, false, false, false>, rustc_query_impl::plumbing::QueryCtxt, true>
              37: rustc_query_impl::query_impl::mir_drops_elaborated_and_const_checked::get_query_incr::__rust_end_short_backtrace
              38: <rustc_session::session::Session>::time::<(), rustc_interface::passes::analysis::{closure#2}>
              39: rustc_interface::passes::analysis
              40: rustc_query_impl::plumbing::__rust_begin_short_backtrace::<rustc_query_impl::query_impl::analysis::dynamic_query::{closure#2}::{closure#0}, rustc_middle::query::erase::Erased<[u8; 1]>>
              41: <rustc_query_impl::query_impl::analysis::dynamic_query::{closure#2} as core::ops::function::FnOnce<(rustc_middle::ty::context::TyCtxt, ())>>::call_once
              42: rustc_query_system::query::plumbing::try_execute_query::<rustc_query_impl::DynamicConfig<rustc_query_system::query::caches::SingleCache<rustc_middle::query::erase::Erased<[u8; 1]>>, false, false, false>, rustc_query_impl::plumbing::QueryCtxt, true>
              43: rustc_query_impl::query_impl::analysis::get_query_incr::__rust_end_short_backtrace
              44: <rustc_middle::ty::context::GlobalCtxt>::enter::<rustc_driver_impl::run_compiler::{closure#1}::{closure#2}::{closure#4}, core::result::Result<(), rustc_span::ErrorGuaranteed>>
              45: <rustc_interface::interface::Compiler>::enter::<rustc_driver_impl::run_compiler::{closure#1}::{closure#2}, core::result::Result<core::option::Option<rustc_interface::queries::Linker>, rustc_span::ErrorGuaranteed>>
              46: std::sys_common::backtrace::__rust_begin_short_backtrace::<rustc_interface::util::run_in_thread_pool_with_globals<rustc_interface::interface::run_compiler<core::result::Result<(), rustc_span::ErrorGuaranteed>, rustc_driver_impl::run_compiler::{closure#1}>::{closure#0}, core::result::Result<(), rustc_span::ErrorGuaranteed>>::{closure#0}::{closure#0}, core::result::Result<(), rustc_span::ErrorGuaranteed>>
              47: <<std::thread::Builder>::spawn_unchecked_<rustc_interface::util::run_in_thread_pool_with_globals<rustc_interface::interface::run_compiler<core::result::Result<(), rustc_span::ErrorGuaranteed>, rustc_driver_impl::run_compiler::{closure#1}>::{closure#0}, core::result::Result<(), rustc_span::ErrorGuaranteed>>::{closure#0}::{closure#0}, core::result::Result<(), rustc_span::ErrorGuaranteed>>::{closure#1} as core::ops::function::FnOnce<()>>::call_once::{shim:vtable#0}
              48: call_once<(), dyn core::ops::function::FnOnce<(), Output=()>, alloc::alloc::Global>
                         at /rustc/b2b34bd83192c3d16c88655158f7d8d612513e88/library/alloc/src/boxed.rs:1985:9
              49: call_once<(), alloc::boxed::Box<dyn core::ops::function::FnOnce<(), Output=()>, alloc::alloc::Global>, alloc::alloc::Global>
                         at /rustc/b2b34bd83192c3d16c88655158f7d8d612513e88/library/alloc/src/boxed.rs:1985:9
              50: thread_start
                         at /rustc/b2b34bd83192c3d16c88655158f7d8d612513e88/library/std/src/sys/unix/thread.rs:108:17
              51: start_thread
                         at ./nptl/pthread_create.c:444:8
              52: __GI___clone3
                         at ./misc/../sysdeps/unix/sysv/linux/x86_64/clone3.S:81

    = note: this error: internal compiler error originates in the macro `int_impl` (in Nightly builds, run with -Z macro-backtrace for more info)

note: we would appreciate a bug report: https://github.com/rust-lang/rust/issues/new?labels=C-bug%2C+I-ICE%2C+T-compiler&template=ice.md

note: rustc 1.72.0-nightly (b2b34bd83 2023-06-06) running on x86_64-unknown-linux-gnu

note: compiler flags: --crate-type lib -C embed-bitcode=no -C debuginfo=2 -C incremental=[REDACTED] -C target_cpu=native

note: some of the compiler flags provided by cargo are hidden

query stack during panic:
end of query stack
error: could not compile `fiddler` (lib)
```

I accidentally found a compiler bug!
I opened the issue for it [here](https://github.com/rust-lang/rust/issues/112748).
I don't know the exact cause for it yet, but I think it's somehow related to constant evaluation.
In any event, annotating `ROOK_ATTACKS_TABLE` with `#[allow(long_running_const_eval)]` seems to fix
it.

Running the compiler again, we find that our compile time has ballooned from about 3 seconds to 48
seconds.
Almost all of that time is spent on generating `ROOK_ATTACKS_TABLE`.

Interestingly enough, I wrote an exhaustive test of the magic table generation code, which does
essentially the same thing as generating the table, except at runtime, and I found that it ran in
0.00 seconds.
I suspect that the constant evaluator in Rust is just plain slow.

## Denouement

Now that we've gotten the whole thing to compile, we can actually run a benchmark.
In chess engines, the main measure of engine quality is Elo, a relative measure of engine
performance.

I threw the new version of Fiddler, with its compile-time generated lookup tables, against the
older dynamically-generated ones, and here are my results:

```text
Score of fiddler_const_magic vs fiddler_dynamic_magic: 5278 - 5003 - 4271 [0.509]
...      fiddler_const_magic playing White: 2766 - 2374 - 2136  [0.527] 7276
...      fiddler_const_magic playing Black: 2512 - 2629 - 2135  [0.492] 7276
...      White vs Black: 5395 - 4886 - 4271  [0.517] 14552
Elo difference: 6.6 +/- 4.7, LOS: 99.7 %, DrawRatio: 29.3 %
14566 of 30000 games finished.
```

We get a whole 6 Elo points - equivalent to a 1% improvement in the engine.
At least it's not a regression!

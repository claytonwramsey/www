+++
title = "We're not done with point clouds"
date = 2026-08-10
description = "If you wait long enough to solve a problem, someone else might just solve it for you."
template = "post.html"
authors = ["Clayton Ramsey"]
+++

If you wait long enough to solve a problem, someone else might just solve it for you.
At least that's what I tell myself about the dishes in my sink.

While in Vienna for a conference, I found another set of researchers who did just that for me: they took some work I had published two years ago and ran with it, and they beat me on just about every benchmark.
I'm writing up this article to draw some attention to their work and, a little selfishly, to yap about the things I learned while reimplementing their work.
In short, they made a data structure for collision-checking against point clouds that runs really fast while also being extremely cheap in memory and construction time.

If you don't care about details, you can jump straight to the [paper](https://rasevents.org/uploads/documents/pdfviewer/b1/d6/223112-5124.pdf) or to the original [C++ implementation](https://github.com/chingchennn/vamp_mvt).
I've also published a Rust implementation with my own optimizations, with [source code on GitHub](https://claytonwramsey/mvtable) and a [package on crates.io](https://crates.io/crates/mvtable).

## Recapt

<figure>

  <div style="display: flex">
    <div style="width: 50%"><img src="panda.png" alt="Panda robot"/></div>
    <div style="width: 50%"><img src="panda_sphere.png" alt="Spherized panda robot"/></div>
    </div>
  <figcaption>A Franka Emika Panda robot and its spherized collision-checking representation.</figcaption>
</figure>

I spend a lot of my time thinking about _motion planning_: finding ways for robots to find collision-free motions from a start state to a goal state.
There are a million different ways to solve motion planning problems, but once you've read enough papers they all kind of look the same.
You sample some configurations, test if they're valid, and try to do a big path search over all possible configurations.
Every one of those algorithms requires _configuration validation_: given a robot's configuration $q$, determine whether a robot in position $q$ collides with the world geometry.
Since robots often work in perceived environments, that world geometry typically comes to us as a point cloud.
If our robot's geometry is simplified to a bunch of spheres, we can further simplify the problem to spherical collision checking: for any configuration, just check if any of the spheres on the robot collide with the perceived point cloud.

> **Problem statement:**
> Given some list of $n$ points $P$ and a set of spheres $S$, determine whether any sphere in $S$ collides with $P$ in minimal time.

A few years ago, I proposed a data structure called the [CAPT](/blog/captree), which is designed to make configuration validation against point clouds really fast.
In short, it's a collision-checker between spheres and point clouds.
It's a nearest-neighbor search structure, much like a $k$-d tree, but we do extra work at construction time to avoid backtracking through the search tree.
The net result is that we have a $k$-d tree with a batch-parallel search algorithm, supporting SIMD-accelerated branchless queries.

The big problem with CAPTs was the construction time: dense point clouds require a lot of duplicated data to avoid backtracking.
Once point clouds get dense enough, CAPT construction scales at $O(n^2)$, which is disastrous for a user's hopes of getting planning at control-loop frequencies.
The data layout for CAPTs requires each leaf of the search tree, which represents some region in space, to store duplicate copies of many points in the point cloud.
Those duplicate copies start to dominate the data structure's footprint, which in turn balloons construction time.

## Thinking inside the box

<figure class="night-invert">

![Voxel-grid collision checking](voxels.png)

<figcaption>

Via [Chen and Yeh](https://rasevents.org/uploads/documents/pdfviewer/b1/d6/223112-5124.pdf), a voxel-based collision-checking scheme.

</figcaption>

</figure>

Ching Chen and Tsung-Tai Yeh, two other robotics researchers, decided to fix the problems with CAPTs for themselves.
To do so, they started by ditching nearest-neighbor search trees entirely.
Instead of with a space-partitioning tree, you can cut up the space into a grid of voxels, each storing a list of points that they contain.
The benefit here is twofold: first, you can tell which voxel a query sphere lies in with simple arithmetic, and second, you don't have to duplicate any points, as finding adjacent voxels is trivial.

But naïvely just storing every voxel in the workspace doesn't work.
If the workspace is a hundred voxels long in every dimension, then you'd have to store the information for a million voxels to record a single point cloud, which after filtering only contains a few thousand points.
To keep things under control, Chen and Yeh sparsely store only occupied voxels in a three-layer sparse tree, where each layer is segmented by one dimension.

Put together with a few axis-aligned bounding box tests, the resulting structure is a _multilevel voxel table_, or MVT.
Like the CAPT, MVTs are parallelizable using single-instruction, multiple-data parallelism (SIMD).
For any given voxel, the collision checker can do a big batch check for collision withh all the points contained in the voxel for a free constant speedup.

## Patching some flat tiers

### Flat as a board

The original implementation of MVTs had some gnarly C++-isms: namely, the voxel tables used a tapestry of pointers to each row of tables.
In addition to being kind of unhinged in general, this made memory management quite difficult, and also was not very size-efficient.
The original C++ implementation also has a bunch of weird manual pool management, which results in disastrous crashes once point clouds get too big.

```cpp
struct MVT {
    // pointers to voxel indices
    using ZLevelTable = uint32_t*;
    // pointers to z-level tables
    using YLevelTable = uint32_t**;
    // pointers to y-level tables
    using XLevelTable = uint32_t***;

    XLevelTable x_level_table;
}
```

To make things easier to implement in Rust, I simplified things a little bit: we just back everything with a `Box<[]>`.

```rust
struct Mvt {
    /// tells us where to get voxel data from a grid index
    tables: Box<[u32]>,
    /// tells us where to get point lists in `points`
    voxels: Box<[u32]>,
    /// flattened SoA shared buffer of all point data
    points: [Box<[f32]>; 3]
    // other fields...
}

struct Voxel {
    /// index of first point stored in this voxel in `points`
    offset: u32,
    /// number of points in the voxel
    count: u32,
    /// other fields...
}
```

The search logic then becomes super simple: use `tables` to find out which voxel you belong to, looked up in `voxels`.
Then use your voxel to find which span of `points` you need to collision-check against, and finally do a brute-force check against those points.

### Getting mutable

In addition to making the search logic way simpler, the new search structure makes it trivial to make MVTs mutable, just by giving each `Voxel` its own points field, instead of sharing one big buffer.

```rust
// `points` is removed from `Mvt`

struct Voxel {
    /// index of first point stored in this voxel in `points`
    offset: u32,
    /// number of points in the voxel
    count: u32,
    /// SoA buffer of points in this voxel
    points: [Vec<[f32]>; 3]
    // other fields...
}
```

Adding mutability comes at a roughly 2x size penalty and a 1.5x construction-time penalty, but it's a nice feature to have.
To keep good performance for people who use `Mvt`s as a single-use structure, I split out the implementation: I wrote both an immutable default `Mvt` and a `MutableMvt` structure.

### Big balls, big problems

<figure class="night-invert">

<div style="display: flex">

<div style="width: 46%">

![The spherized model of a robot](fetch_spheres.png)

</div>

<div style="width: 54%">

![Robot sphere sizing](fetch_highlight.png)

</div>

</div>

<figcaption>

The spherization of a Fetch robot (left) and the radii (right) $r_"max"$, $r_"mobile"$, and $r_"query"$ shown in red, green, and purple respectively.

</figcaption>

</figure>

In order to build an MVT, you need to pick how big your voxels have to be.
If voxels are too big, then collision-checking queries will waste too much time searching through far-away points, but if they're too close, then queries will instead have to cull against dozens of tiny voxels.

There are a few plausible candidates, however.
On each robot's spherized geometry, we can pick out the biggest sphere of the robot, whose radius is $r_"max"$.
Alternately, we could restrict ourselves to just the moving links of the robot, skipping the big spheres on most robots' base links, yielding $r_"mobile"$.
Lastly, we could take a look at the robot's bounding-volume hierarchy, and then pick out $r_"query"$, the size of the largest sphere ever used in a collision-check.

<figure class="night-invert">

![Voxel width performance scaling](voxel_width_sweep.svg)

<figcaption>

Scaling of query speed with voxel width.
Each curve shows the average query time for an MVT generated with the voxel width on the X axis, separated by robot.
$r_"mobile"$, $r_"robot"$, and $r_"query"$ are all shown marked as ●, ■, and ▲ respectively.

</figcaption>

</figure>

The original MVT paper recommended using $r_"max"$, largely just by waving generally at query times and claiming that performance was good enough with that selection.
However, I wanted to get a better answer than that, so I decided to be empirical.
For a simulated workload on every robot, I ran a parameter sweep over the voxel width and recorded the average collision-checking time
I then rendered the collision checking performance in the plot shown above.

For Fetch, Panda, and UR5, $r_"max"$ is indeed a respectable choice of voxel width, but not totally optimal.
However, for the Baxter robot, I found that using $r_"max"$ as the voxel width is exceedingly slow, yielding query times twenty times slower than with an optimal selection.
I suspect the orignal MVT authors never benchmarked against Baxter, or they would have found this, but in any event I will take my free speedup and carry on.

Surprisingly enough, the optimal voxel width for all robots always lands roughly between 10 and 20 cm.
I suspect this is a consequence of the point cloud filtering process: for a given point cloud density, there is a roughly optimal voxel size to minimize the amount of wasted work.

## Going sphere for sphere

Naturally, you have to actually benchmark your code to tell if it's fast.
To do so, I whipped together a few fun benchmarks: I solved a bunch of motion planning problems, recorded all of the collision checks that the planners made, and then replayed those collision checks to just time the collision checking throughput.
For each problem, I recorded the data structure construction and collision checking time across all the data structures I considered: the MVT implementations (both my Rust code and the original C++ version), my old CAPT implementation, and [`kiddo`](https://github.com/sdd-org/kiddo), a very fast $k$-d tree.

<figure class="night-invert">

![Collision checking structure construction times](mbm_throughput_construction.svg)

<figcaption>Construction time scaling for each data structure.
  Each line shows average performance of a data structure for a bucket of point clouds.</figcaption>

</figure>

The most obvious win comes from construction time.
CAPTs were always slow to build, and they were especially slow in the Rust implementation.
In fact, when I benchmarked my end-to-end planning pipelines, CAPT construction was always the slowest step.
Since MVTs don't do nearly as much bookkeeping at construction time, they get a big performance win.
Also, since the MVT has linear memory scaling, its construction time is on the order of $O(n)$ with point cloud size $n$, instead of $O(k n log(n))$ for space-partitioning trees, meaning construction times are great even in large point clouds.

Building mutable MVTs comes at some construction cost, since we have to maintain many separate allocations instead of one big pool, but even then, it's still pretty cheap.

<!-- I don't have much to say about memory usage -->

<!--<figure class="night-invert">

![Data structure memory performance](mbm_throughput_memory.svg)

<figcaption>Memory consumption scaling for each data structure.</figcaption>

</figure>-->

<figure class="night-invert">

![Collision checking throughput plots](mbm_throughput_query.svg)

<figcaption>Collision-checking throughput scaling for each data structure, including the SIMD-parallel batch queries.</figcaption>

</figure>

Even better, MVTs have great query throughput.
I had been quite proud of the ten-nanosecond scale throughput for CAPTs, but MVTs manage to do even better.
Even more surprisingly, mutable MVTs seem to have marginally better query performance than immutable ones.
Most likely, the performance bump comes from some quirk of cache memory: perhaps laying points out in distinct allocations helps.

<figure class="night-invert">

![Motion planning performance plots](primitive_vs_other.svg)

<figcaption>End-to-end motion planning performance. Planning times with ground-truth primitive geometry are on the x-axis, while the y-axis is the planning time using a tested point cloud representation. Each dot represents planning time for one problem.</figcaption>

</figure>

When solving real motion planning problems, MVTs give a respectable speedup across the board.
In the above plot, we see that for nearly every problem, planning with the MVT point cloud representation is faster than with a CAPT, and often is even faster than the ground-truth primitive geometry representation.

## The big problems still aren't solved

MVTs are pretty cool data structures!
They're fast, cheap, and easy to manage.
I also had a blast implementing my Rust version of them.
However, they only fix one of the big problems with CAPTs, which is their construction time.

Point cloud data is necessarily imperfect: it comes out of a camera, and that camera can only ever see one side of an object.
When we plan for real robots, we have to account for this, typically by assuming that unseen space is also invalid.
Previous work on perception data, such as [octomaps](https://octomap.github.io/), can do just this, but I had sacrificed occlusion handling for the CAPT work at the altar of performance.
Now, users are left with the cruel tradeoff of being safe or being fast: octomaps are wicked slow but so far are the only ones handling occlusion.

In a more general sense, I think the classical formulation of motion planning, where a robot gets to operate in a beautiful still-life painting of the world, is just incorrect.
Even the best perception for robots is never better than "bad," and so our approaches to planning should contend with the fact that we only ever plan against an approximation of the real world.
So, much like my dishes, planning from perception remains yet unsolved.

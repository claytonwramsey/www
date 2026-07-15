+++
title = "We're not done with point clouds"
date = 2026-07-14
description = ""
template = "post.html"
authors = ["Clayton Ramsey"]
draft = true
+++

## Recapt

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
As a workaround, I had to implement a new point cloud filtering method to get the clouds to be sparse enough to keep construction times under control.

## Thinking inside the box

- Idea: design the cells to be good instead of bad
- Then take advantage of sparsity

## Patching some flat tiers

Implementation details of the Rust approach.

- Store everything in one big buffer
- Split out mutability
- Go generic over indices, float types, dimension

## Going sphere for sphere

Naturally, you have to actually benchmark your code to tell if it's fast.
To do so, I whipped together a few fun benchmarks: I solved a bunch of motion planning problems, recorded all of the collision checks that the planners made, and then replayed those collision checks to just time the collision checking throughput.
For each problem, I recorded the data structure construction and collision checking time across all the data structures I considered: the MVT implementations, my old CAPT implementation, and `kiddo`, a $k$-d tree.

<figure class="night-invert">

![Collision checking structure construction times](mbm_throughput_construction.svg)

<figcaption>Construction time scaling for each data structure.
  Trendlines show average performance in a size bucket, while the hexbins are colored based on the overall distribution of planning times.</figcaption>

</figure>

The most obvious win comes from construction time.
CAPTs were always slow to build, and they were especially slow in the Rust implementation.
In fact, when I benchmarked my end-to-end planning pipelines, CAPT construction was always the slowest step.
Since MVTs don't do nearly as much bookkeeping at construction time, they get a big performance win.
Also, since the MVT has linear memory scaling, its construction time is on the order of $O(n)$ with point cloud size $n$, instead of $O(k n log(n))$ for space-partitioning trees, meaning construction times are great even in large point clouds.

<!-- I don't have much to say about memory usage -->

<!--<figure class="night-invert">

![Data structure memory performance](mbm_throughput_memory.svg)

<figcaption>Memory consumption scaling for each data structure.</figcaption>

</figure>-->

<figure class="night-invert">

![Collision checking throughput plots](mbm_throughput_query.svg)

<figcaption>Collision-checking throughput scaling for each data structure, including the SIMD-parallel batch queries. I've removed the hexbins for non-SIMD queries to keep the plot from getting too messy.</figcaption>

</figure>

Even better, MVTs have great query throughput.
I had been quite proud of the ten-nanosecond scale throughput for CAPTs, but MVTs manage to do even better.
Even more surprisingly, mutable MVTs seem to have marginally better query performance than immutable ones.
Most likely, the performance bump comes from some quirk of cache memory: perhaps laying points out in distinct allocations helps.

<figure class="night-invert">

![Motion planning performance plots](mbm_plan_times.svg)

<figcaption>End-to-end motion planning performance distribution on the Baxter robot.</figcaption>

</figure>

When solving real motion planning problems, the planners do a bunch of other unrelated work, so the performance differences are not quite as stark.
But on the Baxter robot of my problem dataset, which had the hardest problems, I we find that there is still a big improvement: median planning times fell from about 50 ms using the CAPT's SIMD implementation to more like 24 ms.
**Strangely enough kiddo is in first place...**

**TODO: use final charts from execution on longinus**

##

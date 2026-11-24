+++
title = "Kinodynamic planning isn't so hard"
date = 2026-11-09
description = ""
template = "post.html"
authors = ["Clayton Ramsey"]
draft = true
+++

Nonlinear differential constraints aren't real and they can't hurt you.

## Motion planning like it's 1999

Among the most fundamental problems in robotics is _motion planning_: given a start state $q_s$ and an end state $q_g$, how does the robot get there without hitting anything?
There are a lot of ways of doing this, but one of the big family of motion planning algorithms is _sampling-based planning_.

Every geometric motion planning algorithm looks pretty much the same once you stare at it hard enough.
They always do roughly the same three steps, in a loop.

1. Sample some random configurations.
   Treat each one of those as a node.
2. Connect the random configurations with small, simple motions.
   Treat each motion as an edge.
3. Throw away all the simple motions that crash into obstacles.
4. Do a graph search on those nodes and edges until you get to a goal.

For most robots, this works great!
The state of the art of geometric planners can find [valid plans in sub-millisecond times](/blog/captree).
In particular, so long as each step is computationally cheap, you can solve a planning problem in no time whatsoever.

Sometimes, however, steps 2 and 3 are really, really hard.
Imagine your robot is a car or a drone: how do we find simple motions between robot configurations?
In the general case, this means you have to solve a differential equation for every single edge in the planning graph, of which there are probably tens of thousands.

People have tried, failed, and occasionally succeeded at planning for robots with these kinds of differential constraints, often by inventing bespoke planners or with clever math tricks.
In the rest of this article, I'll go over a new clever math trick that allows us to solve planning problems for complex, dynamical systems in record time.

## Paving the world flat

Let's start by looking at a car.
As any controls textbook would tell you, cars are hard to plan for because they are _non-holonomic_ systems.
If you give me a car's position and heading $(x_1, y_1, theta_1)$, then ask me for a motion to some new $(x_2, y_2, theta_2)$, we can't just drag the car on the ground to get to its desired position.
Instead, the car will have to follow some [spaghetti path](https://en.wikipedia.org/wiki/Dubins_path) to get to its goal.

<figure>
TODO add an image
  <figcaption>A car can follow whatever squiggle you want.</figcaption>
</figure>

But let's squint a little harder at the problem.
Suppose I give up on controlling the orientation $theta$, and instead just want the car to get from $(x_1, y_1)$ to $(x_2, y_2)$.
Then I draw an arbitrary squiggle from start to goal.
If the car follows that squiggle, then I can derive $theta$ at any point by looking at the direction of the squiggle.
More precisely, if I have some curve $(x(t), y(t))$, I can derive $theta(t)$ from my curve's derivatives, $(x'(t), y'(t))$.

$$theta(t) = "atan2"(y'(t), x'(t))$$

This may not seem like much, but we've just found a special property of our system, namely, that this car is _differentially flat_.
In loose terms, if a system is differentially flat, we can give up on controlling some of its variables, such as $theta$, and get an easily-controlled holonomic system.
Then we can reconstruct those lost variables from the state of our holonomic system, as we did by computing $theta(t)$ from $x'(t)$ and $y'(t)$.

## It's all polynomials

- How to calculate motions between flat states

### Direction matters

- Flat states are directional, so you have to make directional motion plans.

## Let's get parallel

- Evaluating flat edges in parallel for VAMP

## Thinking fast

- Benchmark results for planning speed on flat OMPL

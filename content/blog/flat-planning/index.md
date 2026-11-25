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

More precisely, we start with some system whose state vector is $bold(x)$, governed by the constraints below.

$$bold(dot(x)) = f(bold(x)(t), bold(u)(t))$$

This system is flat if there is some other _output state_ $bold(y(t))$, with the following properties:

1. $bold(y(t))$ can computed by some function $xi(bold(x), bold(u), bold(u)' ... bold(u)^r )$ for some derivative order $r$.
2. $bold(x(t))$ and $bold(u(t))$ can be computed by some functions $phi(bold(y), bold(y)' ... bold(y)^((r - 1)))$ and $psi(bold(y), bold(y)' ... bold(y)^(r))$ for some derivative order $r$.
3. $bold(y)$ is _differentially independent_; that is, there are no differential constraints on $bold(y)$.

In our car example, $bold(x)$ was the original car state $(x, y, theta)$, $bold(y)$ was the car's position $(x, y)$, and $phi(bold(x), bold(x)')$ was $(x, y, "atan2"(y'(t), x'(t)))$.
By giving up on controlling $theta$, $bold(y)$ became differentially independent, so we could draw a path in $bold(y)$, then calculate $theta$ just from the values of $bold(y)$ and $bold(y)'$.

In other words, for any flat system, we can bypass differential constraints by planning in the flat output space $bold(y)$, where we don't have to satisfy any nasty differential constraints, and then just transform our solutions back into $bold(x)$ when we are done planning.

## It's all polynomials

By throwing away differential constraints, we are now solving an easier problem.
Instead of figuring out how to find motions for an arbitrary system, we only need motions for exactly one kind of system, known as an Euler integrator.

In an Euler integrator, the state vector is $bold(y)$ and its first $r - 1$ derivatives, denoted $cal(y) = (bold(y), bold(y)' ... bold(y)^(r - 1))$.
To connect two states $cal(y)_0$ and $cal(y)_1$, we need to find some function $bold(p)(t)$, satisfying all the start and endpoint constraints, for some arrival time $T$.

$$
  bold(p)(0) &= bold(y)_0 &#h(1cm) bold(p)(T) &= bold(y)_1 \
  bold(p)'(0) &= bold(y)'_0 &#h(1cm) bold(p)'(T) &= bold(y)'_1 \
  ⋮ & #h(1cm) &⋮ \
  bold(p)^((r-1))(0) &= bold(y)^((r-1))_0 &#h(1cm) bold(p)^((r-1))(T) &= bold(y)^((r-1))_1
$$

This requirement gives us $2r dot "dim"(bold(y))$ constraints.
However, we can choose whatever function $p$ we want, so we can't just solve for $p$ outright from these constraints.
A good choice of $p$ requires further cleverness.

Applying no cleverness whatsoever, we just reach for the first candidate for $p$ we can think of with exactly $2r dot "dim"(bold(y))$ variables: a list of $"dim"(bold(y))$ polynomials with $2r$ coefficients each.

$$bold(p)(t) = bold(c)_0 + bold(c)_1 t + ... + bold(c)_((2r - 1)) t^(2r-1) $$

Once we've picked a value for $T$, computing the coefficient vectors $bold(c)_k$ becomes just an algebra problem: plug your coefficients into the constraints above, then solve for the values of $bold(c)_k$.

<figure>

TODO add an image

<figcaption>

Small $T$ grants faster motions with bigger accelerations.

</figcaption>
</figure>

Now all that's left is finding a value of $T$.
If $T$ is a fixed constant, motions get slower the closer two states are together, which seems wrong.
Worse, if $T$ is small, all our motions will cause the robot to blast through motions at ludicrous accelerations, which is also wrong.
Instead, we really want a $T$ that gives a good tradeoff between traversing from $cal(y)_0$ to $cal(y)_1$ fast and also applying safe controls.
To do so, we can pick the $T$ that minimizes some cost function of both control effort and the time $T$, using the choice below.

$$T^star = op("arg min", limits: #true)_T integral_0^T |bold(y)^((r))(t)|^2 d t + rho T$$

Here, the parameter $rho$ decides how important low acceleration is versus fast motions: bigger $rho$ gets you fast motions, but a really high control effort $bold(y)^((r))(t)$.
You may notice the squared term inside the integral -- this is highly motivated: if you are good at optimiziation, you can find that the above system can be solved for $T^star$ just by solving a polynomial system.
To be exact, for a derivative order $r$, $T^star$ is the minimum of a polynomial of order $2r + 1$; in other words, it's solution to a polynomial $q$ of order $2r$.

### They don't teach this in Algebra II

Finding $T^star$ sounded easy in the last paragraph, but when you get down to the details, it's actually pretty hard, especially if you want to go fast.
From the above definition, we are given some polynomial with order $2r - 1$ and asked to find its minimum.
Taking a derivative, we need to find the zeros of a polynomial $q(t)$ with degree $2r$ where the polynomial crosses from positive to negative.

You may remember from your elementary school abstract algebra classes that polynomials of degree 4 or lower all have closed-form solutions.
This is great for simple, order-2 systems where we can control the robot's acceleration, since the closed form solution is quick to compute and numerically quite accurate.

For higher values of $r$, such when planning for a drone, we are not so lucky.
6th and 8th degree polynomials have no closed form solution, so to find $T^star$, you'll have to start by browsing the Wikipedia page for [root finding algorithms](https://en.wikipedia.org/wiki/Real-root_isolation).

The most typical trick uses some linear algebra.
Since this is a blog post, I'll skate over the details, but here's a quick overview.
Given a polynomial $q$, start by constructing a [special matrix](https://en.wikipedia.org/wiki/Companion_matrix) $C(q)$, such that $C$'s eigenvalues are exactly the roots of the polynomial.
Then throw $C$ into your favorite linear algebra library's eigenvalue solver.
This has the advantage of being easy to program and numerically stable, but it's also not super fast.

To account for this, I wrote my own root solver.

- Bisection solvers
- Descartes' rule

### Direction matters

- Flat states are directional, so you have to make directional motion plans.

## Let's get parallel

- Evaluating flat edges in parallel for VAMP

## Thinking fast

- Benchmark results for planning speed on flat OMPL

$$
$$

$$
$$

$$
$$

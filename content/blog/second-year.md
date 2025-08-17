+++
title = "My second year of grad school: reflections"
template = "post.html"
date = 2025-08-17
authors = ["Clayton Ramsey"]
description = "Two years of Ph.D. study have made me twice as smart as before!"
+++

Two years of Ph.D. study have made me twice as smart as before!

Well, not really.
But I've still grown a lot, and I've added up a lot of achievements.
Admittedly, there hasn't been much outward change, since I've no more publications than last year, but I think I'm in a far better shape than the [last time](/blog/first-year) I wrote a reflection.
I've pushed my prior work in front of loads of eyeballs, especially since I presented it at a number of places, from on campus at Rice to two different workshops at ICRA.
Meanwhile, my long-running ongoing project in task in motion planning is finally wrapping up, so I am now getting ready to publish a paper requiring many-times more work than my first project.
More importantly, though, I think I've grown and developed as a researcher and a programmer.

## Establishing my own direction

This year, my personal theme has been establishing independence.
In the fall, I checked in regularly with my mentors-_cum_-collaborators [Wil](https://wbthomason.com/) and [Zak](https://zkingston.com/), as well as with my doctoral advisor, Lydia, for tactical direction; now, I pick out my own directions and fire off progress updates for vibe-checks.
To toot my own horn: I think this was a big success!
Last year, I feared I wasn't cut out for it; I am quite proud of my growth here.

Admittedly, my research strategies are pretty weird: I've no tolerance eating frogs, so I establish direction via, essentially, play.
I pick my tools, problems, and approaches mostly based on personal excitement; the net result is that I optimize myself into a niche of things that I like.
Day-to-day, this means I spend my time thinking about data structures and hardware acceleration; there is a tiny monkey in my brain pleased only when millisecond counts in my benchmarks go down.
I do not know how long this approach will last or how far it will take me, but for now it is excellent for my morale.

## Getting blocked

I struggle to maintain focus, even on things I like working on.
It's worst when I'm blocked: I encounter a problem that I don't fully understand, requiring at the a context-switch into some other documentation or a coworker's help.
Each blockage is an off-ramp to go do something else; I'd suddenly find myself checking my email, bothering an intern, or just playing with an easier project.
Likewise, I'm introverted and dislike asking others for help, so I wait far too long to seek help when I get stuck --- if I do at all.
The net result is blocked projects stay blocked until I work up the willpower to work on them again.

The longer a project spends in a blocked state, the worse it gets, since making progress now requires facing my own non-progress.
Like any properly maladjusted grad student, I stake my happiness on my work progress, so a slow-moving is also a depressing project.
Continuing from a blocked state then requires not only the standard willpower for working on something hard or socially stressful but also the emotional wherewithal to engage with a project that already makes me feel bad.
The net result is a vicious cycle: I fall behind, feel bad about it, don't continue, and fall further behind.

Under normal conditions I can manage this cycle well enough, but this year has been harder for me.
My research work is much more independent now, so I find I have less immediate feedback; if I want tactical advice, I usually have to ask for it.
More personally, my mother's third and likely final cancer diagnosis has demanded that I spend much of my free time with her, about a three hour drive away from home.
Sometimes I feel that I spend my weeks carting between sleep and work and mom in a dreamlike fug.
Going to work, staying focused, and even doing things I normally find fun are all just a little harder now; the net result is that my own productivity is far more variable than it used to be.

My internship at JSC during the summer was probably the worst case of non-progress that I've had since, frankly, middle school.
My mom's health issues were reaching a head, and I burned an hour commuting each way to the outskirts of Houston to spend all day in a windowless concrete box; such conditions are not conducive to clarity of focus or concentration of will.
By the end, I felt I had next to nothing to show for the summer's work, especially compared to my peers.

Were I older and wiser, perhaps I could conclude with a motivating tale of my resourcefulness and growth; however the astute reader will note the publication date.
I'm writing just after the summer has ended, so I'm fresh off of that experience.
I have some cause for hope though; during the school year, my commute becomes a ten-minute bike ride to a office with a window.
If my surroundings can tank my productivity, then maybe my surroundings can also revive them.

## Having fun with my tools

On to more exciting topics!

My current work is in task and motion planning; the details are irrelevant to this post, but in short, implementing a solver for these planning problems requires gluing a plethora of dependencies together.
All of these pieces are special in their own way, making dependency management an exercise in organized chaos.
The worst offender was task planning: my task planner was a Python script that takes in file-paths with problem definitions, then sets off a chain of dominoes converting the problem into an intermediate representation (another file), and finally firing off a separate search binary compiled from C++ to generate an infinite stream of solutions.
Naturally, there is no way to inspect the process, nor to programmatically request just one solution in a stream, so I wrote a hacky wrapper using `inotify` to inspect the planner's output in `/tmp` and send IPC signals to stop and start the planner process group whenever I needed another task plan.
Of course, any mistake in this management would fill my hard drive with nine hundred gigabytes of task plans.
If I don't catch it, no problem!
My desktop environment will notify me by crashing on out-of-storage errors.

After a few months mired in build scripts and template errors, I just gave up.
I rewrote the entire motion planning framework in Rust, and eventually rewrote my task planners too, then forked my simulation tools to make compile times faster.
On the whole, the rewrites of all my dependencies spanned maybe ten thousand lines of code, and took me a month or two of cumulative effort spread across the fall semester (and my winter break).

Conventional wisdom dictates that one should never do a total rewrite of their software, but in my case, it was a great choice!
Rewriting the motion planner gave me finer control over the planner (good for building on top of it), while rewriting the task planner yielded an order-of-magnitude speedup.
The difference is stark: I spent much of the fall of this year spinning my wheels, with very little clue of what to do and how to do it.
Once I started rewriting my entire project in Rust, I had a second wind: working on the project was way more fun, so I was able to move much more quickly.

I've come to think of my own research as a sort of play: the more fun I'm having, the more progress I make, and the more progress I make, the more fun I'm having.

## A spot of hope?

After over a year of work, I finally have a research project chugging along (mostly) smoothly.
I'm targeting a publication deadline in mid-September, so I have a lot of writing to do, but I am confident that I can make it.
Look out for a blog post when the project is (eventually) done!!

Personally, I feel that this has shown a lot of growth for me.
I can now set my own research directions, but I still struggle with motivation and time management.
In all, though, I'm looking forward to new projects building off my current work, and also maybe to getting sidetracked and building some weird tools.

So far, my research journey is like stumbling through a forest at night: getting tripped up, sometimes circling backward, but eventually getting just a little further.
For a while I thought I was getting nowhere, but now the gaps between the trees grow wider and the roots catch me less often; I walk further, faster, more confidently.
[TODO a nice closing sentence?]

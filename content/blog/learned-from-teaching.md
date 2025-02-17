+++
title = "Things I learned from teaching"
template = "post.html"
date = 2023-12-05
authors = ["Clayton Ramsey"]
description = "This spring, I taught an undergraduate class on chess engines. I probably learned more than any of my students."
+++

This spring, I taught an undergraduate class on chess engines. I
probably learned more than any of my students.

As a senior in college, I was the instructor, lecturer, grader, master
of ceremonies, and grand poobah of COLL 110: Artificial Intelligence for
Chess, 6-7 P.M. every Tuesday for the whole semester. In theory, I had a
faculty advisor, but he was busy most of the time, so at the end of the
day, it was my rodeo and I got to figure it all out on my own. I thought
it was a great experience!

I'm writing this post for a few reasons: first, I want to write down
the things I wish that I had known before I started teaching, in the
hopes that other soon-to-be teachers might take this to heart. The other
reason is to compile my own thoughts on the matter, since I'll possibly
revive this class in the future, and want to have some notes while it's
fresh in my mind.

## You're not even their second priority

If you're teaching a topic, you're probably really passionate about it
(unless, of course, the department forced you to teach the class). At
the very least, I am. Chess engines are cool. Lucky for me, students
taking a COLL course get little in the way of credit for the class, so
most of my pupils were also pretty stoked about it. At the end of the
day, though, they're not getting a Ph.D. in this stuff, and they've
got half a dozen other classes on top of work, family, friends, and this
weekend's party to think about.

To an instructor, this tends to manifest as an air of boredom with the
whole topic. Often, the students aren't actually bored! They just
don't have the time or energy for the topic that I do.

The fix, I think, is to meet students where they are. The hard (and
rewarding) part of teaching a class is that I needed to digest reams of
material into brief, easily-comprehensible components. I have the
patience to trawl through uncommented C++ code and ancient forum posts
to figure out how to build a good chess engine, but the students
shouldn't need it.

I'm not a hundred percent certain of the exact mechanisms of _how_,
yet. In my experience, I learn the most when I struggle; if a student
can shortcut through all the hard parts on, for example, an assignment,
they're not going to learn very much. On the flip side, when most
students struggle, they just give up. Somehow I need to make assignments
which thread the needle between being too hard to solve and too easy to
learn anything.

## Students have wildly varying backgrounds

Chess engines are a relatively niche topic in computer science, so I was
quite surprised to see that my class section was completely full at the
start of the semester. It seems as though most of the students had been
clickbaited by my mention of AI in the title, which is more a callout
for classical artificial intelligence than it is for the modern
machine-learning approaches.

Although a handful of students dropped the course, I was eventually left
with about a dozen students whose experience and programming skill
varied wildly. Some of my students had finished little more than an
introductory computer science course, while others were more qualified
than I was.

This presents a fundamental problem: how do I come up with a curriculum
which is complex enough to excite the experienced students without
completely losing the less experienced ones? The cynical answer is "you
can't," but I did give it a fair attempt, and I think it turned out
OK. Typically, I tried to integrate a mix of skill levels into my
lectures; for instance, when discussing the representation of squares
and directions, I spent a few minutes explaining how they could be
modeled with torsors, but not so long that I would lose the students who
neither knew nor cared about group theory.

Assignment design is harder. I tried to give interesting challenges by
leaving bonus tasks on every assignment, and for the final project, I
gave a choose-your-own-adventure assignment which allowed students to
pick a task that matched their skill level. However, I'm not convinced
that I perfected this approach, so I will need to think more deeply on
how do design "multi-level" projects for a mixed student body.

## Engagement falls off in the first ten minutes

COLL 110 was a standard lectures-and-assignments college class - I
lectured during our scheduled meeting time, then students did their
projects on their own. Having tried this, I think that this is just not
the future of education. This mode of teaching is designed mostly for
the lecturer's convenience, but it's a terrible way to foster student
understanding.

The fundamental reality is that it's impossible to listen actively for
a long period of time. It was even worse in my case: I was teaching a
blow-off class at the end of the day, so students were already tired and
didn't feel any pressure to keep up. The net result was that only about
half of my students were really paying attention at a time, which is
pretty bad if you want them to actually learn anything.

I'm certain that I will need to use a different format for lessons in
the future. Flipped classrooms are popular these days, so I might try
that, but I also feel that pre-recorded lectures are a little soulless.
I might try a hybrid approach, integrating lectures with assignments.

In terms of engagement, one of the best lectures I ever gave was the
introduction to Rust. This was because I got people to pull up the [Rust
Playground](https://play.rust-lang.org/) on their laptops, so they were
actively running and debugging code in class and I could work with them.
Moving forward, I want to try stuff like this some more:
fully-interactive in-class content which revolves around student
experimentation.

Easier said than done, though. Getting people to code in person is
actually quite difficult, and if there's only one of me, I can't keep
up with every student at once. COMP 140, the introductory CS class at
Rice, manages this with a small army of TAs who can keep up with all the
students, but I don't have any TAs to do that for me.

## Nobody goes to office hours

On every assignment, one of my students would write something like this
in the comments of their submission.

```rust
// This doesn't work and I don't know why.
// I didn't have enough time to figure it out.
```

And, invariably, every _single_ time, the problem with their work was
something that I could have (and would have happily) explained to them
at office hours or even in an email. It saddens me greatly to see these
kinds of submissions, since it's evidence of a completely solvable
problem.

I really love getting to work with students one-on-one. It often reveals
gaps in understanding that aren't obvious in lecture or in assignments,
and also shows me where I'm failing to cover material. One of my best
experiences when holding office hours was when I got to explain how the
function call stack works to an underclassman, and it was really
fulfilling to see how it "clicked" for them. When students show up to
office hours, it's extremely valuable for me and for them.

I think that there are a few reasons that students don't like to show
up to office hours. The first, simplest reason, is simply availability.
I think a lot of students start their projects far later than they
really ought to, and so by the time that they get stuck, there aren't
any office hours between then and the due date. The easiest fix is to
make office hours available on the same day that assignments are due, so
that I can be available when students are working on the assignment.

The second issue is comfort: sometimes, students feel like they're
imposing on their instructors' time by showing up to office hours. This
isn't helped by the fact that some professors can be downright _mean_
to their students at office hours, which can leave a bad taste in
students' mouths, even for other classes. When I spoke to one of my
instructional advisors about this, she recommended that I refer to
office hours as "student hours" instead, in order to set the
expectation that it's there for the students' benefit.

## Takeaways

I didn't come away from teaching this class feeling like I had mastered
the art of pedagogy, or even thinking that I was half decent. I suspect
that the core challenges that I faced were much the same as with any
other class, though perhaps exacerbated by COLL 110's status as an
elective.

Even then, I think it was a great opportunity for me to learn and grow
as a person, and has helped me a lot, especially in writing, public
speaking, and professional communication. If you're on the fence about
teaching, you should definitely give it a try, if only because
interacting with students is such a rewarding experience.

Thanks to [Shreyas](https://shreyasminocha.me/) and Charlie for
reviewing this article.

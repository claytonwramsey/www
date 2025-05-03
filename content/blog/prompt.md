+++
title = "I'd rather read the prompt"
date = 2025-05-03
description = ""
template = "post.html"
authors = ["Clayton Ramsey"]
draft = true
+++

When I grade students' assignments, I sometimes see answers like this:

> **Question**: What are the downsides of using Euler angles for representing rotations?
>
> <br>
>
> **Answer**: Utilizing Euler angles for rotation representation could have the following possible downsides:
>
> - **Gimbal lock**: In certain positions, orientations can reach a singularity, which prevents them from continuously rotating without a sudden change in the coordinate values.
> - **Numeric instability**: Using Euler angles could cause numeric computations to be less precise, which can add up and produce inaccuracies if used often.
> - **Non-unique coordinates**: Another downside of Euler angles is that some rotations do not have a unique representation in Euler angles, particularly at singularities.
>
> The downsides of Euler angles make them difficult to utilize in robotics.
> It's important to note that very few implementations employ Euler angles for robotics.
> Instead, one could use rotation matrices or quaternions to facilitate more efficient rotation representation.
>
> _[Not a student's real answer, but my handmade synthesis of the style and content of many answers]_

You only have to read one or two of these answers to know exactly what's up: the students just copy-pasted the output from a large language model, most likely ChatGPT.
They are invariably verbose, interminably waffly, and insipidly fixated on the bullet-points-with-bold style.
The prose rarely surpasses the sixth-grade book report, constantly repeating the prompt, presumably to prove that they're staying on topic.

As an instructor, I am always saddened to read this.
The ChatGPT rhetorical style is distinctive enough that I can catch it, but not so distinctive to be worth passing along to an honor council.
Even if I did, I'm not sure the marginal gains in the integrity of the class would be worth the hours spent litigating the issue.

I write this article as a plea to everyone: not just my students, but the blog posters and Reddit commenters and weak-accept paper authors and Reviewer 2.
**Don't let a computer write for you!**
I say this not for reasons of intellectual honesty, or for the spirit of fairness.
I say this because I believe that your original thoughts are far more interesting, meaningful, and valuable than whatever a large language model can transform them into.
For the rest of this piece, I'll briefly examine some guesses as to why people write with large language models so often, and argue that there's no good reason to use one for creative expression.

## Why do people do this?

I'm not much of a generative-model user myself, but I know many people who heavily rely upon them.
From my own experience, I see a few reasons why people use such models to speak for them.

**It doesn't matter.**
I think this belief is most common in classroom settings.
A typical belief among students is that classes are a series of hurdles to be overcome; at the end of this obstacle course, they shall receive a degree as testament to their completion of these assignments.
I think this is also the source of increasing language model use in in [paper reviews](https://arxiv.org/abs/2403.07183).
Many researchers consider reviewing an ancillary duty to their already-burdensome jobs; some feel that they cannot spare the time to write a good review and so pass the work along to a language model.

**The model produces better work.**
Some of my peers believe that large language models produce strictly better writing than they could produce on their own.
Anecdotally, this phenomenon seems more common among English-as-a-second-language speakers.
I also see it a lot with first-time programmers, for whom programming is a set of mysterious incantations to be memorized and recited.
I think this is also the cause of language model use in some forms of [academic writing](https://arxiv.org/abs/2404.01268): it differs from the prior case with paper reviews in that, presumably, the authors believe that their paper matters, but don't believe they can produce sufficient writing.

**There's skin in the game.**
This last cause is least common among individuals, but probably accounts for the overwhelming majority of language pollution on the Internet.
Examples of skin-in-the-game writing include astroturfing, customer service chatbots, and the rambling prologues found in online baking recipes.
This writing is never meant to be read by a human and does not carry any authorial intent at all.
For this essay, I'm primarily interested in the motivations for private individuals, so I'll avoid discussing this much; however, I have included it for sake of completeness.

## Why do we write, anyway?

I believe that the main reason a human should write is to _communicate original thoughts_.
To be clear, I don't believe that these thoughts need to be special or academic.
Your vacation, your dog, and your favorite color are all fair game.
However, these thoughts should be _yours_: there's no point in wasting ink to communicate someone else's thoughts.

## Fullcoming

If it's not worth writing, it's not worth reading.

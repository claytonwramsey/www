+++
title = "I'd rather read the prompt"
date = 2025-05-03
description = ""
template = "post.html"
authors = ["Clayton Ramsey"]
+++

When I grade students' assignments, I sometimes see answers like this:

> Utilizing Euler angles for rotation representation could have the following possible downsides:
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
Many researchers consider reviewing ancillary to their already-burdensome jobs; some feel they cannot spare time to write a good review and so pass the work along to a language model.

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

In that sense, using a language model to write is worse than plagiarism.
When copying another person's words, one doesn't communicate their own original thoughts, but at least they are communicating a human's thoughts.
A language model, by construction, has no original thoughts of its own; publishing its output is a pointless exercise.

Returning to our reasons for using a language model, we can now examine them once more with this definition in mind.

### If it's not worth doing, it's not worth doing well

The model output in the doesn't-matter category falls under two classes to me: the stuff that actually doesn't matter and the stuff that actually does matter.
I'll start with the things that don't matter.
When someone comments under a Reddit post with a computer-generated summary of the original text, I honestly believe that everyone in the world would be better off had they not done so.
Either the article is so vapid that a summary provides all of its value, in which case, it does not merit the engagement of a comment, or it demands a real reading by a real human for comprehension, in which case the summary is pointless.
In essence, writing such a comment wastes everyone's time.
This is the case for all of the disposable uses of a model.

Meanwhile, there are uses which seem disposable at a surface-level and which in practice are not so disposable (the actually-does-matter category).
I should hope that the purpose of a class writing exercise is not to create an artifact of text but force the student to think; a language model produces the former, not the latter.
For paper reviewers, it's worse: a half-assed review will produce little more than make-work for the original authors and tell the editor nothing they didn't already know.

### If it's worth doing, it's worth doing badly

I'll now cover the opposite case: my peers who see generative models as superior to their own output.
I see this most often in professional communication, typically to produce fluff or fix the tone of their original prompts.
Every single time, the model obscures the original meaning and adds layers of superfluous nonsense to even the simplest of ideas.
If you're lucky, it at least won't be wrong, but most often the model will completely fabricate critical details of the original writing and produce something completely incomprehensible.
No matter how bad any original human's writing is, I can (hopefully?) trust that they have some kind of internal understanding to share; with a language model, there is no such luck.

I have a little more sympathy for programmers, but the long-term results are more insidious.
You might recall Peter Naur's <cite>Programming as Theory Building</cite>: writing a sufficiently complex program requires not only the artifact of code (that is, the program source), but a <dfn>theory</dfn> of the program, in which an individual must fully understand the logical structure behind the code.
Vibe coding; that is, writing programs almost exclusively by language-model generation; produces an artifact with no theory behind it.
The result is simple: with no theory, the produced code is practically useless.
In Naur's terms, such a program is <dfn>dead</dfn>; in our case, it's stillborn.
It should come as no surprise that nearly every vibe-coded app on the Internet struggles with security issues; look no further than [the vibe-coded recipe app that leaks its OpenAI keys](https://news.ycombinator.com/item?id=43553031#43554611).
Every time one generates code by prompt, they create a new stillborn program; vibe coding is the art of stitching together their corpses into Frankenstein's monster.

## An annotated exercise

As an experiment, I copied the thesis statement of this essay into Google Gemini and prompted it to complete the essay.
Below the spoiler is its complete response.

<details>
  <summary>The complete prompt and output.</summary>

Prompt:

> The following is an introduction to a short essay which I have written. Complete the essay by writing 2 short paragraphs.
>
> I write this article as a plea to everyone: not just my students, but the blog posters and Reddit commenters and weak-accept paper authors and Reviewer 2.
> **Don't let a computer write for you!**
> I say this not for reasons of intellectual honesty, or for the spirit of fairness.
> I say this because I believe that your original thoughts are far more interesting, meaningful, and valuable than whatever a large language model can transform them into.
> For the rest of this piece, I'll briefly examine some guesses as to why people write with large language models so often, and argue that there's no good reason to use one for creative expression.

Output:

> It's fascinating to consider why so many are turning to large language models for writing. Perhaps it stems from a desire for efficiency, a wish to quickly generate text without the perceived effort of crafting each sentence. The allure of instant output can be strong, especially in a world that often prioritizes speed. For students facing deadlines, or blog posters needing content, the temptation to shortcut the writing process might feel overwhelming. There could also be a sense of insecurity, a feeling that one's own writing isn't "good enough" and that a language model can somehow elevate it. This might be particularly true for those navigating the often critical world of academic reviews or the sometimes harsh landscape of online commentary.
>
> However, this reliance on artificial intelligence fundamentally misunderstands the very essence of creative expression. Your individual voice, shaped by your unique experiences, perspectives, and even your struggles to articulate an idea, is what makes your writing resonate. A language model, trained on vast datasets of existing text, can only ever produce a pastiche, a reflection of what has already been said. It lacks the spark of genuine insight, the unexpected turn of phrase that comes from wrestling with a concept until it becomes your own. To surrender your voice to an algorithm is to diminish the potential for true connection and the profound satisfaction of communicating your own original thoughts to the world.

</details>

The resulting text is, put plainly, _boring_.
In its 234-word output, the model produces merely a lengthy rehash of the same prompt.
Tonally, it provides no more than sweeping and pointless generality, and any points earned for its brobdingnagian vocabulary are immediately lost to its total lack of taste in using it.
For example, consider the following sentence:

> Perhaps it stems from a desire for efficiency, a wish to quickly generate text without the perceived effort of crafting each sentence.

Gemini has produced a big sentence for a small thought.
I can trivially cut two-thirds of it and remove nothing of substance:

> Perhaps it stems from a desire for efficiency.

With some care, I can trim it a little more.

> Perhaps people do it for efficiency.

So, in short, a language model is great for making nonsense, and not so great for anything else.

## Just show me the prompt

I now circle back to my main point: I have never seen any form of create generative model output (be that image, text, audio, or video) which I would rather see than the original prompt.
The resulting output has less substance than the prompt and lacks any human vision in its creation.
The whole point of making creative work is to share one's own experience - if there's no experience to share, why bother?
If it's not worth writing, it's not worth reading.

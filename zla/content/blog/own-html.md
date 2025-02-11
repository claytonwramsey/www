+++
title = "Writing my own damn HTML"
template = "post.html"
date = 2023-10-07
authors = ["Clayton Ramsey"]
description = "The future of the web doesn't have to be webapp frameworks and cookie prompts."
+++

The future of the web doesn't have to be webapp frameworks and cookie
prompts.

This week, I rewrote my website from scratch. Earlier, I had used
[Jekyll](https://jekyllrb.com/) to generate my website, but I had gotten
sick of it. In particular, I didn't like having to add hack upon hack
to get things to render the way I wanted to, I didn't like the hacky
build system, and I didn't like having to debug the mishmash of
mismatched versions, outdated documentation, and broken Ruby
environments.

In all, I think it's been a really fun experience! To be completely
honest, I think that building this site in vanilla HTML was _easier_
than doing it with Jekyll. The only thing I really miss is writing up my
blog posts in Markdown, because I can write a little faster in it.

More importantly, I think that everyone in the business of having a
personal website should consider writing their own HTML - maybe we
actually got it right in the nineties. I'll explain in further detail
below.

## It's not as hard as you think it is

HTML, at heart, is a very simple format. It's a little ugly, but being
ugly didn't stop us from using C++ either. Shipping your website is as
simple as serving some webpages. If you're like me, and just serving
some text and pictures, it's not worth the effort of minifying your
HTML to save a whole kilobyte of data - you can just serve a page as you
wrote it.

I think the main monotonous part of working with raw HTML is the stuff
that's common across pages - things like the header and footer on this
very website. For now, I'm perfectly comfortable using a mix of
copy-paste and find-and-replace on the 8 pages I have on this website.
Later on, I think I might use a hack with CSS's `:before` and `:after`
in case I decide I don't like it, but for now, I think this is OK.

## Getting fine-grained control

I'm not a huge stickler for the way that my websites look, but I do
think that classic, simple HTML is gorgeous. You only need a tiny bit of
CSS to make a website that's simple, clean, and good-looking.

However, I see my website as a sort of self-expression project - kind of
like a zen garden, but for people who don't go outside. Building a
website should be _fun_, and we (as writers) should be able to
experiment with the ways that they look. Right now, I'm aiming for a
look that blends in with native interfaces, but I might change that
later. Maybe I could go for the 1999 GeoCities look with hot pink
backgrounds and abuse of `<marquee>`.

The thrust of my blog so far seems to have been towards a mix of math,
algorithms, and software engineering. Accordingly, I use a handful of
scripts ([MathJax](https://www.mathjax.org/) and
[Highlight.js](https://highlightjs.org/)) to do so. I suppose that
differentiates me from the HTML-only purists, but I think it's a worthy
tradeoff. You probably have your own preferences on scripts - do it
however you like.

## Need for speed

Most websites I visit regularly are just embarrassing. They take
multiple seconds to load on my 100 Mbps university network. Think about
that!

A handwritten letter is often no more than a thousand words, probably
only a few kilobytes. The HTML for this page is nine kilobytes. Modern
websites, somehow, manage to ship dozens of _megabytes_ every time you
load a page. We often underestimate how wasteful - and, frankly, how
annoying - this is.

Browsers and web connections are actually extremely performant. The
human race as a whole has spent millions of engineer-hours just on
making web pages load faster. When we lean into it and start using
simple, clean HTML, it lets the browser's performance really shine. Try
refreshing this page and seeing if you notice how long it takes!

## Built to last

I'm often bothered by the fact that software _rots._ It feels like it
shouldn't happen - it's just bits! They can be copied losslessly! In
actuality, I don't think it's the software that rots - it's the
institutions and conventions surrounding it. Try getting someone's C++
project from 15 years ago building from source today - if there's any
third-party libraries involved, you might as well just give up and go
home. This is the rule, not the exception, when it comes to software.

But HTML is surprisingly evergreen! I can visit a website designed in
1995 and see it (almost) exactly as the original author intended, except
with a much higher DPI. We often don't appreciate how incredible that
fact is.

There's a bit of a tradeoff between control and resilience, though.
Pure HTML is relatively inflexible, but JavaScript libraries rot and
triply so for third-party scripts, fonts, and styles. We can mitigate
this, though. In my case, I self-host the extra JS libraries that I use
to reduce dependency on third parties. I haven't gotten around to
self-hosting MathJax yet because I haven't quite figured out what to do
with the fonts. I'll do it eventually, though.

I'll probably lose interest in this website someday, or perhaps I'll
move it to another domain. When that happens, I want to make sure that
it's something that I can easily maintain - something simple, that I
can run cross-platform, without pain. Pure HTML is about as close to
getting to zero dependencies as I can get without writing my own web
server.

## Simplicity counts

I really love Guy Steele's 1998 talk, [Growing a
Language](https://www.youtube.com/watch?v=lw6TaiXzHAE). It's a delight,
and if you haven't seen it, you should stop reading this essay and go
watch it. There are a number of great gems in there, but the one I'm
interested in is buried in his final remarks.

I'll spoil the conceit of the talk here here: Steele restricts himself
to using only one-syllable words and the words he defines from them
during the talk. At the very end, he says the following.

> I have found that this mode of speech makes it hard to hedge. It takes
> work and great care and some skill to find just the right way to say
> what you want to say, but in the end, you seem to have no choice but
> to talk straight. If you do not veer wide of the truth you are forced
> to hit it dead on.
>
> <footer>Guy Steele, Growing A Language, 1998</footer>

I think the same reasoning applies to restricting ourselves to simple,
reliable tools. When we're writing every tag, we get to ask ourselves
questions like "is adding this div really worth it?" and "can I find
an easier way to do this?". Simple tools force us to reason about
what's actually important and cut away everything else. That's the
heart of the simple web - it's a shortcut to the things that we truly
value.

Thank you for reading this.

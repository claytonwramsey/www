+++
title = "No longer writing my own damn HTML"
template = "post.html"
date = 2025-02-11
authors = ["Clayton Ramsey"]
description = "I've (mostly) given up on hand-writing HTML for my personal blog."
+++

I've (mostly) given up on hand-writing HTML for my personal blog.
Previously, [I wrote all the HTML for this site by hand](@/blog/own-html.md)
Over the past few days, I recently ported my whole blog from HTML to [Zola](https://www.getzola.org/).
I'm writing this post partly to explain why and how I did it, and in part as a response to [other](https://devpoga.org/i-blog-with-raw-html/) [posts](https://misc.l3m.in/txt/raw_txt.txt) about writing a blog using spartan tooling.

## Papercuts

So, why change over?
In short, I just got sick of it.
I stand by my original claims from when I ported from Jekyll to HTML: namely, handwriting HTML is honestly not that hard.
However, writing every post added a few small papercuts that made writing harder than it had to be.

To write a new article, I'd have to go through a long sequence of steps:

1. Copy-paste an older article to get the correct headers and navbar.
1. Manually edit the title blocks, description, and some links.
1. Write the post, using `<p>` and `<section>` manually.
1. Painstakingly check for mistakes and polish errors.

The story got worse whenever I had to do anything involving math: I wanted to avoid shipping JavaScript to users, so I wrote all my math in MathML.
MathML is many things, but "writable by humans" is not one of them.
Instead, I used a [converter tool](https://temml.org/) once I had finished writing each article and then copy-pasted every formula into the post.
It felt like an exercise in pointless manual labor.

I also wanted to highlight code, but I wasn't going to submit myself to the misery of writing `span`s for every keyword.
As a workaround, I shipped [Highlight.js](https://highlightjs.org/) with all my blog articles, which I never really liked.
My site was static, so why should I force users to do rendering work on their machines?

## An ad-hoc, informally-specified, bug-ridden, slow implementation of half of ~~Common Lisp~~ a static site generator

Eventually, I got sick of manually converting my equations, so I wrote a Python script to automatically convert LaTeX expressions to MathML in my blog posts.
I started considering writing an automated tool for inserting my navbars into the HTML files, and then I realized that I was completely wasting my time.
After some shopping around, I decided Zola was the least deranged of the existing site generators, so I tried rolling with it.

My main requirements were that I wanted to manually implement my own styling and and I needed server-side support for math and code, and I could do both with Zola (albeit requiring a little bit of effort).

## How it works

Right now, this website is served by GitHub Pages via some convoluted manually written actions.
I could have made things easier, but I decided it's the twenty-first century and I should act like it: instead of using KaTeX or MathJaX, I'm using a [fork](https://github.com/cestef/zola) of Zola with Typst support written by [cstef](https://cstef.dev/).
This is a little hacky, but I think it has all the features I really want, so I don't mind pinning myself to one specific version for now.

I ported over all my posts into Markdown using [pandoc](https://pandoc.org/index.html).
It wasn't perfect, but I only had to do a little bit of manual editing, which is far better than rewriting all my posts by hand.
The most annoying part was math, since pandoc seemed to butcher all my math expressions, converting them to an incomprehensible style of LaTeX that I manually converted into Typst.

Because I was using a weird fork of Zola, I had to write my own action pipeline to deploy everything.
It was a pain.
GitHub Actions is one of the most annoying specification languages I've ever had the misfortune to use.
After half an hour of finagling I finally got everything to work somewhat consistently, mostly by cargo-culting my way through YAML specifications.

## Have I learned anything?

I don't think I'm any better at website administration now, but at least I know it won't be too hard to jump ship if I change my mind again.
I certainly can write my blog posts a lot faster, and the "activation energy" for starting a new post is much lower.
My hope is that I'll take advantage of this and start writing more!

So, to make a long story short, I can only say one thing.
For thousands of years, man has invented technology to ameliorate the petty pains and discomforts of his life.
It would be an insult not to use it.

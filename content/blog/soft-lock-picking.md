+++
title = "Soft lock picking in real life"
date = 2026-03-27
description = "Last weekend, I played a fun little indie game called Real Life Soft Lock Picking. To play, just lose your phone, wallet, and keys all at the same time."
template = "post.html"
authors = ["Clayton Ramsey"]
+++

Last weekend, I played a fun little indie game called _Real Life Soft Lock Picking_.
To play, just lose your phone, wallet, and keys all at the same time.

You will then be _soft locked_: despite every system in the world working as intended, you'll be locked out of your home, unable to make any progress or even feed yourself.
The only way out is by [soft lock picking](https://www.youtube.com/playlist?list=PL-UR_8lpdcfepFOyC7AY-AVKN-S_rH0bM), where you have to escape from a soft lock with a mix of cleverness and extraordinary patience.

## Homeward bound

Once soft locked, your first problem is going to be finding some way to eat and sleep.
Having locked your front door, you can't get into your home.
I live alone, so there were no spare copies of my home key except my landlord's --- but naturally, since I was phoneless, I had no way to contact him.

In any event, I lost all my things late on a Saturday night, so it would be unreasonable to expect my landlord to be available anyway.
Once soft-locked, you are at the mercy of others; luckily, I had a friend who was willing to feed and house me until I got my stuff back.
I'm left wondering about the people who aren't as fortunate as me: people who have just moved, or who are traveling, or parents with kids that will all need food and shelter on short notice.
Even when resources for them exist, you still need a way to find them and reach them, and without a phone, money, or transportation, it's nearly impossible.

## Catch twenty-two factor authentication

Even with the most pressing issues solved, you're still soft locked.
Your best lead to finding your stuff is using a tool like Find My to locate your phone and hoping that your phone is in the same place as all your other valuables.
However, you probably won't even be able to access Find My, since everything will be locked by two-factor authentication.

Back in the day, you only needed a username and password to sign into anything.
Since passwords leak [all the time](https://en.wikipedia.org/wiki/List_of_data_breaches), most systems now demand that sign-ons from new devices pass two-factor authentication.
Typically, this means that after trying the half-dozen or so passwords that you can remember, you will be greeted by a fun little message like this:

> <div style="background-color: rgba(0, 0, 0, 0.1); border-radius: 15px; padding: 10px"><h3 style="margin-top: 0px; text-align: center">Let's make sure it's really you</h3>
>
> <p style="text-align: center; text-indent: 0; font-size: 150%">
> [ ] [ ] [ ] [ ] [ ] [ ]
> </p>
>
> We've sent a text to your phone with a 6-digit code.
> Enter that code above in the next 10 minutes to prove it's really you.
>
> - [Email me a code instead](https://www.youtube.com/watch?v=XfELJU1mRMg)
> - [Contact support](file:///dev/null)
>
> </div>

This leaves you with a circular problem:

- You need to access your accounts to locate your phone.
- You need to pass two-factor authentication to access your accounts.
- You need your phone to access your accounts.

If I could get back into my apartment, I could at least use my laptop to try bypassing two-factor authentication.
But after a morning texting him from a borrowed phone, my landlord wasn't answering my texts, so that was right out.

After a few tries, I found that Apple's authentication system is a fickle lover: sometimes, it will decide that your login attempt is cool enough to bypass two-factor authentication.
With this in hand, I tracked down my phone (and all my other stuff) to the home of a confused gentlement who had accidentally grabbed the wrong bag.

## Leaving keys around

In hindsight, it's possible for a prudent person to leave themselves keys to make soft locks a little easier to pick.
They can be physical, like leaving a real key with a friend, or metaphorical, like getting more ways to access your accounts.
Maybe using just using Nix would have fixed this.

But expecting users to leave keys for themselves is a design mistake: Every backup method will eventuall fail.
Users lose stuff and forget things all the time, and soft locking a user for that is just an exercise in automated cruelty.
We make products to serve people, and not the other way around.

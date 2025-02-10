+++
title = "blah"
template = "post.html"
date = 2024-10-01
authors = ["Clayton Ramsey"]
description = "So what?"
+++

Here's some code (it's `code`):

```rust
let chunk_size = /* some number */;
let words = /* list of possible guesses */;
let answers = /* list of possible answer words */;

scope(|s| {
    let handles: Vec<_> = words
        .chunks(chunk_size)
        .enumerate()
        .map(|(j, c)| {
            s.spawn(move || {
                let mut best_ent = f32::INFINITY;
                let mut best_word_id = usize::MAX;
                for (i, w) in c.iter().enumerate() {
                    // imagine `entropy_after` returns
                    // the expected remaining entropy after
                    // guessing `w`
                    let ent = entropy_after(w, answers);
                    if ent < best_ent {
                        best_ent = ent;
                        best_word_id = i;
                    }
                }
                (best_ent, best_word_id + j * chunk_size)
            })
        })
        .collect();

    let mut best_ent = f32::INFINITY;
    let mut best_id = usize::MAX;
    for handle in handles {
        let (ent, id) = handle.join().unwrap();
        if ent < best_ent {
            best_ent = ent;
            best_id = id;
        }
    }

    (best_ent, best_id)
})
```

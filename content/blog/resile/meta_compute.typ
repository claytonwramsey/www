
#import "@preview/lovelace:0.3.0": *

#set page(width: 20cm)

#figure(
  kind: "algorithm",
  supplement: [Algorithm],

  pseudocode-list(booktabs: true, numbered-title: [MetaCompute])[

    - *Input*: wrapped subproblem $p$, existing solution $S$,  old vocabulary $V$, new vocabulary $V'$, solution index $i$, world state $w$,
    - *Output*: solution, incomplete subproblem, or child and sibling problems
    + *if* $p$ is a fictitious node *then*
      + *if* $i = "len"(S)$ *then*
        + *return* DeadEnd;
      + $w_"goal" <-$ world state after executing $S_{..i}$;
      + $i <- i + 1$;
      + $g <- "TryTranslate"(w_"goal", V, V')$;
      + *if* $g = "Failure"$ *then*
        + *return* Incomplete;
      + *return* child subproblem $"MakeSubproblem"(w, g)$ and sibling subproblem $p$;
    + *else*
      + $r <- "Compute"(p)$;
      + *if* $r$ is solution $S^"new"$ *then*
        + $S^"new" <- "TryStitch"(S^"new", S_{i..})$;
        + *if* $S^"new" = "Failure"$ *then*
          + *return* DeadEnd;
        + *return* solution $S^"new"$;
      + *return* $r$;
  ]
) <cool>

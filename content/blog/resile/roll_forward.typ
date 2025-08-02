
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge
#import fletcher.shapes: house, hexagon, brace
#import "@preview/cetz:0.4.1"
#set text(font: "New Computer Modern")
#set page(margin: 1pt)

#let blob(pos, label, tint: white, ..args) = node(
	pos, align(center, label),
	fill: tint.lighten(60%),
	stroke: 1pt + tint.darken(20%),
	corner-radius: 5pt,
	..args,
)

#let e(
  start,
  end,
  ..args,
) = {
  if start.at(0) == end.at(0) {
    edge(start, end, "-|>", ..args)
  } else {
    let ymid = { start.at(1) + end.at(1) } / 2
	edge(start, (start.at(0), ymid), (end.at(0), ymid), end, "-|>", ..args)
  }
}

#diagram(
  // debug: 10,
	spacing: 8pt,
	cell-size: (40mm, 20mm),
	edge-stroke: 1pt,
	edge-corner-radius: 5pt,
	mark-scale: 70%,
	let w0 = (0, 0),
	let w1 = (0, 1),
	let w2 = (0, 2),
	let w3 = (0, 3),

	let w0p = (1, 0),
	let w1p = (1, 1),
	let w2p = (1, 2),

	blob(w0, $w_0$),
	blob(w1, $w_1$),
	blob(w2, $w_2$),
	blob(w3, $w_3$),
	let soln = (0, 3.5),
	node(soln),

	edge(w0, w1, $a_0$, label-side: left, "-|>"),
	edge(w1, w2, $a_1$, label-side: left, "-|>"),
	edge(w2, w3, $a_2$, label-side: left, "-|>"),

	node(
	  enclose: (w0, w1, w2, w3, soln),
		fill: green.lighten(90%),
		stroke: 1pt + green.darken(20%),
		corner-radius: 5pt,
		inset: 8pt,
		label: align(bottom)[Old solution],
		snap: false,
	),

	blob(w0p, $w'_0$, tint: yellow),
	blob(w1p, $w'_1$, tint: yellow),
	blob(w2p, $w'_2$, stroke: (dash: "dashed")),

	edge(w0p, w1p, "-|>", label: $a'_0$, label-side: right),
	edge(w1p, w2p, label: $a'_1$, marks: (
	  (inherit: "X", scale: 200%, stroke: red + 2pt, pos: 0.5),
		"|>",
	), stroke: (dash: "dashed"), label-side: right),
	// e(w2p, w3p, $a_2'$),

	node(
	  enclose: (w0p, w1p),
		shape: brace.with(dir: right, label: [New start states]),
		snap: false,
	),

	edge((0.25, 0.35), (0.75, 0.35), "-|>", bend: +30deg),
	edge((0.25, 1.35), (0.75, 1.35), "-|>", bend: +30deg),
)

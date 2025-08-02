

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
	cell-size: (45mm, 20mm),
	edge-stroke: 1pt,
	edge-corner-radius: 5pt,
	mark-scale: 70%,
	let w0 = (0, 0),
	let w1 = (0, 1),
	let w2 = (0, 2),
	let w3 = (0, 3),

	let g0 = (1, 0),
	let g1 = (1, 1),
	let g2 = (1, 2),
	let g3 = (1, 3),


	blob(w0, $w_0$),
	blob(w1, $w_1$),
	blob(w2, $w_2$),
	blob(w3, $w_3$),
	let soln = (0, 3.5),
	node(soln),

	e(w0, w1, $a_0$),
	e(w1, w2, $a_1$),
	e(w2, w3, $a_2$),

	node(
	  enclose: (w0, w1, w2, w3, soln),
		fill: green.lighten(90%),
		stroke: 1pt + green.darken(20%),
		corner-radius: 5pt,
		inset: 8pt,
		label: align(bottom)[Old solution],
		snap: false
	),


	blob(g0, $g_0$, stroke: (dash: "dashed")),
	blob(g1, $g_1$, stroke: (dash: "dashed")),
	blob(g2, $g_2$, tint: yellow),
	blob(g3, $g_3$, tint: yellow),

	let failed = (
	  (inherit: "X", scale: 200%, stroke: red + 2pt, pos: 0.5),
		"|>",
	),
	edge(w0, g0, marks: failed, bend: +30deg, stroke: (dash: "dashed")),
	edge(w1, g1, marks: failed, bend: +30deg, stroke: (dash: "dashed")),
	edge(w2, g2, "-|>", bend: +30deg),
	edge(w3, g3, "-|>", bend: +30deg),

	node(
	  enclose: (g2, g3),
		shape: brace.with(dir: right, label: [New goal constraints]),
		snap: false,
	),


	node(
	  enclose: ((0.2, -0.5), (0.8, -0.5)),
		shape: brace.with(dir: top, label: [Attempted translation]),
		snap: false,
	)
)

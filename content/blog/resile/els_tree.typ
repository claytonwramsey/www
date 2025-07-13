
#import "@preview/fletcher:0.5.2" as fletcher: diagram, node, edge
#import fletcher.shapes: house, hexagon
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
	spacing: 8pt,
	cell-size: (8mm, 16mm),
	edge-stroke: 1pt,
	edge-corner-radius: 5pt,
	mark-scale: 70%,
	let x = 0,
	let root = (0, 0),
	let pi0 = (0, 1),
	let pi1 = (2, 1),
	let pi2 = (4, 1),
	let pi3 = (5, 1),
	let q0 = (0, 2),
	let q1 = (1, 2),
	let q2 = (2, 2),
	let q3 = (3, 2),
	let m0 = (0, 3),
	let m1 = (2, 3),
	let q4 = (2, 4),
	let q5 = (3, 4),
	let m2 = (2, 5),
	let q6 = (4, 2),

	let soln = (2, 5.6),


	node(soln),
	blob(root, [Root], tint: yellow, shape: hexagon),
	blob(pi0, $pi_0$, tint: blue),
	blob(pi1, $pi_1$, tint: blue),
	blob(pi2, $pi_2$, tint: blue),
	blob(pi3, $pi_3$, tint: orange),
	blob(q0, $q_0$, tint: blue),
	blob(q1, $q_1$, tint: orange),
	blob(q2, $q_2$, tint: blue),
	blob(q3, $q_3$, tint: orange),
	blob(m0, $tau_0$, tint: orange),
	blob(m1, $tau_1$, tint: blue),
	blob(q4, $q_4$, tint: blue),
	blob(q5, $q_5$, tint: orange),
	blob(m2, $tau_2$, tint: blue),
	blob(q6, $q_6$, tint: orange),

	e(root, pi0),
	e(root, pi1),
	e(root, pi2),
	e(root, pi3),

	e(pi0, q0),
	e(pi0, q1),

	e(pi1, q2),
	e(pi1, q3),

	e(q0, m0),
	e(q2, m1),
	e(m1, q4),
	e(m1, q5),
	e(q4, m2),
	e(pi2, q6),

	node(
		enclose: (pi1, q2, m1, q4, m2, soln),
		fill: green.lighten(90%),
		stroke: 1pt + green.darken(20%),
		corner-radius: 5pt,
		inset: 8pt,
		label: align(bottom)[Solution],
	),
)


#import "@preview/fletcher:0.5.2" as fletcher: diagram, node, edge
#import fletcher.shapes: house, hexagon
#set text(font: "New Computer Modern")

#let blob(pos, label, tint: white, ..args) = node(
	pos, align(center, label),
	fill: tint.lighten(60%),
	stroke: 1pt + tint.darken(20%),
	corner-radius: 5pt,
	..args,
)

#let done(pos, label, ..args) = blob(pos, label, tint: blue, ..args)
#let open(pos, label, ..args) = blob(pos, label, tint: orange, ..args)
#let cap(pos, label, ..args) = blob(pos, label, tint: yellow, ..args)

#let e(
  start,
  end,
  ..args,
) = {
  let ymid = { start.at(1) + end.at(1) } / 2
  edge(start, (start.at(0), ymid), (end.at(0), ymid), end, "-|>", ..args)
}

#diagram(
	spacing: 8pt,
	cell-size: (1mm, 5mm),
	edge-stroke: 1pt,
	edge-corner-radius: 5pt,
	mark-scale: 70%,
	let root = (0, 0),

	cap(root, $bold(cal(P))$, tint: yellow, shape: hexagon),
	// edge((0,1), (0, 0.35), "r", (2,3), "r,u", "-|>"),


	edge("-|>"),
	cap((0, 2), $P$, shape: house),
	edge("-|>"),
	done((0, 4), $pi$),
	edge("-|>"),
	open((0, 6), $q$),
	e((0, 2), (1, 4)),
	done((1, 4), $pi$),
	edge("-|>"),
	open((1, 6), $q$),
	e((0, 2), (2, 4)),
	open((2, 4), $pi$),

	cap((4, 2), $R_1$, shape: house),
	e(root, (4, 2)),

	edge("-|>"),
	done((4, 4), $pi$),
	edge("-|>"),
	open((4, 6), $q$),
	e((4, 2), (5, 4)),
	done((5, 4), $pi$),
	edge("-|>"),
	done((5, 6), $q$),
	edge("-|>"),
	done((5, 8), $tau$),
	e((4, 2), (6, 4)),
	open((6, 4), $pi$),


	cap((8, 2), $R_2$, shape: house),
	e(root, (8, 2)),

	edge("-|>"),
	done((8, 4), $pi$),
	edge("-|>"),
	done((8, 6), $q$),
	edge("-|>"),
	open((8, 8), $tau$),
	e((8, 2), (9, 4)),
	done((9, 4), $pi$),
	open((9, 6), $q$),
	e((8, 4), (9, 6)),
	e((8, 2), (10, 4)),
	open((10, 6), $q$),
	e((9, 4), (10, 6)),
	open((10, 4), $pi$),

	node(
	  enclose: ((5, 4), (5, 6), (5, 8)),
		fill: green.lighten(90%),
		stroke: 1pt + green.darken(40%),
		corner-radius: 5pt,
		inset: 8pt,
		snap: false
	),


	cap((12, 2), $R_3$, shape: house),
	e(root, (12, 2)),

	edge("-|>"),
	done((12, 4), $pi$),
	edge("-|>"),
	open((12, 6), $q$),
	e((12, 2), (13, 4)),
	open((13, 4), $pi$),
)

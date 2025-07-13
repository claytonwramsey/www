
#import "@preview/fletcher:0.5.2" as fletcher: diagram, node, edge
#import fletcher.shapes: house, hexagon
#set page(width: auto, height: auto, margin: 5mm, fill: white)
#set text(font: "New Computer Modern")

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
  let ymid = { start.at(1) + end.at(1) } / 2
  edge(start, (start.at(0), ymid), (end.at(0), ymid), end, "-|>", ..args)
}

#diagram(
	spacing: 8pt,
	cell-size: (8mm, 10mm),
	edge-stroke: 1pt,
	edge-corner-radius: 5pt,
	mark-scale: 70%,
	let x = 0,
	let root = (0, 0),

	blob(root, [Root], tint: yellow, shape: hexagon),
	// edge((0,1), (0, 0.35), "r", (1,3), "r,u", "-|>"),


	edge("-|>"),
	blob((x, 2), [Replan], tint: yellow, shape: house),
	edge("-|>"),
	blob((x, 4), $pi_0$, tint: blue),
	e((x, 2), (x + 0.5, 4)),
	let x = x + 0.5,
	blob((x, 4), $pi_1$, tint: blue),
	e((x, 2), (x + 0.5, 4)),
	let x = x + 0.5,
	blob((x, 4), $pi_2$, tint: orange),

	let x = x + 1,
	blob((x, 2), [Repair 1], tint: yellow, shape: house),
	e(root, (x, 2)),

	edge("-|>"),
	blob((x, 4), $pi_0$, tint: blue),
	e((x, 2), (x + 0.5, 4)),
	let x = x + 0.5,
	blob((x, 4), $pi_1$, tint: blue),
	e((x, 2), (x + 0.5, 4)),
	let x = x + 0.5,
	blob((x, 4), $pi_2$, tint: orange),


	let x = x + 1,
	blob((x, 2), [Repair 2], tint: yellow, shape: house),
	e(root, (x, 2)),

	let x = x + 1,
	blob((x,2), [Repair 3], tint: yellow, shape: house),
	e(root, (x, 2)),
)

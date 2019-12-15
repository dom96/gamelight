import sugar, os, options

import gamelight/[graphics, vec, geometry]

let outline = [
  (Point[float](x: 54, y: 2.007), Point[float](x: 46.25, y: 2.007)),
  (Point[float](x: 46.25, y: 2.007), Point[float](x: 32.044, y: 29.975)),
  (Point[float](x: 32.044, y: 29.975), Point[float](x: 0.023, y: 35.5)),
  (Point[float](x: 0.023, y: 35.5), Point[float](x: 0, y: 42.5)),
  (Point[float](x: 0, y: 42.5), Point[float](x: 21.35, y: 63.35)),
  (Point[float](x: 21.35, y: 63.35), Point[float](x: 17.135, y: 93.712)),
  (Point[float](x: 17.135, y: 93.712), Point[float](x: 20.866, y: 97.713)),
  (Point[float](x: 20.866, y: 97.713), Point[float](x: 50, y: 85.021)),
  (Point[float](x: 50, y: 85.021), Point[float](x: 76.75, y: 97.713)),
  (Point[float](x: 76.75, y: 97.713), Point[float](x: 81.925, y: 95.713)),
  (Point[float](x: 81.925, y: 95.713), Point[float](x: 79.135, y: 63.35)),
  (Point[float](x: 79.135, y: 63.35), Point[float](x: 99.634, y: 42.5)),
  (Point[float](x: 99.634, y: 42.5), Point[float](x: 99.634, y: 35.5)),
  (Point[float](x: 99.634, y: 35.5), Point[float](x: 68.198, y: 29.975)),
  (Point[float](x: 68.198, y: 29.975), Point[float](x: 54, y: 2.007)),
]

var isInside = false

proc onTick(renderer: Renderer2D, elapsedTime: float) =
  renderer.fillRect(0, 0, 640, 480, "#6577ac")

  renderer.beginPath()
  for i, line in outline:
    if i == 0:
      renderer.moveTo(line[0].x, line[0].y)
    else:
      renderer.lineTo(line[0].x, line[0].y)
    renderer.lineTo(line[1].x, line[1].y)
  renderer.closePath()
  renderer.strokePath(if isInside: "#ff7300" else: "#fee860", 3)

proc onLoad() {.exportc.} =

  var renderer = newRenderer2D("canvas")
  renderer.onMouseMotion =
    proc (event: MouseMotionEvent) =
      isInside = intersect(outline, Point[float](x: event.x.float, y: event.y.float))

  renderer.startLoop((t: float) => onTick(renderer, t))



when isMainModule and not defined(js):
  onLoad()
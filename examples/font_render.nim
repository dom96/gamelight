import sugar, os, options

import gamelight/[graphics, vec, geometry]

proc onTick(renderer: Renderer2D, elapsedTime: float) =
  renderer.fillRect(0, 0, 640, 480, "#6577ac")

  let pos = Point[int](x: 5, y: 5)
  let text = "Hello World"
  let font = "100px Helvetica"
  renderer.fillText(text, pos, "#70c860", font)
  let textBounds = getTextMetrics(renderer, text, font)
  renderer.strokeRect(pos.x, pos.y, textBounds.width, textBounds.height, "#ff0000")

proc onLoad() {.exportc.} =

  var renderer = newRenderer2D("canvas")

  renderer.startLoop((t: float) => onTick(renderer, t))

when isMainModule and not defined(js):
  onLoad()
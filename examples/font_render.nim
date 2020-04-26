import sugar, os, options

import gamelight/[graphics, vec, geometry]

proc drawText(renderer: Renderer2D, pos: Point, text: string, color: string, font: string, center=false) =
  renderer.fillText(text, pos, color, font, center)
  let textBounds = getTextMetrics(renderer, text, font)
  var pos = pos
  if center:
    pos.x -= textBounds.width div 2
    pos.y -= textBounds.height div 2
  renderer.strokeRect(pos.x, pos.y, textBounds.width, textBounds.height, "#ff0000")

proc onTick(renderer: Renderer2D, elapsedTime: float) =
  renderer.fillRect(0, 0, 640, 480, "#6577ac")

  drawText(renderer, vec2(5, 5), "Hello World", "#70c860","100px Helvetica")
  drawText(renderer, vec2(5, 150), "Transparency", "rgba(255, 255, 255, 0.5)", "50px Helvetica")
  drawText(renderer, vec2(400, 150), "Italics", "rgba(255, 255, 255, 0.5)", "Italic 50px Arial")
  drawText(renderer, vec2(5, 300), "...", "rgba(255, 255, 255, 1.0)", "100px Helvetica")
  drawText(renderer, vec2(100, 300), "!!", "rgba(255, 255, 255, 1.0)", "100px Helvetica")
  drawText(renderer, vec2(400, 300), "Centered", "rgba(255, 255, 255, 1.0)", "100px Helvetica", true)

proc onLoad() {.exportc.} =

  var renderer = newRenderer2D("canvas")

  renderer.startLoop((t: float) => onTick(renderer, t))

when isMainModule and not defined(js):
  onLoad()
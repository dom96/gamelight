import math

import sdl2 except Color
import chroma


proc checkError*(ret: ptr | SDL_Return | cint | bool, file: string = "") =
  if (when ret is ptr: ret.isNil elif ret is bool: not ret elif ret is cint: ret < 0 else: ret != SdlSuccess):
    let err = getError()
    let extraInfo =
      if file.len > 0: " (Could not read: " & file & ")"
      else: ""
    raise newException(Exception, "SDL2 failure: " & (if err.isNil: "nil" else: $err) & extraInfo)

proc getSize*(renderer: RendererPtr): tuple[width, height: int] =
  var w, h: cint
  checkError getRendererOutputSize(renderer, addr w, addr h)
  return (w.int, h.int)

proc setPixelColor*(renderer: RendererPtr, x, y: int, r, g, b, a: uint8) =
  # Alpha here is reversed. In SDL 255 means opaque, but we get 0 for that.
  checkError setDrawColor(renderer, r, g, b, 255'u8-a)
  checkError drawPoint(renderer, x.cint, y.cint)

proc drawThickLine*(renderer: RendererPtr, x0, y0, x1, y1: int, wd: int, color: Color) =
  # Based on http://members.chello.at/~easyfilter/bresenham.html
  # https://gist.github.com/w8r/2f57de439a736b0a079b70ed24c9a246 (plotLineWidth)

  let (r, g, b) = (color.rgba().r, color.rgba().g, color.rgba().b)


  let dx = abs(x1-x0)
  let sx = if x0 < x1: 1 else: -1
  let dy = abs(y1-y0)
  let sy = if y0 < y1: 1 else: -1

  var err = dx-dy
  var e2, x2, y2 = 0
  var x0 = x0
  var y0 = y0

  let ed = if dx+dy == 0: 1.0 else: sqrt(float(dx*dx+dy*dy))

  var wd = (wd+1) / 2
  while true: # Pixel loop
    setPixelColor(
      renderer, x0, y0,
      r, g, b,
      max(0.0, 255 * (abs(err-dx+dy).float / ed-wd+1)).uint8
    )

    e2 = err
    x2 = x0

    if 2*e2 >= -dx: # x step
      e2 += dy
      y2 = y0
      while e2.float < ed*wd and (y1 != y2 or dx > dy):
        y2 += sy
        setPixelColor(
          renderer,
          x0,
          y2,
          r, g, b,
          max(0.0, 255*(abs(e2).float / ed - wd + 1)).uint8
        )
        e2 += dx

      if x0 == x1:
        break
      e2 = err
      err -= dy
      x0 += sx

    if 2*e2 <= dy: # y step
      e2 = dx-e2
      while e2.float < ed*wd and (x1 != x2 or dx < dy):
        x2 += sx
        setPixelColor(
          renderer,
          x2,
          y0,
          r, g, b,
          max(0.0, 255*(abs(e2).float / ed - wd + 1)).uint8
        )

        e2 += dy

      if y0 == y1:
        break
      err += dx
      y0 += sy
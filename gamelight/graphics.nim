import future, colors
import dom, jsconsole
import canvasjs, vec

type
  Renderer2D* = ref object
    canvas: EmbedElement
    context: CanvasRenderingContext
    preferredWidth: int
    preferredHeight: int

proc getWidth(preferredWidth: int): int =
  if preferredWidth == -1:
    window.innerWidth
  else:
    preferredWidth

proc getHeight(preferredHeight: int): int =
  if preferredHeight == -1:
    window.innerHeight
  else:
    preferredHeight

proc resizeCanvas(renderer: Renderer2D) =
  renderer.canvas.width = getWidth(renderer.preferredWidth)

  renderer.canvas.height = getHeight(renderer.preferredHeight)

proc newRenderer2D*(id: string, width = -1, height = -1,
                    hidpi = false): Renderer2D =
  ## Creates a new 2D renderer on a canvas element with the specified
  ## ID. When the ``width`` and ``height`` parameters are set to
  ## ``-1`` the whole screen will be used.
  ##
  ## This proc assumes that the document has been loaded.
  ##
  ## The ``hidpi`` parameter determines whether to create a High
  ## DPI canvas.

  var canvas = document.getElementById(id).EmbedElement
  var context = canvas.getContext("2d")
  if hidpi:
    let ratio = getPixelRatio()
    canvas.width = int(getWidth(width).float * ratio)
    canvas.height = int(getHeight(height).float * ratio)
    canvas.style.width = $getWidth(width) & "px"
    canvas.style.height = $getHeight(height) & "px"
    context.setTransform(ratio, 0, 0, ratio, 0, 0)

  result = Renderer2D(
    canvas: canvas,
    context: context,
    preferredWidth: width,
    preferredHeight: height
  )

  var capturedResult = result
  window.addEventListener("resize",
    (ev: Event) => (resizeCanvas(capturedResult)))

  resizeCanvas(result)

proc strokeLine*(renderer: Renderer2D, start, finish: Point, width = 1,
    style = "#000000", shadowBlur = 0, shadowColor = "#000000") =
  renderer.context.beginPath()
  renderer.context.moveTo(start.x, start.y)
  renderer.context.lineTo(finish.x, finish.y)
  renderer.context.lineWidth = width
  renderer.context.strokeStyle = style
  renderer.context.shadowBlur = shadowBlur
  renderer.context.shadowColor = shadowColor
  renderer.context.stroke()

  renderer.context.shadowBlur = 0

proc strokeLines*(renderer: Renderer2D, points: seq[Point], width = 1,
    style = "#000000", shadowBlur = 0, shadowColor = "#000000") =
  if points.len == 0: return
  renderer.context.beginPath()

  renderer.context.moveTo(points[0].x, points[0].y)

  for i in 1 .. <points.len:
    renderer.context.lineTo(points[i].x, points[i].y)

  renderer.context.lineWidth = width
  renderer.context.strokeStyle = style
  renderer.context.shadowBlur = shadowBlur
  renderer.context.shadowColor = shadowColor
  renderer.context.stroke()

  renderer.context.shadowBlur = 0

proc fillRect*(renderer: Renderer2D, x, y, width, height: int | float,
    style = "#000000") =
  renderer.context.fillStyle = style
  renderer.context.fillRect(x, y, width, height)

proc strokeRect*(renderer: Renderer2D, x, y, width, height: int | float,
    style = "#000000", lineWidth = 1) =
  renderer.context.strokeStyle = style
  renderer.context.lineWidth = lineWidth
  renderer.context.strokeRect(x, y, width, height)

proc fillText*(renderer: Renderer2D, text: string, pos: Point,
    style = "#000000", font = "12px Helvetica") =
  renderer.context.fillStyle = style
  renderer.context.font = font
  renderer.context.fillText(text, pos.x, pos.y)

proc setTranslation*(renderer: Renderer2D, pos: Point) =
  renderer.context.setTransform(1, 0, 0, 1, pos.x, pos.y)

proc getWidth*(renderer: Renderer2D): int =
  renderer.canvas.width

proc getHeight*(renderer: Renderer2D): int =
  renderer.canvas.height

proc createTextElement*(renderer: Renderer2D, text: string, pos: Point,
                        style="#000000", font="12px Helvetica"): Element =
  ## This procedure allows you to draw crisp text on your canvas.
  ##
  ## Note that this creates a new DOM element which you should keep. If you
  ## need the text to move or its contents modified then use the `style`
  ## and `innerHTML` setters.
  let p = document.createElement("p")
  p.innerHTML = text
  p.style.position = "absolute"
  p.style.top = "0"
  p.style.margin = "0"
  p.style.marginLeft = $pos.x & "px"
  p.style.marginTop = $pos.y & "px"
  p.style.font = font
  p.style.color = style

  renderer.canvas.parentNode.insertBefore(p, renderer.canvas)
  return p

proc `[]=`*(renderer: Renderer2D, pos: (int, int) | (float, float),
            color: Color) =
  let image = renderer.context.createImageData(1, 1)
  let (r, g, b) = color.extractRGB()
  image.data[0] = r
  image.data[1] = g
  image.data[2] = b
  image.data[3] = 255

  renderer.context.putImageData(image, pos[0], pos[1])

proc `[]=`*(renderer: Renderer2D, pos: Point, color: Color) =
  renderer[(pos.x, pos.y)] = color
import future
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
    console.log(ratio, int(getWidth(width).float * ratio))
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

proc fillRect*(renderer: Renderer2D, x, y, width, height: int,
    style = "#000000") =
  renderer.context.fillStyle = style
  renderer.context.fillRect(x, y, width, height)

proc strokeRect*(renderer: Renderer2D, x, y, width, height: int,
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

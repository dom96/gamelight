import dom

type
  CanvasRenderingContext* = ref object
    fillStyle* {.importc.}: cstring
    strokeStyle* {.importc.}: cstring
    width* {.importc: "canvas.width".}: int
    height* {.importc: "canvas.height".}: int

    shadowColor* {.importc.}: cstring
    shadowBlur* {.importc.}: int

    lineWidth* {.importc.}: int

    font* {.importc.}: cstring
    textAlign* {.importc.}: cstring
    textBaseline* {.importc.}: cstring
    globalCompositeOperation* {.importc.}: cstring
    globalAlpha* {.importc.}: float

  ContextAttributes* = ref object
    alpha* {.importc.}: bool
    # TODO: WebGL

  ImageData* = ref object
    data*: seq[byte]
    width*, height*: int

  Image* = ref object
    src*: cstring
    height*: int
    width*: int
    onload*: proc ()
    complete*: bool

proc newImage*(): Image {.importcpp: "new Image()".}

proc getPixelRatio*(): float =
  # Based on: http://stackoverflow.com/a/15666143/492186
  {.emit: """
    var ctx = document.createElement("canvas").getContext("2d"),
        dpr = window.devicePixelRatio || 1,
        bsr = ctx.webkitBackingStorePixelRatio ||
                ctx.mozBackingStorePixelRatio ||
                ctx.msBackingStorePixelRatio ||
                ctx.oBackingStorePixelRatio ||
                ctx.backingStorePixelRatio || 1;

    `result` = dpr / bsr;
  """.}

{.push importcpp.}

proc getContext*(canvasElement: Element, contextType: cstring,
    contextAttributes = ContextAttributes(alpha: false)): CanvasRenderingContext

proc fillRect*[T: SomeNumber, Y: SomeNumber](context: CanvasRenderingContext,
    x, y: T, width, height: Y)

proc clearRect*(context: CanvasRenderingContext,
    x, y, width, height: SomeNumber)

proc strokeRect*[T: SomeNumber, Y: SomeNumber](context: CanvasRenderingContext,
    x, y: T, width, height: Y)

proc beginPath*(context: CanvasRenderingContext)
proc closePath*(context: CanvasRenderingContext)

proc moveTo*(context: CanvasRenderingContext, x, y: SomeNumber)

proc lineTo*(context: CanvasRenderingContext, x, y: SomeNumber)

proc stroke*(context: CanvasRenderingContext)

proc fill*(context: CanvasRenderingContext)

proc fillText*(context: CanvasRenderingContext, text: cstring, x, y: SomeNumber)

proc translate*(context: CanvasRenderingContext, x, y: SomeNumber)

proc rotate*(context: CanvasRenderingContext, angle: float)

proc scale*(context: CanvasRenderingContext, x, y: float)

proc setTransform*(context: CanvasRenderingContext, a, b, c, d, e, f: SomeNumber)

proc createImageData*(context: CanvasRenderingContext, width, height: SomeNumber): ImageData

proc putImageData*(context: CanvasRenderingContext, image: ImageData, dx, dy: SomeNumber)

proc save*(context: CanvasRenderingContext)

proc restore*(context: CanvasRenderingContext)

proc drawImage*(context: CanvasRenderingContext, img: Image | EmbedElement, dx, dy: SomeNumber)

proc drawImage*[T: SomeNumber, Y: SomeNumber](context: CanvasRenderingContext, img: Image | EmbedElement, dx, dy: T, dWidth, dHeight: Y)

proc arc*[T: SomeNumber, Y: SomeNumber](context: CanvasRenderingContext, x, y, radius: T, startAngle, endAngle: Y, anticlockwise=false)
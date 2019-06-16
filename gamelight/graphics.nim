import sugar, colors, math, tables, lenientops

const
  isCanvas = defined(js)

when isCanvas:
  import dom, jsconsole
  import canvasjs
else:
  import strutils, os
  import sdl2/[gfx, ttf]
  import sdl2 except Point
import vec

when isCanvas:
  type
    PositionedElement = ref object
      originalLeft, originalTop: float
      originalFontSize: float
      originalWidth, originalHeight: float
      element: Element

type
  EventKind* = enum
    KeyDown, MouseButtonDown, MouseButtonUp, MouseMotion

type
  Renderer2D* = ref object
    when isCanvas:
      canvas: EmbedElement
      context*: CanvasRenderingContext
      lastFrameUpdate: float
    else:
      window: WindowPtr
      renderer: RendererPtr
      events: array[EventKind, proc (evt: sdl2.Event)]
      scalingFactor, translationFactor: Point[float]
      savedFactors: seq[(Point[float], Point[float])]
      currentPath: seq[Point[int]]
      fontCache: Table[(string, cint), FontPtr]
      lastFrameUpdate: uint64
    preferredWidth: int
    preferredHeight: int
    rotation: float
    scaleToScreen: bool
    when isCanvas:
      positionedElements: seq[PositionedElement]
      images: Table[string, Image]

type
  ImageAlignment* = enum
    Center, TopLeft

proc adjustPos(width, height: int, pos: Point, align: ImageAlignment): Point =
  result = pos
  case align
  of Center:
    result = Point(
      x: result.x - (width / 2),
      y: result.y - (height / 2)
    )
  of TopLeft:
    discard

when isCanvas:
  export KeyboardEvent, MouseEvent, TouchEvent
  type
    MouseButtonEvent* = MouseEvent
    MouseMotionEvent* = MouseEvent

  const
    positionedElementCssClass = "gamelight-graphics-element"

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

  template getScalingFactors() =
    let screenWidth {.inject.} = window.innerWidth
    let screenHeight {.inject.} = window.innerHeight
    let ratioX = screenWidth / renderer.canvas.width
    let ratioY = screenHeight / renderer.canvas.height

    # We also grab the current zoom ratio. This is necessary when the user
    # zooms accidentally, or the OS zooms for them (when keyboard shows up on
    # iOS for example)
    # Ref: http://stackoverflow.com/a/11797565/492186
    let zoomRatio = document.body.clientWidth / window.innerWidth

    let minRatio {.inject.} = min(ratioX, ratioY)
    let scaledWidth {.inject.} = renderer.canvas.width.float * minRatio
    let scaledHeight {.inject.} = renderer.canvas.height.float * minRatio

    let left {.inject.} = (screenWidth.float - scaledWidth) / 2
    let top {.inject.} = (screenHeight.float - scaledHeight) / 2

  proc scale*[T](renderer: Renderer2D, pos: Point[T]): Point[T] =
    ## Scales the specified ``Point[T]`` by the scaling factor, if the
    ## ``scaleToScreen`` option is enabled, otherwise just returns ``pos``.
    ##
    ## Note: This does not convert the point into screen coordinates, it assumes
    ## the point will be used on the canvas. So (0, 0) is the top of the canvas.
    if renderer.scaleToScreen:
      getScalingFactors()

      return (T(pos.x.float * minRatio),
              T(pos.y.float * minRatio))
    else:
      return pos

  proc resizeCanvas(renderer: Renderer2D) =
    renderer.canvas.width = getWidth(renderer.preferredWidth)

    renderer.canvas.height = getHeight(renderer.preferredHeight)

    if renderer.scaleToScreen:
      console.log("Scaling to screen")
      getScalingFactors()

      renderer.canvas.style.width = $scaledWidth & "px"
      renderer.canvas.style.height = $scaledHeight & "px"
      renderer.canvas.style.marginLeft = $left & "px"
      renderer.canvas.style.marginTop = $top & "px"

      # Ensure the parent container has the correct styles.
      renderer.canvas.parentNode.style.position = "absolute"
      renderer.canvas.parentNode.style.left = "0"
      renderer.canvas.parentNode.style.top = "0"
      renderer.canvas.parentNode.style.width = $screenWidth & "px"
      renderer.canvas.parentNode.style.height = $screenHeight & "px"
      renderer.canvas.parentNode.Element.classList.add("fullscreen")

      # Go through each element and adjust its position.
      for item in renderer.positionedElements:
        let element = item.element
        element.style.marginLeft =
          $(item.originalLeft * minRatio + left) & "px"
        element.style.marginTop =
          $(item.originalTop * minRatio + top) & "px"

        if item.originalFontSize > 0.0:
          element.style.fontSize = $(item.originalFontSize * minRatio) & "px"
        if item.originalWidth > 0.0:
          element.style.width = $(item.originalWidth * minRatio) & "px"
        if item.originalHeight > 0.0:
          element.style.height = $(item.originalHeight * minRatio) & "px"

      window.scrollTo(0, 0)

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
      preferredHeight: height,
      scaleToScreen: false,
      positionedElements: @[],
      images: initTable[string, Image]()
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

  proc setTranslation*(renderer: Renderer2D, pos: Point, zoom=1.0) =
    renderer.context.setTransform(zoom, 0, 0, zoom, pos.x, pos.y)

  proc centerOn*(renderer: Renderer2D, pos: Point, zoom=1.0) =
    renderer.context.translate(-pos.x, -pos.y)
    renderer.context.scale(zoom, zoom)
    renderer.context.translate(
      renderer.canvas.width / 2,
      renderer.canvas.height / 2
    )

  proc getWidth*(renderer: Renderer2D): int =
    renderer.canvas.width

  proc getHeight*(renderer: Renderer2D): int =
    renderer.canvas.height

  proc setProperties(renderer: Renderer2D, element: Element, pos: Point,
                     width, height, fontSize: float) =
    element.style.position = "absolute"
    element.style.margin = "0"
    element.style.marginLeft = $pos.x & "px"
    element.style.marginTop = $pos.y & "px"
    element.style.fontSize = $fontSize & "px"
    if width >= 0.0:
      element.style.width = $width & "px"

    if height >= 0.0:
      element.style.height = $height & "px"

    element.classList.add(positionedElementCssClass)
    renderer.positionedElements.add(PositionedElement(
      originalLeft: pos.x,
      originalTop: pos.y,
      element: element,
      originalFontSize: fontSize,
      originalWidth: width,
      originalHeight: height
    ))
    resizeCanvas(renderer)

  proc createTextElement*(renderer: Renderer2D, text: string, pos: Point,
                          style="#000000", fontSize=12.0,
                          fontFamily="Helvetica", width = -1.0): Element =
    ## This procedure allows you to draw crisp text on your canvas.
    ##
    ## Note that this creates a new DOM element which you should keep. If you
    ## need the text to move or its contents modified then use the `style`
    ## and `innerHTML` setters.
    ##
    ## **Warning:** Movement will fail if the canvas is scaled via the
    ## ``scaleToScreen`` option.
    let p = document.createElement("p")
    p.innerHTML = text
    renderer.setProperties(p, pos, width, 0.0, fontSize)

    p.style.fontFamily = fontFamily
    p.style.color = style

    renderer.canvas.parentNode.insertBefore(p, renderer.canvas)
    return p

  proc createTextBox*(renderer: Renderer2D, pos: Point, width = -1.0,
                      height = -1.0, fontSize = 12.0): Element =
    let input = document.createElement("input")
    input.EmbedElement.`type` = "text"
    renderer.setProperties(input, pos, width, height, fontSize)

    renderer.canvas.parentNode.insertBefore(input, renderer.canvas)
    return input.OptionElement

  proc createButton*(renderer: Renderer2D, pos: Point, text: string,
                     width = -1.0, height = -1.0, fontSize = 12.0,
                     fontFamily = "Helvetica"): Element =
    let input = document.createElement("input")
    input.EmbedElement.`type` = "button"
    input.OptionElement.value = text
    renderer.setProperties(input, pos, width, height, fontSize)
    input.style.fontFamily = fontFamily

    renderer.canvas.parentNode.insertBefore(input, renderer.canvas)
    return input.OptionElement

  proc `[]=`*(renderer: Renderer2D, pos: (int, int) | (float, float),
              color: Color) =
    let image = renderer.context.createImageData(1, 1)
    let (r, g, b) = color.extractRGB()
    image.data[0] = r
    image.data[1] = g
    image.data[2] = b
    image.data[3] = 255

    renderer.context.putImageData(image, round(pos[0]), round(pos[1]))

  proc `[]=`*(renderer: Renderer2D, pos: Point, color: Color) =
    renderer[(pos.x, pos.y)] = color

  proc setRotation*(renderer: Renderer2D, rotation: float) =
    ## Sets the current renderer surface rotation to the specified radians value.
    renderer.context.rotate((PI - renderer.rotation) + rotation)
    renderer.rotation = rotation

  proc setScaleToScreen*(renderer: Renderer2D, value: bool) =
    ## When set to ``true`` this property will scale the renderer's canvas to
    ## fit the device's screen. Elements created using the procedures defined
    ## in this module will also be handled, every object will be resized by
    ## either the ratio of screen width to canvas width or screen height to
    ## canvas height, whichever one is smallest.
    renderer.scaleToScreen = value

    renderer.resizeCanvas()

  proc getScaleToScreen*(renderer: Renderer2D): bool =
    renderer.scaleToScreen

  proc drawImage*(
    renderer: Renderer2D, url: string, pos: Point, width, height: int,
    align: ImageAlignment = ImageAlignment.Center, degrees: float = 0
  ) =
    assert width != 0 and height != 0
    let pos = adjustPos(width, height, pos, align)
    renderer.context.save()
    renderer.context.translate(pos.x + width / 2, pos.y + height / 2)
    renderer.context.rotate(degToRad(degrees))
    renderer.context.translate(-pos.x - width / 2, -pos.y - height / 2)
    if url in renderer.images:
      let img = renderer.images[url]
      renderer.context.drawImage(img, pos.x, pos.y, width, height)
    else:
      let img = newImage()
      img.src = url
      img.onload =
        proc () =
          renderer.context.drawImage(img, pos.x, pos.y, width, height)
      renderer.images[url] = img

    renderer.context.restore()

  proc fillCircle*(
    renderer: Renderer2D, pos: Point, radius: int | float, style = "#000000"
  ) =
    renderer.context.beginPath()
    renderer.context.arc(pos.x, pos.y, radius, 0, 2 * math.PI)
    renderer.context.fillStyle = style
    renderer.context.fill()

  proc onFrame(renderer: Renderer2D, frameTime: float, onTick: proc (elapsedTime: float)) =
    let r = window.requestAnimationFrame((time: float) => onFrame(renderer, time, onTick))
    let elapsedTime = frameTime - renderer.lastFrameUpdate
    renderer.lastFrameUpdate = frameTime
    onTick(elapsedTime)

  proc startLoop*(renderer: Renderer2D, onTick: proc (elapsedTime: float)) =
    onFrame(renderer, 0, onTick)

  proc preventDefault*(ev: TouchEvent | MouseEvent | KeyboardEvent) =
    dom.preventDefault(ev)

  proc `onKeyDown=`*(renderer: Renderer2D, onKeyDown: proc (event: KeyboardEvent)) =
    window.addEventListener("keydown", (ev: Event) => onKeyDown(ev.KeyboardEvent))

  proc `onMouseButtonDown=`*(renderer: Renderer2D, onMouseButtonDown: proc (event: MouseButtonEvent)) =
    window.addEventListener("mousedown", (ev: Event) => onMouseButtonDown(ev.MouseButtonEvent))

  proc `onMouseButtonUp=`*(renderer: Renderer2D, onMouseButtonUp: proc (event: MouseButtonEvent)) =
    window.addEventListener("mouseup", (ev: Event) => onMouseButtonUp(ev.MouseButtonEvent))

  proc `onMouseMotion=`*(renderer: Renderer2D, onMouseMotion: proc (event: MouseMotionEvent)) =
    window.addEventListener("mousemove", (ev: Event) => onMouseMotion(ev.MouseMotionEvent))

  proc moveTo*(renderer: Renderer2D, x, y: float) =
    renderer.context.moveTo(x, y)

  proc lineTo*(renderer: Renderer2D, x, y: float) =
    renderer.context.lineTo(x, y)

  proc beginPath*(renderer: Renderer2D) =
    renderer.context.beginPath()

  proc closePath*(renderer: Renderer2D) =
    renderer.context.closePath()

  proc fillPath*(renderer: Renderer2D, style: string) =
    renderer.context.fillStyle = style
    renderer.context.fill()

  proc strokePath*(renderer: Renderer2D, style: string, lineWidth: int) =
    renderer.context.strokeStyle = style
    renderer.context.lineWidth = lineWidth
    renderer.context.stroke()

  proc scale*(renderer: Renderer2D, x, y: float) =
    renderer.context.scale(x, y)

  proc translate*(renderer: Renderer2D, x, y: float) =
    renderer.context.translate(x, y)

  proc save*(renderer: Renderer2D) =
    renderer.context.save()

  proc restore*(renderer: Renderer2D) =
    renderer.context.restore()
else:
  # SDL2
  export KeyboardEventObj, MouseButtonEventObj, MouseMotionEventObj

  proc checkError(ret: ptr | SDL_Return | cint) =
    if (when ret is ptr: ret.isNil elif ret is cint: ret < 0 else: ret != SdlSuccess):
      raise newException(Exception, "SDL2 failure: " & $getError())

  checkError sdl2.init(INIT_EVERYTHING)
  checkError ttfInit()
  proc newRenderer2D*(id: string, width = 640, height = 480,
                      hidpi = false): Renderer2D =

    var window: WindowPtr
    var renderer: RendererPtr
    checkError createWindowAndRenderer(
      width.cint, height.cint, SDL_WINDOW_SHOWN, window, renderer
    )

    result = Renderer2D(
      window: window,
      renderer: renderer,
      preferredWidth: width,
      preferredHeight: height,
      scaleToScreen: false,
      lastFrameUpdate: 0,
      scalingFactor: Point[float](x: 1.0, y: 1.0)
    )

    for ev in EventKind:
      result.events[ev] = nil

    # var capturedResult = result
    # window.addEventListener("resize",
    #   (ev: Event) => (resizeCanvas(capturedResult)))

    # resizeCanvas(result)=

  proc startLoop*(renderer: Renderer2D, onTick: proc (elapsedTime: float)) =
    var
      event = sdl2.defaultEvent
      fpsman: FpsManager
    fpsman.init()

    block eventLoop:
      while true:
        while pollEvent(event):
          case event.kind
          of QuitEvent:
            break eventLoop
          of EventType.KeyDown:
            if not renderer.events[EventKind.KeyDown].isNil:
              renderer.events[EventKind.KeyDown](event)
          of EventType.MouseButtonDown:
            if not renderer.events[EventKind.MouseButtonDown].isNil:
              renderer.events[EventKind.MouseButtonDown](event)
          of EventType.MouseMotion:
            if not renderer.events[EventKind.MouseMotion].isNil:
              renderer.events[EventKind.MouseMotion](event)
          else: discard

        let frameTime = getPerformanceCounter()
        let elapsedTime = ((frameTime - renderer.lastFrameUpdate)*1000) / getPerformanceFrequency().float
        renderer.lastFrameUpdate = frameTime

        checkError renderer.renderer.setDrawColor(0,0,0,255)
        checkError renderer.renderer.clear()

        onTick(elapsedTime.float)

        renderer.renderer.present()
        fpsman.delay

    destroy renderer.renderer
    destroy renderer.window

  type
    KeyboardEvent* = KeyboardEventObj
    MouseButtonEvent* = MouseButtonEventObj
    MouseMotionEvent* = MouseMotionEventObj

  proc keyCode*(event: KeyboardEvent): int =
    event.keysym.sym.int

  proc preventDefault*(event: KeyboardEvent | MouseButtonEvent | MouseMotionEvent) = discard

  proc clientX*(event: MouseButtonEvent | MouseMotionEvent): int =
    event.x.int

  proc clientY*(event: MouseButtonEvent | MouseMotionEvent): int =
    event.y.int

  proc `onKeyDown=`*(renderer: Renderer2D, onKeyDown: proc (event: KeyboardEventObj)) =
    renderer.events[EventKind.KeyDown] =
      proc (event: sdl2.Event) =
        let ev = cast[sdl2.KeyboardEventObj](event)
        onKeyDown(ev)

  proc `onMouseButtonDown=`*(renderer: Renderer2D, onMouseButtonDown: proc (event: MouseButtonEventObj)) =
    renderer.events[EventKind.MouseButtonDown] =
      proc (event: sdl2.Event) =
        let ev = cast[sdl2.MouseButtonEventObj](event)
        onMouseButtonDown(ev)

  proc `onMouseButtonUp=`*(renderer: Renderer2D, onMouseButtonUp: proc (event: MouseButtonEventObj)) =
    renderer.events[EventKind.MouseButtonUp] =
      proc (event: sdl2.Event) =
        let ev = cast[sdl2.MouseButtonEventObj](event)
        onMouseButtonUp(ev)

  proc `onMouseMotion=`*(renderer: Renderer2D, onMouseMotion: proc (event: MouseMotionEventObj)) =
    renderer.events[EventKind.MouseMotion] =
      proc (event: sdl2.Event) =
        let ev = cast[sdl2.MouseMotionEventObj](event)
        onMouseMotion(ev)

  # Drawing utils

  proc applyTranslation(renderer: Renderer2D, x, y: int | float): (cint, cint) =
    return (
      cint(x + renderer.translationFactor.x),
      cint(y + renderer.translationFactor.y)
    )

  proc applyTranslation(renderer: Renderer2D, pos: Point[int] | Point[float]): Point[int] =
    return Point[int](
      x: pos.x.int + renderer.translationFactor.x.int,
      y: pos.y.int + renderer.translationFactor.y.int
    )

  # Drawing

  proc fillRect*(renderer: Renderer2D, x, y, width, height: int | float,
      style = "#000000") =
    let color = parseColor(style).extractRGB()
    checkError renderer.renderer.setDrawColor(color.r.uint8, color.g.uint8, color.b.uint8)
    let (x, y) = applyTranslation(renderer, x, y)
    var rect = (x, y, width.cint, height.cint)
    checkError renderer.renderer.fillRect(addr rect)

  proc strokeRect*(renderer: Renderer2D, x, y, width, height: int | float,
      style = "#000000", lineWidth = 1) =
    let color = parseColor(style).extractRGB()
    let (x, y) = applyTranslation(renderer, x, y)
    var rect = (x.cint, y.cint, width.cint, height.cint)
    # TODO: Line width
    checkError renderer.renderer.setDrawColor(color.r.uint8, color.g.uint8, color.b.uint8)
    checkError renderer.renderer.drawRect(addr rect)

  proc fillCircle*(
    renderer: Renderer2D, pos: Point, radius: int | float, style = "#000000"
  ) =
    let color = parseColor(style).extractRGB()

    let pos = applyTranslation(renderer, pos)
    checkError renderer.renderer.filledCircleRGBA(
      pos.x.int16,
      pos.y.int16,
      radius.int16,
      color.r.uint8,
      color.g.uint8,
      color.b.uint8,
      255
    )

  proc drawImage*(
    renderer: Renderer2D, url: string, pos: Point, width, height: int,
    align: ImageAlignment = ImageAlignment.Center, degrees: float = 0
  ) =
    assert width != 0 and height != 0
    discard # TODO

  proc loadFont(renderer: Renderer2D, font: string): FontPtr =
    let s = font.split(" ")
    assert s[0].endsWith("px")

    let size = parseInt(s[0][0 .. ^3]).cint
    let name = s[1].replace(" ", "_") & ".ttf"

    let key = (name, size)
    if key notin renderer.fontCache:
      renderer.fontCache[key] = openFont(getCurrentDir() / "fonts" / name, size)

    result = renderer.fontCache[key]
    checkError(result)

  proc fillText*(renderer: Renderer2D, text: string, pos: Point,
      style = "#000000", font = "12px Helvetica") =
    let color = parseColor(style).extractRGB()
    let font = renderer.loadFont(font)
    let sdlColor = sdl2.color(color.r, color.g, color.b, 0)

    let textSurface = renderTextSolid(font, text, sdlColor)
    checkError textSurface
    let texture = createTextureFromSurface(renderer.renderer, textSurface)
    let width = textSurface.w
    let height = textSurface.h
    freeSurface(textSurface)

    let pos = applyTranslation(renderer, pos)
    var destRect = sdl2.rect(pos.x.cint, pos.y.cint, width, height)
    # echo("Render: ", destRect, " ", text)
    checkError sdl2.copy(renderer.renderer, texture, nil, addr destRect)

  # Path drawing
  proc lineTo*(renderer: Renderer2D, x, y: float) =
    renderer.currentPath.add(Point[int](x: x.int, y: y.int))

  proc moveTo*(renderer: Renderer2D, x, y: float) =
    assert renderer.currentPath.len == 0
    renderer.lineTo(x, y)

  proc beginPath*(renderer: Renderer2D) =
    renderer.currentPath = @[]

  proc closePath*(renderer: Renderer2D) =
    discard

  proc fillPath*(renderer: Renderer2D, style: string) =
    discard # TODO;

  proc strokePath*(renderer: Renderer2D, style: string, lineWidth: int) =
    let color = parseColor(style).extractRGB()

    for i in 0 ..< renderer.currentPath.len:
      let next =
        if i == renderer.currentPath.len-1: 0
        else: i+1
      let first = applyTranslation(renderer, renderer.currentPath[i])
      let second = applyTranslation(renderer, renderer.currentPath[next])
      renderer.renderer.thickLineRGBA(
        first.x.int16,
        first.y.int16,
        second.x.int16,
        second.y.int16,
        lineWidth.uint8,
        color.r.uint8,
        color.g.uint8,
        color.b.uint8,
        255
      )

  # Viewport functions
  proc scale*(renderer: Renderer2D, x, y: float) =
    renderer.scalingFactor = vec.Point[float](x: x, y: y)
    renderer.renderer.setScale(x, y)

  proc translate*(renderer: Renderer2D, x, y: float) =
    renderer.translationFactor = vec.Point[float](x: x, y: y)

  proc save*(renderer: Renderer2D) =
    renderer.savedFactors.add((renderer.scalingFactor, renderer.translationFactor))

  proc restore*(renderer: Renderer2D) =
    let (scalingFactor, translationFactor) =
      if renderer.savedFactors.len > 0: renderer.savedFactors.pop()
      else: (Point[float](x: 1, y: 1), Point[float](x: 0, y: 1))
    renderer.scalingFactor = scalingFactor
    renderer.renderer.setScale(renderer.scalingFactor.x, renderer.scalingFactor.y)
    renderer.translationFactor = translationFactor

  # Accessors
  proc getWidth*(renderer: Renderer2D): int =
    renderer.preferredWidth

  proc getHeight*(renderer: Renderer2D): int =
    renderer.preferredHeight
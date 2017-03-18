import math
type
  Point* = object
    x*, y*: int

converter toPoint*(point: (int, int)): Point =
  Point(x: point[0], y: point[1])

proc `+`*(point: Point, point2: Point): Point =
  (point.x + point2.x, point.y + point2.y)

proc `-`*(point: Point, point2: Point): Point =
  (point.x - point2.x, point.y - point2.y)

proc `-`*(point: Point): Point =
  (-point.x, -point.y)

proc `/`*(point: Point, scalar: int): Point =
  (int(point.x / scalar), int(point.y / scalar))

proc `*`*(point: Point, scalar: int): Point =
  (int(point.x * scalar), int(point.y * scalar))

proc add*(point: var Point, value: Point) =
  point.x += value.x
  point.y += value.y

proc copy*(point: Point): Point =
  return Point(x: point.x, y: point.y)

proc distanceSquared*(point, point2: Point): int =
  return (point2.x - point.x)^2 + (point2.y - point.y)^2

proc isOrigin*(point: Point): bool =
  return point.x == 0 and point.y == 0

proc rotate*(point: Point, radians: float): Point =
  let ca = cos(radians)
  let sa = sin(radians)
  return Point(x: int(ca*point.x.float - sa*point.y.float),
      y: int(sa*point.x.float + ca*point.y.float))

proc midpoint*(point, point2: Point): Point =
  return ((point.x + point2.x) div 2, (point.y + point2.y) div 2)
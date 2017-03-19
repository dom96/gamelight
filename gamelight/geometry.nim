import math
import vec

type
  Direction* = enum
    dirNorth, dirEast, dirSouth, dirWest

  LineSegment*[T] = tuple[start, finish: Point[T]]
  Rect*[T] = tuple[left, top, width, height: T]

converter toLineSegment*(x: tuple[start, finish: (int, int)]): LineSegment[int] =
  return (x.start.toPoint, x.finish.toPoint)

converter toLineSegment*(x: tuple[start: (int, int),
                                  finish: Point[int]]): LineSegment[int] =
  return (x.start.toPoint, x.finish)

proc intersect*(line1, line2: LineSegment, point: var Point,
    epsilon = 0.001): bool =
  ## Based on algorithm described by Paul Bourke.
  ## http://paulbourke.net/geometry/pointlineplane/

  let (x1, y1) = (line1.start.x, line1.start.y)
  let (x2, y2) = (line1.finish.x, line1.finish.y)
  let (x3, y3) = (line2.start.x, line2.start.y)
  let (x4, y4) = (line2.finish.x, line2.finish.y)

  let denom  = (y4-y3) * (x2-x1) - (x4-x3) * (y2-y1)
  let numera = (x4-x3) * (y1-y3) - (y4-y3) * (x1-x3)
  let numerb = (x2-x1) * (y1-y3) - (y2-y1) * (x1-x3)

  if denom == 0:
    return false

  # Is the intersection along the segments?
  let mua = numera / denom
  let mub = numerb / denom

  if mua >= 0 and mua <= 1 and mub >= 0 and mub <= 1:
    point.x = int(x1.float + (mua * float(x2 - x1)))
    point.y = int(y1.float + (mua * float(y2 - y1)))
    return true

proc intersect*[T](line1, line2: LineSegment[T], epsilon = 0.001): bool =
  var foo: Point[T]
  return intersect(line1, line2, foo, epsilon)

proc intersect*(rect: Rect, p: Point): bool =
  return p.x >= rect.left and p.x <= (rect.left + rect.width) and
      p.y >= rect.top and p.y <= (rect.top + rect.height)

proc intersect*(rect: Rect, line: LineSegment): bool =
  # Check if line is inside rectangle.
  if rect.intersect(line.start) or rect.intersect(line.finish):
    return true

  # Check if `line` intersects any of the lines of the rectangle.
  let topLeft = (rect.left, rect.top)
  let top = (topLeft, topLeft + (rect.width, 0))
  let left = (topLeft, topLeft + (0, rect.height))
  let bottom = (left[1], top[1] + (0, rect.height))
  let right = (top[1], bottom[1])
  return top.intersect(line) or left.intersect(line) or
      bottom.intersect(line) or right.intersect(line)

proc distanceSquared*(line: LineSegment, point: Point): int =
  # http://stackoverflow.com/a/1501725/492186
  proc dist2(v, w: Point): int = ((v.x - w.x) ^ 2) + ((v.y - w.y) ^ 2)

  let lsq = dist2(line.start, line.finish)
  if lsq == 0: return dist2(point, line.start)

  var t = ((point.x - line.start.x) * (line.finish.x - line.start.x) +
      (point.y - line.start.y) * (line.finish.y - line.start.y)) / lsq
  t = max(0, min(1, t))

  let x = int(line.start.x.float + t * float(line.finish.x - line.start.x))
  let y = int(line.start.y.float + t * float(line.finish.y - line.start.y))
  return dist2(point, (x, y))

proc distance*(line: LineSegment, point: Point): float =
  return sqrt(distanceSquared(line, point).float)

proc intersect*(line: LineSegment, point: Point): bool =
  return distanceSquared(line, point) == 0

proc nearestEdge*(line: LineSegment, point: Point): Point =
  ## Returns `line.start` if it's nearest to `point`, `line.finish` otherwise.
  let start = distanceSquared(line.start, point)
  let finish = distanceSquared(line.finish, point)
  if start < finish:
    return line.start
  else:
    return line.finish

proc `+`*(line: LineSegment, point: Point): LineSegment =
  (start: line.start + point, finish: line.finish + point)

proc `-`*(line: LineSegment, point: Point): LineSegment =
  line + (-point)

proc parallelWith*(line: LineSegment, direction: Direction): bool =
  if line.start.x == line.finish.x:
    return direction in {dirNorth, dirSouth}
  if line.start.y == line.finish.y:
    return direction in {dirEast, dirWest}

  assert false, "We only support lines which are parallel to the x or y-axis."

proc toPoint*[T](direction: Direction): Point[T] =
  case direction
  of dirNorth: Point[T]((0.T, -1.T))
  of dirEast: Point[T]((1.T, 0.T))
  of dirSouth: Point[T]((0.T, 1.T))
  of dirWest: Point[T]((-1.T, 0.T))

when isMainModule:
  # Test cases shamelessly stolen from https://martin-thoma.com/how-to-check-if-two-line-segments-intersect/

  block:
    let a = ((0, 0), (7, 7))
    let b = ((3, 4), (4, 5))
    assert(not intersect(a, b))

  block:
    let a = ((-4, 4), (-2, 1))
    let b = ((-2, 3), (0, 0))
    assert(not intersect(a, b))

  block:
    let a = ((0, -2), (0, 2))
    let b = ((-2, 0), (2, 0))
    assert(intersect(a, b))

  block:
    let a = ((5, 5), (0, 0))
    let b = ((1, 1), (8, 2))
    assert(intersect(a, b))

  # TODO: Tests to ensure that correct intersection point is returned.

  # Rectangle intersections
  block:
    let a = (left: 0, top: 0, width: 100, height: 50)
    assert(intersect(a, (50, 25)))
    assert(not intersect(a, (101, 25)))

  # Rectangle x line segment intersections
  block:
    let a = (left: 0, top: 0, width: 100, height: 50)
    assert(intersect(a, ((-5, 25), (125, 25))))
    assert(not intersect(a, ((125, 25), (160, 25))))

  # Test cases found "in the wild".
  block:
    let line1 = ((x: 960, y: 200), (x: 960, y: 270))
    let line2 = ((x: 960, y: 368), (x: 960, y: 388))
    assert(not intersect(line1, line2))

  # Distance test cases
  block:
    let line = ((0, 0), (100, 0))
    assert(distanceSquared(line, (50, 25)) == 25^2)

  # ParallelWith test cases
  block:
    let line1 = ((0, 0), (100, 0))
    assert(line1.parallelWith(dirEast))
    assert(line1.parallelWith(dirWest))
    assert(not line1.parallelWith(dirNorth))
    assert(not line1.parallelWith(dirSouth))
    let line2 = ((0, 0), (0, 100))
    assert(not line2.parallelWith(dirEast))
    assert(not line2.parallelWith(dirWest))
    assert(line2.parallelWith(dirNorth))
    assert(line2.parallelWith(dirSouth))

  echo("Tests passed!")
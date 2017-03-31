proc isTouchDevice*(): bool =
  ## Determines whether the current device is _primarily_ a touch device.

  # Based on: http://stackoverflow.com/a/4819886/492186
  {.emit: """
    `result` = 'ontouchstart' in window || navigator.maxTouchPoints;
  """.}
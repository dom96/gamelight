proc isTouchDevice*(): bool =
  ## Determines whether the current device is _primarily_ a touch device.

  # Based on: http://stackoverflow.com/a/4819886/492186
  {.emit: """
    `result` = 'ontouchstart' in window || navigator.maxTouchPoints;
  """.}

when defined(ios):
  # TODO: Hack below to make sure header is included.
  type
    NSString {.header: "<UIKit/UIKit.h>", importc.} = object
  proc getResourcePathIOS*(resource: cstring, fileType: cstring): cstring =
    var temp: ptr NSString
    {.emit: """
      `temp` = [[NSBundle mainBundle] pathForResource:[NSString stringWithUTF8String:`resource`] ofType:[NSString stringWithUTF8String:`fileType`]];
      result = `temp`.UTF8String;
    """.}

  proc getResourcePathIOS*(): cstring =
    var temp: ptr NSString
    {.emit: """
      `temp` = [NSBundle mainBundle].resourcePath;
      result = `temp`.UTF8String;
    """.}
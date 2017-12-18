/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa

private var colorCache = [Int: NSColor]()

class ColorUtils {

  static func colorIgnoringAlpha(_ rgb: Int) -> NSColor {
    if let color = colorCache[rgb] {
      return color
    }

    let red =   (CGFloat((rgb >> 16) & 0xFF)) / 255.0;
    let green = (CGFloat((rgb >>  8) & 0xFF)) / 255.0;
    let blue =  (CGFloat((rgb      ) & 0xFF)) / 255.0;

    let color = NSColor(srgbRed: red, green: green, blue: blue, alpha: 1.0)
    colorCache[rgb] = color

    return color
  }
}

import CoreGraphics
import Foundation

enum WindowFrames {
    static func current() -> [Int: CGRect] {
        guard let windows = CGWindowListCopyWindowInfo(
            [.optionAll, .excludeDesktopElements], kCGNullWindowID
        ) as? [[String: Any]] else { return [:] }

        var frames: [Int: CGRect] = [:]
        for window in windows {
            guard let id = window[kCGWindowNumber as String] as? Int,
                  let bounds = window[kCGWindowBounds as String] as? [String: Any],
                  let x = bounds["X"] as? NSNumber,
                  let y = bounds["Y"] as? NSNumber,
                  let width = bounds["Width"] as? NSNumber,
                  let height = bounds["Height"] as? NSNumber else { continue }
            frames[id] = CGRect(x: x.doubleValue, y: y.doubleValue,
                                width: width.doubleValue, height: height.doubleValue)
        }
        return frames
    }
}

import Foundation

extension NSObject {
    static func simpleClassName() -> String {
        NSStringFromClass(self).components(separatedBy: ".").last ?? ""
    }
}

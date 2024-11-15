import Foundation

internal extension String {
    func fromBase64URL() -> String? {
        var base64 = self
        base64 = base64.replacingOccurrences(of: "-", with: "+")
        base64 = base64.replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64 = base64.appending("=")
        }
        guard let data = Data(base64Encoded: base64) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func toBase64URL() -> String {
        var result = Data(utf8).base64EncodedString()
        result = result.replacingOccurrences(of: "+", with: "-")
        result = result.replacingOccurrences(of: "/", with: "_")
        result = result.replacingOccurrences(of: "=", with: "")
        return result
    }
    
    func padStart(toLength: Int, padString: String = " ") -> String {
        var stringLength = count
        if stringLength < toLength {
            var newString = ""
            while toLength != stringLength {
                if toLength - stringLength >= padString.count {
                    newString.append(padString)
                    stringLength += padString.count
                } else {
                    newString.append(String(padString.prefix(toLength - stringLength)))
                    break
                }
            }
            return newString + self
        } else {
            return self
        }
    }
}

//
//  String.swift
//  friendly-mail
//
//  Created by Philip Loden on 8/20/21.
//

import Foundation

extension String {
    
    /// Returns a new string made by removing in the `String` all "soft line
    /// breaks" and replacing all quoted-printable escape sequences with the
    /// matching characters as determined by a given encoding.
    /// - parameter encoding:     A string encoding. The default is UTF-8.
    /// - returns:                The decoded string, or `nil` for invalid input.
    
    func decodeQuotedPrintable(encoding enc : String.Encoding = .utf8) -> String? {
        
        // Handle soft line breaks, then replace quoted-printable escape sequences.
        return self
            .replacingOccurrences(of: "=\r\n", with: "")
            .replacingOccurrences(of: "=\n", with: "")
            .decodeQuotedPrintableSequences(encoding: enc)
    }
    
    /// Helper function doing the real work.
    /// Decode all "=HH" sequences with respect to the given encoding.
    
    private func decodeQuotedPrintableSequences(encoding enc : String.Encoding) -> String? {
        
        var result = ""
        var position = startIndex
        
        // Find the next "=" and copy characters preceding it to the result:
        while let range = range(of: "=", range: position..<endIndex) {
            result.append(contentsOf: self[position ..< range.lowerBound])
            position = range.lowerBound
            
            // Decode one or more successive "=HH" sequences to a byte array:
            var bytes = Data()
            repeat {
                let hexCode = self[position...].dropFirst().prefix(2)
                if hexCode.count < 2 {
                    return nil // Incomplete hex code
                }
                guard let byte = UInt8(hexCode, radix: 16) else {
                    return nil // Invalid hex code
                }
                bytes.append(byte)
                position = index(position, offsetBy: 3)
            } while position != endIndex && self[position] == "="
            
            // Convert the byte array to a string, and append it to the result:
            guard let dec = String(data: bytes, encoding: enc) else {
                return nil // Decoded bytes not valid in the given encoding
            }
            result.append(contentsOf: dec)
        }
        
        // Copy remaining characters to the result:
        result.append(contentsOf: self[position ..< endIndex])
        
        return result
    }
}

// https://stackoverflow.com/questions/25471114/how-to-validate-an-e-mail-address-in-swift?page=1&tab=votes#tab-top
extension String {
    func isValidEmail() -> Bool {
        // here, `try!` will always succeed because the pattern is valid
        let regex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$", options: .caseInsensitive)
        return regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: count)) != nil
    }
}

// =====================================================================================================================
//
//  File:       ASCII.swift
//  Project:    SwifterJSON
//
//  Version:    0.9.1
//
//  Author:     Marinus van der Lugt
//  Website:    http://www.balancingrock.nl/swifterjson
//  Blog:       http://swiftrien.blogspot.com
//  Git:        https://github.com/Swiftrien/SwifterJSON
//
//  Copyright:  (c) 2014-2016 Marinus van der Lugt, All rights reserved.
//
//  License:    Use or redistribute this code any way you like with the following two provision:
//
//  1) You ACCEPT this source code AS IS without any guarantees that it will work as intended. Any liability from its
//  use is YOURS.
//
//  2) You WILL NOT seek damages from the author or balancingrock.nl.
//
//  I also ask you to please leave this header with the source code.
//
//  I strongly believe that NAP is the way for societies to function optimally. I thus reject the implicit use of force
//  to extract payment. Since I cannot negotiate with you about the price of this code, I have choosen to leave it up to
//  you to determine its price. You pay me whatever you think this code is worth to you.
//
//   - You can send payment via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  I prefer the above two, but if these options don't suit you, you might also send me a gift from my amazon.co.uk
//  whishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
//
//  If you like to pay in another way, please contact me at rien@balancingrock.nl
//
//  (It is always a good idea to visit the website/blog/google to ensure that you actually pay me and not some imposter)
//
//  For private and non-profit use the suggested price is the price of 1 good cup of coffee, say $4.
//  For commercial use the suggested price is the price of 1 good meal, say $20.
//
//  You are however encouraged to pay more ;-)
//
//  Prices/Quotes for support, modifications or enhancements can be obtained from: rien@balancingrock.nl
//
// =====================================================================================================================
//
// History
//
// v0.9.1 - Added hexLookup
//        - Changed 'is___' functions to var's
// v0.9.0 Initial release
// =====================================================================================================================

import Foundation


typealias ASCII = UInt8


// Control Characters

let ASCII_NUL: ASCII = 0x00
let ASCII_SOH: ASCII = 0x01
let ASCII_STX: ASCII = 0x02
let ASCII_ETX: ASCII = 0x03
let ASCII_EOT: ASCII = 0x04
let ASCII_ENQ: ASCII = 0x05
let ASCII_ACK: ASCII = 0x06
let ASCII_BEL: ASCII = 0x07
let ASCII_BS:  ASCII = 0x08; let ASCII_BACKSPACE = ASCII_BS
let ASCII_TAB: ASCII = 0x09
let ASCII_LF:  ASCII = 0x0A; let ASCII_LINEFEED = ASCII_LF; let ASCII_NEWLINE = ASCII_LF
let ASCII_VT:  ASCII = 0x0B
let ASCII_FF:  ASCII = 0x0C; let ASCII_FORMFEED = ASCII_FF
let ASCII_CR:  ASCII = 0x0D; let ASCII_CARRIAGE_RETURN = ASCII_CR; let ASCII_RETURN = ASCII_CR
let ASCII_SO:  ASCII = 0x0E
let ASCII_SI:  ASCII = 0x0F

let ASCII_DLE: ASCII = 0x10
let ASCII_DC1: ASCII = 0x11
let ASCII_DC2: ASCII = 0x12
let ASCII_DC3: ASCII = 0x13
let ASCII_DC4: ASCII = 0x14
let ASCII_NAK: ASCII = 0x15
let ASCII_SYN: ASCII = 0x16
let ASCII_ETB: ASCII = 0x17
let ASCII_CAN: ASCII = 0x18
let ASCII_EM:  ASCII = 0x19
let ASCII_SUB: ASCII = 0x1A
let ASCII_ESC: ASCII = 0x1B
let ASCII_FS:  ASCII = 0x1C
let ASCII_GS:  ASCII = 0x1D
let ASCII_RS:  ASCII = 0x1E
let ASCII_US:  ASCII = 0x1F


// Printable characters

let ASCII_SPACE: ASCII                = 0x20; let ASCII_BLANK = ASCII_SPACE
let ASCII_EXCLAMATION_MARK: ASCII     = 0x21
let ASCII_DOUBLE_QUOTES: ASCII        = 0x22
let ASCII_NUMBER: ASCII               = 0x23; let ASCII_HASH = ASCII_NUMBER
let ASCII_DOLLAR: ASCII               = 0x24
let ASCII_PERCENT_SIGN: ASCII         = 0x25
let ASCII_AMPERSAND: ASCII            = 0x26
let ASCII_SINGLE_QUOTE: ASCII         = 0x27
let ASCII_ROUND_BRACKET_OPEN: ASCII   = 0x28; let ASCII_PARENTHESES_OPEN = ASCII_ROUND_BRACKET_OPEN; let ASCII_FUNCTION_BRACKET_OPEN = ASCII_ROUND_BRACKET_OPEN
let ASCII_ROUND_BRACKET_CLOSE: ASCII  = 0x29; let ASCII_PARENTHESES_CLOSE = ASCII_ROUND_BRACKET_CLOSE; let ASCII_FUNCTION_BRACKET_CLOSE = ASCII_ROUND_BRACKET_CLOSE
let ASCII_ASTERISK: ASCII             = 0x2A
let ASCII_PLUS: ASCII                 = 0x2B
let ASCII_COMMA: ASCII                = 0x2C
let ASCII_HYPHEN: ASCII               = 0x2D; let ASCII_MINUS = ASCII_HYPHEN; let ASCII_DASH = ASCII_HYPHEN
let ASCII_PERIOD: ASCII               = 0x2E; let ASCII_DOT = ASCII_PERIOD; let ASCII_POINT = ASCII_PERIOD
let ASCII_SLASH: ASCII                = 0x2F; let ASCII_SOLIDUS = ASCII_SLASH; let ASCII_FOREWARD_SLASH = ASCII_SLASH; let ASCII_SLASH_FOREWARD = ASCII_SLASH

let ASCII_0: ASCII                    = 0x30
let ASCII_1: ASCII                    = 0x31
let ASCII_2: ASCII                    = 0x32
let ASCII_3: ASCII                    = 0x33
let ASCII_4: ASCII                    = 0x34
let ASCII_5: ASCII                    = 0x35
let ASCII_6: ASCII                    = 0x36
let ASCII_7: ASCII                    = 0x37
let ASCII_8: ASCII                    = 0x38
let ASCII_9: ASCII                    = 0x39
let ASCII_COLON: ASCII                = 0x3A
let ASCII_SEMICOLON: ASCII            = 0x3B
let ASCII_LESS_THAN: ASCII            = 0x3C; let ASCII_LT = ASCII_LESS_THAN
let ASCII_EQUALS: ASCII               = 0x3D
let ASCII_GREATER_THAN: ASCII         = 0x3E; let ASCII_GT = ASCII_GREATER_THAN
let ASCII_QUESTION_MARK: ASCII        = 0x3F

let ASCII_AT_SYMBOL: ASCII            = 0x40
let ASCII_A: ASCII                    = 0x41
let ASCII_B: ASCII                    = 0x42
let ASCII_C: ASCII                    = 0x43
let ASCII_D: ASCII                    = 0x44
let ASCII_E: ASCII                    = 0x45
let ASCII_F: ASCII                    = 0x46
let ASCII_G: ASCII                    = 0x47
let ASCII_H: ASCII                    = 0x48
let ASCII_I: ASCII                    = 0x49
let ASCII_J: ASCII                    = 0x4A
let ASCII_K: ASCII                    = 0x4B
let ASCII_L: ASCII                    = 0x4C
let ASCII_M: ASCII                    = 0x4D
let ASCII_N: ASCII                    = 0x4E
let ASCII_O: ASCII                    = 0x4F

let ASCII_P: ASCII                    = 0x50
let ASCII_Q: ASCII                    = 0x51
let ASCII_R: ASCII                    = 0x52
let ASCII_S: ASCII                    = 0x53
let ASCII_T: ASCII                    = 0x54
let ASCII_U: ASCII                    = 0x55
let ASCII_V: ASCII                    = 0x56
let ASCII_W: ASCII                    = 0x57
let ASCII_X: ASCII                    = 0x58
let ASCII_Y: ASCII                    = 0x59
let ASCII_Z: ASCII                    = 0x5A
let ASCII_SQUARE_BRACKET_OPEN: ASCII  = 0x5B; let ASCII_BOX_BRACKET_OPEN = ASCII_SQUARE_BRACKET_OPEN; let ASCII_ARRAY_BRACKET_OPEN = ASCII_SQUARE_BRACKET_OPEN
let ASCII_BACKSLASH: ASCII            = 0x5C; let ASCII_REVERSE_SOLIDUS = ASCII_BACKSLASH; let ASCII_BACKWARD_SLASH = ASCII_BACKSLASH; let ASCII_SLASH_BACKWARD = ASCII_BACKSLASH
let ASCII_SQUARE_BRACKET_CLOSE: ASCII = 0x5D; let ASCII_BOX_BRACKET_CLOSE = ASCII_SQUARE_BRACKET_CLOSE; let ASCII_ARRAY_BRACKET_CLOSE = ASCII_SQUARE_BRACKET_CLOSE
let ASCII_CARET: ASCII                = 0x5E
let ASCII_UNDERSCORE: ASCII           = 0x5F

let ASCII_GRAVE_ACCENT: ASCII         = 0x60
let ASCII_a: ASCII                    = 0x61
let ASCII_b: ASCII                    = 0x62
let ASCII_c: ASCII                    = 0x63
let ASCII_d: ASCII                    = 0x64
let ASCII_e: ASCII                    = 0x65
let ASCII_f: ASCII                    = 0x66
let ASCII_g: ASCII                    = 0x67
let ASCII_h: ASCII                    = 0x68
let ASCII_i: ASCII                    = 0x69
let ASCII_j: ASCII                    = 0x6A
let ASCII_k: ASCII                    = 0x6B
let ASCII_l : ASCII                   = 0x6C
let ASCII_m: ASCII                    = 0x6D
let ASCII_n: ASCII                    = 0x6E
let ASCII_o: ASCII                    = 0x6F

let ASCII_p: ASCII                    = 0x70
let ASCII_q: ASCII                    = 0x71
let ASCII_r: ASCII                    = 0x72
let ASCII_s: ASCII                    = 0x73
let ASCII_t: ASCII                    = 0x74
let ASCII_u: ASCII                    = 0x75
let ASCII_v: ASCII                    = 0x76
let ASCII_w: ASCII                    = 0x77
let ASCII_x: ASCII                    = 0x78
let ASCII_y: ASCII                    = 0x79
let ASCII_z: ASCII                    = 0x7A
let ASCII_BRACE_OPEN: ASCII           = 0x7B; let ASCII_CURLY_BRACE_OPEN = ASCII_BRACE_OPEN
let ASCII_VERTICAL_BAR: ASCII         = 0x7C
let ASCII_BRACE_CLOSE: ASCII          = 0x7D; let ASCII_CURLY_BRACE_CLOSE = ASCII_BRACE_CLOSE
let ASCII_TILDE: ASCII                = 0x7E
let ASCII_DELETE: ASCII               = 0x7F

let hexLookup: Array<String> = [
    "00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "0A", "0B", "0C", "0D", "0E", "0F",
    "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "1A", "1B", "1C", "1D", "1E", "1F",
    "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "2A", "2B", "2C", "2D", "2E", "2F",
    "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "3A", "3B", "3C", "3D", "3E", "3F",
    "40", "41", "42", "43", "44", "45", "46", "47", "48", "49", "4A", "4B", "4C", "4D", "4E", "4F",
    "50", "51", "52", "53", "54", "55", "56", "57", "58", "59", "5A", "5B", "5C", "5D", "5E", "5F",
    "60", "61", "62", "63", "64", "65", "66", "67", "68", "69", "6A", "6B", "6C", "6D", "6E", "6F",
    "70", "71", "72", "73", "74", "75", "76", "77", "78", "79", "7A", "7B", "7C", "7D", "7E", "7F",
    "80", "81", "82", "83", "84", "85", "86", "87", "88", "89", "8A", "8B", "8C", "8D", "8E", "8F",
    "90", "91", "92", "93", "94", "95", "96", "97", "98", "99", "9A", "9B", "9C", "9D", "9E", "9F",
    "A0", "A1", "A2", "A3", "A4", "A5", "A6", "A7", "A8", "A9", "AA", "AB", "AC", "AD", "AE", "AF",
    "B0", "B1", "B2", "B3", "B4", "B5", "B6", "B7", "B8", "B9", "BA", "BB", "BC", "BD", "BE", "BF",
    "C0", "C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C9", "CA", "CB", "CC", "CD", "CE", "CF",
    "D0", "D1", "D2", "D3", "D4", "D5", "D6", "D7", "D8", "D9", "DA", "DB", "DC", "DD", "DE", "DF",
    "E0", "E1", "E2", "E3", "E4", "E5", "E6", "E7", "E8", "E9", "EA", "EB", "EC", "ED", "EE", "EF",
    "F0", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "FA", "FB", "FC", "FD", "FE", "FF",
]

func isAsciiControl(c: ASCII) -> Bool {
    return c < ASCII_SPACE
}

func isAsciiPrintable(c: ASCII) -> Bool {
    return (c >= ASCII_SPACE && c < ASCII_DELETE)
}

func isAsciiNumber(c: ASCII) -> Bool {
    return (c >= ASCII_0 && c <= ASCII_9)
}

func isAsciiHexadecimalDigit(c: ASCII) -> Bool {
    
    if isAsciiNumber(c) { return true }
    if (c >= ASCII_a && c <= ASCII_f) { return true }
    if (c >= ASCII_A && c <= ASCII_F) { return true }
    return false
}

func isAsciiWhitespace(c: ASCII) -> Bool {
    if c == ASCII_SPACE { return true }
    if c == ASCII_TAB { return true }
    if c == ASCII_CR { return true }
    if c == ASCII_LF { return true }
    return false
}

extension ASCII {
    
    var isAsciiControl: Bool {
        return self < ASCII_SPACE
    }
    
    var isAsciiPrintable: Bool {
        return (self >= ASCII_SPACE && self < ASCII_DELETE)
    }
    
    var isAsciiNumber: Bool {
        return (self >= ASCII_0 && self <= ASCII_9)
    }
    
    var isAsciiHexadecimalDigit: Bool {
        if self.isAsciiNumber { return true }
        if (self >= ASCII_a && self <= ASCII_f) { return true }
        if (self >= ASCII_A && self <= ASCII_F) { return true }
        return false
    }
    
    var isAsciiWhitespace: Bool {
        if self == ASCII_SPACE { return true }
        if self == ASCII_TAB { return true }
        if self == ASCII_CR { return true }
        if self == ASCII_LF { return true }
        return false
    }
    
    var hexString: String {
        return hexLookup[Int(self)]
    }
}

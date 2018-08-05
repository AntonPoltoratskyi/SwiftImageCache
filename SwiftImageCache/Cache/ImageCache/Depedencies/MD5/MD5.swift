//
//  MD5.swift
//  SwiftImageCache
//
//  Currently, import CommonCrypto into Swift framework is problematic. More detail here:
//  https://stackoverflow.com/questions/25248598/importing-commoncrypto-in-a-swift-framework
//  So, we are using some parts of source code from CryptoSwift that only includes MD5.
//  The original software can be found at: https://github.com/krzyzanowskim/CryptoSwift
//  This is the original copyright:
//
//  CryptoSwift
//
//  Copyright (C) 2014-2017 Marcin Krzyżanowski <marcin@krzyzanowskim.com>
//  This software is provided 'as-is', without any express or implied warranty.
//
//  In no event will the authors be held liable for any damages arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  - The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation is required.
//  - Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
//  - This notice may not be removed or altered from any source or binary distribution.
//

public final class MD5 {
    static let blockSize: Int = 64
    static let digestLength: Int = 16 // 128 / 8
    fileprivate static let hashInitialValue: Array<UInt32> = [0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476]
    
    fileprivate var accumulated = Array<UInt8>()
    fileprivate var processedBytesTotalCount: Int = 0
    fileprivate var accumulatedHash: Array<UInt32> = MD5.hashInitialValue
    
    /** specifies the per-round shift amounts */
    private let s: Array<UInt32> = [
        7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
        5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
        4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
        6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
        ]
    
    /** binary integer part of the sines of integers (Radians) */
    private let k: Array<UInt32> = [
        0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
        0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
        0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
        0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
        0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
        0xd62f105d, 0x2441453, 0xd8a1e681, 0xe7d3fbc8,
        0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
        0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
        0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
        0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
        0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x4881d05,
        0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
        0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
        0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
        0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
        0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
        ]
    
    public init() {
    }
    
    public func calculate(for bytes: Array<UInt8>) -> Array<UInt8> {
        do {
            return try update(withBytes: bytes.slice, isLast: true)
        } catch {
            fatalError()
        }
    }
    
    // mutating currentHash in place is way faster than returning new result
    fileprivate func process(block chunk: ArraySlice<UInt8>, currentHash: inout Array<UInt32>) {
        assert(chunk.count == 16 * 4)
        
        // Initialize hash value for this chunk:
        var A: UInt32 = currentHash[0]
        var B: UInt32 = currentHash[1]
        var C: UInt32 = currentHash[2]
        var D: UInt32 = currentHash[3]
        
        var dTemp: UInt32 = 0
        
        // Main loop
        for j in 0..<k.count {
            var g = 0
            var F: UInt32 = 0
            
            switch j {
            case 0...15:
                F = (B & C) | ((~B) & D)
                g = j
                break
            case 16...31:
                F = (D & B) | (~D & C)
                g = (5 * j + 1) % 16
                break
            case 32...47:
                F = B ^ C ^ D
                g = (3 * j + 5) % 16
                break
            case 48...63:
                F = C ^ (B | (~D))
                g = (7 * j) % 16
                break
            default:
                break
            }
            dTemp = D
            D = C
            C = B
            
            // break chunk into sixteen 32-bit words M[j], 0 ≤ j ≤ 15 and get M[g] value
            let gAdvanced = g << 2
            
            var Mg = UInt32(chunk[chunk.startIndex &+ gAdvanced])
            Mg |= UInt32(chunk[chunk.startIndex &+ gAdvanced &+ 1]) << 8
            Mg |= UInt32(chunk[chunk.startIndex &+ gAdvanced &+ 2]) << 16
            Mg |= UInt32(chunk[chunk.startIndex &+ gAdvanced &+ 3]) << 24
            
            B = B &+ rotateLeft(A &+ F &+ k[j] &+ Mg, by: s[j])
            A = dTemp
        }
        
        currentHash[0] = currentHash[0] &+ A
        currentHash[1] = currentHash[1] &+ B
        currentHash[2] = currentHash[2] &+ C
        currentHash[3] = currentHash[3] &+ D
    }
}

extension MD5: Updatable {
    public func update(withBytes bytes: ArraySlice<UInt8>, isLast: Bool = false) throws -> Array<UInt8> {
        accumulated += bytes
        
        if isLast {
            let lengthInBits = (processedBytesTotalCount + accumulated.count) * 8
            let lengthBytes = lengthInBits.bytes(totalBytes: 64 / 8) // A 64-bit representation of b
            // Step 1. Append padding
            bitPadding(to: &accumulated, blockSize: MD5.blockSize, allowance: 64 / 8)
            
            // Step 2. Append Length a 64-bit representation of lengthInBits
            accumulated += lengthBytes.reversed()
        }
        
        var processedBytes = 0
        for chunk in accumulated.batched(by: MD5.blockSize) {
            if isLast || (accumulated.count - processedBytes) >= MD5.blockSize {
                process(block: chunk, currentHash: &accumulatedHash)
                processedBytes += chunk.count
            }
        }
        accumulated.removeFirst(processedBytes)
        processedBytesTotalCount += processedBytes
        
        // output current hash
        var result = Array<UInt8>()
        result.reserveCapacity(MD5.digestLength)
        
        for hElement in accumulatedHash {
            let hLE = hElement.littleEndian
            result += Array<UInt8>(arrayLiteral: UInt8(hLE & 0xff), UInt8((hLE >> 8) & 0xff), UInt8((hLE >> 16) & 0xff), UInt8((hLE >> 24) & 0xff))
        }
        
        // reset hash value for instance
        if isLast {
            accumulatedHash = MD5.hashInitialValue
        }
        
        return result
    }
}

// MARK: - Updatable

/// A type that supports incremental updates. For example Digest or Cipher may be updatable
/// and calculate result incerementally.
public protocol Updatable {
    /// Update given bytes in chunks.
    ///
    /// - parameter bytes: Bytes to process.
    /// - parameter isLast: Indicate if given chunk is the last one. No more updates after this call.
    /// - returns: Processed partial result data or empty array.
    mutating func update(withBytes bytes: ArraySlice<UInt8>, isLast: Bool) throws -> Array<UInt8>
    
    /// Update given bytes in chunks.
    ///
    /// - Parameters:
    ///   - bytes: Bytes to process.
    ///   - isLast: Indicate if given chunk is the last one. No more updates after this call.
    ///   - output: Resulting bytes callback.
    /// - Returns: Processed partial result data or empty array.
    mutating func update(withBytes bytes: ArraySlice<UInt8>, isLast: Bool, output: (_ bytes: Array<UInt8>) -> Void) throws
}

extension Updatable {
    public mutating func update(withBytes bytes: ArraySlice<UInt8>, isLast: Bool = false, output: (_ bytes: Array<UInt8>) -> Void) throws {
        let processed = try update(withBytes: bytes, isLast: isLast)
        if !processed.isEmpty {
            output(processed)
        }
    }
    
    public mutating func update(withBytes bytes: ArraySlice<UInt8>, isLast: Bool = false) throws -> Array<UInt8> {
        return try update(withBytes: bytes, isLast: isLast)
    }
}

// MARK: - Bit

public enum Bit: Int {
    case zero
    case one
}


// MARK: - Batched Collection

struct BatchedCollectionIndex<Base: Collection> {
    let range: Range<Base.Index>
}

extension BatchedCollectionIndex: Comparable {
    static func == <Base>(lhs: BatchedCollectionIndex<Base>, rhs: BatchedCollectionIndex<Base>) -> Bool {
        return lhs.range.lowerBound == rhs.range.lowerBound
    }
    
    static func < <Base>(lhs: BatchedCollectionIndex<Base>, rhs: BatchedCollectionIndex<Base>) -> Bool {
        return lhs.range.lowerBound < rhs.range.lowerBound
    }
}

protocol BatchedCollectionType: Collection {
    associatedtype Base: Collection
}

struct BatchedCollection<Base: Collection>: Collection {
    let base: Base
    let size: Int
    typealias Index = BatchedCollectionIndex<Base>
    private func nextBreak(after idx: Base.Index) -> Base.Index {
        return base.index(idx, offsetBy: size, limitedBy: base.endIndex) ?? base.endIndex
    }
    
    var startIndex: Index {
        return Index(range: base.startIndex..<nextBreak(after: base.startIndex))
    }
    
    var endIndex: Index {
        return Index(range: base.endIndex..<base.endIndex)
    }
    
    func index(after idx: Index) -> Index {
        return Index(range: idx.range.upperBound..<nextBreak(after: idx.range.upperBound))
    }
    
    subscript(idx: Index) -> Base.SubSequence {
        return base[idx.range]
    }
}

// MARK: - Collections

extension Collection {
    func batched(by size: Int) -> BatchedCollection<Self> {
        return BatchedCollection(base: self, size: size)
    }
}

extension Array {
    var slice: ArraySlice<Element> {
        return self[self.startIndex ..< self.endIndex]
    }
}

// MARK: - Integers

/** Bits */
extension UInt8 {
    
    /** array of bits */
    public func bits() -> [Bit] {
        let totalBitsCount = MemoryLayout<UInt8>.size * 8
        
        var bitsArray = [Bit](repeating: Bit.zero, count: totalBitsCount)
        
        for j in 0..<totalBitsCount {
            let bitVal: UInt8 = 1 << UInt8(totalBitsCount - 1 - j)
            let check = self & bitVal
            
            if check != 0 {
                bitsArray[j] = Bit.one
            }
        }
        return bitsArray
    }
}

extension FixedWidthInteger {
    @_transparent
    func bytes(totalBytes: Int = MemoryLayout<Self>.size) -> Array<UInt8> {
        return arrayOfBytes(value: self.littleEndian, length: totalBytes)
        // TODO: adjust bytes order
        // var value = self.littleEndian
        // return withUnsafeBytes(of: &value, Array.init).reversed()
    }
}

/// Array of bytes. Caution: don't use directly because generic is slow.
///
/// - parameter value: integer value
/// - parameter length: length of output array. By default size of value type
///
/// - returns: Array of bytes
@_specialize(exported: true, where T == Int)
@_specialize(exported: true, where T == UInt)
@_specialize(exported: true, where T == UInt8)
@_specialize(exported: true, where T == UInt16)
@_specialize(exported: true, where T == UInt32)
@_specialize(exported: true, where T == UInt64)
func arrayOfBytes<T: FixedWidthInteger>(value: T, length totalBytes: Int = MemoryLayout<T>.size) -> Array<UInt8> {
    let valuePointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
    valuePointer.pointee = value
    
    let bytesPointer = UnsafeMutablePointer<UInt8>(OpaquePointer(valuePointer))
    var bytes = Array<UInt8>(repeating: 0, count: totalBytes)
    for j in 0..<min(MemoryLayout<T>.size, totalBytes) {
        bytes[totalBytes - 1 - j] = (bytesPointer + j).pointee
    }
    
    valuePointer.deinitialize(count: 1)
    valuePointer.deallocate()
    
    return bytes
}

/** build bit pattern from array of bits */
@_specialize(exported: true, where T == UInt8)
func integerFrom<T: FixedWidthInteger>(_ bits: Array<Bit>) -> T {
    var bitPattern: T = 0
    for idx in bits.indices {
        if bits[idx] == Bit.one {
            let bit = T(UInt64(1) << UInt64(idx))
            bitPattern = bitPattern | bit
        }
    }
    return bitPattern
}

/**
 ISO/IEC 9797-1 Padding method 2.
 Add a single bit with value 1 to the end of the data.
 If necessary add bits with value 0 to the end of the data until the padded data is a multiple of blockSize.
 - parameters:
 - blockSize: Padding size in bytes.
 - allowance: Excluded trailing number of bytes.
 */
@inline(__always)
func bitPadding(to data: inout Array<UInt8>, blockSize: Int, allowance: Int = 0) {
    let msgLength = data.count
    // Step 1. Append Padding Bits
    // append one bit (UInt8 with one bit) to message
    data.append(0x80)
    
    // Step 2. append "0" bit until message length in bits ≡ 448 (mod 512)
    let max = blockSize - allowance // 448, 986
    if msgLength % blockSize < max { // 448
        data += Array<UInt8>(repeating: 0, count: max - 1 - (msgLength % blockSize))
    } else {
        data += Array<UInt8>(repeating: 0, count: blockSize + max - 1 - (msgLength % blockSize))
    }
}

@_transparent
func rotateLeft(_ value: UInt32, by: UInt32) -> UInt32 {
    return ((value << by) & 0xffffffff) | (value >> (32 - by))
}

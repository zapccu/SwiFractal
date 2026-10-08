//
//  Matrix.swift
//  SwiFractal
//
//  Created by Dirk Braner on 28.03.26.
//

//
// Implement a matrix type as 1-dimensional array
//
// Initialize matrix:
//
//   let M = Matrix<Double>((rows, columns), defaultValue: 0.0)
//   let M = Matrix<Int> = [
//     [1, 2, 3],
//     [4, 5, 6]
//   ]
//
// Access matrix:
//
//   Element: M[row, col]
//   Row:     M[row: r]
//   Column:  M[col: c]
//
// Properties:
//
//   dim.x: width of matrix
//   dim.y: height of matrix
//   size:  size of matrix (number of elements)
//   grid:  the 1-dimensional array
//

struct Matrix<E: Sendable> : Sendable {
    
    /// Matrix dimensions
    let dim: (Int, Int)
    
    /// Default value
    var defaultValue: E
    
    /// Return number of rows
    var rows: Int { dim.0 }
    
    /// Return number of columns
    var cols: Int { dim.1 }
    
    /// Return number of matrix elements
    var size: Int { dim.0 * dim.1 }
        
    /// Internal array
    var grid: [E] = []
    
    /// Return true if matrix is empty
    var isEmpty: Bool { grid.isEmpty }

    /// Initialize empty matrix
    init(defaultValue: E) {
        self.dim = (0, 0)
        self.defaultValue = defaultValue
    }
    
    /// Initialize Matrix with default value
    init(_ dim: (Int, Int), defaultValue: E) {
        self.dim = dim
        self.defaultValue = defaultValue
        self.grid = Array(repeating: defaultValue, count: dim.0 * dim.1)
    }
    
    /// Initialize Matrix with grid values
    /// - Parameters:
    ///   - dim: Dimensions of matrix (rows, columns). Must match the number of elements in grid.
    ///   - grid: Array of elements in row-major order. Must have dim.0 x dim.1 elements.
    init(_ dim: (Int, Int), grid: [E]) {
        assert(dim.0 * dim.1 == grid.count, "Matrix size mismatch")
        self.dim = dim
        self.defaultValue = grid.first!
        self.grid = grid
    }
    
    init(_ dim: (Int, Int), grid: UnsafeBufferPointer<E>) {
        assert(dim.0 * dim.1 == grid.count, "Matrix size mismatch")
        self.dim = dim
        self.defaultValue = grid.first!
        self.grid = Array(grid)
    }

    /// Return array index of element
    /// - Parameters:
    ///   - y: row
    ///   - x: column
    /// - Returns: Position of element in grid
    @inline(__always) func idx(_ y: Int, _ x: Int) -> Int {
        return y * dim.1 + x
    }
    
    /// Return array index of first element of row
    /// - Parameter y: row
    /// - Returns: Position of first element of row in grid
    @inline(__always) func idx(_ y: Int) -> Int {
        return y * dim.1
    }
    
    /// Access matrix element [row, col]
    @inline(__always) subscript(y: Int, x: Int) -> E {
        get {
            assert(x >= 0 && x < dim.1, "Column index out of bounds")
            assert(y >= 0 && y < dim.0, "Line index out of bounds")
            return grid[y * dim.1 + x]
        }
        set {
            assert(x >= 0 && x < dim.1, "Column index out of bounds")
            assert(y >= 0 && y < dim.0, "Line index out of bounds")
            grid[y * dim.1 + x] = newValue
        }
    }
    
    /// Access matrix row
    @inline(__always) subscript(y: Int) -> [E] {
        get {
            assert(y >= 0 && y < dim.0, "Line index out of bounds")
            let start = y * dim.1
            let end = start + dim.1
            return Array(grid[start..<end])
        }
        set {
            assert(y >= 0 && y < dim.1, "Line index out of bounds")
            assert(newValue.count == dim.1, "Input array size mismatch")
            let start = y * dim.1
            let end = start + dim.1
            grid.replaceSubrange(start..<end, with: newValue)
        }
    }

    /// Access matrix column
    @inline(__always) subscript(col x: Int) -> [E] {
        get {
            assert(x >= 0 && x < dim.1, "Column index out of bounds")
            return (0..<dim.0).map { y in grid[y * dim.1 + x] }
        }
        set {
            assert(x >= 0 && x < dim.1, "Column index out of bounds")
            assert(newValue.count == dim.0, "Input array size mismatch")
            for y in 0..<dim.0 {
                grid[y * dim.1 + x] = newValue[y]
            }
        }
    }
    
    /// Return column of matrix using fast direct buffer access without bounds checking
    /// - Parameter x: column
    /// - Returns: Array containing matrix column
    func getColumn(_ x: Int) -> [E] {
        guard x >= 0 && x < dim.1 else { return [] }
        
        return grid.withUnsafeBufferPointer { buffer in
            var col = [E]()
            col.reserveCapacity(dim.0)
            
            for y in 0..<dim.0 {
                col.append(buffer[y * dim.1 + x])
            }
            
            return col
        }
    }
    
    /// Reset array to default value
    @inline(__always) mutating func reset() {
        for i in grid.indices {
            grid[i] = defaultValue
        }
    }
    
}

extension Matrix {
    
    /// Return the element with the smallest selector value
    func minElement<T: Comparable>(by selector: (E) -> T) -> E {
        return grid.min { selector($0) > selector($1) } ?? defaultValue
    }
    
    /// Return the element with the largest selector value
    func maxElement<T: Comparable>(by selector: (E) -> T) -> E {
        return grid.max { selector($0) < selector($1) } ?? defaultValue
    }
    
    /// Return the smallest selector value in matrix
    func minValue<T: Comparable>(by selector: (E) -> T) -> T? {
        return grid.map(selector).min()
    }
    
    /// Return the largest selector value in matrix
    func maxValue<T: Comparable>(by selector: (E) -> T) -> T? {
        return grid.map(selector).max()
    }

}

//
// Provide map function for matrix
//
extension Matrix {
    
    func map<T>(_ transform: (E) -> T) -> [T] {
        return grid.map(transform)
    }
    
}

extension Matrix: ExpressibleByArrayLiteral where E: Numeric {

    typealias ArrayLiteralElement = [E]
    
    /// Initialize matrix by assigning row arrays
    init(arrayLiteral elements: [E]...) {
        self.dim = (elements.count, elements.first?.count ?? 0)
            
        // Validate elements
        for row in elements {
            assert(row.count == self.dim.1, "All rows must be of same length")
        }

        self.grid = elements.flatMap { $0 }
        self.defaultValue = .zero
    }
    
    /// Multiply each matrix element with scalar value
    static func *= (lhs: inout Matrix<E>, rhs: E) {
        for i in 0..<lhs.grid.count {
            lhs.grid[i] *= rhs
        }
    }
    
    /// Multiply each matrix element with scalar value
    static func * (lhs: Matrix<E>, rhs: E) -> Matrix<E> {
        var newMatrix = lhs
        newMatrix *= rhs
        return newMatrix
    }
    
    /// Add scalar value to each matrix element
    static func += (lhs: inout Matrix<E>, rhs: E) {
        for i in 0..<lhs.grid.count {
            lhs.grid[i] += rhs
        }
    }
    
    /// Add scalar value to each matrix element
    static func + (lhs: Matrix<E>, rhs: E) -> Matrix<E> {
        var newMatrix = lhs
        newMatrix += rhs
        return newMatrix
    }
    
    /// Subtract scalar value from each matrix element
    static func -= (lhs: inout Matrix<E>, rhs: E) {
        for i in 0..<lhs.grid.count {
            lhs.grid[i] -= rhs
        }
    }
    
    /// Subtract scalar value from each matrix element
    static func - (lhs: Matrix<E>, rhs: E) -> Matrix<E> {
        var newMatrix = lhs
        newMatrix -= rhs
        return newMatrix
    }
    
    /// Dot product of matrix and vector
    static func * (_ mat: Matrix<E>, _ vec: Vector<E>) -> Vector<E> {
        guard mat.dim.0 == vec.dim else { return Vector<E>() }
        var r = Vector<E>(vec.dim, defaultValue: 0)
        
        for i in 0..<mat.dim.0 {
            for j in 0..<vec.dim {
                r[i] += mat[i, j] * vec[j]
            }
        }
        
        return r
    }
    
}

extension Matrix where E: FloatingPoint {

    /// Divide each matrix element by scalar value
    @inline(__always)
    static func /= (lhs: inout Matrix<E>, rhs: E) {
        for i in 0..<lhs.grid.count {
            lhs.grid[i] /= rhs
        }
    }
    
    /// Divide each matrix element by scalar value
    @inline(__always)
    static func / (lhs: Matrix<E>, rhs: E) -> Matrix<E> {
        var newMatrix = lhs
        newMatrix /= rhs
        return newMatrix
    }
    
}

extension Matrix where E: BinaryInteger {

    /// Divide each matrix element by scalar value
    static func /= (lhs: inout Matrix<E>, rhs: E) {
        for i in 0..<lhs.grid.count {
            lhs.grid[i] /= rhs
        }
    }
    
    /// Divide each matrix element by scalar value
    static func / (lhs: Matrix<E>, rhs: E) -> Matrix<E> {
        var newMatrix = lhs
        newMatrix /= rhs
        return newMatrix
    }
    
}

extension Matrix where E: ComplexNumber {
    
    typealias RT = E.RT
    
    /// Initialize a matrix with linear distributed complex values
    init(_ dim: (Int, Int), start: E, end: E) {
        let zeroValue = RT.zero
        
        self.init(dim, defaultValue: E(zeroValue, zeroValue))

        let realParts = RT.linspace(start.real, end.real, self.dim.1)
        let imagParts = RT.linspace(start.imaginary, end.imaginary, self.dim.0)
        
        // Initialize matrix
        var i = 0
        for y in 0..<self.dim.0 {
            for x in 0..<self.dim.1 {
                grid[i] = E(realParts[x], imagParts[y])
                i += 1
            }
        }
    }
                                                                               
}

//
// Extend Matrix to create a histogram of values
//
extension Matrix {
    
    /// Count how often each value in range 0...maxValue appears in a matrix
    /// - Parameters:
    ///   - maxValue: Maximum value in matrix
    ///   - histValue: Closure returning the matrix value as Int
    /// - Returns: Array with index 0...maxValue
    func histogram(maxValue: Int, histValue: (E) -> Int) -> [Int] {
        var hist = [Int](repeating: 0, count: maxValue + 1)
        
        for gv in grid {
            let rhv = histValue(gv)
            if rhv >= 0 && rhv <= maxValue {
                hist[rhv] += 1
            }
        }
        
        return hist
    }
    
    /// Cumulative histogram, normalized to [0, 1]
    func normalizedCumulativeHistogram(maxValue: Int, histValue: (E) -> Int) -> [Double] {
        var cumulative = [Double](repeating: 0, count: maxValue + 1)

        let hist = histogram(maxValue: maxValue, histValue: histValue)
        let total = hist.reduce(0, +)

        guard total > 0 else { return cumulative }

        var running = 0
        for i in 0...maxValue {
            running += hist[i]
            cumulative[i] = Double(running) / Double(total)
        }
        
        return cumulative
    }
    
}

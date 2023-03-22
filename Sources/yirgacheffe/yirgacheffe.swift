

public struct PixelScale {
    public let x: Double
    public let y: Double
}

enum AreaError: Error {
    case InvalidDimensions
}

public struct Area {
    public let left: Double
    public let top: Double
    public let right: Double
    public let bottom: Double

    init(left: Double, top: Double, right: Double, bottom: Double) throws {
        if (left >= right) || (bottom >= top) {
            throw AreaError.InvalidDimensions
        }
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
    }
}
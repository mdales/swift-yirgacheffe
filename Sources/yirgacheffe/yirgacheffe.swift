
public struct PixelScale: Equatable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public enum AreaError: Error {
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

public struct Window {
    public let xoff: Int
    public let yoff: Int
    public let xsize: Int
    public let ysize: Int

    public init(xoff: Int, yoff: Int, xsize: Int, ysize: Int) {
        self.xoff = xoff
        self.yoff = yoff
        self.xsize = xsize
        self.ysize = ysize
    }
}
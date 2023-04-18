

public protocol Layer {
    associatedtype T

    var area: Area { get }
    var pixelScale: PixelScale { get }
    var window: Window { get }

    func setAreaOfInterest(area: Area) throws -> any Layer
    func withDataAt(region: Window, block: (UnsafeBufferPointer<T>) throws -> Void) throws
}


// public struct ConstantLayer<T>: Layer {
//     let const: T
// }

public enum LayerError: Error {
    case NoLayersProvided
    case LayersNotAtSameScale
    case NoIntersectionPossible
}

public func calculateIntersection(layers: [any Layer]) throws -> Area {
    guard layers.count > 0 else {
        throw LayerError.NoLayersProvided
    }

    let targetScale = layers.first!.pixelScale
    let are_layes_same_scale = layers.reduce(true) { ($0 && ($1.pixelScale == targetScale)) }
    guard are_layes_same_scale else {
        throw LayerError.LayersNotAtSameScale
    }

    for layer in layers { print(layer.area)}
    let intersection = try Area(
        left: (layers.map{$0.area.left}).max()!,
        top: (layers.map{$0.area.top}).min()!,
        right: (layers.map{$0.area.right}).min()!,
        bottom: (layers.map{$0.area.bottom}).max()!
    )
    guard (intersection.left < intersection.right) && (intersection.bottom < intersection.top) else {
        throw LayerError.NoIntersectionPossible
    }
    return intersection
}

import LibTIFF

public protocol Layer {
        
}

public struct GeoTiffLayer<T>: Layer {
    let tiff : TIFFImage<T>

    init(_ path: String) throws {
        tiff = try TIFFImage<T>(readingAt: path)

        
    }

}

public struct ConstantLayer<T>: Layer {
    let const: T
}

import XCTest
@testable import Yirgacheffe

final class yirgacheffeTests: XCTestCase {
    func testOpenGeoTiff() throws {
        let url = Bundle.module.url(
            forResource: "small_made_with_gdal",
            withExtension: "tif")!
        let _ = try GeoTiffLayer<Float>(url.path)
    }
}

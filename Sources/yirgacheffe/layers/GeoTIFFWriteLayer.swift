import Foundation

import LibTIFF

public struct GeoTIFFWriteLayer<T>  {
	let tiff : GeoTIFFImage<T>

	// public let projection: String
	public let pixelScale: PixelScale
	public let geoTransform: [Double]
	public let area: Area

	public init(path: String, area: Area, pixelScale: PixelScale) throws {

		// We treat the provided area as aspirational, and we need to align it to pixel boundaries
		let abs_xstep = abs(pixelScale.x)
		let abs_ystep = abs(pixelScale.y)
		self.area = try Area(
			left: floor(area.left / abs_xstep) * abs_xstep,
			top: ceil(area.top / abs_ystep) * abs_ystep,
			right: ceil(area.right / abs_xstep) * abs_xstep,
			bottom: floor(area.bottom / abs_ystep) * abs_ystep
		)

		self.pixelScale = pixelScale
		self.geoTransform =  [self.area.left, pixelScale.x, 0.0, self.area.top, 0.0, pixelScale.y]

		// calc image size
		let size = Size(
			width: Int((area.right - area.left) / abs_xstep),
			height: Int((area.top - area.bottom) / abs_ystep)
		)

		// TODO: not this format please
		self.tiff = try GeoTIFFImage<T>(writingAt: path, size: size, samplesPerPixel: 4, hasAlpha: false)

		try self.tiff.setPixelScale([pixelScale.x, pixelScale.y * -1, 0.0])
		try self.tiff.setTiePoint([0.0, 0.0, 0.0, area.left, area.top, 0.0])
		try self.tiff.setProjection("WGS 84")

		let directoryEntries = [
			GeoTIFFDirectoryEntry(
				keyID: .GTModelTypeGeoKey,
				tiffTag: nil,
				valueCount: 1,
				valueOrIndex: 2
			),
			GeoTIFFDirectoryEntry(
				keyID: .GTRasterTypeGeoKey,
				tiffTag: 34737,
				valueCount: 1,
				valueOrIndex: 1
			),
			GeoTIFFDirectoryEntry(
				keyID: .GeodeticCitationGeoKey,
				tiffTag: 34737,
				valueCount: 1,
				valueOrIndex: 2 //?
			),
			GeoTIFFDirectoryEntry(
				keyID: .GeodeticCRSGeoKey,
				tiffTag: nil,
				valueCount: 1,
				valueOrIndex: 4326
			),
		]
		let directory = GeoTIFFDirectory(
			majorVersion: 1,
			minorVersion: 1,
			revision: 1,
			entries: directoryEntries
		)
		try self.tiff.setDirectory(directory)

		// TIFF is now ready to receive data
	}

	public func writeArray() {
	}
}
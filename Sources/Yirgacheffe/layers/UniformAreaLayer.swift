import Foundation

import LibTIFF

enum UniformAreaLayerError: Error {
	case AreaNotOnePixelWide
}

public struct UniformAreaLayer<T>: Layer {
	let tiff : GeoTIFFImage<T>
	let interest: Area?
	let data: UnsafeBufferPointer<T>

	public let projection: String
	public let pixelScale: PixelScale
	public let geoTransform: [Double]
	public let area: Area
	public let window: Window

	public init(_ path: String) throws {
		tiff = try GeoTIFFImage<T>(readingAt: path)
		guard tiff.attributes.width == 1 else {
			throw UniformAreaLayerError.AreaNotOnePixelWide
		}

		let rawPixelScale = try tiff.getPixelScale()
		guard rawPixelScale.count == 3 else {
			throw GeoTIFFLayerError.InvalidMetadata
		}
		pixelScale = PixelScale(x: rawPixelScale[0], y: rawPixelScale[1] * -1.0)

		let rawTilePoint = try tiff.getTilePoint()
		guard rawTilePoint.count == 6 else {
			throw GeoTIFFLayerError.InvalidMetadata
		}
		// out of habit we keep this in GDAL terms
		geoTransform = [
			rawTilePoint[3], pixelScale.x, 0.0, rawTilePoint[4], 0.0, pixelScale.y
		]

		projection = try tiff.getProjection()

		self.area = try Area(
			left: -180.0,
			top: geoTransform[3],
			right: 180.0,
			bottom: geoTransform[3] + (Double(tiff.attributes.height) * pixelScale.y)
		)
		self.window = Window(
			xoff: 0,
			yoff: 0,
			xsize: Int(360.0 / pixelScale.x),
			ysize: Int(self.tiff.attributes.height)
		)
		self.interest = nil

		// we cache the whole thing
		self.data = try self.tiff.read(LibTIFF.Area(
			origin: Point(x: 0, y: 0),
			size: Size(width: 1, height: Int(tiff.attributes.height))
		))
	}

	// deinit {
	// 	self.data?.deallocate()
	// }

	init(
		tiff: GeoTIFFImage<T>,
		pixelScale: PixelScale,
		projection: String,
		geoTransform: [Double],
		area: Area,
		interest: Area,
		window: Window
	) throws {
		self.tiff = tiff
		self.pixelScale = pixelScale
		self.projection = projection
		self.geoTransform = geoTransform
		self.area = area
		self.interest = interest
		self.window = window

		// struct has to own the data
		self.data = try self.tiff.read(LibTIFF.Area(
			origin: Point(x: 0, y: 0),
			size: Size(width: 1, height: Int(tiff.attributes.height))
		))
	}

	public func setAreaOfInterest(area: Area) throws -> any Layer {
		let new_window = Window(
			xoff: round_down_pixels(
				value: (area.left - self.area.left) / self.geoTransform[1],
				pixelScale: self.geoTransform[1]
			),
			yoff: round_down_pixels(
				value: (self.area.top - area.top) / (self.geoTransform[5] * -1.0),
				pixelScale: self.geoTransform[5] * -1.0
			),
			xsize: round_up_pixels(
				value: (area.right - area.left) / self.geoTransform[1],
				pixelScale: self.geoTransform[1]
			),
			ysize: round_up_pixels(
				value: (area.top - area.bottom) / (self.geoTransform[5] * -1.0),
				pixelScale: (self.geoTransform[5] * -1.0)
			)
		)

		return try UniformAreaLayer(
			tiff: self.tiff,
			pixelScale: self.pixelScale,
			projection: self.projection,
			geoTransform: self.geoTransform,
			area: self.area,
			interest: area,
			window: new_window
		)
	}

	public func withDataAt(region: Window, block: (UnsafeBufferPointer<T>, Int) throws -> Void) throws {
		// we provide just a 1 pixel wide stripe
		let pointer = self.data.baseAddress!
		let subset = UnsafeBufferPointer<T>(
			start: pointer + (region.yoff + self.window.yoff),
			count: region.ysize
		)
		try block(subset, 1)
	}
}

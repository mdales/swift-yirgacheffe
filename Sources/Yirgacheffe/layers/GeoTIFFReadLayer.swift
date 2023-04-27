import Foundation

import LibTIFF

enum GeoTIFFLayerError: Error {
	case InvalidMetadata
	case WindowExceedsTIFF
}

public struct GeoTIFFReadLayer<T>: Layer {
	let tiff : GeoTIFFImage<T>
	let interest: Area?

	public let projection: String
	public let pixelScale: PixelScale
	public let geoTransform: [Double]
	public let area: Area
	public let window: Window

	public init(_ path: String) throws {
		tiff = try GeoTIFFImage<T>(readingAt: path)

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
			left: geoTransform[0],
			top: geoTransform[3],
			right: geoTransform[0] + (Double(tiff.attributes.width) * pixelScale.x),
			bottom: geoTransform[3] + (Double(tiff.attributes.height) * pixelScale.y)
		)

		self.window = Window(
			xoff: 0,
			yoff: 0,
			xsize: Int(self.tiff.attributes.width),
			ysize: Int(self.tiff.attributes.height)
		)

		self.interest = nil
	}

	init(
		tiff: GeoTIFFImage<T>,
		pixelScale: PixelScale,
		projection: String,
		geoTransform: [Double],
		area: Area,
		interest: Area,
		window: Window
	) {
		self.tiff = tiff
		self.pixelScale = pixelScale
		self.projection = projection
		self.geoTransform = geoTransform
		self.area = area
		self.interest = interest
		self.window = window
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
		guard (((new_window.xoff + new_window.xsize) <= Int(self.tiff.attributes.width)) && ((new_window.yoff + new_window.ysize) <= Int(self.tiff.attributes.height))) else {
			throw GeoTIFFLayerError.WindowExceedsTIFF
		}

		return GeoTIFFReadLayer(
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
		// for now we just
		let imageArea = LibTIFF.Area(
			origin: Point(x: region.xoff + self.window.xoff, y: region.yoff + self.window.yoff),
			size: Size(width: region.xsize, height: region.ysize)
		)
		let data = try self.tiff.read(imageArea)
		defer { data.deallocate() }

		try block(data, region.xsize)
	}
}

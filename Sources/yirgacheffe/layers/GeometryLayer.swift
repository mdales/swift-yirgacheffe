import Foundation

import GeoPackage
import PlatformGraphics
import Utils

enum GeometryLayerError: Error {
	case InvalidEnvelope
	case UnsupportedGeometryType
}


public struct GeometryLayer: Layer {
	let geometry: Geometry
	let interest: Area?

	// public let projection: String
	public let pixelScale: PixelScale
	public let geoTransform: [Double]
	public let area: Area
	public let window: Window

	public init(geometry: Geometry, pixelScale: PixelScale) throws {
		self.geometry = geometry
		self.pixelScale = pixelScale

		guard geometry.envelope.count >= 4 else {
			throw GeometryLayerError.InvalidEnvelope
		}

		// we need to map the envelope to the pixel scale
		let abs_xstep = abs(pixelScale.x)
		let abs_ystep = abs(pixelScale.y)
		self.area = try Area(
			left: floor(geometry.envelope[0] / abs_xstep) * abs_xstep,
			top: ceil(geometry.envelope[3] / abs_ystep) * abs_ystep,
			right: ceil(geometry.envelope[1] / abs_xstep) * abs_xstep,
			bottom: floor(geometry.envelope[2] / abs_ystep) * abs_ystep
		)
		self.window = Window(
			xoff: 0,
			yoff: 0,
			xsize: round_up_pixels(
				value: (self.area.right - self.area.left) / abs_xstep,
				pixelScale: abs_xstep
			),
			ysize: round_up_pixels(
				value: (self.area.top - self.area.bottom) / abs_ystep,
				pixelScale: abs_ystep
			)
		)
		self.interest = nil

		self.geoTransform = [
			geometry.envelope[0], pixelScale.x, 0.0, geometry.envelope[3], 0.0, pixelScale.y
		]
	}

	init(
		geometry: Geometry,
		pixelScale: PixelScale,
		geoTransform: [Double],
		area: Area,
		interest: Area,
		window: Window
	) {
		self.geometry = geometry
		self.pixelScale = pixelScale
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

		return GeometryLayer(
			geometry: self.geometry,
			pixelScale: self.pixelScale,
			geoTransform: self.geoTransform,
			area: self.area,
			interest: area,
			window: new_window
		)
	}

	func renderPolygon(region: Window, context: PlatformGraphicsContext, polygon: WKBPolygon) {
		// TODO: do some intersection checks
		let paths = polygon.rings.map { path in
			return path.points.map { point in
				return Vec2<Double>(
					x: ((point.x - self.area.left) / pixelScale.x) - Double(region.xoff),
					y: ((point.y - self.area.top) / pixelScale.y) - Double(region.yoff)
				)
			}
		}
		context.draw(polygon: Polygon(paths: Array(paths), isFilled: true))
	}

	func renderMultiPolygon(region: Window, context: PlatformGraphicsContext, multi_polygon: WKBMultiPolygon) {
		for polygon in multi_polygon.wkbPolygons {
			renderPolygon(region: region, context: context, polygon: polygon)
		}
	}

	public func withDataAt(region: Window, block: (UnsafeBufferPointer<UInt8>) throws -> Void) throws {
		let ctx = try PlatformGraphicsContext(width: region.xsize, height: region.ysize, format: .g8)

		let wkbgeometry = geometry.geometry
		switch wkbgeometry.type {
			case .MultiPolygon:
				renderMultiPolygon(region: region, context: ctx, multi_polygon: wkbgeometry as! WKBMultiPolygon)
			default:
				throw GeometryLayerError.UnsupportedGeometryType
		}
		try ctx.withUnsafeMutableBytes {
			try block(UnsafeBufferPointer<UInt8>($0))
		}
	}

}
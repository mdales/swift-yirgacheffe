import Foundation

func almost_equal(a: Double, b: Double) -> Bool {
	return abs(a - b) < Double.ulpOfOne
}

// As per https://xkcd.com/2170/, we need to stop caring about floating point
// accuracy at some point as it becomes problematic.
// The value here is 1 meter, given that geo data that we've been working with
// is accurate to 100 meter, but if you need to worry about the biodiversity
// of a virus in a petri dish this assumption may not work for you.
let kMinimalDistanceOfInterest = 1.0
let kDistancePerDegreeAtEqualtor = 40075017.0 / 360.0
let kMinimalDegreeOfInterest = kMinimalDistanceOfInterest / kDistancePerDegreeAtEqualtor


// In general we round up pixels, as we don't want to lose range data,
// but floating point math means we will get errors where the value of pixel
// scale value rounds us to a tiny faction of a pixel up, and so math.ceil
// would round us up for microns worth of distance.
func round_up_pixels(value: Double, pixelScale: Double) -> Int {
	let floored = floor(value)
	let diff = value - floored
	let degrees_diff = diff * pixelScale
	return degrees_diff < kMinimalDegreeOfInterest ? Int(floored) : Int(ceil(value))
}

func round_down_pixels(value: Double, pixelScale: Double) -> Int {
	let ceiled = ceil(value)
	let diff = ceiled - value
	let degrees_diff = diff * pixelScale
	return degrees_diff < kMinimalDegreeOfInterest ? Int(ceiled) : Int(floor(value))
}

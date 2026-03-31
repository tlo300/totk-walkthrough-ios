// MapPin.swift — Map location model for shrine and Skyview Tower pins.
import Foundation

enum MapLayer: String, Codable {
    case surface, sky, depths
}

enum PinType: String, Codable {
    case shrine, tower
}

struct MapPin: Identifiable, Codable {
    let slug: String
    let type: PinType
    let layer: MapLayer
    let x: Double
    let y: Double
    let name: String?

    var id: String { slug }
}

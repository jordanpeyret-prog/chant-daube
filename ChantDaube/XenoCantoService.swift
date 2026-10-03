import Foundation

struct XenoRecording: Codable, Identifiable {
    let id: String
    let file: String
    let lic: String
    let type: String?
    let q: String?
    let rec: String?
    let cnt: String?
    let loc: String?
}

private struct XenoResponse: Codable {
    let recordings: [XenoRecording]
}

actor XenoCantoService {
    static let shared = XenoCantoService()
    private var cache: [String: XenoRecording] = [:]

    func bestRecording(for scientificName: String) async -> XenoRecording? {
        if let cached = cache[scientificName] {
            return cached
        }

        guard var components = URLComponents(
            string: "https://xeno-canto.org/api/2/recordings"
        ) else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(
                name: "query",
                value: "species:\(scientificName)"
            )
        ]

        guard let url = components.url else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(
                XenoResponse.self,
                from: data
            )

            let cc = response.recordings.filter {
                let license = $0.lic.lowercased()
                return license.contains("creative commons") ||
                       license.hasPrefix("cc")
            }

            let chosen = cc.sorted {
                score($0) > score($1)
            }.first

            if let chosen {
                cache[scientificName] = chosen
            }

            return chosen
        } catch {
            return nil
        }
    }

    private func score(_ r: XenoRecording) -> Int {
        var score = 0

        if r.q == "A" {
            score += 50
        } else if r.q == "B" {
            score += 35
        } else if r.q == "C" {
            score += 20
        }

        if r.type?.lowercased().contains("song") == true {
            score += 30
        }

        if r.cnt == "France" {
            score += 10
        }

        return score
    }
}

import Foundation
import SwiftUI
import AlarmKit

@MainActor
final class AlarmStore: ObservableObject {
    @Published var hour = 7
    @Published var minute = 0
    @Published var enabled = true
    @Published var selectedBird = birds[0]
    @Published var status = ""

    private let manager = AlarmManager.shared
    private let alarmID = UUID(uuidString: "D8A2E4B0-2E5A-4A0A-9F4A-000000000001")!

    func requestAccessAndSchedule() async {
        do {
            let auth = try await manager.requestAuthorization()
            guard auth == .authorized else {
                status = "Autorisation des alarmes refusée."
                return
            }
            try await schedule()
            status = "Réveil programmé à %02d:%02d".formatted(hour, minute)
            enabled = true
        } catch {
            status = "Impossible de programmer le réveil : \(error.localizedDescription)"
        }
    }

    func schedule() async throws {
        let time = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
        let schedule = Alarm.Schedule.Relative(time: time, repeats: .never)

        let presentation = AlarmPresentation.Alert(
            title: "Chant d’aube",
            stopButton: .stopButton,
            secondaryButton: .repeatButton,
            secondaryButtonBehavior: .countdown
        )

        let attributes = AlarmAttributes(
            presentation: AlarmPresentation(alert: presentation),
            metadata: BirdAlarmMetadata(
                birdID: selectedBird.id,
                birdName: selectedBird.name
            ),
            tintColor: Color.green
        )

        let configuration = AlarmManager.AlarmConfiguration.alarm(
            schedule: schedule,
            attributes: attributes,
            sound: .default
        )

        _ = try await manager.schedule(id: alarmID, configuration: configuration)
    }

    func cancel() {
        do {
            try manager.cancel(id: alarmID)
            enabled = false
            status = "Réveil désactivé"
        } catch {
            status = "Impossible de désactiver le réveil."
        }
    }
}

struct BirdAlarmMetadata: AlarmMetadata, Codable {
    let birdID: String
    let birdName: String
}

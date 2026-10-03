import SwiftUI
import AVFoundation

struct ContentView: View {
    @EnvironmentObject private var alarm: AlarmStore
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            WakeView()
                .tabItem { Label("Réveil", systemImage: "alarm.fill") }
                .tag(0)

            BirdsView()
                .tabItem { Label("Oiseaux", systemImage: "bird.fill") }
                .tag(1)
        }
        .tint(.green)
    }
}

struct WakeView: View {
    @EnvironmentObject private var alarm: AlarmStore
    @State private var isScheduling = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 5) {
                        Text("Chant d’aube")
                            .font(.largeTitle.bold())
                        Text("Réveillez-vous avec le chant des oiseaux")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)

                    DatePicker(
                        "Heure",
                        selection: Binding(
                            get: {
                                Calendar.current.date(
                                    from: DateComponents(
                                        hour: alarm.hour,
                                        minute: alarm.minute
                                    )
                                ) ?? Date()
                            },
                            set: {
                                alarm.hour = Calendar.current.component(.hour, from: $0)
                                alarm.minute = Calendar.current.component(.minute, from: $0)
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .frame(height: 150)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Oiseau du réveil")
                            .font(.headline)
                        BirdRow(bird: alarm.selectedBird, selected: true)
                    }

                    Button {
                        isScheduling = true
                        Task {
                            await alarm.requestAccessAndSchedule()
                            isScheduling = false
                        }
                    } label: {
                        HStack {
                            if isScheduling {
                                ProgressView().tint(.white)
                            }
                            Text("Programmer le réveil").bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isScheduling)

                    Button("Désactiver le réveil", role: .destructive) {
                        alarm.cancel()
                    }

                    if !alarm.status.isEmpty {
                        Text(alarm.status)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Fonctionne écran verrouillé", systemImage: "lock.fill")
                        Label("Heure à la minute près", systemImage: "clock")
                        Label("Réveil géré par iOS", systemImage: "iphone")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        .green.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                }
                .padding()
            }
            .navigationTitle("Réveil")
        }
    }
}

struct BirdsView: View {
    @EnvironmentObject private var alarm: AlarmStore
    @State private var query = ""
    @State private var recording: XenoRecording?
    @State private var player: AVAudioPlayer?

    var filtered: [Bird] {
        birds.filter {
            query.isEmpty ||
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.latin.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { bird in
                BirdRow(
                    bird: bird,
                    selected: bird == alarm.selectedBird
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    alarm.selectedBird = bird
                }
                .swipeActions {
                    Button("Écouter") {
                        Task { await play(bird) }
                    }
                    .tint(.green)
                }
            }
            .searchable(text: $query, prompt: "Chercher un oiseau")
            .navigationTitle("Oiseaux")
        }
    }

    private func play(_ bird: Bird) async {
        guard
            let r = await XenoCantoService.shared.bestRecording(
                for: bird.xenoQuery
            ),
            let url = URL(string: r.file)
        else {
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            player = try AVAudioPlayer(data: data)
            player?.play()
            recording = r
        } catch {
            // Lecture impossible : on laisse l'interface silencieuse.
        }
    }
}

struct BirdRow: View {
    let bird: Bird
    let selected: Bool

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: bird.photoURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Text(bird.emoji)
                        .font(.largeTitle)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading) {
                Text(bird.name)
                    .font(.headline)
                Text(bird.latin)
                    .italic()
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

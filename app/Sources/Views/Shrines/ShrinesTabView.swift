// ShrinesTabView.swift — Shrine list with completion tracking, regional sections, and detail navigation.
import SwiftUI

struct ShrinesTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingSettings = false
    @State private var searchText = ""

    private var completionFraction: Double {
        let total = contentStore.shrines.count
        guard total > 0 else { return 0 }
        let done = contentStore.shrines.filter { progressStore.isQuestComplete($0.slug) }.count
        return Double(done) / Double(total)
    }

    private var filteredGrouped: [String: [Quest]] {
        let items = searchText.isEmpty
            ? contentStore.shrines
            : contentStore.shrines.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        return Dictionary(grouping: items) { $0.region ?? "Other" }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabHeaderView(title: "Shrines", showingSettings: $showingSettings)
                    .environmentObject(themeManager)
                SearchBar(text: $searchText)
                    .environmentObject(themeManager)

                List {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Shrine Progress")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(themeManager.colors.primaryText)
                                Spacer()
                                Text("\(Int(completionFraction * Double(contentStore.shrines.count))) / \(contentStore.shrines.count)")
                                    .font(.subheadline)
                                    .foregroundStyle(themeManager.colors.accent)
                            }
                            ProgressView(value: completionFraction)
                                .tint(themeManager.colors.progressFill)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(themeManager.colors.cardBackground)
                    }

                    if !searchText.isEmpty && filteredGrouped.isEmpty {
                        Section {
                            Text("No results")
                                .foregroundStyle(themeManager.colors.secondaryText)
                                .listRowBackground(themeManager.colors.cardBackground)
                        }
                    }

                    ForEach(ModelConfig.regionOrder.filter { filteredGrouped[$0] != nil }, id: \.self) { region in
                        Section {
                            ForEach(filteredGrouped[region]!) { shrine in
                                HStack(spacing: 12) {
                                    Button {
                                        progressStore.toggleQuest(shrine.slug)
                                    } label: {
                                        Image(systemName: progressStore.isQuestComplete(shrine.slug) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(progressStore.isQuestComplete(shrine.slug) ? themeManager.colors.checkpointDone : themeManager.colors.secondaryText)
                                    }
                                    .buttonStyle(.plain)

                                    NavigationLink(destination: QuestDetailView(quest: shrine)) {
                                        Text(shrine.title)
                                            .foregroundStyle(progressStore.isQuestComplete(shrine.slug) ? themeManager.colors.secondaryText : themeManager.colors.primaryText)
                                            .strikethrough(progressStore.isQuestComplete(shrine.slug))
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        progressStore.toggleQuest(shrine.slug)
                                    } label: {
                                        Label(
                                            progressStore.isQuestComplete(shrine.slug) ? "Undo" : "Done",
                                            systemImage: progressStore.isQuestComplete(shrine.slug) ? "arrow.uturn.backward" : "checkmark"
                                        )
                                    }
                                    .tint(progressStore.isQuestComplete(shrine.slug) ? .gray : .green)
                                }
                                .listRowBackground(themeManager.colors.cardBackground)
                            }
                        } header: {
                            Text(region)
                                .foregroundStyle(themeManager.colors.sectionLabel)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(themeManager.colors.background)
                .toolbar(.hidden, for: .navigationBar)
            }
            .background(themeManager.colors.background)
            .onAppear {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsSheet().environmentObject(themeManager)
            }
        }
    }
}

import Foundation

struct Passage: Codable, Identifiable {
    let id = UUID()
    let reference: String
    let text: String
    let themes: [String]
    let crossrefs: [String]
}

class ScriptureStore: ObservableObject {
    @Published var passages: [Passage] = []
    
    init() {
        loadScripture()
    }
    
    private func loadScripture() {
        guard let url = Bundle.main.url(forResource: "scripture", withExtension: "json") else {
            print("Could not find scripture.json")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            passages = try JSONDecoder().decode([Passage].self, from: data)
        } catch {
            print("Error loading scripture: \(error)")
        }
    }
    
    func pick(byThemes themes: [String]) -> Passage {
        // Find passages that match any of the given themes
        let matchingPassages = passages.filter { passage in
            passage.themes.contains { theme in
                themes.contains(theme)
            }
        }
        
        // Return a random matching passage, or default to Psalm 46
        if let randomPassage = matchingPassages.randomElement() {
            return randomPassage
        }
        
        // Default fallback
        return passages.first { $0.reference == "Psalm 46:1-3" } ?? passages.first!
    }
    
    func pickRandom() -> Passage {
        passages.randomElement() ?? passages.first!
    }
} 
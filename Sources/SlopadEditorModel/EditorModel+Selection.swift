import SlopadCoreModel

// MARK: - EditorModel Selection

extension EditorModel {
    package func replaceSelection(_ selection: EditorSelection) {
        self.selection = selection
    }
}

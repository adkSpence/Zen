import SwiftUI
import SwiftData

struct FocusListCard: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusListItem.order) private var items: [FocusListItem]

    @State private var newItemText = ""
    @State private var isAddingItem = false
    @FocusState private var addFieldFocused: Bool

    private var doneItems: [FocusListItem] { items.filter(\.isDone) }
    private var hasDone: Bool { !doneItems.isEmpty }

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 0) {
                CardHeader(title: "Focus List", trailing: AnyView(addButton))

                if items.isEmpty && !isAddingItem {
                    emptyState
                } else {
                    itemList
                }

                if isAddingItem {
                    addField
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                }

                if hasDone {
                    clearCompletedButton
                        .padding(.top, 12)
                }
            }
        }
    }

    // MARK: - Subviews

    private var addButton: some View {
        Button {
            withAnimation(.focusDefault) { isAddingItem = true }
            addFieldFocused = true
        } label: {
            Image(systemName: "plus")
                .foregroundStyle(items.isEmpty ? Color.accentFocus : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add focus item")
    }

    private var emptyState: some View {
        Text("What are you focusing on?")
            .font(.system(size: 14))
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, minHeight: 80)
            .multilineTextAlignment(.center)
    }

    private var itemList: some View {
        LazyVStack(spacing: 0) {
            ForEach(items) { item in
                FocusListRow(item: item, onDelete: { delete(item) })
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
            .onMove(perform: reorder)
        }
        .animation(.focusDefault, value: items.map(\.id))
        .padding(.top, 8)
    }

    private var addField: some View {
        HStack {
            Circle()
                .stroke(Color.secondary.opacity(0.4), lineWidth: 1.5)
                .frame(width: 18, height: 18)
            TextField("New item", text: $newItemText)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($addFieldFocused)
                .onSubmit { commitNewItem() }
                .onKeyPress(.escape) {
                    withAnimation(.focusDefault) { cancelAdd() }
                    return .handled
                }
        }
        .padding(.vertical, 6)
    }

    private var clearCompletedButton: some View {
        Button("Clear completed") {
            withAnimation(.focusDefault) {
                doneItems.forEach { modelContext.delete($0) }
                try? modelContext.save()
            }
        }
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Actions

    private func commitNewItem() {
        let text = newItemText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { cancelAdd(); return }
        let maxOrder = items.map(\.order).max() ?? -1
        let item = FocusListItem(text: text, order: maxOrder + 1)
        withAnimation(.focusDefault) {
            modelContext.insert(item)
            try? modelContext.save()
            newItemText = ""
            isAddingItem = false
        }
    }

    private func cancelAdd() {
        newItemText = ""
        isAddingItem = false
    }

    private func delete(_ item: FocusListItem) {
        withAnimation(.focusDefault) {
            modelContext.delete(item)
            try? modelContext.save()
        }
    }

    private func reorder(_ from: IndexSet, _ to: Int) {
        var reordered = items
        reordered.move(fromOffsets: from, toOffset: to)
        for (i, item) in reordered.enumerated() {
            item.order = i
        }
        try? modelContext.save()
    }
}

// MARK: - Row

struct FocusListRow: View {
    @Bindable var item: FocusListItem
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var isEditing = false
    @FocusState private var editFocused: Bool
    @State private var editText = ""

    var body: some View {
        HStack(spacing: 10) {
            // Checkbox
            Button {
                withAnimation(.focusDefault) { item.isDone.toggle() }
            } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(item.isDone ? Color.accentFocus : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isDone ? "Mark incomplete" : "Mark complete")

            if isEditing {
                TextField("", text: $editText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .focused($editFocused)
                    .onSubmit { commitEdit() }
                    .onKeyPress(.escape) { cancelEdit(); return .handled }
            } else {
                Text(item.text)
                    .font(.system(size: 14))
                    .strikethrough(item.isDone, color: .secondary)
                    .foregroundStyle(item.isDone ? Color.secondary.opacity(0.5) : Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onTapGesture(count: 2) { startEditing() }
            }

            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
                .accessibilityLabel("Delete item")
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }

    private func startEditing() {
        editText = item.text
        isEditing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { editFocused = true }
    }

    private func commitEdit() {
        let t = editText.trimmingCharacters(in: .whitespaces)
        if !t.isEmpty { item.text = t }
        isEditing = false
    }

    private func cancelEdit() {
        isEditing = false
    }
}

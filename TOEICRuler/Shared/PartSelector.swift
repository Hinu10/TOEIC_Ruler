import SwiftUI

struct PartSelector: View {
    @Binding var selection: Set<TOEICPart>

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
            ForEach(TOEICPart.allCases) { part in
                Button {
                    toggle(part)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(part.title)
                                .font(.headline)
                            Spacer()
                            Image(systemName: selection.contains(part) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selection.contains(part) ? Color.accentColor : Color.secondary)
                        }
                        Text(part.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                    .padding(10)
                    .background(selection.contains(part) ? Color.accentColor.opacity(0.12) : Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggle(_ part: TOEICPart) {
        if selection.contains(part) {
            selection.remove(part)
        } else {
            selection.insert(part)
        }
    }
}

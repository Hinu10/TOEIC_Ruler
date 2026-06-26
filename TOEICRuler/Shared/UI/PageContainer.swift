import SwiftUI

struct PageContainer<Content: View>: View {
    let title: String
    let route: AppRoute?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AppHeader(title: title, route: route)
            content
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.clear)
        .navigationTitle(title)
    }
}

import SwiftUI

struct ShowcaseView: View {
    @StateObject
    private var coordinator = BaseNavigationCoordinator<AppRoute>()
    @StateObject
    private var settingsCoordinator = SettingsCoordinator()
    var body: some View {
        ScrollView {
            LazyVStack {
            }
        }
        .environmentObject(coordinator)
        .environmentObject(settingsCoordinator)
    }
}

struct ShowcaseView_Previews: PreviewProvider {
    static var previews: some View {
        ShowcaseView()
    }
}

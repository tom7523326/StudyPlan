import SwiftUI

class AppSettings: ObservableObject {
    @Published var username: String = "小明"
    @Published var themeColor: Color = .blue
    @Published var motivation: String = "每天进步一点点！"
}

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    var body: some View {
        GeometryReader { geometry in
            let isWide = geometry.size.width > 700
            NavigationView {
                if isWide {
                    HStack(alignment: .top, spacing: 32) {
                        ScrollView {
                            FormPanel(appSettings: appSettings)
                                .frame(maxWidth: 400)
                        }
                        Spacer()
                        ScrollView {
                            AboutPanel()
                                .frame(maxWidth: 300)
                        }
                    }
                    .padding([.top, .horizontal])
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            FormPanel(appSettings: appSettings)
                            AboutPanel()
                        }
                        .padding([.top, .horizontal])
                    }
                }
            }
            .navigationTitle("设置")
            .ignoresSafeArea(.keyboard)
        }
    }
}

struct FormPanel: View {
    @ObservedObject var appSettings: AppSettings
    var body: some View {
        Form {
            Section(header: Text("用户信息")) {
                TextField("昵称", text: $appSettings.username)
                    .frame(maxWidth: .infinity)
            }
            Section(header: Text("主题色")) {
                ColorPicker("选择主题色", selection: $appSettings.themeColor)
                    .frame(maxWidth: .infinity)
            }
            Section(header: Text("激励语")) {
                TextField("激励语", text: $appSettings.motivation)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: 400)
    }
}

struct AboutPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("关于")
                .font(.headline)
            Text("学习计划 v1.0\n© 2024")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: 300)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .shadow(color: Color(.systemGray4).opacity(0.12), radius: 2, x: 0, y: 1)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView().environmentObject(AppSettings())
    }
} 
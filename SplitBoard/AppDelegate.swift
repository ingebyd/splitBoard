import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     configurationForConnecting session: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: "Default", sessionRole: session.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    /// `-gallery split|merged [-galleryLang ru|en]` renders the keyboard on its
    /// own for screenshots; without the flag the app starts normally.
    private static func makeRoot() -> UIViewController {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-gallery"), index + 1 < args.count else {
            return RootViewController()
        }
        let split = args[index + 1] == "split"
        var language = KBLanguage.en
        if let li = args.firstIndex(of: "-galleryLang"), li + 1 < args.count,
           let parsed = KBLanguage(rawValue: args[li + 1]) {
            language = parsed
        }
        let text = args.firstIndex(of: "-galleryText").map { args[$0 + 1] }
            ?? "Hold the iPad in both hands and type with your thumbs."
        return GalleryViewController(split: split, language: language, text: text)
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = Self.makeRoot()
        window.makeKeyAndVisible()
        self.window = window
    }
}

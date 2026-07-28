import UIKit

/// Host app: setup instructions plus a text field for trying the keyboard out.
final class RootViewController: UIViewController {

    private let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let title = UILabel()
        title.text = "SplitBoard"
        title.font = .systemFont(ofSize: 34, weight: .bold)

        let subtitle = UILabel()
        subtitle.text = "Разделяемая клавиатура для iPad"
        subtitle.font = .systemFont(ofSize: 17)
        subtitle.textColor = .secondaryLabel

        let steps = UILabel()
        steps.numberOfLines = 0
        steps.font = .systemFont(ofSize: 16)
        steps.attributedText = Self.instructions()

        let settingsButton = UIButton(configuration: {
            var c = UIButton.Configuration.filled()
            c.title = "Открыть Настройки"
            c.cornerStyle = .large
            return c
        }())
        settingsButton.addAction(UIAction { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }, for: .touchUpInside)

        textView.font = .systemFont(ofSize: 20)
        textView.layer.borderColor = UIColor.separator.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 12
        textView.autocapitalizationType = .sentences
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        textView.accessibilityIdentifier = "playground"

        let stack = UIStackView(arrangedSubviews: [title, subtitle, steps, settingsButton, textView])
        stack.axis = .vertical
        stack.spacing = 18
        stack.setCustomSpacing(4, after: title)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -28),
            textView.heightAnchor.constraint(equalToConstant: 220),
            settingsButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }

    private static func instructions() -> NSAttributedString {
        let lines = [
            "1. Настройки → Основные → Клавиатура → Клавиатуры → Новые клавиатуры → SplitBoard",
            "2. Вернитесь сюда и нажмите на поле ниже",
            "3. Долгое нажатие на 🌐 → выберите SplitBoard",
            "4. Кнопка с иконкой ▯▯ в нижнем ряду делит клавиатуру пополам и обратно",
            "5. Короткое нажатие на 🌐 переключает English ⇄ Русский, долгое - уходит на другую клавиатуру",
            "6. Удержание клавиши показывает доп. символы, свайп вниз по клавише вводит цифру/знак",
        ]
        let paragraph = NSMutableParagraphStyle()
        paragraph.paragraphSpacing = 8
        paragraph.lineSpacing = 2
        return NSAttributedString(string: lines.joined(separator: "\n"), attributes: [
            .paragraphStyle: paragraph,
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.label,
        ])
    }
}

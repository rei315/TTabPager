import UIKit

public final class TTabViewCell: UICollectionViewCell {
    public enum State {
        case normal
        case emphasized
        case notAvailable
    }

    private let itemButton: UIButton = .init()

    private(set) var buttonState: State = .notAvailable
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        itemButton.isUserInteractionEnabled = false
        itemButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(itemButton)
        NSLayoutConstraint.activate([
            itemButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            itemButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            itemButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            itemButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public func setupView(
        title: String,
        fontSize: CGFloat = 13
    ) {
        itemButton.titleLabel?.font = .systemFont(ofSize: fontSize)
        itemButton.setTitle(title, for: .normal)
    }

    public func configureCell(state: State) {
        buttonState = state

        let isEnableItem = !(state == .notAvailable)
        backgroundColor = .systemBackground
        itemButton.setTitleColor(configureStyle(state: state), for: .normal)
        itemButton.isEnabled = isEnableItem
        
    }

    private func configureStyle(state: TTabViewCell.State) -> UIColor {
        switch state {
        case .normal:
            .systemGray
        case .emphasized:
            .orange
        case .notAvailable:
            .systemGray4
        }
    }
}

import UIKit

public struct TTabViewItem: Equatable {
    var isEnable: Bool
    let title: String
    
    public init(isEnable: Bool, title: String) {
        self.isEnable = isEnable
        self.title = title
    }
}

public protocol TTabViewDelegate: AnyObject {
    @MainActor
    func onTapPageItem(index: Int?)
}

public final class TTabView: UIView {
    public static let heightForTabView: CGFloat = 41.0

    public weak var delegate: TTabViewDelegate?

    private var pageTabItems: [TTabViewItem]
    private let pageTabItemsCount: Int
    private let parentViewWidth: CGFloat

    private var currentIndex: Int = 0
    private var cachedCellSizes: [IndexPath: CGSize] = [:]
    private var statusBar: UIView?
    private var statusBarLeadingConstraint: NSLayoutConstraint!
    private var statusBarWidthConstraint: NSLayoutConstraint!
    private var statusBarHeight: CGFloat = 4
    private var currentXPos: CGFloat = 0

    public init(items: [TTabViewItem], width: CGFloat) {
        pageTabItems = items
        pageTabItemsCount = items.count
        parentViewWidth = width
        super.init(frame: .zero)

        backgroundColor = .white

        setupCollectionView()
    }

    required init?(coder _: NSCoder) {
        pageTabItems = []
        pageTabItemsCount = 0
        parentViewWidth = 0
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var collectionView: UICollectionView = {
        let itemWidth = parentViewWidth / CGFloat(pageTabItemsCount)
        let itemSize = CGSize(
            width: itemWidth, height: TTabView.heightForTabView - statusBarHeight
        )
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = itemSize
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        let collectionView: UICollectionView = .init(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.isScrollEnabled = false
        collectionView.scrollsToTop = false
        collectionView.register(
            TTabViewCell.self,
            forCellWithReuseIdentifier: TTabViewCell.simpleClassName()
        )
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()

    private lazy var dataSource: UICollectionViewDiffableDataSource<TabSection, TabRow> = .init(
        collectionView: collectionView
    ) { [weak self] collectionView, indexPath, _ in
        let cell = collectionView.dequeueReusableCell(withType: TTabViewCell.self, for: indexPath)
        guard let self else {
            return cell
        }

        let fixedIndex = indexPath.item

        let item = self.pageTabItems[indexPath.item]
        let title = item.title
        let isCurrentIndex = self.currentIndex == indexPath.item
        let isEnable = item.isEnable
        let state: TTabViewCell.State

        if isEnable {
            state = isCurrentIndex ? .emphasized : .normal
        } else {
            state = .notAvailable
        }

        cell.setupView(title: title)
        cell.configureCell(state: state)

        return cell
    }

    private func setupCollectionView() {
        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: self.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            collectionView.heightAnchor.constraint(
                equalToConstant: TTabView.heightForTabView - statusBarHeight)
        ])
        collectionView.delegate = self
        collectionView.dataSource = dataSource

        var snapshot = dataSource.snapshot()
        snapshot.appendSections(TabSection.allCases)
        let tabRows: [TabRow] = pageTabItems.enumerated().map {
            TabRow.item($0.offset)
        }
        snapshot.appendItems(tabRows)
        dataSource.apply(snapshot)

        let itemWidth = parentViewWidth / CGFloat(pageTabItemsCount)
        let statusBar = createStatusBar()
        addSubview(statusBar)
        statusBarWidthConstraint = statusBar.widthAnchor.constraint(equalToConstant: itemWidth)
        statusBarWidthConstraint.isActive = true
        statusBarLeadingConstraint = statusBar.leadingAnchor.constraint(equalTo: self.leadingAnchor)
        statusBarLeadingConstraint.isActive = true
        NSLayoutConstraint.activate([
            statusBar.heightAnchor.constraint(equalToConstant: statusBarHeight),
            statusBar.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        self.statusBar = statusBar
    }

    fileprivate func createStatusBar() -> UIView {
        let view = UIView()
        view.backgroundColor = .orange
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    @MainActor
    public func updateTabViewItem(items: [TTabViewItem]) {
        guard !pageTabItems.isEmpty,
              pageTabItems != items
        else {
            return
        }

        for item in items {
            if let index = pageTabItems.firstIndex(where: { $0.title == item.title }) {
                pageTabItems[index].isEnable = item.isEnable
            }
        }
        var snapshot = dataSource.snapshot()
        snapshot.reconfigureItems(snapshot.itemIdentifiers)
        dataSource.apply(snapshot)
    }

    @MainActor
    public func updateCollectionViewUserInteractionEnabled(_ userInteractionEnabled: Bool) {
        collectionView.isUserInteractionEnabled = userInteractionEnabled
    }
}

extension TTabView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard pageTabItems[indexPath.item].isEnable else {
            return
        }

        if let cell = collectionView.cellForItem(at: indexPath) as? TTabViewCell,
           cell.buttonState != .emphasized {
            updateCollectionViewUserInteractionEnabled(false)
        }

        delegate?.onTapPageItem(index: indexPath.item)
    }
}

extension TTabView {
    @MainActor
    public func updateCurrentIndex(index: Int) {
        guard
            let beforeCell = collectionView.cellForItem(
                at: IndexPath(row: currentIndex, section: 0)) as? TTabViewCell,
            let nextCell = collectionView.cellForItem(at: IndexPath(row: index, section: 0))
            as? TTabViewCell
        else {
            return
        }

        currentIndex = index
        scrollStatusBar(row: index)

        let beforeCellNewState: TTabViewCell.State =
            beforeCell.buttonState == .notAvailable ? .notAvailable : .normal
        beforeCell.configureCell(state: beforeCellNewState)

        let nextCellNewState: TTabViewCell.State =
            nextCell.buttonState == .notAvailable ? .notAvailable : .emphasized
        nextCell.configureCell(state: nextCellNewState)
    }

    @MainActor
    private func scrollStatusBar(row: Int) {
        statusBarLeadingConstraint.constant =
            (frame.size.width / CGFloat(pageTabItemsCount)) * CGFloat(row)
        UIView.animate(
            withDuration: 0.2,
            animations: { [weak self] in
                self?.layoutIfNeeded()
            },
            completion: { [weak self] _ in
                self?.updateCollectionViewUserInteractionEnabled(true)
            }
        )
    }
}

extension TTabView {
    enum TabSection: CaseIterable {
        case tab
    }

    enum TabRow: Hashable {
        case item(Int)
    }
}

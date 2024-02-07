import UIKit

public protocol TTabPageDelegate: AnyObject {
    @MainActor
    func updatePageIndex(index: Int)

    @MainActor
    func updateCollectionViewUserInteractionEnabled(_ isEnable: Bool)
}

public struct TTabPageItem: Equatable {
    var isEnable: Bool
    let viewController: UIViewController
    
    public init(isEnable: Bool, viewController: UIViewController) {
        self.isEnable = isEnable
        self.viewController = viewController
    }
}

public class TTabPageController: UIPageViewController {
    public weak var tabPageDelegate: TTabPageDelegate?

    public var currentIndex: Int? {
        guard let viewController = viewControllers?.first else {
            return nil
        }
        return tabItems.firstIndex { $0.viewController == viewController }
    }

    private var currentIndexForSwipeGesture: Int = 0
    private var tabItems: [TTabPageItem] = []
    private var tabItemsCount: Int {
        tabItems.count
    }

    private var isAnimating: Bool = false

    public init(tabItems: [TTabPageItem]) {
        self.tabItems = tabItems
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }

    public required init?(coder _: NSCoder) {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        setupPageViewController()
        setupScrollView()
    }

    private func setupPageViewController() {
        dataSource = self
        delegate = self

        guard let firstVC = tabItems.first?.viewController else {
            return
        }

        isAnimating = true

        setViewControllers(
            [firstVC],
            direction: .forward,
            animated: false
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isAnimating = false
                self?.currentIndexForSwipeGesture = 0
            }
        }
    }

    private func setupScrollView() {
        guard let scrollView = view.subviews.compactMap({ $0 as? UIScrollView }).first else {
            return
        }

        scrollView.delegate = self
        scrollView.scrollsToTop = false
        scrollView.contentInsetAdjustmentBehavior = .never
    }

    @MainActor
    public func updateViewControllers(tabItems: [TTabPageItem]) {
        guard !self.tabItems.isEmpty,
              self.tabItems != tabItems
        else {
            return
        }
        for item in tabItems {
            if let targetItemIndex = self.tabItems.firstIndex(where: {
                $0.viewController == item.viewController
            }) {
                self.tabItems[targetItemIndex].isEnable = item.isEnable
            }
        }
    }

    @MainActor
    public func displayControllerWithIndex(
        _ index: Int,
        animated: Bool,
        scrollToTopHandler: ((Int) -> Void)? = nil,
        completion: @escaping () -> Void
    ) {
        guard let currentIndex,
              !isAnimating
        else {
            return
        }

        guard currentIndex != index else {
            scrollToTopHandler?(index)
            return
        }

        var direction: UIPageViewController.NavigationDirection = .forward
        if index < currentIndex {
            direction = .reverse
        }

        let nextViewControllers: [UIViewController] = [tabItems[index].viewController]

        let completionBlock: ((Bool) -> Void) = { [weak self] _ in
            Task { @MainActor in
                guard let self,
                      let targetViewControllers = self.viewControllers,
                      let targetViewController = targetViewControllers.last,
                      let index = self.tabItems.firstIndex(where: {
                          $0.viewController == targetViewController
                      })
                else {
                    return
                }

                self.currentIndexForSwipeGesture = index
                self.isAnimating = false
            }
        }

        isAnimating = true

        self.setViewControllers(
            nextViewControllers,
            direction: direction,
            animated: animated,
            completion: completionBlock
        )

        completion()

        guard isViewLoaded else {
            return
        }
        tabPageDelegate?.updatePageIndex(index: index)
    }
}

extension TTabPageController: UIPageViewControllerDelegate {
    public func pageViewController(_: UIPageViewController, willTransitionTo _: [UIViewController]) {
        tabPageDelegate?.updateCollectionViewUserInteractionEnabled(false)
        isAnimating = true
    }

    public func pageViewController(
        _ pageViewController: UIPageViewController, didFinishAnimating _: Bool,
        previousViewControllers _: [UIViewController], transitionCompleted _: Bool
    ) {
        if let currentIndex, currentIndex < tabItemsCount {
            tabPageDelegate?.updatePageIndex(index: currentIndex)
        }

        tabPageDelegate?.updateCollectionViewUserInteractionEnabled(true)

        isAnimating = false

        guard let targetViewControllers = pageViewController.viewControllers,
              let targetViewController = targetViewControllers.last,
              let index = tabItems.firstIndex(where: { $0.viewController == targetViewController })
        else {
            return
        }

        currentIndexForSwipeGesture = index
    }

    public func scrollViewDidEndScrollingAnimation(_: UIScrollView) {
        isAnimating = false
        tabPageDelegate?.updateCollectionViewUserInteractionEnabled(true)
    }
}

extension TTabPageController: UIPageViewControllerDataSource {
    private func getNeighborViewController(_ viewController: UIViewController, isNext: Bool)
        -> UIViewController? {
        let tabItems = tabItems.filter { $0.isEnable == true }
        guard var index = tabItems.firstIndex(where: { $0.viewController == viewController }) else {
            return nil
        }

        if isNext {
            index += 1
        } else {
            index -= 1
        }

        if index >= 0, index < tabItems.count {
            return tabItems[index].viewController
        }

        return nil
    }

    public func pageViewController(
        _: UIPageViewController, viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        getNeighborViewController(viewController, isNext: true)
    }

    public func pageViewController(
        _: UIPageViewController, viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        getNeighborViewController(viewController, isNext: false)
    }
}

extension TTabPageController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
        guard let currentViewController = viewControllers?.first,
              pageViewController(self, viewControllerBefore: currentViewController) == nil
        else {
            return false
        }

        return true
    }

    public func gestureRecognizer(
        _: UIGestureRecognizer, shouldBeRequiredToFailBy _: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

extension TTabPageController: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if currentIndexForSwipeGesture == 0,
           scrollView.contentOffset.x < scrollView.bounds.size.width {
            scrollView.contentOffset = CGPoint(x: scrollView.bounds.size.width, y: 0)
        } else if currentIndexForSwipeGesture == tabItems.count - 1,
                  scrollView.contentOffset.x > scrollView.bounds.size.width {
            scrollView.contentOffset = CGPoint(x: scrollView.bounds.size.width, y: 0)
        }
    }

    public func scrollViewWillEndDragging(
        _ scrollView: UIScrollView, withVelocity _: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        if currentIndexForSwipeGesture == 0,
           scrollView.contentOffset.x < scrollView.bounds.size.width {
            targetContentOffset.pointee = CGPoint(x: scrollView.bounds.size.width, y: 0)
        } else if currentIndexForSwipeGesture == tabItems.count - 1,
                  scrollView.contentOffset.x > scrollView.bounds.size.width {
            targetContentOffset.pointee = CGPoint(x: scrollView.bounds.size.width, y: 0)
        }
    }
}

//
//  ViewController.swift
//  Example
//
//  Created by minguk-kim on 2024/02/08.
//

import UIKit
import TTabPager

class ViewController: UIViewController {
    
    private var pageVC: TTabPageController?
    private var tabView: TTabView?
    
    private var sampleVC1: UIViewController = .init()
    private var sampleVC2: UIViewController = .init()
    private var sampleVC3: UIViewController = .init()
    private var sampleVC4: UIViewController = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView() {
        sampleVC1.view.backgroundColor = .white
        sampleVC2.view.backgroundColor = .red
        sampleVC3.view.backgroundColor = .blue
        sampleVC4.view.backgroundColor = .green
        
        let tabItems: [TTabViewItem] = [
            TTabViewItem(isEnable: true, title: "1番"),
            TTabViewItem(isEnable: true, title: "2番"),
            TTabViewItem(isEnable: false, title: "3番"),
            TTabViewItem(isEnable: true, title: "4番"),
        ]
        let tabView: TTabView = .init(items: tabItems, width: view.frame.size.width)
        self.tabView = tabView
        tabView.delegate = self
        view.addSubview(tabView)
        tabView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tabView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabView.heightAnchor.constraint(equalToConstant: TTabView.heightForTabView)
        ])
        
        let pageItems: [TTabPageItem] = [
            .init(isEnable: true, viewController: sampleVC1),
            .init(isEnable: true, viewController: sampleVC2),
            .init(isEnable: false, viewController: sampleVC3),
            .init(isEnable: true, viewController: sampleVC4),
        ]
        
        let pageVC: TTabPageController = .init(tabItems: pageItems)
        self.pageVC = pageVC
        pageVC.tabPageDelegate = self
        pageVC.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(pageVC)
        view.addSubview(pageVC.view)
        NSLayoutConstraint.activate([
            pageVC.view.topAnchor.constraint(equalTo: tabView.bottomAnchor),
            pageVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pageVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        pageVC.didMove(toParent: self)
    }
}

extension ViewController: TTabPageDelegate {
    func updatePageIndex(index: Int) {
        tabView?.updateCurrentIndex(index: index)
    }
    
    func updateCollectionViewUserInteractionEnabled(_ isEnable: Bool) {
        tabView?.updateCollectionViewUserInteractionEnabled(isEnable)
    }
}

extension ViewController: TTabViewDelegate {
    func onTapPageItem(index: Int?) {
        guard let index,
              let currentIndex = pageVC?.currentIndex else {
            return
        }

        pageVC?.displayControllerWithIndex(index, animated: true, completion: {})
    }
}

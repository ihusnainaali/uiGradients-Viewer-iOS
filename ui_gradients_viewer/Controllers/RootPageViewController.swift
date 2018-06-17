//
//  ViewController.swift
//  ui_gradients_viewer
//
//  Created by Alexander Murphy on 8/27/17.
//  Copyright © 2017 Alexander Murphy. All rights reserved.
//

import UIKit
import GradientView
import Pageboy
import Anchorage

class RootPageViewController: PageboyViewController, PageboyViewControllerDataSource, PageboyViewControllerDelegate {
    
    func pageboyViewController(_ pageboyViewController: PageboyViewController, didScrollToPageAt index: Int, direction: PageboyViewController.NavigationDirection, animated: Bool) {
        dispatch?.dispatch(.selectedGradient(index))
    }
    
    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return gradientVCs.count
    }
    
    func viewController(for pageboyViewController: PageboyViewController, at index: PageboyViewController.PageIndex) -> UIViewController? {
        return gradientVCs[index]
    }
    
    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return .at(index: startingIndex)
    }
    
    
    var startingIndex: Int = 0
    weak var dispatch: GradientActionDispatching?
    
    
    var gradientVCs = [GradientDetailViewController]() {
        didSet {
            DispatchQueue.main.async {
                self.reloadPages()
            }
        }
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.dataSource = self
        self.delegate = self
        
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 114, height: 18))
        imageView.image = #imageLiteral(resourceName: "uigradients")
        self.navigationItem.titleView = imageView
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = .clear
        self.navigationController?.navigationBar.backgroundColor = .clear
        
        
        let navItemImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        navItemImageView.image = #imageLiteral(resourceName: "hamburger_menu").withRenderingMode(.alwaysTemplate)
        navItemImageView.contentMode = .scaleAspectFit
        navItemImageView.tintColor = .white
        navItemImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didPressOpenMenu)))
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: navItemImageView)
    }
    
    @objc func didPressOpenMenu() {
        let select = UINavigationController(rootViewController: SelectGradientViewController())
        select.modalPresentationStyle = .overCurrentContext
        present(select, animated: true, completion: nil)
    }
    
    func didPressCreate() {
    }
}

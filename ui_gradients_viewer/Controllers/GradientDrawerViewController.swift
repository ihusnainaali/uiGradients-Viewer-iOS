import UIKit
import Anchorage
import Pulley
import GradientView
import GoogleMobileAds

final class GradientDrawerViewController: UIViewController {
    let cardView = GradientCardViewController()
    let header = DrawerHeaderView()
    let pager = PagerView()
    let customize = CustomizeGradientView()
    let export = ExportView()
    
    var gradients: [GradientColor] = [] {
        didSet {
            cardView.gradients = gradients
        }
    }
    
    var gradient: GradientColor? {
        didSet {
            if let gradient = gradient {
                update(gradient)
            }
        }
    }
    
    private func update(_ gradient: GradientColor) {
        header.gradient = gradient
        customize.gradient = gradient
        export.gradient = gradient
        
        guard
            let pulley = parent as? PulleyViewController,
            let selectedColor = gradient.colors.first(where: { $0.isSelected })?.color else {
                return
        }

        if selectedColor.isLight {
            UIView.animate(withDuration: 0.3) {
                pulley.drawerBackgroundVisualEffectView?.effect = UIBlurEffect(style: .dark)
                self.customize.colorPicker.hexLabel.textColor = .white
                self.customize.radius.titleLabel.textColor = .white
                self.customize.typeSegmented.titleLabel.textColor = .white
                self.customize.position.titleLabel.textColor = .white
                self.header.indicator.backgroundColor = .white
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                pulley.drawerBackgroundVisualEffectView?.effect = UIBlurEffect(style: .light)
                self.customize.colorPicker.hexLabel.textColor = .black
                self.customize.radius.titleLabel.textColor = .black
                self.customize.typeSegmented.titleLabel.textColor = .black
                self.customize.position.titleLabel.textColor = .black
                self.header.indicator.backgroundColor = .darkGray
            }
        }
    }
    
    weak var dispatch: GradientActionDispatching? {
        didSet {
            cardView.dispatcher = dispatch
            customize.dispatch = dispatch
            header.dispatch = dispatch
            export.dispatch = dispatch
            header.colorSection.dispatcher = dispatch
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        
        customize.colorPicker.delegate = self
        pager.pagerDatasource = self
        pager.pagerDelegate = self
        pager.collection.reloadData()
        
        export.banner.adUnitID = Obfuscator().reveal(key: ObfuscatedConstants.exportBannerId)
        export.banner.rootViewController = self
        export.banner.load(GADRequest())
        export.banner.delegate = self
        
        header.colorCollection.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongGesture(gesture:))))
        pulleyViewController?.topInset = 100
        
        let stack = UIStackView(arrangedSubviews: [header, pager])
        stack.spacing = 0
        stack.axis = .vertical
        view.addSubview(stack)
        view.backgroundColor = .clear
        stack.edgeAnchors == view.edgeAnchors
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 114, height: 18))
        imageView.image = #imageLiteral(resourceName: "uigradients")
        self.navigationItem.titleView = imageView
        self.navigationController?.navigationBar.barTintColor = .black
        
        let navItemImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        navItemImageView.image = #imageLiteral(resourceName: "close_menu").withRenderingMode(.alwaysTemplate)
        navItemImageView.contentMode = .scaleAspectFit
        navItemImageView.tintColor = .white
        navItemImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: navItemImageView)
        
        _ = GradientHelper.produceGradients { [weak self] (gradients) in
            self?.gradients = gradients
        }
        
        addChildViewController(cardView)
        cardView.didMove(toParentViewController: self)
    }
    
    @objc func close() {
        dismiss(animated: true, completion: nil)
    }
            

    @objc func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        switch(gesture.state) {
        case .began:
            guard let selectedIndexPath = header.colorCollection.indexPathForItem(at: gesture.location(in: header.colorCollection)) else {
                break
            }
            header.colorCollection.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            header.colorCollection.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case .ended:
            header.colorCollection.endInteractiveMovement()
        default:
            header.colorCollection.cancelInteractiveMovement()
        }
    }
}


extension GradientDrawerViewController: PulleyDrawerViewControllerDelegate {
    func supportedDrawerPositions() -> [PulleyPosition] {
        return [
            .collapsed,
            .partiallyRevealed,
            .open
        ]
    }
    
    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return bottomSafeArea + 100
    }
    
    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 260 + bottomSafeArea
    }
}

extension GradientDrawerViewController: ChromaColorPickerDelegate {
    func colorDidChange(_ colorPicker: ChromaColorPicker, color: UIColor) {
        guard
            let selectedIndex = header.colorCollection.indexPathsForSelectedItems?.first?.row,
            let gradient = gradient,
            color != gradient.colors[selectedIndex].color else {
                return
        }
        dispatch?.dispatch(.colorChange(identifier: gradient.colors[selectedIndex].identifier, newColor: color))
    }
    
    
    func colorPickerDidChooseColor(_ colorPicker: ChromaColorPicker, color: UIColor) {
        guard
            let selectedIndex = header.colorCollection.indexPathsForSelectedItems?.first?.row,
            let gradient = gradient else {
                return
        }
        dispatch?.dispatch(.colorChange(identifier: gradient.colors[selectedIndex].identifier, newColor: color))
    }
}


extension GradientDrawerViewController: PagerDelegate, PagerDatasource {
    func numberOfPages() -> Int {
        return 3
    }
    
    func pageForItem(at indexPath: IndexPath) -> UIView {
        switch indexPath.row {
        case 0: return customize
        case 1: return cardView.view
        default: return export
        }
    }
}


extension GradientDrawerViewController: GADBannerViewDelegate {
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("adViewDidReceiveAd")
    }
    
    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
                didFailToReceiveAdWithError error: GADRequestError) {
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("adViewWillPresentScreen")
    }
    
    /// Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("adViewWillDismissScreen")
    }
    
    /// Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("adViewDidDismissScreen")
    }
    
    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("adViewWillLeaveApplication")
    }
}

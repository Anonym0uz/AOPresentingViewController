import UIKit

class AOPresentationController: UIPresentationController {
    
    private var dismissHandler: () -> Void = {}

    // MARK: - Properties
    private var direction: PresentationDirection
    private var size: PresentationSize
    private var enableCloseByTap: Bool = true
    private var enableCloseByPan: Bool = true
    private var chevronIsVisible: Bool = true
    private var dimmingView: UIView!
    private var dimmyAlpha: CGFloat!
    private var roundCorners: UIRectCorner = .init()
    private var roundRadius: CGFloat = 0.0
    private var panGesture: UIPanGestureRecognizer!
    private var sliderView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.init(red: 191 / 255.0, green: 191 / 255.0, blue: 191 / 255.0, alpha: 1)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.clipsToBounds = true
        v.layer.cornerRadius = 6/2
        return v
    }()
    private var sliderWidthConstraint: NSLayoutConstraint!
    
    private var scrollView: UIScrollView?
    
    private var originView: CGPoint!
    private var originalSize: CGSize!
    
    init(presentedViewController: UIViewController,
         presenting presentingViewController: UIViewController?,
         direction: PresentationDirection,
         size: PresentationSize,
         dimmy: CGFloat,
         dismissHandler: @escaping () -> Void,
         closeByTap: Bool = true) {
        self.direction = direction
        self.size = size
        self.dismissHandler = dismissHandler
        self.enableCloseByTap = closeByTap
        self.dimmyAlpha = dimmy
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        
        setupDimmingView()
        
        checkScrollView()
    }
    
    func setRoundCorners(_ c: UIRectCorner, radius: CGFloat) {
        roundCorners = c
        roundRadius = radius
    }
    
    func setCloseByPan(_ b: Bool) {
        enableCloseByPan = b
    }
    
    func setChevronVisible(_ c: Bool) {
        chevronIsVisible = c
        
        sliderView.isHidden = (chevronIsVisible) ? false : true
    }
    
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        
        guard let dimmingView = dimmingView else {
            return
        }
        
        containerView?.insertSubview(dimmingView, at: 0)
        
        NSLayoutConstraint.activate([
            dimmingView.heightAnchor.constraint(equalTo: containerView!.heightAnchor),
            dimmingView.widthAnchor.constraint(equalTo: containerView!.widthAnchor)
        ])
        
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 1.0
            return
        }
        
        coordinator.animate { (_) in
            self.dimmingView.alpha = 1.0
        }
    }
    
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 0.0
            return
        }
        
        coordinator.animate { (_) in
            self.dimmingView.alpha = 0.0
        }
    }
    
    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        let path = UIBezierPath(roundedRect: presentedView!.bounds, byRoundingCorners: roundCorners, cornerRadii: CGSize(width: roundRadius, height: roundRadius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        presentedView?.layer.mask = (!roundCorners.isEmpty) ? mask : nil
        presentedView?.clipsToBounds = (!roundCorners.isEmpty) ? true : false
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
        originView = presentedView?.frame.origin
        originalSize = presentedView?.frame.size
    }
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        return getDirection(parentSize)
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        var frame: CGRect = .zero
        frame.size = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerView!.bounds.size)
        
        switch direction {
        case .right:
            frame.origin.x = containerView!.frame.width * (1.0/3.0)
        case .bottom:
            frame.origin.x = getFrame().x
            frame.origin.y = getFrame().y
        default:
            frame.origin = .zero
        }
        return frame
    }
}

// MARK: - Private
private extension AOPresentationController {
    @objc func handleGesture(_ gest: UIPanGestureRecognizer) {
        if gest.state == .began {
            originView = gest.view?.frame.origin
            originalSize = gest.view?.frame.size
        }
        if gest.state == .changed {
            let translation = gest.translation(in: gest.view)
            
//            gest.view!.frame.origin.y = (translation.y > 0) ?
//                originView.y + translation.y :
//                originView.y
            
            if !enableCloseByPan {
                if translation.y > 0 {
                    gest.view!.frame.origin.y = originView.y + (translation.y / 30)
                } else {
                    gest.view!.frame.origin.y = originView.y
                }
                return
            }
            
            print(translation.y)
            if translation.y > 0 {
                gest.view!.frame.origin.y = originView.y + translation.y
//                changeSlider(translation)
            } else {
                gest.view!.frame.origin.y = originView.y
                blockScroll(locked: false)
//                changeSlider(CGPoint(x: 0, y: 0))
            }
            dimmingView.backgroundColor = UIColor(white: 0.0, alpha: (translation.y / gest.view!.frame.size.height > 0) ?
                                                    dimmyAlpha - (abs(translation.y)) / (gest.view!.frame.size.height * 2) :
                                                    dimmyAlpha)
        }
        if gest.state == .ended {
            if (gest.view!.frame.origin.y >= presentedView!.frame.maxY / 1.7 || gest.velocity(in: gest.view).y >= 1000) && enableCloseByPan {
                presentingViewController.dismiss(animated: true, completion: dismissHandler)
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.presentedView?.frame.origin.y = self.originView.y
                    self.presentedView?.frame.size.width = self.originalSize.width
                    self.dimmingView.backgroundColor = UIColor(white: 0.0, alpha: self.dimmyAlpha)
                    self.changeSlider(nil)
                    self.blockScroll(locked: false)
                }
            }
        }
    }
    
    func changeSlider(_ translation: CGPoint?) {
        
        sliderView.constraints.forEach({ $0.isActive = ($0 == sliderWidthConstraint) ? false : true })
        
        sliderWidthConstraint = sliderView.widthAnchor.constraint(equalToConstant: (translation != nil) ? 45 + (abs(translation!.y)) : 45)
        
        sliderWidthConstraint.isActive = true
        
        containerView?.layoutIfNeeded()
    }
    
    func getDirection(_ parentSize: CGSize) -> CGSize {
        switch direction {
        case .left, .right:
            return CGSize(width: parentSize.width * (2.0/3.0), height: parentSize.height)
        case .bottom, .top:
            return getSize(parentSize)
        }
    }
    
    func getSize(_ parentSize: CGSize) -> CGSize {
        switch size {
        case .half:
            return CGSize(width: parentSize.width, height: parentSize.height / 2)
        case .full:
            return CGSize(width: parentSize.width, height: parentSize.height)
        case let .custom(x: _, y: _, width: width, height: height):
            return CGSize(width: (width == 0) ? parentSize.width : width,
                          height: (height == 0) ? parentSize.height : height)
        }
    }
    
    func getFrame() -> CGPoint {
        switch size {
        case .half:
            return CGPoint(x: 0, y: containerView!.frame.height * (2.0/4.0))
        case .full:
            return CGPoint(x: 0, y: containerView!.frame.height * (0.4/5.0))
        case let .custom(x: x, y: y, width: _, height: height):
//            guard let x = x, let y = y else { return CGPoint(x: containerView!.center.x - width / 2, y: containerView!.frame.maxY - height)  }
            guard let x = x, let y = y else { return CGPoint(x: 0, y: containerView!.frame.maxY - height)  }
            return CGPoint(x: x, y: y)
        }
    }
    
    func setupDimmingView() {
        dimmingView = UIView()
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        dimmingView.backgroundColor = UIColor(white: 0.0, alpha: dimmyAlpha)
        dimmingView.alpha = 0.0
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        (enableCloseByTap) ? dimmingView.addGestureRecognizer(recognizer) : nil
        presentedView?.addGestureRecognizer(panGesture)
        
        presentedView?.addSubview(sliderView)
        
        sliderView.topAnchor.constraint(equalTo: presentedView!.topAnchor, constant: 15).isActive = true
        sliderView.centerXAnchor.constraint(equalTo: presentedView!.centerXAnchor).isActive = true
        sliderView.heightAnchor.constraint(equalToConstant: 6).isActive = true
        sliderWidthConstraint = sliderView.widthAnchor.constraint(equalToConstant: 45)
        sliderWidthConstraint.isActive = true
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        presentingViewController.dismiss(animated: true, completion: dismissHandler)
    }
}

extension AOPresentationController: UIScrollViewDelegate {
    
    func checkScrollView() {
        presentedViewController.view.subviews.forEach({ ($0 is UIScrollView) ? self.scrollView = ($0 as! UIScrollView) : print("No scroll view") })
        if let scroll = scrollView { scroll.delegate = self; scroll.canCancelContentTouches = true }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= 0 {
            print("Scroll Y: \(scrollView.contentOffset.y)")
            if scrollView.isDragging {
                presentedView?.frame.origin.y = originView.y - (scrollView.contentOffset.y * 2)
            } else {
                if scrollView.contentOffset.y * 2 <= -130 {
                    handleTap(recognizer: UITapGestureRecognizer())
                }
            }
            
        } else {
            print("Scroll Y: \(scrollView.contentOffset.y)")
//            blockScroll(locked: false)
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.y < 0 {
            print("Scroll Y: \(scrollView.contentOffset.y)")
            if scrollView.contentOffset.y * 2 <= -130 {
//                handleTap(recognizer: UITapGestureRecognizer())
//                presentedView!.frame.origin.y = presentedView!.frame.maxY
            }
            
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y == 0 {
            print("Scroll Y: \(scrollView.contentOffset.y)")
        }
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 0 {
            print("Scroll Y: \(scrollView.contentOffset.y)")
        }
    }
    
    func blockScroll(locked: Bool = true) {
        if enableCloseByPan {
            if let scroll = scrollView {
                scroll.isScrollEnabled = !locked
            }
        }
    }
}
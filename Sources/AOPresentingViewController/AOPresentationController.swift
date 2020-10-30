import UIKit

class AOPresentationController: UIPresentationController {
    
    private var dismissHandler: () -> Void = {}

    // MARK: - Properties
    private var direction: PresentationDirection
    private var size: PresentationSize
    private var enableCloseByTap: Bool = true
    private var enableCloseByPan: Bool = true
    private var dimmingView: UIView!
    private var dimmyAlpha: CGFloat!
    private var roundCorners: UIRectCorner = .init()
    private var roundRadius: CGFloat = 0.0
    private var panGesture: UIPanGestureRecognizer!
    
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
    }
    
    func setRoundCorners(_ c: UIRectCorner, radius: CGFloat) {
        roundCorners = c
        roundRadius = radius
    }
    
    func setCloseByPan(_ b: Bool) {
        enableCloseByPan = b
        
        (!enableCloseByPan) ? presentedView?.removeGestureRecognizer(panGesture) : nil
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
            print(translation.y)
            if translation.y > 0 {
                gest.view!.frame.origin.y = originView.y + translation.y
            } else {
                gest.view!.frame.origin.y = originView.y
            }
            dimmingView.backgroundColor = UIColor(white: 0.0, alpha: ((originView.y + translation.y) / 1000 > dimmyAlpha) ?
                                                  (originView.y + translation.y) / 1000 :
                                                  dimmyAlpha)
        }
        if gest.state == .ended {
            if gest.view!.frame.origin.y >= presentedView!.frame.maxY / 1.7 {
                presentingViewController.dismiss(animated: true, completion: dismissHandler)
            } else {
                UIView.animate(withDuration: 0.5) {
                    self.presentedView?.frame.origin.y = self.originView.y
                    self.presentedView?.frame.size.width = self.originalSize.width
                    self.dimmingView.backgroundColor = UIColor(white: 0.0, alpha: self.dimmyAlpha)
                }
            }
        }
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
        (enableCloseByPan) ? presentedView?.addGestureRecognizer(panGesture) : presentedView?.removeGestureRecognizer(panGesture)
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        presentingViewController.dismiss(animated: true, completion: dismissHandler)
    }
}

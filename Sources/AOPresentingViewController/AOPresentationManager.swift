import UIKit

public enum PresentationDirection {
    case left
    case top
    case right
    case bottom
}

public enum PresentationSize {
    /**
     * Half screen size
     */
    case half
    /**
     * Full screen size
     */
    case full
    /**
     * Custom size with 4 CGFloat params (X, Y, Width, Height)
     */
    case custom(x: CGFloat? = nil, y: CGFloat? = nil, width: CGFloat = 0, height: CGFloat = 0)
}

public class AOPresentationManager: NSObject {
    public var direction: PresentationDirection = .left
    public var size: PresentationSize = .half
    public var dismissHandler: () -> Void = {}
    public var enableCloseByTap: Bool = true
    public var enableCloseByPan: Bool = true
    public var dimmyAlpha: CGFloat = 0.5
    public var roundCorners: UIRectCorner = .init()
    public var roundRadius: CGFloat = 0.0
    public var needNavigationBar: Bool = false
    public var showChevron: Bool = true
    public var fadeDismiss: Bool = false
    
    public func setDismissHandler(_ h: @escaping () -> Void) { dismissHandler = h }
}

// MARK: - UIViewControllerTransitioningDelegate
extension AOPresentationManager: UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentationController = AOPresentationController(presentedViewController: presented,
                                                              presenting: presenting,
                                                              direction: direction,
                                                              size: size,
                                                              dimmy: dimmyAlpha,
                                                              dismissHandler: dismissHandler,
                                                              closeByTap: enableCloseByTap)
        presentationController.setRoundCorners(roundCorners, radius: roundRadius)
        presentationController.setCloseByPan(enableCloseByPan)
        presentationController.setChevronVisible(showChevron)
        presentationController.setFadeDismiss(fadeDismiss)
        return presentationController
    }
    // MARK: - Custom presenting view controller
    public func customPresent(onView controller: UIViewController,
                       present: UIViewController,
                       transitioningDelegate: UIViewControllerTransitioningDelegate,
                       animated: Bool = true,
                       completeHandler: (() -> Void)? = nil) {
        present.transitioningDelegate = transitioningDelegate
        present.modalPresentationStyle = .custom
        controller.present(present, animated: animated, completion: completeHandler)
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AOPresentationAnimator(direction: direction, isPresentation: true)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AOPresentationAnimator(direction: direction, isPresentation: false)
    }
}

extension UIViewController {
    func customPresent(_ vc: UIViewController,
                       delegate: AOPresentationManager,
                       animated: Bool = true,
                       completeHandler: (() -> Void)? = nil) {
        vc.transitioningDelegate = delegate
        vc.modalPresentationStyle = .custom
        self.present(vc, animated: animated, completion: completeHandler)
    }
}

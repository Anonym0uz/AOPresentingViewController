import UIKit

enum PresentationDirection {
    case left
    case top
    case right
    case bottom
}

enum PresentationSize {
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

class AOPresentationManager: NSObject {
    var direction: PresentationDirection = .left
    var size: PresentationSize = .half
    var dismissHandler: () -> Void = {}
    var enableCloseByTap: Bool = true
    var enableCloseByPan: Bool = true
    var dimmyAlpha: CGFloat = 0.5
    var roundCorners: UIRectCorner = .init()
    var roundRadius: CGFloat = 0.0
    var needNavigationBar: Bool = false
    var showChevron: Bool = true
    
    func setDismissHandler(_ h: @escaping () -> Void) { dismissHandler = h }
}

// MARK: - UIViewControllerTransitioningDelegate
extension AOPresentationManager: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
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
        return presentationController
    }
    
    func customPresent(onView controller: UIViewController,
                       present: UIViewController,
                       transitioningDelegate: UIViewControllerTransitioningDelegate,
                       animated: Bool = true,
                       completeHandler: (() -> Void)? = nil) {
        present.transitioningDelegate = transitioningDelegate
        present.modalPresentationStyle = .custom
        controller.present(present, animated: animated, completion: completeHandler)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AOPresentationAnimator(direction: direction, isPresentation: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AOPresentationAnimator(direction: direction, isPresentation: false)
    }
}

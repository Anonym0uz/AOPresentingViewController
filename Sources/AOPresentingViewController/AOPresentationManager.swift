import UIKit

enum PresentationDirection {
    case left
    case top
    case right
    case bottom
}

enum PresentationSize {
    case half
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
    var dimmyAlpha: CGFloat = 0.5
    var roundCorners: UIRectCorner = .init()
    var roundRadius: CGFloat = 0.0
    
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
        return presentationController
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AOPresentationAnimator(direction: direction, isPresentation: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AOPresentationAnimator(direction: direction, isPresentation: false)
    }
}

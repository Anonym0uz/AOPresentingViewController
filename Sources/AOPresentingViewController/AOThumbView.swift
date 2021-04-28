//
//  AOThumbView.swift
//  
//
//  Created by Alexander Orlov on 28.04.2021.
//

import Foundation
import UIKit

open class AOThumbView : UIView {
    
    private let shapeLayer: CAShapeLayer = .init()
    
    public override init(frame: CGRect) {
        super.init(frame: .zero)
        layer.addSublayer(shapeLayer)
        translatesAutoresizingMaskIntoConstraints = false
        shapeLayer.fillColor = UIColor.lightGray.cgColor
    }
    
    open override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 3)
    }
    
    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        
        shapeLayer.frame = bounds
        shapeLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: .infinity).cgPath
    }
}

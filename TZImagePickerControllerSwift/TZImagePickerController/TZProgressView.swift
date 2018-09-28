//
//  TZProgressView.swift
//  TZImagePickerControllerSwift
//
//  Created by Huang.Tan on 2018/1/22.
//  Copyright © 2018年 Huang.Tan All rights reserved.
//

import UIKit

class TZProgressView: UIView {


    var progress: CGFloat? {
        didSet {
            setNeedsDisplay()
        }
    }

    private var progressLayer: CAShapeLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear

        progressLayer = CAShapeLayer()
        progressLayer?.fillColor = UIColor.clear.cgColor
        progressLayer?.strokeColor = UIColor.white.cgColor
        progressLayer?.opacity = 1
        progressLayer?.lineCap = CAShapeLayerLineCap.round
        progressLayer?.lineWidth = 5

        progressLayer?.shadowColor = UIColor.black.cgColor
        progressLayer?.shadowOffset = CGSize(width: 1, height: 1)
        progressLayer?.shadowOpacity = 0.5
        progressLayer?.shadowRadius = 2
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard self.progress != nil else {
            return
        }
        let center: CGPoint = CGPoint(x: rect.width * 0.5, y: rect.height * 0.5)
        let radius: CGFloat = rect.width * 0.5
        let startA: CGFloat = -CGFloat(Float.pi) * 0.5
        let endA: CGFloat = -CGFloat(Float.pi) * 0.5 + CGFloat(Float.pi) * 2 * self.progress!
        progressLayer?.frame = self.bounds
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startA, endAngle: endA, clockwise: true)
        progressLayer?.path = path.cgPath
        self.layer.addSublayer(progressLayer!)

    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}



class TZCollectionView: UICollectionView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        if view.isKind(of: UIControl.classForCoder()) {
            return true
        }
        return super.touchesShouldCancel(in: view)
    }


    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }

}









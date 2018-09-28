//
//  TZImageCropManager.swift
//  TZImagePickerControllerSwift
//
//  Created by Huang.Tan on 2018/1/22.
//  Copyright © 2018年 Huang.Tan All rights reserved.
//

import UIKit
import CoreGraphics

class TZImageCropManager: NSObject {

    /// 裁剪框背景的处理
    class func overlay(clippingWithView view: UIView?, cropRect: CGRect?, containerView: UIView?, needCircleCrop: Bool) {
        let path = UIBezierPath(rect: UIScreen.main.bounds)
        let layer = CAShapeLayer()
        if (needCircleCrop) { // 圆形裁剪框
            path.append(UIBezierPath(arcCenter: (containerView?.center)!, radius: (cropRect?.width)! * 0.5, startAngle: 0, endAngle: CGFloat(2 * Double.pi), clockwise: false))
        } else { // 矩形裁剪框
            path.append(UIBezierPath(rect: UIScreen.main.bounds))
        }
        layer.path = path.cgPath;
        layer.fillRule = CAShapeLayerFillRule.evenOdd;
        layer.fillColor = UIColor.black.cgColor
        layer.opacity = 0.5;
        view?.layer.addSublayer(layer)
    }

    /*
     1.7.2 为了解决多位同学对于图片裁剪的需求，我这两天有空便在研究图片裁剪
     幸好有tuyou的PhotoTweaks库做参考，裁剪的功能实现起来简单许多
     该方法和其内部引用的方法基本来自于tuyou的PhotoTweaks库，我做了稍许删减和修改
     感谢tuyou同学在github开源了优秀的裁剪库PhotoTweaks，表示感谢
     PhotoTweaks库的github链接：https://github.com/itouch2/PhotoTweaks
     */
    /// 获得裁剪后的图片
    class func crop(imageView: UIImageView?, rect: CGRect?, zoomScale: Double?, containerView: UIView?) -> UIImage? {
        var transform = CGAffineTransform.identity
        // 平移的处理
        let imageViewRect = imageView?.convert((imageView?.bounds)!, to: containerView)
        let point = CGPoint(x: (imageViewRect?.origin.x)! + (imageViewRect?.size.width)! / 2, y: (imageViewRect?.origin.y)! + (imageViewRect?.size.height)! / 2);
        let xMargin = (containerView?.frame.width)! - (rect?.maxX)! - (rect?.origin.x)!
        let zeroPoint = CGPoint(x: ((containerView?.frame.width)! - xMargin) / 2, y: (containerView?.center.y)!);
        let translation = CGPoint(x: point.x - zeroPoint.x, y: point.y - zeroPoint.y);
        transform = transform.translatedBy(x: translation.x, y: translation.y)
        // 缩放的处理
        transform = transform.scaledBy(x: CGFloat(zoomScale!), y: CGFloat(zoomScale!))

        let imageRef = self.newTransformed(transform: transform, sourceImage: imageView?.image?.cgImage, sourceSize: imageView?.image?.size, outputWidth: (rect?.size.width)! * UIScreen.main.scale, cropSize: rect?.size, imageViewSize: imageView?.frame.size)
        var cropedImage = UIImage(cgImage: imageRef!)
        cropedImage = TZImageManager.manager.fixOrientation(cropedImage)
        return cropedImage;
    }

    class func newTransformed(transform: CGAffineTransform?, sourceImage: CGImage?, sourceSize: CGSize?, outputWidth: CGFloat?, cropSize: CGSize?, imageViewSize: CGSize?) -> CGImage? {
        let source = self.newScaledImage(source: sourceImage, to: sourceSize)
        let aspect = (cropSize?.height)! / (cropSize?.width)!
        let outputSize = CGSize(width: outputWidth!, height: outputWidth! * aspect)

        let context = CGContext(data: nil, width: Int(outputSize.width), height: Int(outputSize.height), bitsPerComponent: (source?.bitsPerComponent)!, bytesPerRow: 0, space: (source?.colorSpace)!, bitmapInfo: (source?.bitmapInfo.rawValue)!)
        context?.setFillColor(UIColor.clear.cgColor)
        context?.fill(CGRect(x: 0, y: 0, width: outputSize.width, height: outputSize.height))

        var uiCoords = CGAffineTransform(scaleX: outputSize.width / (cropSize?.width)!, y: outputSize.height / (cropSize?.height)!)
        uiCoords = uiCoords.translatedBy(x: (cropSize?.width)! / 2.0, y: (cropSize?.height)! / 2.0)
        uiCoords = uiCoords.scaledBy(x: 1.0, y: -1.0)
        context?.concatenate(uiCoords)
        context?.concatenate(transform!)
        context?.scaleBy(x: 1.0, y: -1.0)

        context?.draw(source!, in: CGRect(x: -(imageViewSize?.width)! / 2, y: -(imageViewSize?.height)! / 2.0, width: (imageViewSize?.width)!, height: (imageViewSize?.height)!))
        let resultRef = context?.makeImage()
        return resultRef;
    }

    class func newScaledImage(source: CGImage?, to size: CGSize?) -> CGImage? {
        guard let srcSize = size  else {
            return source
        }
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        let context = CGContext(data: nil, width: Int(srcSize.width), height: Int(srcSize.height), bitsPerComponent: 8, bytesPerRow: 0, space: rgbColorSpace, bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue).rawValue)
        context?.interpolationQuality = .none
        context?.translateBy(x: srcSize.width * 0.5, y: srcSize.height * 0.5)
        context?.draw(source!, in: CGRect(x: -srcSize.width/2, y: -srcSize.height/2, width: srcSize.width, height: srcSize.height))
        let resultRef = context?.makeImage()
        return resultRef;
    }

    /// 获取圆形图片
    class func circular(clipImage image: UIImage?) -> UIImage? {

        UIGraphicsBeginImageContextWithOptions(image!.size, false, UIScreen.main.scale)

        let ctx = UIGraphicsGetCurrentContext();
        let rect = CGRect(x: 0, y: 0, width: (image?.size.width)!, height: (image?.size.height)!);
        ctx?.addEllipse(in: rect)
        ctx?.clip()
        image?.draw(in: rect)

        let circleImage = UIGraphicsGetImageFromCurrentImageContext();

        UIGraphicsEndImageContext();
        return circleImage;
    }


}

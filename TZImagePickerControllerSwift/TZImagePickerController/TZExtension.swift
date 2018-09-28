//
//  TZExtension.swift
//  TZImagePickerControllerSwift
//
//  Created by Huang.Tan on 2018/1/10.
//  Copyright © 2018年 Huang.Tan All rights reserved.
//

import Foundation
import UIKit.UIView

var bundle: Bundle?

public extension Bundle {

    class func TZ_isGlobalHideStatusBar() -> Bool {
        return (Bundle.main.object(forInfoDictionaryKey: "UIStatusBarHidden") as? Bool) ?? false
    }

    class func tz_imagePickerBundle() -> Bundle {
        let bundle = Bundle(for: TZImagePickerController.classForCoder())
        let url = bundle.url(forResource: "TZImagePickerController", withExtension: "bundle")
        return Bundle(url: url!)!
    }

    class func tz_localizedString(forKey key: String, value: String) -> String {

        if bundle == nil {
            var language = NSLocale.preferredLanguages.first
            if language?.range(of: "zh-Hans") != nil {
                language = "zh-Hans"
            } else {
                language = "en"
            }
            bundle = Bundle(path: self.tz_imagePickerBundle().path(forResource: language, ofType: "lproj")!)
        }
        return (bundle?.localizedString(forKey: key, value: value, table: nil))!
    }

    class func tz_localizedString(forKey key: String) -> String {
        return self.tz_localizedString(forKey: key, value: "")
    }
}

enum TZOscillatoryAnimationType {
    case bigger
    case smaller
}

extension UIView {
    class func showOscillatoryAnimationWithLayer(layer: CALayer, type: TZOscillatoryAnimationType) {

        let animationScale1 = type == .bigger ? NSNumber(value: 1.15) : NSNumber(value: 0.5)
        let animationScale2 = type == .bigger ? NSNumber(value: 0.92) : NSNumber(value: 1.15)

        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.duration = 0.15
        animation.fromValue = animationScale1
        animation.toValue = animationScale2
        animation.autoreverses = true
        layer.add(animation, forKey: "scale-layer")
    }
}

public extension String {
    func tz_containsString(string: String) -> Bool {
        return self.contains(string)
    }
}

public extension UIImage {
    class func imageNamedFromMyBundle(name: String) -> UIImage? {
        let imageBundle = Bundle.tz_imagePickerBundle()
        var newname = name
        newname.append("@2x")
        let imagePath = imageBundle.path(forResource: newname, ofType: "png")
        let image = UIImage(contentsOfFile: imagePath ?? name)

        if image != nil {
            return image
        }
        return UIImage(named: newname.replacingOccurrences(of: "@2x", with: ""))
    }

    class func sd_tz_animated(GIFWithData data: Data?) -> UIImage? {
        guard let tz_data = data else {
            return nil
        }

        let source = CGImageSourceCreateWithData(tz_data as CFData, nil)
        let count = CGImageSourceGetCount(source!)
        var animatedImage: UIImage?
        if count <= 1 {
            animatedImage = UIImage(data: tz_data)
        } else {
            var images = [UIImage]()
            var duration: Float = 0.0
            for i in 0..<count {
                let image = CGImageSourceCreateImageAtIndex(source!, i, nil)
                if image == nil { continue }

                duration += self.sd_frame(durationAtIndex: i, source: source)

                images.append(UIImage(cgImage: image!, scale: UIScreen.main.scale, orientation: UIImage.Orientation.up))

            }
            if duration == 0 {
                duration = Float(0.1 * Float(count))
            }

            animatedImage = UIImage.animatedImage(with: images, duration: TimeInterval(duration))
        }
        return animatedImage
    }

    class func sd_frame(durationAtIndex index: Int?, source: CGImageSource?) -> Float {
        var frameDuration: Float = 0.1
        guard index != nil, source != nil else {
            return frameDuration
        }
        let cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source!, index!, nil)
        if let frameProperties = cfFrameProperties as Dictionary? {
            let gifProperties = frameProperties[kCGImagePropertyGIFDictionary]
            let delayTimeUnclampedProp = gifProperties![kCGImagePropertyGIFUnclampedDelayTime]
            if delayTimeUnclampedProp != nil {
                frameDuration = delayTimeUnclampedProp as! Float
            } else {
                let delayTimeProp = gifProperties![kCGImagePropertyGIFDelayTime]
                if delayTimeProp != nil {
                    frameDuration = delayTimeProp as! Float
                }
            }
        }

        if frameDuration < 0.011 {
            frameDuration = 0.1
        }

        return frameDuration
    }

}


public extension Double {

    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}







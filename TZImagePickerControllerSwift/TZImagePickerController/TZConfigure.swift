//
//  TZConfigure.swift
//  TZImagePickerControllerSwift
//
//  Created by 希达 on 2018/1/9.
//  Copyright © 2018年 Tan.huang. All rights reserved.
//

import UIKit.UIDevice
import Foundation.NSBundle


let TZ_isGlobalHideStatusBar = Bundle.main.object(forInfoDictionaryKey: "UIStatusBarHidden")

/// 根据RGBA生成颜色(格式为：22,22,22,0.5)
var gof_RGBAColor: (CGFloat, CGFloat, CGFloat, CGFloat) -> UIColor = {red, green, blue, alpha in
    return UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha);
}


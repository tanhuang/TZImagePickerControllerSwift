
# TZImagePickerControllerSwift
TZImagePickerControllerSwift版

![](https://img.shields.io/badge/pod-1.0.0-blue.svg)
![](https://img.shields.io/badge/swift-4X-orange.svg)

模仿TZImagePickerController写的Swift版本，接触不久，写的不好请见谅，我会持续更新的。用法基本和OC一样

![Objcetive-C版](https://github.com/banchichen/TZImagePickerController)

![](https://github.com/tanhuang/TZImagePickerControllerSwift/blob/master/2018-03-23%2010_36_28.gif)


一. Installation 安装
===
CocoaPods

    pod 'TZImagePickerControllerSwift'

手动安装

    将TZImagePickerController文件夹拽入项目中
    
二. Example 例子
===
```
        let imagePickerVc = TZImagePickerController(delegate: self, maxImagesCount: Int(self.maxCountTF.text!)!, columnNumber: Int(self.columnNumberTF.text!)!, pushPhotoPickerVc: true)

        //TODO: - 五类个性化设置，这些参数都可以不传，此时会走默认设置
        imagePickerVc.isSelectOriginalPhoto = _isSelectOriginalPhoto

        if Int(self.maxCountTF.text!)! > 1 {
            // 1.设置目前已经选中的图片数组
            imagePickerVc.selectedAssets = selectedAssets // 目前已经选中的图片数组
        }
        imagePickerVc.allowTakePicture = self.showTakePhotoBtnSwitch.isOn; // 在内部显示拍照按钮

        // imagePickerVc.photoWidth = 1000;

        // 2. Set the appearance
        // 2. 在这里设置imagePickerVc的外观
        // imagePickerVc.navigationBar.barTintColor = [UIColor greenColor];
        // imagePickerVc.oKButtonTitleColorDisabled = [UIColor lightGrayColor];
        // imagePickerVc.oKButtonTitleColorNormal = [UIColor greenColor];
        // imagePickerVc.navigationBar.translucent = NO;

        // 3. Set allow picking video & photo & originalPhoto or not
        // 3. 设置是否可以选择视频/图片/原图
        imagePickerVc.allowPickingVideo = self.allowPickingVideoSwitch.isOn;
        imagePickerVc.allowPickingImage = self.allowPickingImageSwitch.isOn;
        imagePickerVc.allowPickingOriginalPhoto = self.allowPickingOriginalPhotoSwitch.isOn;
        imagePickerVc.allowPickingGif = self.allowPickingGifSwitch.isOn;
        imagePickerVc.allowPickingMultipleVideo = self.allowPickingMuitlpleVideoSwitch.isOn; // 是否可以多选视频

        // 4. 照片排列按修改时间升序
        imagePickerVc.sortAscendingByModificationDate = self.sortAscendingSwitch.isOn;

        // imagePickerVc.minImagesCount = 3;
        // imagePickerVc.alwaysEnableDoneBtn = YES;

        // imagePickerVc.minPhotoWidthSelectable = 3000;
        // imagePickerVc.minPhotoHeightSelectable = 2000;

        /// 5. Single selection mode, valid when maxImagesCount = 1
        /// 5. 单选模式,maxImagesCount为1时才生效
        imagePickerVc.showSelectBtn = false
        imagePickerVc.allowCrop = self.allowCropSwitch.isOn
        imagePickerVc.needCircleCrop = self.needCircleCropSwitch.isOn
        // 设置竖屏下的裁剪尺寸
        let left: CGFloat = 30;
        let widthHeight: CGFloat = self.view.frame.width - 2 * left
        let top: CGFloat = (self.view.frame.height - widthHeight) / 2
        imagePickerVc.cropRect = CGRect(x: left, y: top, width: widthHeight, height: widthHeight)
        // 设置横屏下的裁剪尺寸
        // imagePickerVc.cropRectLandscape = CGRectMake((self.view.tz_height - widthHeight) / 2, left, widthHeight, widthHeight);
        /*
         [imagePickerVc setCropViewSettingBlock:^(UIView *cropView) {
         cropView.layer.borderColor = [UIColor redColor].CGColor;
         cropView.layer.borderWidth = 2.0;
         }];*/

        //imagePickerVc.allowPreview = NO;
        // 自定义导航栏上的返回按钮
        /*
         [imagePickerVc setNavLeftBarButtonSettingBlock:^(UIButton *leftButton){
         [leftButton setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
         [leftButton setImageEdgeInsets:UIEdgeInsetsMake(0, -20, 0, 20)];
         }];
         imagePickerVc.delegate = self;
         */

        imagePickerVc.isStatusBarDefault = false
        //TODO: - 到这里为止

        // You can get the photos by block, the same as by delegate.
        // 你可以通过block或者代理，来得到用户选择的照片.
        imagePickerVc.didFinishPickingPhotosWithInfosHandle = { (photos, assets, isSelectOriginalPhoto, infoArr) -> (Void) in

            debugPrint("\(photos.count) ---\(assets.count) ---- \(isSelectOriginalPhoto) --- \((infoArr?.count)!)")
        }
        
        self.present(imagePickerVc, animated: true, completion: nil)
```

三. Requirements 要求
===
 iOS8及以上系统可使用. ARC环境. Swift4
=======



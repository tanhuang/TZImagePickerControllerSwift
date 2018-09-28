//
//  ViewController.swift
//  TZImagePickerControllerSwift
//
//  Created by Huang.Tan on 2018/1/3.
//  Copyright © 2018年 Huang.Tan All rights reserved.
//

import UIKit
import Photos



class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, LxGridViewDataSource, LxGridViewDelegateFlowLayout {
    //MARK: - IBOutlet
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var showTakePhotoBtnSwitch: UISwitch!
    @IBOutlet weak var sortAscendingSwitch: UISwitch!
    @IBOutlet weak var allowPickingVideoSwitch: UISwitch!
    @IBOutlet weak var allowPickingImageSwitch: UISwitch!
    @IBOutlet weak var allowPickingGifSwitch: UISwitch!
    @IBOutlet weak var allowPickingOriginalPhotoSwitch: UISwitch!
    @IBOutlet weak var showSheetSwitch: UISwitch!
    @IBOutlet weak var maxCountTF: UITextField!
    @IBOutlet weak var columnNumberTF: UITextField!
    @IBOutlet weak var allowCropSwitch: UISwitch!
    @IBOutlet weak var needCircleCropSwitch: UISwitch!
    @IBOutlet weak var allowPickingMuitlpleVideoSwitch: UISwitch!


    var _isSelectOriginalPhoto: Bool = false

    var _itemWH: CGFloat = 0
    var _margin: CGFloat = 0

    var layout: LxGridViewFlowLayout?
    var location: CLLocation?

    //MARK: - 
    lazy var collectionView: UICollectionView = {
        let margin: CGFloat = 4

        let width = view.frame.width - 2 * margin - 4
        var itemWH: CGFloat = width / 3 - margin
        let flowlayout = UICollectionViewFlowLayout()
        flowlayout.itemSize = CGSize(width: itemWH, height: itemWH)
        flowlayout.minimumInteritemSpacing = margin
        flowlayout.minimumLineSpacing = margin
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowlayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor(red: 244 / 255.0, green: 244 / 255.0, blue: 244 / 255.0, alpha: 1)

        collectionView.register(TZTestCell.classForCoder(), forCellWithReuseIdentifier: "TZTestCell")
        return collectionView
    }()

    lazy var imagePickerVC: UIImagePickerController = {
        let imagePickerVC = UIImagePickerController()
        imagePickerVC.delegate = self
        imagePickerVC.navigationBar.barTintColor = self.navigationController?.navigationBar.barTintColor
        imagePickerVC.navigationBar.tintColor = self.navigationController?.navigationBar.tintColor
        let tzBarItem: UIBarButtonItem?, BarItem: UIBarButtonItem?
        if #available(iOS 9.0, *) {
            tzBarItem = UIBarButtonItem.appearance(whenContainedInInstancesOf: [TZImagePickerController.classForCoder() as! UIAppearanceContainer.Type])
            BarItem = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIImagePickerController.classForCoder() as! UIAppearanceContainer.Type])
        } else {
            tzBarItem = UIBarButtonItem.appearance()
            BarItem = UIBarButtonItem.appearance()
        }
        let titleTextAttributes = tzBarItem?.titleTextAttributes(for: .normal)
        BarItem?.setTitleTextAttributes(titleTextAttributes ?? nil, for: .normal)
        return imagePickerVC
    }()



    var selectedPhotos = [UIImage]()
    var selectedAssets = [PHAsset]()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white

        configCollectionView()

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let contentSizeH: CGFloat = 12 * 35 + 20
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            self.scrollView.contentSize = CGSize(width: 0, height: contentSizeH + 5)
        }
        let width = self.view.frame.width - 2 * _margin - 4
        _margin = 4
        _itemWH = width / 3 - _margin
        layout?.itemSize = CGSize(width: _itemWH, height: _itemWH)
        layout?.minimumInteritemSpacing = _margin
        layout?.minimumLineSpacing = _margin
        self.collectionView.setCollectionViewLayout(layout!, animated: false)
        self.collectionView.frame = CGRect(x: 0, y: contentSizeH, width: self.view.frame.width, height: self.view.frame.height - contentSizeH);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func configCollectionView() {
        // 如不需要长按排序效果，将LxGridViewFlowLayout类改成UICollectionViewFlowLayout即可
        layout = LxGridViewFlowLayout()
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout!)
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = UIColor(red: 244 / 255.0, green: 244 / 255.0, blue: 244 / 255.0, alpha: 1)

        collectionView.contentInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4);
        collectionView.dataSource = self;
        collectionView.delegate = self;
        collectionView.keyboardDismissMode = .onDrag
        self.view.addSubview(collectionView)
        collectionView.register(TZTestCell.classForCoder(), forCellWithReuseIdentifier: "TZTestCell")
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.selectedPhotos.count + 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TZTestCell", for: indexPath) as! TZTestCell
        cell.videoImageView?.isHidden = true
        if indexPath.row == selectedPhotos.count {
            let image = UIImage(named: "AlbumAddBtn")
            cell.imageView?.image = image
            cell.deleteBtn?.isHidden = true;
            cell.gifLable?.isHidden = true;
        } else {
            cell.imageView?.image = selectedPhotos[indexPath.row];
            cell.asset = selectedAssets[indexPath.row];
            cell.deleteBtn?.isHidden = false;
        }
        if (!self.allowPickingGifSwitch.isOn) {
            cell.gifLable?.isHidden = true;
        }
        cell.deleteBtn?.tag = indexPath.row;
        cell.deleteBtn?.addTarget(self, action: #selector(deleteBtnClick(_:)), for: .touchUpInside)
        return cell;
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == selectedPhotos.count {
            let showSheet = self.showSheetSwitch.isOn
            if (showSheet) {
                let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alertVC.addAction(UIAlertAction(title: "拍照", style: .default, handler: { (action) in
                    self.takePhoto()
                }))
                alertVC.addAction(UIAlertAction(title: "去相册选择", style: .default, handler: { (action) in
                    self.pushTZImagePickerController()
                }))
                alertVC.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                self.present(alertVC, animated: true, completion: nil)
            } else {
                self.pushTZImagePickerController()
            }
        } else { // preview photos or video / 预览照片或者视频
            let asset = selectedAssets[indexPath.row];
            let isVideo = asset.mediaType == .video
            if (asset.value(forKey: "filename") as! String).tz_containsString(string: "GIF") && self.allowPickingGifSwitch.isOn && !self.allowPickingMuitlpleVideoSwitch.isOn {
                let vc = TZGifPhotoPreviewController()
                vc.model = TZAssetModel(asset: asset, type: .photoGif, isSelected: false, timeLength: "0");
                self.present(vc, animated: true, completion: nil)
            } else if isVideo && !self.allowPickingMuitlpleVideoSwitch.isOn { // perview video / 预览视频
                let vc = TZVideoPlayerController()
                vc.model = TZAssetModel(asset: asset, type: .video, isSelected: false, timeLength: "0")
                self.present(vc, animated: true, completion: nil)
            } else { // preview photos / 预览照片
                let imagePickerVc = TZImagePickerController(selectedAssets: selectedAssets, selectedPhotos: selectedPhotos, index: indexPath.row)
                imagePickerVc.maxImagesCount = Int(self.maxCountTF.text!)!
                imagePickerVc.allowPickingGif = self.allowPickingGifSwitch.isOn;
                imagePickerVc.allowPickingOriginalPhoto = self.allowPickingOriginalPhotoSwitch.isOn;
                imagePickerVc.allowPickingMultipleVideo = self.allowPickingMuitlpleVideoSwitch.isOn;
                imagePickerVc.isSelectOriginalPhoto = _isSelectOriginalPhoto
                imagePickerVc.didFinishPickingPhotosWithInfosHandle = {[weak self] (photos, assets, isSelectOriginalPhoto, infoArr) -> (Void) in
                    self?.selectedPhotos = photos
                    self?.selectedAssets = assets
                    self?.collectionView.reloadData()
                    self?._isSelectOriginalPhoto = isSelectOriginalPhoto
                    let margin = (self?._margin)! + (self?._itemWH)!
                    let height = CGFloat((self?.selectedPhotos.count)! + 2) / 3  * margin
                    self?.collectionView.contentSize = CGSize(width: 0, height: height)

                }

                self.present(imagePickerVc, animated: true, completion: nil)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        if indexPath.isEmpty {
            return false
        }
        return indexPath.item < selectedPhotos.count
    }

    func collectionView(collectionView: UICollectionView, itemAtIndexPath sourceIndexPath: IndexPath, didMoveToIndexPath destinationIndexPath: IndexPath) {
        let image = selectedPhotos[sourceIndexPath.item]
        selectedPhotos.remove(at: sourceIndexPath.item)
        selectedPhotos.insert(image, at: destinationIndexPath.item)


        let asset = selectedAssets[sourceIndexPath.item]
        selectedAssets.remove(at: sourceIndexPath.item)
        selectedAssets.insert(asset, at: destinationIndexPath.item)

        collectionView.reloadData()
    }


    func collectionView(collectionView: UICollectionView, itemAtIndexPath sourceIndexPath: IndexPath, canMoveToIndexPath destinationIndexPath: IndexPath) -> Bool {
        return sourceIndexPath.item < selectedPhotos.count && destinationIndexPath.item < selectedPhotos.count
    }


    func pushTZImagePickerController() {
        if Int(self.maxCountTF.text!)! <= 0 {
            return
        }
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
//         imagePickerVc.navigationBar.barTintColor = UIColor.green
//         imagePickerVc.oKButtonTitleColorDisabled = UIColor.lightGray
//         imagePickerVc.oKButtonTitleColorNormal = UIColor.green
//         imagePickerVc.navigationBar.isTranslucent = false

//        imagePickerVc.photoOriginDefImageName = "photo_delete"
//        imagePickerVc.photoOriginSelImageName = "back"
//        imagePickerVc.previewBtnTitleDefColor = UIColor.red
//        imagePickerVc.previewBtnTitleDisColor = UIColor.blue
        // 相片选择器底部ToolBar背景色
//        imagePickerVc.photoPickerBottomToolBarBgColor = UIColor.lightGray

//        imagePickerVc.naviTitleFont = UIFont.systemFont(ofSize: 40)
//        imagePickerVc.naviTitleColor = UIColor.red
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

            debugPrint("\(photos.count) ---\(assets.count) ---- \(isSelectOriginalPhoto) --- \(String(describing: infoArr))")
        }
        
        self.present(imagePickerVc, animated: true, completion: nil)
    }

    func takePhoto() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authStatus == .restricted || authStatus == .denied {
            // 无相机权限 做一个友好的提示
            let alertVC = UIAlertController(title: "无法使用相机", message: "请在iPhone的\"设置-隐私-相机\"中允许访问相机", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "设置", style: .default, handler: { (action) in
                UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
            }))
            alertVC.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            self.present(alertVC, animated: true, completion: nil)
        } else if authStatus == .notDetermined {
            // fix issue 466, 防止用户首次拍照拒绝授权时相机页黑屏
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if granted {
                    DispatchQueue.main.async {
                        self.takePhoto()
                    }
                }
            }
            // 拍照之前还需要检查相册权限
        } else if TZImageManager.authorizationStatus() == 2 { // 已被拒绝，没有相册权限，将无法保存拍的照片
            // 无相机权限 做一个友好的提示
            let alertVC = UIAlertController(title: "无法使用相机", message: "请在iPhone的\"设置-隐私-相机\"中允许访问相机", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "设置", style: .default, handler: { (action) in
                UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
            }))
            alertVC.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            self.present(alertVC, animated: true, completion: nil)
        } else if TZImageManager.authorizationStatus() == 0 { // 未请求过相册权限
            TZImageManager.manager.requestAuthorizationWithCompletion {
                self.takePhoto()
            }
        } else {
            pushImagePickerController()
        }
    }
    
    // 调用相机
    func pushImagePickerController() {
        // 提前定位placemark
        TZLocationManager.manager.startLocation(successBlock: { (location1, location2) -> (Void) in
            self.location = location1
        }, failureBlock: { (error) -> (Void) in
            self.location = nil
        }, geocoderBlock:{ (placemark) -> (Void) in
            
        })
        
        let sourceType = UIImagePickerController.SourceType.camera
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            self.imagePickerVC.sourceType = sourceType
            self.imagePickerVC.modalPresentationStyle = .overCurrentContext
            present(self.imagePickerVC, animated: true, completion: nil)
        } else {
            print("模拟器中无法打开照相机,请在真机中使用")
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let type = info[.mediaType] as? String else { return }
        if type == "public.image" {
            let tzImagePickerVc = TZImagePickerController(delegate: self, maxImagesCount: 1)
            tzImagePickerVc.sortAscendingByModificationDate = self.sortAscendingSwitch.isOn
            tzImagePickerVc.showProgressHUD()
            
            guard let image = info[.originalImage] as? UIImage else {
                tzImagePickerVc.hideProgressHUD()
                debugPrint("image is nil")
                return
            }
            // save photo and get asset / 保存图片，获取到asset
            TZImageManager.manager.savePhotoWithImage(with: image, location: self.location, completion: { (error) -> (Void) in
                if let error_save = error {
                    tzImagePickerVc.hideProgressHUD()
                    debugPrint("save error \(error_save.localizedDescription)")
                    return
                }

                TZImageManager.manager.getCameraRollAlbum(allowPickingVideo: false, allowPickingImage: true, completion: { (model) in
                    TZImageManager.manager.getAssets(assetsFromFetchResult: model.result!, allowPickingVideo: false, allowPickingImage: true, completion: { (models) -> (Void) in
                        tzImagePickerVc.hideProgressHUD()
                        var assetModel = models?.first
                        if tzImagePickerVc.sortAscendingByModificationDate {
                            assetModel = models?.last
                        }
                        if self.allowCropSwitch.isOn {
                            let imagePicker = TZImagePickerController.init(cropTypeWithAsset: (assetModel?.asset)!, photo: image, completion: { (image, asset) in
                                self.refreshCollectionView(asset!, image: image!)
                            })
                            imagePicker.circleCropRadius = 100;
                            self.present(imagePicker, animated: true, completion: nil)
                        } else {
                            self.refreshCollectionView((assetModel?.asset)!, image: image)
                        }
                    })
                })
            })
            self.location = nil;
        }
    }

    func refreshCollectionView(_ asset: PHAsset, image:UIImage) {
        selectedAssets.append(asset)
        selectedPhotos.append(image)
        collectionView.reloadData()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        if picker.isKind(of: UIImagePickerController.classForCoder()) {
            picker.dismiss(animated: true, completion: nil);
        }
    }

    //MARK: -  click
    @IBAction func showTakePhotoBtnSwitchClick(_ sender: UISwitch) {
        if (sender.isOn) {
            self.showSheetSwitch.setOn(false, animated: true)
            self.allowPickingImageSwitch.setOn(true, animated: true)
        }
    }

    @IBAction func showSheetSwitchClick(_ sender: UISwitch) {
        if (sender.isOn) {
            self.showTakePhotoBtnSwitch.setOn(false, animated: true)
            self.allowPickingImageSwitch.setOn(true, animated: true)
        }
    }

    @IBAction func allowPickingOriginPhotoSwitchClick(_ sender: UISwitch) {
        if (sender.isOn) {
            self.allowPickingImageSwitch.setOn(true, animated: true)
            self.needCircleCropSwitch.setOn(false, animated: true)
            self.allowCropSwitch.setOn(false, animated: true)
        }
    }

    @IBAction func allowPickingImageSwitchClick(_ sender: UISwitch) {
        if (!sender.isOn) {
            self.allowPickingOriginalPhotoSwitch.setOn(false, animated: true)
            self.showTakePhotoBtnSwitch.setOn(false, animated: true)
            self.allowPickingVideoSwitch.setOn(true, animated: true)
            self.allowPickingGifSwitch.setOn(false, animated: true)
        }
    }

    @IBAction func allowPickingGifSwitchClick(_ sender: UISwitch) {
        if sender.isOn {
            self.allowPickingImageSwitch.setOn(true, animated: true)
        } else if !self.allowPickingVideoSwitch.isOn {
            self.allowPickingMuitlpleVideoSwitch.setOn(false, animated: true)
        }
    }

    @IBAction func allowPickingVideoSwitchClick(_ sender: UISwitch) {
        if !sender.isOn {
            self.allowPickingImageSwitch.setOn(true, animated: true)
            if !self.allowPickingGifSwitch.isOn {
                self.allowPickingMuitlpleVideoSwitch.setOn(false, animated: true)
            }
        }
    }

    @IBAction func allowCropSwitchClick(_ sender: UISwitch) {
        if (sender.isOn) {
            self.maxCountTF.text = "1";
            self.allowPickingOriginalPhotoSwitch.setOn(false, animated: true)
        } else {
            if self.maxCountTF.text == "1" {
                self.maxCountTF.text = "9";
            }
            self.needCircleCropSwitch.setOn(false, animated: true)
        }
    }

    @IBAction func needCircleCropSwitchClick(_ sender: UISwitch) {
        if sender.isOn {
            self.allowCropSwitch.setOn(true, animated: true)
            self.maxCountTF.text = "1"
            self.allowPickingOriginalPhotoSwitch.setOn(false, animated: true)
        }
    }

    @IBAction func allowPickingMultipleVideoSwitchClick(_ sender: UISwitch) {
    }


    @objc func deleteBtnClick(_ sender: UIButton) {

        selectedAssets.remove(at: sender.tag)
        selectedPhotos.remove(at: sender.tag)

        collectionView.performBatchUpdates({
            let indexPath = IndexPath(item: sender.tag, section: 0)
            self.collectionView.deleteItems(at: [indexPath])
        }) { (finished) in
            self.collectionView.reloadData()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

}


extension ViewController: TZImagePickerControllerDelegate {
    /// User click cancel button
    /// 取消
    func tz_imagePickerControllerDidCancel(_ picker: TZImagePickerController) {
        print("取消")
    }

    // The picker should dismiss itself; when it dismissed these handle will be called.
    // If isOriginalPhoto is YES, user picked the original photo.
    // You can get original photo with asset, by the method [[TZImageManager manager] getOriginalPhotoWithAsset:completion:].
    // The UIImage Object in photos default width is 828px, you can set it by photoWidth property.
    // 这个照片选择器会自己dismiss，当选择器dismiss的时候，会执行下面的代理方法
    // 如果isSelectOriginalPhoto为YES，表明用户选择了原图
    // 你可以通过一个asset获得原图，通过这个方法：[[TZImageManager manager] getOriginalPhotoWithAsset:completion:]
    // photos数组里的UIImage对象，默认是828像素宽，你可以通过设置photoWidth属性的值来改变它
    func imagePickerController(_ picker: TZImagePickerController, didFinishPicking photos: [UIImage], sourceAssets: [PHAsset], isSelectOriginalPhoto: Bool, infos: [Dictionary<String, Any>]?) {
        selectedPhotos = photos
        selectedAssets = sourceAssets

        _isSelectOriginalPhoto = isSelectOriginalPhoto;
        collectionView.reloadData()
        // _collectionView.contentSize = CGSizeMake(0, ((_selectedPhotos.count + 2) / 3 ) * (_margin + _itemWH));

        // 1.打印图片名字
        _ = sourceAssets.map({
            debugPrint($0.value(forKey: "filename") ?? "没有名字")
        })
        // 2.图片位置信息
        _ = sourceAssets.map({
            debugPrint($0.location ?? "没有位置信息")
        })

    }

    // If user picking a video, this callback will be called.
    // 如果用户选择了一个视频，下面的handle会被执行
    func imagePickerController(_ picker: TZImagePickerController, didFinishPickingVideo coverImage: UIImage, sourceAssets: PHAsset) {
        selectedPhotos = [coverImage]
        selectedAssets = [sourceAssets]
        // open this code to send video / 打开这段代码发送视频
        TZImageManager.manager.getVideoOutput(sourceAssets) { (outputPath) -> (Void) in
            debugPrint("视频导出到本地完成,沙盒路径为: \(outputPath!)")
            // Export completed, send video here, send by outputPath or NSData
            // 导出完成，在这里写上传代码，通过路径或者通过NSData上传
        }
        collectionView.reloadData()
    }

    // If user picking a gif image, this callback will be called.
    // 如果用户选择了一个gif图片，下面的handle会被执行
    func imagePickerController(_ picker: TZImagePickerController, didFinishPickingGifImage animatedImage: UIImage, sourceAssets: PHAsset) {
        selectedPhotos.append(animatedImage)
        selectedAssets.append(sourceAssets)
        collectionView.reloadData()
    }

    // Decide album show or not't
    // 决定相册显示与否
//    func isAlbumCanSelect(albumName: String, result: PHFetchResult<PHAsset>) -> Bool {
        /*
         if albumName == "个人收藏" {
            return false
         }
         if albumName == "视频" {
            return false
         }
        */
//        return true
//    }

    // Decide asset show or not't
    // 决定asset显示与否
//    func isAssetCanSelect(asset: PHAsset) -> Bool {

        /*
        switch asset.mediaType {
        case .video:
            // 视频时长
            let duration = asset.duration
            break
        case .image:
            // 图片尺寸
            if asset.pixelWidth > 3000 || asset.pixelWidth > 3000 {
                return false
            }
            return true
        break
        case .audio:
            return false

        case .unknown:
            return false
        default:
            break
        }
        */
//        return true
//    }
}







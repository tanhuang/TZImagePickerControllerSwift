//
//  TZPhotoPickerController.swift
//  TZImagePickerControllerSwift
//
//  Created by Huang.Tan on 2018/1/22.
//  Copyright © 2018年 Huang.Tan All rights reserved.
//

import UIKit
import Photos
import CoreLocation

public class TZPhotoPickerController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, TZAssetCellDelegate {

    public var isFirstAppear: Bool = false
    public var columnNumber: Int = 0
    public var model: TZAlbumModel?

    
    private var _models: Array<TZAssetModel>?

    private var _bottomToolBar: UIView?
    private var _previewButton: UIButton?
    private var _doneButton: UIButton?
    private var _numberImageView: UIImageView?
    private var _numberLabel: UILabel?
    private var _originalPhotoButton: UIButton?
    private var _originalPhotoLabel: UILabel?
    private var _divideLine: UIView?

    private var _shouldScrollToBottom = false
    private var _showTakePhotoBtn = false

    private var _offsetItemCount: CGFloat = 0

    private var previousPreheatRect = CGRect.zero
    private var isSelectOriginalPhoto = false
    private var collectionView: TZCollectionView?
    private var layout: UICollectionViewFlowLayout?


    private var location: CLLocation?


    private var AssetGridThumbnailSize = CGSize.zero
    private var itemMargin: CGFloat = 5

    lazy private var imagePickerVc: UIImagePickerController = {
        let imagePickerVC = UIImagePickerController()
        imagePickerVC.delegate = self
        imagePickerVC.navigationBar.barTintColor = self.navigationController?.navigationBar.barTintColor
        imagePickerVC.navigationBar.tintColor = self.navigationController?.navigationBar.tintColor
        var tzBarItem: UIBarButtonItem?, barItem: UIBarButtonItem?
        if #available(iOS 9.0, *) {
            tzBarItem = UIBarButtonItem.appearance(whenContainedInInstancesOf: [TZImagePickerController.classForCoder() as! UIAppearanceContainer.Type])
            barItem = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIImagePickerController.classForCoder() as! UIAppearanceContainer.Type])
        } else {
            // Fallback on earlier versions
            barItem = UIBarButtonItem.appearance()
            tzBarItem = UIBarButtonItem.appearance()
        }
        let titleTextAttributes = tzBarItem?.titleTextAttributes(for: .normal)

        barItem?.setTitleTextAttributes(titleTextAttributes, for: .normal)
        return imagePickerVC
    }()


    override public func viewDidLoad() {
        super.viewDidLoad()

//        resetCachedAssets()

        let tzImagePickerVc = self.navigationController as? TZImagePickerController
        isSelectOriginalPhoto = (tzImagePickerVc?.isSelectOriginalPhoto)!
        _shouldScrollToBottom = true

        view.backgroundColor = UIColor.white
        navigationItem.title = model?.name
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: tzImagePickerVc?.cancelBtnTitleStr, style: .plain, target: tzImagePickerVc, action: #selector(tzImagePickerVc?.cancelButtonClick))

        if tzImagePickerVc?.navLeftBarButtonSettingBlock != nil {
            let leftButton = UIButton(type: .custom)
            leftButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
            leftButton.addTarget(self, action: #selector(navLeftBarButtonClick), for: .touchUpInside)
            tzImagePickerVc?.navLeftBarButtonSettingBlock?(leftButton)
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftButton)
        }

        _showTakePhotoBtn = ((model?.isCameraRoll)! && (tzImagePickerVc?.allowTakePicture)!)

        NotificationCenter.default.addObserver(self, selector: #selector(didChangeStatusBarOrientationNotification(notification:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let tzImagePickerVc = self.navigationController as? TZImagePickerController
        tzImagePickerVc?.isSelectOriginalPhoto = isSelectOriginalPhoto
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        var scale: CGFloat = 2.0
        if UIScreen.main.bounds.size.width > 600 {
            scale = 1.0
        }
        if collectionView != nil {
            let cellSize = collectionView?.collectionViewLayout.collectionViewContentSize
            AssetGridThumbnailSize = CGSize(width: (cellSize?.width)! * scale, height: (cellSize?.height)! * scale)
        }

        if _models == nil {
            self.fetchAssetModels()
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if collectionView != nil {
            // self.updateCachedAssets()
        }
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()


        let tzImagePickerVc = self.navigationController as? TZImagePickerController

        var top: CGFloat = 0
        var collectionViewHeight: CGFloat = 0
        let naviBarHeight = (self.navigationController?.navigationBar.frame.height)!
        let isStatusBarHidden = UIApplication.shared.isStatusBarHidden
        if (self.navigationController?.navigationBar.isTranslucent)! {
            top = naviBarHeight
            if !isStatusBarHidden {
                top += 20
            }
            collectionViewHeight = (tzImagePickerVc?.showSelectBtn)! ? view.frame.height - 50 - top : view.frame.height - top
        } else {
            collectionViewHeight = (tzImagePickerVc?.showSelectBtn)! ? view.frame.height - 50 : view.frame.height
        }
        collectionView?.frame = CGRect(x: 0, y: top, width: self.view.frame.width, height: collectionViewHeight);
        let itemWH: CGFloat = (self.view.frame.width - CGFloat(self.columnNumber + 1) * itemMargin) / CGFloat(self.columnNumber)
        layout?.itemSize = CGSize(width: itemWH, height: itemWH)
        layout?.minimumInteritemSpacing = itemMargin
        layout?.minimumLineSpacing = itemMargin
        collectionView?.setCollectionViewLayout(layout!, animated: true)

        if (_offsetItemCount) > 0 {
            let offsetY = _offsetItemCount * ((layout?.itemSize.height)! + (layout?.minimumLineSpacing)!);
            collectionView?.setContentOffset(CGPoint(x: 0, y: offsetY), animated: true)
        }

        var yOffset: CGFloat = 0;
        if !((self.navigationController?.navigationBar.isHidden)!) {
            yOffset = self.view.frame.height - 50;
        } else {
            let navigationHeight: CGFloat = naviBarHeight + 20
            yOffset = self.view.frame.height - 50 - navigationHeight;
        }
        _bottomToolBar?.frame = CGRect(x: 0, y: yOffset, width: self.view.frame.width, height: 50);
        var previewWidth = (tzImagePickerVc?.previewBtnTitleStr.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: .usesFontLeading, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], context: nil).width)! + 2
        if !((tzImagePickerVc?.allowPreview)!) {
            previewWidth = 0.0
        }
        _previewButton?.frame = CGRect(x: 10, y: 3, width: previewWidth, height: 44)
        _previewButton?.frame.size.width = !((tzImagePickerVc?.showSelectBtn)!) ? 0 : previewWidth;
        if (tzImagePickerVc?.allowPickingOriginalPhoto)! {
            let fullImageWidth = (tzImagePickerVc?.fullImageBtnTitleStr.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: .usesFontLeading, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)], context: nil).width)!
            _originalPhotoButton?.frame = CGRect(x: (_previewButton?.frame.maxX)!, y: self.view.frame.height - 50, width: fullImageWidth + 56, height: 50);
            _originalPhotoLabel?.frame = CGRect(x: fullImageWidth + 46, y: 0, width: 80, height: 50)
        }
        _doneButton?.frame = CGRect(x: self.view.frame.width - 44 - 12, y: 3, width: 44, height: 44)
        _numberImageView?.frame = CGRect(x: self.view.frame.width - 56 - 28, y: 10, width: 30, height: 30)
        _numberLabel?.frame = (_numberImageView?.frame)!
        _divideLine?.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 1)

        let columnNumber = TZImageManager.manager.columnNumber
        TZImageManager.manager.columnNumber = columnNumber
        self.collectionView?.reloadData()
    }

    override public var prefersStatusBarHidden: Bool {
        return false
    }

    public func fetchAssetModels() {
        let tzImagePickerVc = self.navigationController as? TZImagePickerController
        if isFirstAppear {
            tzImagePickerVc?.showProgressHUD()
        }
        
        DispatchQueue.global().async {
            if !(tzImagePickerVc?.sortAscendingByModificationDate)! && self.isFirstAppear {
                TZImageManager.manager.getCameraRollAlbum(allowPickingVideo: (tzImagePickerVc?.allowPickingVideo)!, allowPickingImage: (tzImagePickerVc?.allowPickingImage)!, completion: { (model) in
                    self.model = model
                    self._models = model.models
                    self.initSubviews()
                })
            } else {
                if self._showTakePhotoBtn || self.isFirstAppear {
                    TZImageManager.manager.getAssets(assetsFromFetchResult: (self.model?.result)!, allowPickingVideo: (tzImagePickerVc?.allowPickingVideo)!, allowPickingImage: (tzImagePickerVc?.allowPickingImage)!, completion: { (models) -> (Void) in
                        self._models = models
                        self.initSubviews()
                    })
                } else {
                    self._models = self.model?.models
                    self.initSubviews()
                }
            }
        }
    }

    public func initSubviews() {
        DispatchQueue.main.async {
            let tzImagePickerVc = self.navigationController as? TZImagePickerController
            tzImagePickerVc?.hideProgressHUD()
            self.checkSelectedModels()
            self.configCollectionView()
            self.collectionView?.isHidden = true
            self.configBottomToolBar()

            self.scrollCollectionViewToBottom()

            // self.updateCachedAssets()
        }
    }

    public func configCollectionView() {
        let tzImagePickerVc = self.navigationController as? TZImagePickerController

        layout = UICollectionViewFlowLayout()
        collectionView = TZCollectionView(frame: CGRect.zero, collectionViewLayout: layout!)
        collectionView?.backgroundColor = UIColor.white
        collectionView?.dataSource = self;
        collectionView?.delegate = self;
        collectionView?.alwaysBounceHorizontal = false
        collectionView?.contentInset = UIEdgeInsets(top: itemMargin, left: itemMargin, bottom: itemMargin, right: itemMargin);

        if _showTakePhotoBtn && (tzImagePickerVc?.allowTakePicture)! {
            collectionView?.contentSize = CGSize(width: view.frame.width, height: CGFloat(((model?.count)! + columnNumber) / columnNumber) * view.frame.width);
        } else {
            collectionView?.contentSize = CGSize(width: view.frame.width, height:  CGFloat(((model?.count)! + columnNumber - 1) / columnNumber) * view.frame.width);
        }
        self.view.addSubview(collectionView!)
        collectionView?.register(TZAssetCell.classForCoder(), forCellWithReuseIdentifier: "TZAssetCell")
        collectionView?.register(TZAssetCameraCell.classForCoder(), forCellWithReuseIdentifier: "TZAssetCameraCell")
    }

    public func configBottomToolBar() {
        guard let tzImagePickerVc = self.navigationController as? TZImagePickerController else {
            return
        }
        
        if !tzImagePickerVc.showSelectBtn {
            return
        }

        _bottomToolBar = UIView(frame: CGRect.zero)
        _bottomToolBar?.backgroundColor = tzImagePickerVc.photoPickerBottomToolBarBgColor

        _previewButton = UIButton(type: .custom)
        _previewButton?.addTarget(self, action: #selector(previewButtonClick), for: .touchUpInside)
        _previewButton?.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        _previewButton?.setTitle(tzImagePickerVc.previewBtnTitleStr, for: .normal)
        _previewButton?.setTitle(tzImagePickerVc.previewBtnTitleStr, for: .disabled)
        _previewButton?.setTitleColor(tzImagePickerVc.previewBtnTitleDefColor, for: .normal)
        _previewButton?.setTitleColor(tzImagePickerVc.previewBtnTitleDisColor, for: .disabled)
        _previewButton?.isEnabled = !(tzImagePickerVc.selectedModels.isEmpty)

        _doneButton = UIButton(type: .custom)
        _doneButton?.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        _doneButton?.addTarget(self, action: #selector(doneButtonClick), for: .touchUpInside)
        _doneButton?.setTitle(tzImagePickerVc.doneBtnTitleStr, for: .normal)
        _doneButton?.setTitle(tzImagePickerVc.doneBtnTitleStr, for: .disabled)
        _doneButton?.setTitleColor(tzImagePickerVc.oKButtonTitleColorNormal, for: .normal)
        _doneButton?.setTitleColor(tzImagePickerVc.oKButtonTitleColorDisabled, for: .disabled)
        _doneButton?.isEnabled = !(tzImagePickerVc.selectedModels.isEmpty) || tzImagePickerVc.alwaysEnableDoneBtn

        _numberImageView = UIImageView(image: UIImage.imageNamedFromMyBundle(name: tzImagePickerVc.photoNumberIconImageName))
        _numberImageView?.isHidden = tzImagePickerVc.selectedModels.count <= 0;
        _numberImageView?.backgroundColor = UIColor.clear

        _numberLabel = UILabel()
        _numberLabel?.font = UIFont.systemFont(ofSize: 15)
        _numberLabel?.textColor = UIColor.white
        _numberLabel?.textAlignment = .center
        _numberLabel?.text = "\(tzImagePickerVc.selectedModels.count)"
        _numberLabel?.isHidden = tzImagePickerVc.selectedModels.isEmpty
        _numberLabel?.backgroundColor = UIColor.clear

        _divideLine = UIView()
        _divideLine?.backgroundColor = UIColor(red: 222 / 255.0, green: 222 / 255.0, blue: 222 / 255.0, alpha: 1)

        _bottomToolBar?.addSubview(_divideLine!)
        _bottomToolBar?.addSubview(_previewButton!)
        _bottomToolBar?.addSubview(_doneButton!)
        _bottomToolBar?.addSubview(_numberImageView!)
        _bottomToolBar?.addSubview(_numberLabel!)
        view.addSubview(_bottomToolBar!)

        if tzImagePickerVc.allowPickingOriginalPhoto {
            _originalPhotoButton = UIButton(type: .custom)
            _originalPhotoButton?.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0);
            _originalPhotoButton?.addTarget(self, action: #selector(originalPhotoButtonClick), for: .touchUpInside)
            _originalPhotoButton?.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            _originalPhotoButton?.setTitle(tzImagePickerVc.fullImageBtnTitleStr, for: .normal)
            _originalPhotoButton?.setTitle(tzImagePickerVc.fullImageBtnTitleStr, for: .selected)

            _originalPhotoButton?.setTitleColor(UIColor.lightGray, for: .normal)
            _originalPhotoButton?.setTitleColor(UIColor.black, for: .selected)
            _originalPhotoButton?.setImage(UIImage.imageNamedFromMyBundle(name: tzImagePickerVc.photoOriginDefImageName), for: .normal)
            _originalPhotoButton?.setImage(UIImage.imageNamedFromMyBundle(name: tzImagePickerVc.photoOriginSelImageName), for: .selected)
            _originalPhotoButton?.isSelected = isSelectOriginalPhoto
            _originalPhotoButton?.isEnabled = !(tzImagePickerVc.selectedModels.isEmpty)

            _originalPhotoLabel = UILabel()
            _originalPhotoLabel?.textAlignment = .left;
            _originalPhotoLabel?.font = UIFont.systemFont(ofSize: 16)
            _originalPhotoLabel?.textColor = UIColor.black
            if isSelectOriginalPhoto {
                self.getSelectedPhotoBytes()
            }

            view.addSubview(_originalPhotoButton!)
            _originalPhotoButton?.addSubview(_originalPhotoLabel!)
        }

    }

    //MARK: - Notification
    @objc func didChangeStatusBarOrientationNotification(notification: Notification) {

        _offsetItemCount = (collectionView?.contentOffset.y)! / ((layout?.itemSize.height)! + (layout?.minimumLineSpacing)!)
    }

    //MARK: - Click Event
    @objc func navLeftBarButtonClick()  {
        navigationController?.popViewController(animated: true)
    }

    @objc func previewButtonClick() {
        let photoPreviewVc = TZPhotoPreviewController()
        self.pushPhotoPrevireViewController(photoPreviewVc: photoPreviewVc)
    }

    @objc func originalPhotoButtonClick() {
        _originalPhotoButton?.isSelected = !((_originalPhotoButton?.isSelected)!)
        isSelectOriginalPhoto = (_originalPhotoButton?.isSelected)!
        _originalPhotoLabel?.isHidden = !((_originalPhotoButton?.isSelected)!)
        if isSelectOriginalPhoto {
            self.getSelectedPhotoBytes()
        }
    }

    @objc func doneButtonClick() {
        let tzImagePickerVc = self.navigationController as? TZImagePickerController
        // 1.6.8 判断是否满足最小必选张数的限制
        if (tzImagePickerVc?.minImagesCount)! > 0 && (tzImagePickerVc?.selectedModels.count)! < (tzImagePickerVc?.minImagesCount)! {
            let title = String(format: NSLocalizedString("Select a minimum of %zd photos", tableName: nil, bundle: bundle!, comment: ""), (tzImagePickerVc?.minImagesCount)!)
            _ = tzImagePickerVc?.showAlert(title: title)
            return;
        }
        tzImagePickerVc?.showProgressHUD()


        var photos = Array<Any>()
        var assets = Array<Any>()
        var infoArr = Array<Any>()
        _ = tzImagePickerVc?.selectedModels.map({ _ in
            photos.append(NSNumber(value: 1))
            assets.append(NSNumber(value: 1))
            infoArr.append(NSNumber(value: 1))
        })

        var havenotShowAlert = true
        TZImageManager.manager.shouldFixOrientation = true
        var alertView: UIAlertController?
        for (index, model) in (tzImagePickerVc?.selectedModels.enumerated())! {
            _ = TZImageManager.manager.getPhoto(with: model.asset, networkAccessAllowed: true, completion: { (photo, info, isDegraded) -> (Void) in
                if isDegraded != nil && isDegraded! {
                    return
                }
                guard var _photo = photo, let _info = info else {
                    return
                }

                _photo = self.scaleImage(_photo, to: CGSize(width: (tzImagePickerVc?.photoWidth)!, height: ((tzImagePickerVc?.photoWidth)! * _photo.size.height / _photo.size.width)))!

                photos[index] = _photo
                assets[index] = model.asset
                infoArr[index] = _info

                if (photos as AnyObject).contains(NSNumber(value: 1)) {
                    return
                }

                if havenotShowAlert {
                    if alertView != nil {
                        tzImagePickerVc?.hideAlertView(alertView: alertView!)
                    }
                    self.didGetAll(photos: photos as? Array<UIImage>, assets: assets as? Array<PHAsset>, infoArr: infoArr)
                }
            }, progressHandler: { (progress, error, stop, info) -> (Void) in
                if progress! < 1 && havenotShowAlert && alertView == nil {
                    tzImagePickerVc?.hideProgressHUD()
                    alertView = tzImagePickerVc?.showAlert(title: Bundle.tz_localizedString(forKey: "Synchronizing photos from iCloud"))
                    havenotShowAlert = false
                    return
                }
                if progress! >= 1 {
                    havenotShowAlert = true
                }
            })
        }

        if (tzImagePickerVc?.selectedModels.count)! <= 0 {
            self.didGetAll(photos: photos as? Array<UIImage>, assets: assets as? Array<PHAsset>, infoArr: infoArr)
        }
    }

    func didGetAll(photos: Array<UIImage>?, assets: Array<PHAsset>?, infoArr: Array<Any>?) {
        let tzImagePickerVc = self.navigationController as? TZImagePickerController
        tzImagePickerVc?.hideProgressHUD()

        if (tzImagePickerVc?.autoDismiss)! {
            self.navigationController?.dismiss(animated: true, completion: {
                self.callDelegateMethod(photos: photos, assets: assets, infoArr: infoArr)
            })
        } else {
            self.callDelegateMethod(photos: photos, assets: assets, infoArr: infoArr)
        }
    }

    func callDelegateMethod(photos: Array<UIImage>?, assets: Array<PHAsset>?, infoArr: Array<Any>?) {
        guard let tzImagePickerVc = self.navigationController as? TZImagePickerController  else {
            return
        }

        if (tzImagePickerVc.pickerDelegate?.responds(to: #selector(tzImagePickerVc.pickerDelegate?.imagePickerController(_:didFinishPicking:sourceAssets:isSelectOriginalPhoto:infos:))))! {
            tzImagePickerVc.pickerDelegate?.imagePickerController!(tzImagePickerVc, didFinishPicking: photos!, sourceAssets: assets!, isSelectOriginalPhoto: isSelectOriginalPhoto, infos: infoArr as? [Dictionary<String, Any>])
        }

        tzImagePickerVc.didFinishPickingPhotosWithInfosHandle?(photos!, assets!, isSelectOriginalPhoto, infoArr as? Array<Dictionary<String, Any>>)
    }

    //MARK: - UICollectionViewDataSource && Delegate
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if _showTakePhotoBtn {
            let tzImagePickerVc = self.navigationController as? TZImagePickerController
            if (tzImagePickerVc?.allowPickingImage)! && (tzImagePickerVc?.allowTakePicture)! {
                return (_models?.count)! + 1;
            }
        }
        return (_models?.count)!
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // the cell lead to take a picture / 去拍照的cell
        let tzImagePickerVc = self.navigationController as? TZImagePickerController
        if ((tzImagePickerVc?.sortAscendingByModificationDate)! && indexPath.row >= (_models?.count)!) || (!((tzImagePickerVc?.sortAscendingByModificationDate)!) && indexPath.row == 0) && _showTakePhotoBtn {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TZAssetCameraCell", for: indexPath) as! TZAssetCameraCell
            cell.imageView?.image = UIImage.imageNamedFromMyBundle(name: (tzImagePickerVc?.takePictureImageName)!)
            return cell
        }
        // the cell dipaly photo or video / 展示照片或视频的cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TZAssetCell", for: indexPath) as! TZAssetCell
        cell.allowPickingMultipleVideo = (tzImagePickerVc?.allowPickingMultipleVideo)!
        cell.photoDefImageName = (tzImagePickerVc?.photoDefImageName)!
        cell.photoSelImageName = (tzImagePickerVc?.photoSelImageName)!
        var model: TZAssetModel?
        if (tzImagePickerVc?.sortAscendingByModificationDate)! || !_showTakePhotoBtn {
            model = _models?[indexPath.row]
        } else {
            model = _models?[indexPath.row - 1]
        }
        cell.allowPickingGif = (tzImagePickerVc?.allowPickingGif)!
        cell.representedAssetIdentifier = (model?.asset.localIdentifier)!
        cell.model = model
        cell.showSelectBtn = (tzImagePickerVc?.showSelectBtn)!
        cell.delegate = self
        cell.allowPreview = (tzImagePickerVc?.allowPreview)!
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // take a photo / 去拍照
        let tzImagePickerVc = self.navigationController as? TZImagePickerController
        if ((tzImagePickerVc?.sortAscendingByModificationDate)! && indexPath.row >= (_models?.count)!) ||
            (!((tzImagePickerVc?.sortAscendingByModificationDate)!) && indexPath.row == 0)
            && _showTakePhotoBtn {
            self.takePhoto()
            return
        }
        // preview phote or video / 预览照片或视频
        var index = indexPath.row;
        if !((tzImagePickerVc?.sortAscendingByModificationDate)!) && _showTakePhotoBtn {
            index = indexPath.row - 1;
        }

        guard let model = _models?[index]  else {
            debugPrint("TZAssetModel is nil")
            return
        }

        if model.type == .video && !((tzImagePickerVc?.allowPickingMultipleVideo)!) {
            if (tzImagePickerVc?.selectedModels.count)! > 0 {
                _ = tzImagePickerVc?.showAlert(title: Bundle.tz_localizedString(forKey: "Can not choose both video and photo"))
            } else {
                let videoPlayerVc = TZVideoPlayerController()
                videoPlayerVc.model = model
                self.navigationController?.pushViewController(videoPlayerVc, animated: true)
            }
        } else if model.type == .photoGif && (tzImagePickerVc?.allowPickingGif)! && !((tzImagePickerVc?.allowPickingMultipleVideo)!) {
            if (tzImagePickerVc?.selectedModels.count)! > 0 {
                _ = tzImagePickerVc?.showAlert(title: Bundle.tz_localizedString(forKey: "Can not choose both photo and GIF"))
            } else {
                let gifPreviewVc = TZGifPhotoPreviewController()
                gifPreviewVc.model = model;
                self.navigationController?.pushViewController(gifPreviewVc, animated: true)
            }
        } else {
            let photoPreviewVc = TZPhotoPreviewController()
            photoPreviewVc.currentIndex = index
            photoPreviewVc.models = _models!
            self.pushPhotoPrevireViewController(photoPreviewVc: photoPreviewVc)
        }
    }


    func tz_assetCell(_ cell: TZAssetCell,_ model: TZAssetModel, _ isSelect: Bool) {

        guard let tzImagePickerVc = self.navigationController as? TZImagePickerController else { return }

        // 1. cancel select / 取消选择
        if (isSelect) {
            cell.selectPhotoButton.isSelected = false
            model.isSelected = false

            for (index, model_item) in tzImagePickerVc.selectedModels.enumerated() {
                if  model.asset.localIdentifier == model_item.asset.localIdentifier {
                    tzImagePickerVc.selectedModels.remove(at:index)
                    break
                }
            }
            self.refreshBottomToolBarStatus()
        } else {
            // 2. select:check if over the maxImagesCount / 选择照片,检查是否超过了最大个数的限制
            if tzImagePickerVc.selectedModels.count < tzImagePickerVc.maxImagesCount {
                cell.selectPhotoButton.isSelected = true
                model.isSelected = true
                tzImagePickerVc.selectedModels.append(model)
                self.refreshBottomToolBarStatus()
            } else {
                let string = String(format:
                    NSLocalizedString("Select a maximum of %zd photos", tableName: nil, bundle: bundle!, comment: ""), tzImagePickerVc.maxImagesCount)
                _ = tzImagePickerVc.showAlert(title: string)
            }
        }
        UIView.showOscillatoryAnimationWithLayer(layer: (self._numberImageView?.layer)!, type: .smaller)
    }

    //MARK: - Private Method
    /// 拍照按钮点击事件
    @objc func takePhoto() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        if authStatus == .restricted || authStatus == .denied{
            // 无权限 做一个友好的提示
            var appName = Bundle.main.infoDictionary!["CFBundleDisplayName"]
            if appName == nil {
                appName = Bundle.main.infoDictionary?["CFBundleName"]
            }
            let message = String(format: NSLocalizedString("Please allow %@ to access your camera in \"Settings -> Privacy -> Camera\"", tableName: nil, bundle: bundle!, comment: ""), appName! as! CVarArg)
            let alert = UIAlertController(title: Bundle.tz_localizedString(forKey: "Can not use camera"), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Bundle.tz_localizedString(forKey: "Cancel"), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: Bundle.tz_localizedString(forKey: "Setting"), style: .default, handler: { (action) in
                UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
            }))
        } else if (authStatus == .notDetermined) {
            // fix issue 466, 防止用户首次拍照拒绝授权时相机页黑屏
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted) in
                if granted {
                    DispatchQueue.main.async {
                        self.pushImagePickerController()
                    }
                }
            })
        } else {
            self.pushImagePickerController()
        }
    }
    /// 调用相机
    public func pushImagePickerController() {
        // 提前定位
        TZLocationManager.manager.startLocation(successBlock: { (location, oldLocation) -> (Void) in
            self.location = location
        }, failureBlock: { (error) -> (Void) in
            self.location = nil
        }, geocoderBlock: { (geocoderArray) -> (Void) in
            
        })

        let sourceType = UIImagePickerController.SourceType.camera
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            self.imagePickerVc.sourceType = sourceType;
            self.imagePickerVc.modalPresentationStyle = .overCurrentContext
            self.present(imagePickerVc, animated: true, completion: nil)
        } else {
            debugPrint("模拟器中无法打开照相机,请在真机中使用")
        }
    }

    public func refreshBottomToolBarStatus() {
        let tzImagePickerVc = self.navigationController as? TZImagePickerController

        _previewButton?.isEnabled = (tzImagePickerVc?.selectedModels.count)! > 0;
        _doneButton?.isEnabled = (tzImagePickerVc?.selectedModels.count)! > 0 || (tzImagePickerVc?.alwaysEnableDoneBtn)!

        _numberImageView?.isHidden = (tzImagePickerVc?.selectedModels.count)! <= 0;
        _numberLabel?.isHidden = (tzImagePickerVc?.selectedModels.count)! <= 0;
        _numberLabel?.text = "\((tzImagePickerVc?.selectedModels.count)!)"

        _originalPhotoButton?.isEnabled = (tzImagePickerVc?.selectedModels.count)! > 0;
        _originalPhotoButton?.isSelected = (isSelectOriginalPhoto && (_originalPhotoButton?.isEnabled)!);
        _originalPhotoLabel?.isHidden = (!(_originalPhotoButton?.isSelected)!);
        if isSelectOriginalPhoto {
            self.getSelectedPhotoBytes()
        }
    }

    func pushPhotoPrevireViewController(photoPreviewVc: TZPhotoPreviewController) {
        photoPreviewVc.isSelectOriginalPhoto = isSelectOriginalPhoto
        photoPreviewVc.backButtonClickBlock = {[weak self] (isSelectOriginalPhoto) -> (Void) in
            self?.isSelectOriginalPhoto = isSelectOriginalPhoto!
            self?.collectionView?.reloadData()
            self?.refreshBottomToolBarStatus()
        }
        photoPreviewVc.doneButtonClickBlock = {[weak self] (isSelectOriginalPhoto) -> (Void) in
            self?.isSelectOriginalPhoto = isSelectOriginalPhoto!
            self?.doneButtonClick()
        }

        photoPreviewVc.doneButtonClickBlockCropMode = {
            [weak self] (cropedImage, asset) -> (Void) in
            self?.didGetAll(photos: [cropedImage!], assets: [asset!], infoArr: nil)
        }
        navigationController?.pushViewController(photoPreviewVc, animated: true)
    }

    public func getSelectedPhotoBytes() {
        let imagePickerVc = self.navigationController as? TZImagePickerController
        TZImageManager.manager.getPhotos(bytesWithArray: imagePickerVc?.selectedModels) { (totalBytes) -> (Void) in
            self._originalPhotoLabel?.text = "(\(totalBytes!))"
        }
    }

    public func scaleImage(_ image: UIImage?, to size: CGSize) -> UIImage? {
        guard let _image = image else {
            return nil
        }
        if _image.size.width > size.width {
            return image
        }
        UIGraphicsBeginImageContext(size)
        image?.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }

    public func scrollCollectionViewToBottom()  {
        let tzImagePickerVc = self.navigationController as? TZImagePickerController
        if _shouldScrollToBottom && (_models?.count)! > 0 {
            var item = 0
            if (tzImagePickerVc?.sortAscendingByModificationDate)! {
                item = (_models?.count)! - 1;
                if _showTakePhotoBtn {
                    if (tzImagePickerVc?.allowPickingImage)! && (tzImagePickerVc?.allowTakePicture)! {
                        item += 1;
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01, execute: {
                self.collectionView?.scrollToItem(at: IndexPath(item: item, section: 0), at: .bottom, animated: false)
                self._shouldScrollToBottom = false
                self.collectionView?.isHidden = false
            })
        } else {
            collectionView?.isHidden = false
        }
    }

    public func checkSelectedModels() {
        let tzImagePickerVc = self.navigationController as? TZImagePickerController
        _ = self._models?.map({ model1 in
            model1.isSelected = false
            var selectedAssets = [PHAsset]()
            _ = tzImagePickerVc?.selectedModels.map({ model2 in
                selectedAssets.append(model2.asset)
            })
            if selectedAssets.contains(model1.asset) {
                model1.isSelected = true
            }
        })
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // self.updateCachedAssets()
    }


    //MARK: - UIImagePickerControllerDelegate

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let type = info[UIImagePickerController.InfoKey.mediaType] as! String
        if type == "public.image" {
            let imagePickerVc = self.navigationController as? TZImagePickerController
            imagePickerVc?.showProgressHUD()
            guard let photo = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
                imagePickerVc?.hideProgressHUD()
                debugPrint("image is nil")
                return
            }
            TZImageManager.manager.savePhotoWithImage(with: photo, location: self.location, completion: { (error) -> (Void) in
                if error == nil {
                    self.reloadPhotoArray()
                } else {
                    imagePickerVc?.hideProgressHUD()
                    _ = imagePickerVc?.showAlert(title: "保存图片失败")
                }
            })
            self.location = nil;
        }
    }

    public func reloadPhotoArray() {
        guard let tzImagePickerVc = self.navigationController as? TZImagePickerController else {
            return
        }
        TZImageManager.manager.getCameraRollAlbum(allowPickingVideo: tzImagePickerVc.allowPickingVideo, allowPickingImage: tzImagePickerVc.allowPickingImage) { (model) in
            self.model = model
            TZImageManager.manager.getAssets(assetsFromFetchResult: (self.model?.result)!, allowPickingVideo: tzImagePickerVc.allowPickingVideo, allowPickingImage: tzImagePickerVc.allowPickingImage, completion: { (assetModels) -> (Void) in
                tzImagePickerVc.hideProgressHUD()
                
                var assetModel: TZAssetModel?
                if tzImagePickerVc.sortAscendingByModificationDate {
                    assetModel = assetModels?.last
                    self._models?.append(assetModel!)
                } else {
                    assetModel = assetModels?.first
                    self._models?.insert(assetModel!, at: 0)
                }

                if tzImagePickerVc.maxImagesCount <= 1 {
                    if tzImagePickerVc.allowCrop {
                        let photoPreviewVc = TZPhotoPreviewController()
                        if tzImagePickerVc.sortAscendingByModificationDate {
                            photoPreviewVc.currentIndex = (self._models?.count)! - 1
                        } else {
                            photoPreviewVc.currentIndex = 0
                        }
                        photoPreviewVc.models = self._models!
                        self.pushPhotoPrevireViewController(photoPreviewVc: photoPreviewVc)
                    } else {
                        tzImagePickerVc.selectedModels.append(assetModel!)
                        self.doneButtonClick()
                    }
                    return
                } else if tzImagePickerVc.selectedModels.count < tzImagePickerVc.maxImagesCount {
                    assetModel?.isSelected = true
                    tzImagePickerVc.selectedModels.append(assetModel!)
                    self.refreshBottomToolBarStatus()
                }
                self.collectionView?.isHidden = true
                self.collectionView?.reloadData()

                self._shouldScrollToBottom = true
                self.scrollCollectionViewToBottom()
            })
        }
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    //MARK: - Asset Caching

    public func resetCachedAssets() {
        TZImageManager.manager.cachingImageManager.stopCachingImagesForAllAssets()
        self.previousPreheatRect = CGRect.zero;
    }

    public func updateCachedAssets() {
        // Update only if the view is visible.
        guard isViewLoaded && view.window != nil else { return }

        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)

        /*
         Check if the collection view is showing an area that is significantly
         different to the last preheated area.
         */
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }

        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in _models![indexPath.item < (_models?.count)! ? indexPath.item : (_models?.count)! - 1].asset }
        let removedAssets = removedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in _models![indexPath.item < (_models?.count)! ? indexPath.item : (_models?.count)! - 1].asset }

        // Update the assets the PHCachingImageManager is caching.
        TZImageManager.manager.cachingImageManager.startCachingImages(for: addedAssets,
                                        targetSize: AssetGridThumbnailSize, contentMode: .aspectFill, options: nil)
        TZImageManager.manager.cachingImageManager.stopCachingImages(for: removedAssets,
                                       targetSize: AssetGridThumbnailSize, contentMode: .aspectFill, options: nil)

        // Store the preheat rect to compare against in the future.
        previousPreheatRect = preheatRect
    }


    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }

//
//    func computeDifferenceBetweenRect(oldRect: CGRect?, newRect: CGRect?, removedHandler: ((_ removedRect: CGRect?) -> (Swift.Void))?, addedHandler: ((_ addedRect: CGRect?) -> (Swift.Void))?)  {
//        guard let _oldRect = oldRect, let _newRect = newRect else {
//            addedHandler?(nil)
//            removedHandler?(nil)
//            return
//        }
//
//        if _newRect.intersects(_oldRect) {
//            let oldMaxY = _oldRect.maxY
//            let oldMinY = _oldRect.minY
//            let newMaxY = _newRect.maxY
//            let newMinY = _newRect.minY
//
//            if (newMaxY > oldMaxY) {
//                let rectToAdd = CGRect(x: _newRect.origin.x, y: oldMaxY, width: _newRect.size.width, height: (newMaxY - oldMaxY));
//                addedHandler?(rectToAdd)
//            }
//
//            if (oldMinY > newMinY) {
//                let rectToAdd = CGRect(x: _newRect.origin.x, y: newMinY, width: _newRect.size.width, height: (oldMinY - newMinY));
//                addedHandler?(rectToAdd);
//            }
//
//            if (newMaxY < oldMaxY) {
//                let rectToRemove = CGRect(x: _newRect.origin.x, y: newMaxY, width: _newRect.size.width, height: (oldMaxY - newMaxY));
//                removedHandler?(rectToRemove);
//            }
//
//            if (oldMinY < newMinY) {
//                let rectToRemove = CGRect(x: _newRect.origin.x, y: oldMinY, width: _newRect.size.width, height: (newMinY - oldMinY));
//                removedHandler?(rectToRemove);
//            }
//        } else {
//            addedHandler?(_newRect);
//            removedHandler?(_oldRect);
//        }
//    }

    public func assetsAtIndexPaths(indexPaths: Array<IndexPath>?) -> Array<PHAsset?>? {

        guard let _indexPaths = indexPaths else {
            return nil
        }

        var assets = [PHAsset]()
        _ = _indexPaths.map({ assets.append(_models![$0.item < (_models?.count)! ? $0.item : (_models?.count)! - 1].asset) })

        return assets;
    }

    public func aapl_indexPaths(for ElementsInRect: CGRect?) -> Array<IndexPath>? {
        guard let allLayoutAttributes = collectionView?.collectionViewLayout.layoutAttributesForElements(in: ElementsInRect!) else {
            return nil
        }

        var indexPaths = [IndexPath]()
        _ = allLayoutAttributes.map({ indexPaths.append($0.indexPath) })
        return indexPaths;
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */

    deinit {
        debugPrint("释放了...\(self.classForCoder)")
    }


}





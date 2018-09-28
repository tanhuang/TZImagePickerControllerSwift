//
//  TZPhotoPreviewController.swift
//  TZImagePickerControllerSwift
//
//  Created by Huang.Tan on 2018/1/22.
//  Copyright © 2018年 Huang.Tan All rights reserved.
//

import UIKit
import Photos.PHAsset

public class TZPhotoPreviewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {


    public var models = Array<TZAssetModel>()                  ///< All photo models / 所有图片模型数组
    public var photos = Array<UIImage>()               ///< All photos  / 所有图片数组
    public var currentIndex: Int = 0           ///< Index of the photo user click / 用户点击的图片的索引
    public var isSelectOriginalPhoto: Bool = false       ///< If YES,return original photo / 是否返回原图
    public var isCropImage: Bool = false


    /// Return the new selected photos / 返回最新的选中图片数组
    public var backButtonClickBlock: ((_ isSelectOriginalPhoto: Bool?) -> (Swift.Void))?
    public var doneButtonClickBlock: ((_ isSelectOriginalPhoto: Bool?) -> (Swift.Void))?
    public var doneButtonClickBlockCropMode: ((_ cropedImage: UIImage?, _ asset: PHAsset?) -> (Swift.Void))?
    public var doneButtonClickBlockWithPreviewType: ((_ photos: Array<UIImage>?, _ assets: Array<PHAsset>?, _ isSelectOriginalPhoto: Bool?) -> (Swift.Void))?

    private var _collectionView: UICollectionView?
    private var _layout: UICollectionViewFlowLayout?
    private var _photosTemp = Array<UIImage>()
    private var _assetsTemp = Array<PHAsset>()

    private var _naviBar: UIView?
    private var _backButton: UIButton?
    private var _selectButton: UIButton?

    private var _toolBar: UIView?
    private var _doneButton: UIButton?
    private var _numberImageView: UIImageView?
    private var _numberLabel: UILabel?
    private var _originalPhotoButton: UIButton?
    private var _originalPhotoLabel: UILabel?

    private var _offsetItemCount: CGFloat = 0

    private var isHideNaviBar: Bool = false
    private var cropBgView: UIView?
    private var cropView: UIView?

    private var progress: Double = 0.0
    private var alertView:Any?

    override public func viewDidLoad() {
        super.viewDidLoad()

        TZImageManager.manager.shouldFixOrientation = true
        let _tzImagePickerVc = self.navigationController as? TZImagePickerController
        if self.models.count == 0 {
            self.models = (_tzImagePickerVc?.selectedModels)!
            self._assetsTemp = (_tzImagePickerVc?.selectedAssets)!
            self.isSelectOriginalPhoto = (_tzImagePickerVc?.isSelectOriginalPhoto)!
        }
        self._photosTemp = photos;

        self.configCollectionView()
        self.configCustomNaviBar()
        self.configBottomToolBar()
        view.clipsToBounds = true

        NotificationCenter.default.addObserver(self, selector: #selector(didChangeStatusBarOrientationNotification(notification:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        if !Bundle.TZ_isGlobalHideStatusBar() {
            UIApplication.shared.isStatusBarHidden = true
        }
        if currentIndex > 0 {
            _collectionView?.setContentOffset(CGPoint(x: (view.frame.width + 20) * CGFloat(currentIndex), y: 9), animated: true)
        }
        self.refreshNaviBarAndBottomBarState()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        if !Bundle.TZ_isGlobalHideStatusBar() {
            UIApplication.shared.isStatusBarHidden = false
        }
        TZImageManager.manager.shouldFixOrientation = false
    }

    override public var prefersStatusBarHidden: Bool {
        return true
    }

    public func configCollectionView() {
        _layout = UICollectionViewFlowLayout()
        _layout?.scrollDirection = .horizontal
        _collectionView = UICollectionView(frame: .zero, collectionViewLayout: _layout!)
        _collectionView?.backgroundColor = UIColor.black
        _collectionView?.dataSource = self;
        _collectionView?.delegate = self;
        _collectionView?.isPagingEnabled = true
        _collectionView?.scrollsToTop = false
        _collectionView?.showsHorizontalScrollIndicator = false
        _collectionView?.contentOffset = CGPoint(x: 0, y: 0)
        _collectionView?.contentSize = CGSize(width: CGFloat(self.models.count) * (view.frame.width + 20), height: 0)
        view.addSubview(_collectionView!)
        _collectionView?.register(TZPhotoPreviewCell.classForCoder(), forCellWithReuseIdentifier: "TZPhotoPreviewCell")
        _collectionView?.register(TZVideoPreviewCell.classForCoder(), forCellWithReuseIdentifier: "TZVideoPreviewCell")
        _collectionView?.register(TZGifPreviewCell.classForCoder(), forCellWithReuseIdentifier: "TZGifPreviewCell")
    }

    public func configCustomNaviBar()  {
        guard let _tzImagePickerVc = self.navigationController as? TZImagePickerController else {
            return
        }

        _naviBar = UIView(frame: CGRect.zero)
        _naviBar?.backgroundColor = UIColor(red: 34 / 255.0, green: 34 / 255.0, blue: 34 / 255.0, alpha: 0.7)

        _backButton = UIButton(frame: CGRect.zero)
        _backButton?.setImage(UIImage.imageNamedFromMyBundle(name: "navi_back"), for: .normal)
        _backButton?.setTitleColor(UIColor.white, for: .normal)
        _backButton?.addTarget(self, action: #selector(backButtonClick), for: .touchUpInside)

        _selectButton = UIButton(frame: .zero)
        _selectButton?.setImage(UIImage.imageNamedFromMyBundle(name: _tzImagePickerVc.photoDefImageName), for: .normal)
        _selectButton?.setImage(UIImage.imageNamedFromMyBundle(name: _tzImagePickerVc.photoSelImageName), for: .selected)
        _selectButton?.isHidden = !_tzImagePickerVc.showSelectBtn
        _selectButton?.addTarget(self, action: #selector(select(selectButton:)), for: .touchUpInside)

        _naviBar?.addSubview(_selectButton!)
        _naviBar?.addSubview(_backButton!)
        view.addSubview(_naviBar!)
    }

    public func configBottomToolBar()  {

        guard let _tzImagePickerVc = self.navigationController as? TZImagePickerController else {
            return
        }

        _toolBar = UIView(frame: .zero)
        _toolBar?.backgroundColor = UIColor(red: 34 / 255.0, green: 34 / 255.0, blue: 34 / 255.0, alpha: 0.7)

        if _tzImagePickerVc.allowPickingOriginalPhoto {
            _originalPhotoButton = UIButton(type: .custom)
            _originalPhotoButton?.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
            _originalPhotoButton?.backgroundColor = UIColor.clear
            _originalPhotoButton?.addTarget(self, action: #selector(originalPhotoButtonClick(_:)), for: .touchUpInside)
            _originalPhotoButton?.setTitle(_tzImagePickerVc.fullImageBtnTitleStr, for: .normal)
            _originalPhotoButton?.setTitle(_tzImagePickerVc.fullImageBtnTitleStr, for: .selected)
            _originalPhotoButton?.setTitleColor(UIColor.lightGray, for: .normal)
            _originalPhotoButton?.setTitleColor(UIColor.white, for: .normal)
            _originalPhotoButton?.setImage(UIImage.imageNamedFromMyBundle(name: _tzImagePickerVc.photoPreviewOriginDefImageName), for: .normal)
            _originalPhotoButton?.setImage(UIImage.imageNamedFromMyBundle(name: _tzImagePickerVc.photoOriginSelImageName), for: .selected)

            _originalPhotoLabel = UILabel()
            _originalPhotoLabel?.textAlignment = .left
            _originalPhotoLabel?.font = UIFont.systemFont(ofSize: 13)
            _originalPhotoLabel?.textColor = UIColor.white
            _originalPhotoLabel?.backgroundColor = UIColor.clear
            if isSelectOriginalPhoto {
                self.showPhotoBytes()
            }
            _toolBar?.addSubview(_originalPhotoLabel!)
            _toolBar?.addSubview(_originalPhotoButton!)
        }

        _doneButton = UIButton(type: .custom)
        _doneButton?.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        _doneButton?.addTarget(self, action: #selector(doneButtonClick), for: .touchUpInside)
        _doneButton?.setTitle(_tzImagePickerVc.doneBtnTitleStr, for: .normal)
        _doneButton?.setTitleColor(_tzImagePickerVc.oKButtonTitleColorNormal, for: .normal)

        _numberImageView = UIImageView(image: UIImage.imageNamedFromMyBundle(name: _tzImagePickerVc.photoNumberIconImageName))
        _numberImageView?.backgroundColor = UIColor.clear
        _numberImageView?.isHidden = _tzImagePickerVc.selectedModels.count <= 0

        _numberLabel = UILabel()
        _numberLabel?.font = UIFont.systemFont(ofSize: 15)
        _numberLabel?.textColor = UIColor.white
        _numberLabel?.textAlignment = .center
        _numberLabel?.text = "\(_tzImagePickerVc.selectedModels.count)"
        _numberLabel?.isHidden = _tzImagePickerVc.selectedModels.count <= 0;
        _numberLabel?.backgroundColor = UIColor.clear

        _toolBar?.addSubview(_doneButton!)
        _toolBar?.addSubview(_numberImageView!)
        _toolBar?.addSubview(_numberLabel!)
        view.addSubview(_toolBar!)
    }

    public func configCropView()  {
        let _tzImagePickerVc = self.navigationController as? TZImagePickerController
        if !(_tzImagePickerVc?.showSelectBtn)! && (_tzImagePickerVc?.allowCrop)! {
            cropView?.removeFromSuperview()
            cropBgView?.removeFromSuperview()

            cropBgView = UIView()
            cropBgView?.isUserInteractionEnabled = false
            cropBgView?.frame = view.bounds
            cropBgView?.backgroundColor = UIColor.clear
            view.addSubview(cropBgView!)

            TZImageCropManager.overlay(clippingWithView: cropBgView, cropRect: _tzImagePickerVc?.cropRect, containerView: view, needCircleCrop: (_tzImagePickerVc?.needCircleCrop)!)

            cropView = UIView()
            cropView?.isUserInteractionEnabled = false
            cropView?.frame = (_tzImagePickerVc?.cropRect)!
            cropView?.backgroundColor = UIColor.clear
            cropView?.layer.borderColor = UIColor.white.cgColor
            cropView?.layer.borderWidth = 1

            if (_tzImagePickerVc?.needCircleCrop)! {
                cropView?.layer.cornerRadius = (_tzImagePickerVc?.cropRect.width)! * 0.5
                cropView?.clipsToBounds = true
            }
            view.addSubview(cropView!)

            _tzImagePickerVc?.cropViewSettingBlock?(cropView!)

            view.bringSubviewToFront(_naviBar!)
            view.bringSubviewToFront(_toolBar!)
        }
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let _tzImagePickerVc = self.navigationController as? TZImagePickerController

        _naviBar?.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 64)
        _backButton?.frame = CGRect(x: 10, y: 10, width: 44, height: 44)
        _selectButton?.frame = CGRect(x: view.frame.width - 54, y: 10, width: 42, height: 42)

        _layout?.itemSize = CGSize(width: view.frame.width + 20, height: view.frame.height)
        _layout?.minimumLineSpacing = 0
        _layout?.minimumInteritemSpacing = 0
        _collectionView?.frame = CGRect(x: -10, y: 0, width: view.frame.width + 20, height: view.frame.height)
//        _collectionView?.setCollectionViewLayout(_layout!, animated: false)
        _collectionView?.collectionViewLayout = _layout!
        if _offsetItemCount > 0 {
            let offsetX = _offsetItemCount * (_layout?.itemSize.width)!
            _collectionView?.contentOffset = CGPoint(x: offsetX, y: 0)
//            _collectionView?.setContentOffset(CGPoint(x: offsetX, y: 0), animated: false)
        }
        if (_tzImagePickerVc?.allowCrop)! {
            _collectionView?.reloadData()
        }

        _toolBar?.frame = CGRect(x: 0, y: view.frame.height - 44, width: view.frame.width, height: 44)
        if (_tzImagePickerVc?.allowPickingOriginalPhoto)! {
            let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)]
            let fullImageWidth = _tzImagePickerVc?.fullImageBtnTitleStr.boundingRect(with: CGSize(width: 320.0, height: 999.9), options: .usesFontLeading, attributes: attributes, context: nil).width
            _originalPhotoButton?.frame = CGRect.init(x: 0, y: 0, width: fullImageWidth! + 56, height: 44)
            _originalPhotoLabel?.frame = CGRect(x: (_originalPhotoButton?.frame.maxX)!, y: 0, width: 80, height: 44)
        }
        _doneButton?.frame = CGRect(x: view.frame.width - 44 - 12, y: 0, width: 44, height: 44)
        _numberImageView?.frame = CGRect(x: view.frame.width - 56 - 28, y: 7, width: 30, height: 30)
        _numberLabel?.frame = (_numberImageView?.frame)!

        configCropView()

    }

    //MARK: - UIScrollViewDelegate
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {

        var offSetWidth = scrollView.contentOffset.x;
        offSetWidth = offSetWidth +  ((view.frame.width + 20) * 0.5)

        let index = offSetWidth / (view.frame.width + 20)

        if (Int(index) < models.count && currentIndex != Int(index)) {
            currentIndex = Int(index)
            self.refreshNaviBarAndBottomBarState()
        }
        NotificationCenter.default.post(name: Notification.Name("photoPreviewCollectionViewDidScroll"), object: nil)
    }

    //MARK: - UICollectionViewDataSource && Delegate
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return models.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let tzImagePickerVc = self.navigationController as? TZImagePickerController else {
            return UICollectionViewCell()
        }

        let model = models[indexPath.row]

        var cell: TZAssetPreviewCell?

        if tzImagePickerVc.allowPickingMultipleVideo && model.type == .video {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TZVideoPreviewCell", for: indexPath) as! TZVideoPreviewCell
        } else if tzImagePickerVc.allowPickingMultipleVideo && model.type == .photoGif && tzImagePickerVc.allowPickingGif {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TZGifPreviewCell", for: indexPath) as! TZGifPreviewCell
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TZPhotoPreviewCell", for: indexPath) as! TZPhotoPreviewCell
            (cell as! TZPhotoPreviewCell).cropRect = tzImagePickerVc.cropRect
            (cell as! TZPhotoPreviewCell).allowCrop = tzImagePickerVc.allowCrop
            (cell as! TZPhotoPreviewCell).imageProgressUpdateBlock = {[weak self] (progress) -> (Void) in
                self?.progress = progress
                if (self?.isSelectOriginalPhoto)! {
                    self?.showPhotoBytes()
                }
                if (self?.alertView != nil) && (self?._collectionView?.visibleCells.contains(cell!))! {
                    tzImagePickerVc.hideAlertView(alertView: self?.alertView as! UIAlertController)
                    self?.alertView = nil
                    self?.doneButtonClick()
                }
            }
        }
        cell?.singleTapGestureBlock = {[weak self] () -> (Void) in
            self?.didTapPreviewCell()
        }
        cell?.model = model
        return cell!
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if cell.isKind(of: TZPhotoPreviewCell.classForCoder()) {
            (cell as! TZPhotoPreviewCell).recoverSubviews()
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if cell.isKind(of: TZPhotoPreviewCell.classForCoder()) {
            (cell as! TZPhotoPreviewCell).recoverSubviews()
        } else if cell.isKind(of: TZVideoPreviewCell.classForCoder()) {
            (cell as! TZVideoPreviewCell).pausePlayerAndShowNaviBar()
        }
    }

    //MARK: - Click Event
    @objc func select(selectButton: UIButton) {
        guard let _tzImagePickerVc = self.navigationController as? TZImagePickerController else {
            return
        }

        let model = models[currentIndex]
        if !selectButton.isSelected {
            if _tzImagePickerVc.selectedModels.count >= _tzImagePickerVc.maxImagesCount {
                let title = String(format: NSLocalizedString("Select a maximum of %zd photos", tableName: nil, bundle: bundle!, comment: ""), _tzImagePickerVc.maxImagesCount)
                _ = _tzImagePickerVc.showAlert(title: title)
                return
            } else {
                _tzImagePickerVc.selectedModels.append(model)

                if !self.photos.isEmpty {
                    _tzImagePickerVc.selectedAssets.append(_assetsTemp[currentIndex])
                    let photo = _photosTemp[currentIndex]
                    self.photos.append(photo)
                }
                if model.type == .video && !_tzImagePickerVc.allowPickingMultipleVideo {
                    _ = _tzImagePickerVc.showAlert(title: Bundle.tz_localizedString(forKey: "Select the video when in multi state, we will handle the video as a photo"))
                }
            }
        } else {
            let selectedModels = _tzImagePickerVc.selectedModels
            for model_item in selectedModels {
                if model.asset.localIdentifier == model_item.asset.localIdentifier {
                    let selectedModelsTmp = _tzImagePickerVc.selectedModels
                    for (index, model1) in selectedModelsTmp.enumerated() {
                        if model1.isEqual(model_item) {
                            _tzImagePickerVc.selectedModels.remove(at: index)
                            break
                        }
                    }

                    if !self.photos.isEmpty {
                        let selectedAssetsTmp = _tzImagePickerVc.selectedAssets
                        for i in 0 ..< selectedAssetsTmp.count {
                            let asset = selectedAssetsTmp[i]
                            if asset.isEqual(_assetsTemp[currentIndex]) {
                                _tzImagePickerVc.selectedAssets.remove(at: i)
                                break
                            }
                        }
//                        for (index, asset) in selectedAssetsTmp.enumerated() {
//                        }
                        let index = self.photos.index(of: _photosTemp[currentIndex])
                        self.photos.remove(at: index!)
                    }
                    break
                }
            }
        }
        model.isSelected = !selectButton.isSelected
        self.refreshNaviBarAndBottomBarState()
        if model.isSelected {
            UIView.showOscillatoryAnimationWithLayer(layer: (selectButton.imageView?.layer)!, type: .bigger)
        }
        UIView.showOscillatoryAnimationWithLayer(layer: (_numberImageView?.layer)!, type: .smaller)
    }

    @objc func originalPhotoButtonClick(_ sender: UIButton) {

        guard let _tzImagePickerVc = self.navigationController as? TZImagePickerController else {
            return
        }
        sender.isSelected = !sender.isSelected
        isSelectOriginalPhoto = sender.isSelected
        _originalPhotoLabel?.isHidden = !sender.isSelected
        if isSelectOriginalPhoto {
            self.showPhotoBytes()
            if !(_selectButton?.isSelected)! {
                // 如果当前已选择照片张数 < 最大可选张数 && 最大可选张数大于1，就选中该张图
                if _tzImagePickerVc.selectedModels.count < _tzImagePickerVc.maxImagesCount && _tzImagePickerVc.showSelectBtn {
                    self.select(selectButton: _selectButton!)
                }
            }
        }
    }

    @objc func backButtonClick() {
        if ((self.navigationController?.children.count)! < 2) {
            self.navigationController?.dismiss(animated: true, completion: nil)
            return;
        }
        self.navigationController?.popViewController(animated: true)
        if self.backButtonClickBlock != nil {
            self.backButtonClickBlock?(isSelectOriginalPhoto)
        }
    }

    @objc func doneButtonClick() {

        guard let _tzImagePickerVc = self.navigationController as? TZImagePickerController else {
            return
        }

        // 如果图片正在从iCloud同步中,提醒用户
        if (Int(progress) > 0 && Int(progress) < 1 && (_selectButton!.isSelected || !_tzImagePickerVc.selectedModels.isEmpty)) {
            alertView = _tzImagePickerVc.showAlert(title: Bundle.tz_localizedString(forKey: "Synchronizing photos from iCloud"))
            return
        }

        // 如果没有选中过照片 点击确定时选中当前预览的照片
        if (_tzImagePickerVc.selectedModels.count == 0 && _tzImagePickerVc.minImagesCount <= 0) {
            let model = models[currentIndex];
            _tzImagePickerVc.selectedModels.append(model)
        }
        if _tzImagePickerVc.allowCrop { // 裁剪状态
            let indexPath = IndexPath(item: currentIndex, section: 0)
            let cell: TZPhotoPreviewCell? = _collectionView?.cellForItem(at: indexPath) as? TZPhotoPreviewCell
            var cropedImage = TZImageCropManager.crop(imageView: cell?.previewView?.imageView, rect: _tzImagePickerVc.cropRect, zoomScale: Double((cell?.previewView?.scrollView?.zoomScale)!), containerView: view)
            if _tzImagePickerVc.needCircleCrop {
                cropedImage = TZImageCropManager.circular(clipImage: cropedImage)
            }
            if self.doneButtonClickBlockCropMode != nil {
                let model = models[currentIndex];
                self.doneButtonClickBlockCropMode?(cropedImage,model.asset);
            }
        } else if self.doneButtonClickBlock != nil { // 非裁剪状态
            self.doneButtonClickBlock?(isSelectOriginalPhoto);
        }
        if self.doneButtonClickBlockWithPreviewType != nil {
            self.doneButtonClickBlockWithPreviewType?(self.photos, _tzImagePickerVc.selectedAssets, self.isSelectOriginalPhoto);
        }
    }

    public func didTapPreviewCell()  {
        self.isHideNaviBar = !self.isHideNaviBar
        _naviBar?.isHidden = self.isHideNaviBar
        _toolBar?.isHidden = self.isHideNaviBar
    }

    public func showPhotoBytes() {
        TZImageManager.manager.getPhotos(bytesWithArray: [models[currentIndex]]) { (totalBytes) -> (Void) in
            self._originalPhotoLabel?.text = "(\(totalBytes!))"
        }
    }

    //MARK: - Notification
    @objc func didChangeStatusBarOrientationNotification(notification: Notification)  {
        _offsetItemCount = (_collectionView?.contentOffset.x)! / (_layout?.itemSize.width)!
    }

    public func refreshNaviBarAndBottomBarState() {
        guard let _tzImagePickerVc = self.navigationController as? TZImagePickerController  else { return }

        let model = models[currentIndex]
        _selectButton?.isSelected = model.isSelected
        _numberLabel?.text = "\(_tzImagePickerVc.selectedModels.count)"
        _numberImageView?.isHidden = (_tzImagePickerVc.selectedModels.count <= 0 || isHideNaviBar || isCropImage)
        _numberLabel?.isHidden = (_tzImagePickerVc.selectedModels.count <= 0 || isHideNaviBar || isCropImage)

        _originalPhotoButton?.isSelected = isSelectOriginalPhoto
        _originalPhotoLabel?.isHidden = !(_originalPhotoButton?.isSelected)!
        if isSelectOriginalPhoto {
            self.showPhotoBytes()
        }

        // If is previewing video, hide original photo button
        // 如果正在预览的是视频，隐藏原图按钮
        if (!isHideNaviBar) {
            if (model.type == .video) {
                _originalPhotoButton?.isHidden = true
                _originalPhotoLabel?.isHidden = true
            } else {
                _originalPhotoButton?.isHidden = false
                if (isSelectOriginalPhoto) {
                    _originalPhotoLabel?.isHidden = false
                }
            }
        }

        _doneButton?.isHidden = false
        _selectButton?.isHidden = !_tzImagePickerVc.showSelectBtn
        // 让宽度/高度小于 最小可选照片尺寸 的图片不能选中
        if !TZImageManager.manager.isPhoto(selectableWithAsset: model.asset) {
            _numberLabel?.isHidden = true
            _numberImageView?.isHidden = true
            _selectButton?.isHidden = true
            _originalPhotoButton?.isHidden = true
            _originalPhotoLabel?.isHidden = true
            _doneButton?.isHidden = true
        }

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

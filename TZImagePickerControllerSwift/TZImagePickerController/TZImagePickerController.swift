//
//  TZImagePickerController.swift
//  TZImagePickerControllerSwift
//
//  Created by Huang.Tan on 2018/1/3.
//  Copyright © 2018年 Huang.Tan All rights reserved.
//

import UIKit
import Photos

@objc public protocol TZImagePickerControllerDelegate: NSObjectProtocol {
    // The picker should dismiss itself; when it dismissed these handle will be called.
    // You can also set autoDismiss to NO, then the picker don't dismiss itself.
    // If isOriginalPhoto is YES, user picked the original photo.
    // You can get original photo with asset, by the method [[TZImageManager manager] getOriginalPhotoWithAsset:completion:].
    // The UIImage Object in photos default width is 828px, you can set it by photoWidth property.
    // 这个照片选择器会自己dismiss，当选择器dismiss的时候，会执行下面的handle
    // 你也可以设置autoDismiss属性为NO，选择器就不会自己dismis了
    // 如果isSelectOriginalPhoto为YES，表明用户选择了原图
    // 你可以通过一个asset获得原图，通过这个方法：[[TZImageManager manager] getOriginalPhotoWithAsset:completion:]
    // photos数组里的UIImage对象，默认是828像素宽，你可以通过设置photoWidth属性的值来改变它
    @objc optional func imagePickerController(_ picker: TZImagePickerController, didFinishPicking photos: [UIImage], sourceAssets: [PHAsset], isSelectOriginalPhoto: Bool, infos: [Dictionary<String, Any>]?)

    @objc optional func tz_imagePickerControllerDidCancel(_ picker: TZImagePickerController)

    // If user picking a video, this callback will be called.
    // 如果用户选择了一个视频，下面的handle会被执行
    @objc optional func imagePickerController(_ picker: TZImagePickerController, didFinishPickingVideo coverImage: UIImage, sourceAssets: PHAsset)

    // If user picking a gif image, this callback will be called.
    // 如果用户选择了一个gif图片，下面的handle会被执行
    @objc optional func imagePickerController(_ picker: TZImagePickerController, didFinishPickingGifImage animatedImage: UIImage, sourceAssets: PHAsset)

    // Decide album show or not't
    // 决定相册显示与否 albumName:相册名字 result:相册原始数据
    @objc optional func isAlbumCanSelect(albumName: String, result: PHFetchResult<PHAsset>) -> Bool

    // Decide asset show or not't
    // 决定照片显示与否
    @objc optional func isAssetCanSelect(asset: PHAsset) -> Bool

}


public class TZImagePickerController: UINavigationController {
    //MARK: - private
    private var _timer: Timer?
    private var _tipLabel: UILabel?
    private var _settingBtn: UIButton?
    private var _didPushPhotoPickerVc = false

    private var _progressHUD: UIButton?
    private var _HUDContainer: UIView?
    private var _HUDIndicatorView: UIActivityIndicatorView?
    private var _HUDLabel: UILabel?

    private var _originStatusBarStyle: UIStatusBarStyle?
    /// Default is 4, Use in photos collectionView in TZPhotoPickerController
    /// 默认4列, TZPhotoPickerController中的照片collectionView
    private var columnNumber: Int = 4 {
        didSet {
            if columnNumber <= 2 {
                columnNumber = 2
            } else if columnNumber >= 6 {
                columnNumber = 6
            }

            if (self.children.first?.isMember(of: TZAlbumPickerController.classForCoder()))! {
                let albumPickerVC: TZAlbumPickerController = self.children.first as! TZAlbumPickerController
                albumPickerVC.columnNumber = columnNumber
            }
            TZImageManager.manager.columnNumber = columnNumber
        }
    }

    //MARK: - open
    public var pushPhotoPickerVc = false

    /// Default is 9 / 默认最大可选9张图片
    public var maxImagesCount: Int = 9 {
        didSet {
            if maxImagesCount > 1 {
                showSelectBtn = true
                allowCrop = false
            }
        }
    }

    /// The minimum count photos user must pick, Default is 0
    /// 最小照片必选张数,默认是0
    public var minImagesCount: Int = 0

    /// Always enale the done button, not require minimum 1 photo be picked
    /// 让完成按钮一直可以点击，无须最少选择一张图片
    public var alwaysEnableDoneBtn: Bool = true

    /// Sort photos ascending by modificationDate，Default is YES
    /// 对照片排序，按修改时间升序，默认是YES。如果设置为NO,最新的照片会显示在最前面，内部的拍照按钮会排在第一个
    public var sortAscendingByModificationDate: Bool = true {
        didSet {
            TZImageManager.manager.sortAscendingByModificationDate = sortAscendingByModificationDate;
        }
    }

    /// The pixel width of output image, Default is 828px / 导出图片的宽度，默认828像素宽
    public var photoWidth: CGFloat = 828.0 {
        didSet {
            TZImageManager.manager.photoWidth = photoWidth
        }
    }

    /// Default is 600px / 默认600像素宽
    public var photoPreviewMaxWidth: CGFloat = 600.0 {
        didSet {
            if photoPreviewMaxWidth > 800 {
                photoPreviewMaxWidth = 800
            } else if photoPreviewMaxWidth < 500 {
                photoPreviewMaxWidth = 500
            }
            TZImageManager.manager.photoPreviewMaxWidth = photoPreviewMaxWidth
        }
    }

    /// Default is 15, While fetching photo, HUD will dismiss automatic if timeout;
    /// 超时时间，默认为15秒，当取图片时间超过15秒还没有取成功时，会自动dismiss HUD；
    public var timeout: TimeInterval = 15 {
        didSet {
            if timeout < 5 {
                timeout = 5
            } else if timeout > 60 {
                timeout = 60
            }
        }
    }

    /// Default is YES, if set NO, the original photo button will hide. user can't picking original photo.
    /// 默认为YES，如果设置为NO,原图按钮将隐藏，用户不能选择发送原图
    public var allowPickingOriginalPhoto: Bool = true

    /// Default is YES, if set NO, user can't picking video.
    /// 默认为YES，如果设置为NO,用户将不能选择视频
    public var allowPickingVideo: Bool = true {
        didSet {
            TZImageManager.manager.allowPickingVideo = allowPickingVideo
        }
    }
    /// Default is NO / 默认为NO，为YES时可以多选视频/gif图片，和照片共享最大可选张数maxImagesCount的限制
    public var allowPickingMultipleVideo: Bool = false

    /// Default is NO, if set YES, user can picking gif image.
    /// 默认为NO，如果设置为YES,用户可以选择gif图片
    public var allowPickingGif: Bool = false

    /// Default is YES, if set NO, user can't picking image.
    /// 默认为YES，如果设置为NO,用户将不能选择发送图片
    public var allowPickingImage: Bool = true {
        didSet {
            TZImageManager.manager.allowPickingImage = allowPickingImage
        }
    }

    /// Default is YES, if set NO, user can't take picture.
    /// 默认为YES，如果设置为NO,拍照按钮将隐藏,用户将不能选择照片
    public var allowTakePicture: Bool = true

    /// Default is YES, if set NO, user can't preview photo.
    /// 默认为YES，如果设置为NO,预览按钮将隐藏,用户将不能去预览照片
    public var allowPreview: Bool = true

    /// Default is YES, if set NO, the picker don't dismiss itself.
    /// 默认为YES，如果设置为NO, 选择器将不会自己dismiss
    public var autoDismiss: Bool = true

    /// The photos user have selected
    /// 用户选中过的图片数组
    public var selectedAssets = [PHAsset]() {
        didSet {
            selectedModels.removeAll()
            for asset in selectedAssets {
                let model = TZAssetModel(asset: asset, type: TZImageManager.manager.getAssetType(asset: asset), isSelected: false, timeLength: "0")
                model.isSelected = true
                selectedModels.append(model)
            }
        }
    }
    public var selectedModels = [TZAssetModel]()

    /// Minimum selectable photo width, Default is 0
    /// 最小可选中的图片宽度，默认是0，小于这个宽度的图片不可选中
    public var minPhotoWidthSelectable: CGFloat = 0 {
        didSet {
            TZImageManager.manager.minPhotoWidthSelectable = minPhotoWidthSelectable
        }
    }

    public var minPhotoHeightSelectable: Int = 0
    /// Hide the photo what can not be selected, Default is NO
    /// 隐藏不可以选中的图片，默认是NO，不推荐将其设置为YES
    public var hideWhenCanNotSelect: Bool = false {
        didSet {
            TZImageManager.manager.hideWhenCanNotSelect = hideWhenCanNotSelect
        }
    }

    /// 顶部statusBar 是否为系统默认的黑色，默认为NO
    public var isStatusBarDefault: Bool = false
    /// Single selection mode, valid when maxImagesCount = 1
    /// 单选模式,maxImagesCount为1时才生效
    ///< 在单选模式下，照片列表页中，显示选择按钮,默认为NO
    public var showSelectBtn: Bool = false {
        didSet {
            if showSelectBtn == false && maxImagesCount > 1 {
                showSelectBtn = true
            }
        }
    }

    public var allowCrop: Bool = false {
        didSet {
            if allowCrop {
                self.allowPickingOriginalPhoto = false
                self.allowPickingGif = false
            }
        }
    }            ///< 允许裁剪,默认为YES，showSelectBtn为NO才生效

    public var cropRect: CGRect = CGRect.zero {
        didSet {
            cropRectPortrait = cropRect
            let widthHeight = cropRect.size.width
            cropRectLandscape = CGRect(x: (view.frame.height - widthHeight) * 0.5, y: cropRect.origin.x, width: widthHeight, height: widthHeight)
        }
    }           ///< 裁剪框的尺寸

    public var cropRectPortrait: CGRect = CGRect.zero;   ///< 裁剪框的尺寸(竖屏)
    public var cropRectLandscape: CGRect = CGRect.zero;  ///< 裁剪框的尺寸(横屏)
    public var needCircleCrop: Bool = false;       ///< 需要圆形裁剪框
    public var circleCropRadius: CGFloat = 0 {
        didSet {
            cropRect = CGRect(x: view.frame.width * 0.5 - circleCropRadius, y: view.frame.height * 0.5 - circleCropRadius, width: circleCropRadius * 2, height: circleCropRadius * 2)
        }
    };  ///< 圆形裁剪框半径大小

    public var cropViewSettingBlock: ((_ cropView: UIView) -> Void)? ///< 自定义裁剪框的其他属性
    public var navLeftBarButtonSettingBlock: ((_ leftButton: UIButton) -> Void)?    ///< 自定义返回按钮样式及其属性

    public var isSelectOriginalPhoto: Bool = false

    public var takePictureImageName            = "takePicture"
    public var photoSelImageName               = "photo_sel_photoPickerVc"
    public var photoDefImageName               = "photo_def_photoPickerVc"
    public var photoOriginSelImageName         = "photo_original_sel"
    public var photoOriginDefImageName         = "photo_original_def"
    public var photoPreviewOriginDefImageName  = "preview_original_def"
    public var photoNumberIconImageName        = "photo_number_icon"

    /// Appearance / 外观颜色 + 按钮文字
    public var oKButtonTitleColorNormal = UIColor(red: 83/255.0, green: 179/255.0, blue: 17/255.0, alpha: 1)
    public var oKButtonTitleColorDisabled = UIColor(red: 83/255.0, green: 179/255.0, blue: 17/255.0, alpha: 1)
    
    public var naviBgColor: UIColor? {
        didSet {
            self.navigationBar.barTintColor = naviBgColor
        }
    }

    public var naviTitleColor: UIColor? {
        didSet {
            self.configNaviTitleAppearance()
        }
    }

    public var naviTitleFont: UIFont? {
        didSet {
            self.configNaviTitleAppearance()
        }
    }

    public var barItemTextColor: UIColor? {
        didSet {
            self.configBarButtonItemAppearance()
        }
    }

    public var barItemTextFont: UIFont? {
        didSet {
            self.configBarButtonItemAppearance()
        }
    }

    public var doneBtnTitleStr = Bundle.tz_localizedString(forKey: "Done")
    public var cancelBtnTitleStr = Bundle.tz_localizedString(forKey: "Cancel")
    public var previewBtnTitleStr = Bundle.tz_localizedString(forKey: "Preview")
    public var fullImageBtnTitleStr = Bundle.tz_localizedString(forKey: "Full image")
    public var settingBtnTitleStr = Bundle.tz_localizedString(forKey: "Setting")
    public var processHintStr = Bundle.tz_localizedString(forKey: "Processing...")
    
    /// 预览按钮文字颜色
    public var previewBtnTitleDefColor = UIColor.black
    public var previewBtnTitleDisColor = UIColor.lightGray
    
    // 相片选择器底部ToolBar背景色
    public var photoPickerBottomToolBarBgColor = UIColor(red: 235 / 255.0, green: 235 / 255.0, blue: 235 / 255.0, alpha: 1)

    public var didFinishPickingPhotosWithInfosHandle: ((_ photos: Array<UIImage>, _ assets: Array<PHAsset>, _ isSelectOriginalPhoto: Bool, _ infos: Array<Dictionary<String, Any>>?) -> (Swift.Void))?
    public var imagePickerControllerDidCancelHandle: (() -> (Swift.Void))?

    // If user picking a video, this handle will be called.
    // 如果用户选择了一个视频，下面的handle会被执行
    public var didFinishPickingVideoHandle: ((_ coverImage: UIImage, _ asset: PHAsset) -> (Swift.Void))?

    // If user picking a gif image, this callback will be called.
    // 如果用户选择了一个gif图片，下面的handle会被执行
    public var didFinishPickingGifImageHandle: ((_ animatedImage: UIImage, _ sourceAssets: PHAsset) -> (Swift.Void))?

    public weak var pickerDelegate: TZImagePickerControllerDelegate?

    public init(delegate: TZImagePickerControllerDelegate, maxImagesCount: Int = 9, columnNumber: Int = 4, pushPhotoPickerVc: Bool = true) {
        let rootViewController = TZAlbumPickerController()
        super.init(rootViewController: rootViewController)
        rootViewController.columnNumber = columnNumber
        self.pushPhotoPickerVc = pushPhotoPickerVc
        self.columnNumber = columnNumber
        self.maxImagesCount = maxImagesCount
        self.pickerDelegate = delegate

        initDelegateData()

        if TZImageManager.manager.authorizationStatusAuthorized() {
            pushPhotoPickerViewController()
        } else {
            _tipLabel = UILabel()
            _tipLabel?.frame = CGRect(x: 8, y: 120, width: view.frame.width - 16, height: 60)
            _tipLabel?.textAlignment = .center
            _tipLabel?.numberOfLines = 0
            _tipLabel?.font = UIFont.systemFont(ofSize: 16)
            _tipLabel?.textColor = UIColor.black
            var infoDict = Bundle.main.localizedInfoDictionary
            if infoDict == nil {
                infoDict = Bundle.main.infoDictionary
            }
            var appName = infoDict?["CFBundleDisplayName"]
            if appName == nil { appName = infoDict?["CFBundleName"] }
            let tipText = String(format: NSLocalizedString("Allow %@ to access your album in \"Settings -> Privacy -> Photos\"", tableName: nil, bundle: bundle!, comment: ""), Bundle.tz_localizedString(forKey: appName as! String))
            _tipLabel?.text = tipText
            view.addSubview(_tipLabel!)

            _settingBtn = UIButton(type: .system)
            _settingBtn?.frame = CGRect(x: 0, y: 180, width: view.frame.width, height: 44)
            _settingBtn?.setTitle(settingBtnTitleStr, for: .normal)
            _settingBtn?.titleLabel?.font = UIFont.systemFont(ofSize: 18)
            _settingBtn?.addTarget(self, action: #selector(settingBtnClick(_:)), for: .touchUpInside)
            view.addSubview(_settingBtn!)

            _timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(observeAuthrizationStatusChange), userInfo: nil, repeats: true)
        }
    }

    /// This init method just for previewing photos / 用这个初始化方法以预览图片
    public init(selectedAssets: Array<PHAsset>, selectedPhotos: Array<UIImage>, index: Int) {
        let rootViewController = TZPhotoPreviewController()
        super.init(rootViewController: rootViewController)
        self.selectedAssets = selectedAssets

        initSelecedData()

        rootViewController.photos = selectedPhotos
        rootViewController.currentIndex = index
        rootViewController.doneButtonClickBlockWithPreviewType = {[weak self] (photos, assets, isSelectOriginalPhoto) -> (Void) in
            self?.dismiss(animated: true, completion: {
                self?.didFinishPickingPhotosWithInfosHandle?(photos!, assets!, isSelectOriginalPhoto!, nil)
            })
        }
    }

    /// This init method for crop photo / 用这个初始化方法以裁剪图片
    public init(cropTypeWithAsset asset: PHAsset, photo: UIImage, completion: ((_ cropImage: UIImage?, _ asset: PHAsset?) -> ())?) {
        let rootViewController = TZPhotoPreviewController()
        super.init(rootViewController: rootViewController)
        self.maxImagesCount = 1
        self.allowCrop = true
        self.selectedAssets = [asset]

        /// init初始化属性时，不会调用didSet方法，需要额外设置
        initCropData()
        
        let cropViewWH = min(self.view.frame.width, self.view.frame.height) / 3 * 2
        self.cropRect = CGRect(x: (self.view.frame.width - cropViewWH) * 0.5, y: (self.view.frame.height - cropViewWH) / 2, width: cropViewWH, height: cropViewWH)

        rootViewController.photos = [photo]
        rootViewController.isCropImage = true
        rootViewController.currentIndex = 0

        rootViewController.doneButtonClickBlockCropMode = {[weak self] (cropImage, asset) -> (Void) in
            self?.dismiss(animated: true, completion: {
                completion?(cropImage, asset)
            })
        }
    }


    private func initCropData() {

        if allowCrop {
            self.allowPickingOriginalPhoto = false
            self.allowPickingGif = false
        }

        initSelecedData()
    }

    private func initSelecedData() {

        for asset in selectedAssets {
            let model = TZAssetModel(asset: asset, type: TZImageManager.manager.getAssetType(asset: asset), isSelected: false, timeLength: "0")
            model.isSelected = true
            selectedModels.append(model)
        }
    }


    private func initDelegateData() {

        if maxImagesCount > 1 {
            showSelectBtn = true
            allowCrop = false
        }

        if columnNumber <= 2 {
            columnNumber = 2
        } else if columnNumber >= 6 {
            columnNumber = 6
        }

        if (self.children.first?.isMember(of: TZAlbumPickerController.classForCoder()))! {
            let albumPickerVC: TZAlbumPickerController = self.children.first as! TZAlbumPickerController
            albumPickerVC.columnNumber = columnNumber
        }
        TZImageManager.manager.columnNumber = columnNumber

        TZImageManager.manager.pickerDelegate = pickerDelegate

    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - override

    override public func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white
        navigationBar.barStyle = .black
        navigationBar.isTranslucent = true

        navigationBar.barTintColor = UIColor(red: 34 / 255.0, green: 34 / 255.0, blue: 34 / 255.0, alpha: 1)
        navigationBar.tintColor = UIColor.white
        automaticallyAdjustsScrollViewInsets = false
        if !Bundle.TZ_isGlobalHideStatusBar() {
            UIApplication.shared.isStatusBarHidden = false
        }
    }


    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _originStatusBarStyle = UIApplication.shared.statusBarStyle

        UIApplication.shared.statusBarStyle = self.isStatusBarDefault ? .default : .lightContent
    }


    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.statusBarStyle = _originStatusBarStyle!
    }
    

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        _HUDContainer?.frame = CGRect(x: (view.frame.width - 120) * 0.5, y: (view.frame.height - 90) * 0.5, width: 120, height: 90)
        _HUDIndicatorView?.frame = CGRect(x: 45, y: 15, width: 30, height: 30)
        _HUDLabel?.frame = CGRect(x: 0, y: 40, width: 120, height: 50)
    }


    override public func pushViewController(_ viewController: UIViewController, animated: Bool) {
        viewController.automaticallyAdjustsScrollViewInsets = false
        if _timer != nil {
            _timer?.invalidate()
            _timer = nil
        }
        super.pushViewController(viewController, animated: animated)
    }

    //MARK: - UIContentContainer

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.willInterfaceOrientionChange()
        if size.width > size.height {
            cropRect = cropRectLandscape
        } else {
            cropRect = cropRectPortrait
        }
    }

    func willInterfaceOrientionChange() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.02) {
            if !UIApplication.shared.isStatusBarHidden {
                UIApplication.shared.isStatusBarHidden = false
            }
        }
    }

    func pushPhotoPickerViewController() {
        _didPushPhotoPickerVc = false
        if !_didPushPhotoPickerVc && pushPhotoPickerVc {
            let photoPickerVc = TZPhotoPickerController()
            photoPickerVc.isFirstAppear = true
            photoPickerVc.columnNumber = self.columnNumber
            TZImageManager.manager.getCameraRollAlbum(allowPickingVideo: allowPickingVideo, allowPickingImage: allowPickingImage, completion: { (albumModel) in
                photoPickerVc.model = albumModel
                self.pushViewController(photoPickerVc, animated: true)
                self._didPushPhotoPickerVc = true
            })
        }

        let albumPickerVc = self.visibleViewController
        if (albumPickerVc?.isKind(of: TZAlbumPickerController.classForCoder()))! {
            (albumPickerVc as! TZAlbumPickerController).configTableView()
        }
    }

    func showAlert(title: String) -> UIAlertController {
        let alertVC = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: Bundle.tz_localizedString(forKey: "OK"), style: .default, handler: nil))
        self.present(alertVC, animated: true, completion: nil)
        return alertVC
    }

    func hideAlertView(alertView: UIAlertController) {
        alertView.dismiss(animated: true, completion: nil)
    }

    func showProgressHUD() {
        if _progressHUD == nil {
            _progressHUD = UIButton(type: .custom)
            _progressHUD?.backgroundColor = UIColor.clear

            _HUDContainer = UIView()
            _HUDContainer?.layer.cornerRadius = 8
            _HUDContainer?.clipsToBounds = true
            _HUDContainer?.backgroundColor = UIColor.darkGray
            _HUDContainer?.alpha = 0.7

            _HUDIndicatorView = UIActivityIndicatorView(style: .white)
            
            _HUDLabel = UILabel()
            _HUDLabel?.textAlignment = .center
            _HUDLabel?.text = self.processHintStr
            _HUDLabel?.font = UIFont.systemFont(ofSize: 15)
            _HUDLabel?.textColor = UIColor.white

            _HUDContainer?.addSubview(_HUDLabel!)
            _HUDContainer?.addSubview(_HUDIndicatorView!)
            _progressHUD?.addSubview(_HUDContainer!)
        }

        _HUDIndicatorView?.startAnimating()
        UIApplication.shared.keyWindow?.addSubview(_progressHUD!)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + self.timeout) {
            self.hideProgressHUD()
        }
    }

    func hideProgressHUD() {
        if _progressHUD != nil {
            _HUDIndicatorView?.stopAnimating()
            _progressHUD?.removeFromSuperview()
        }
    }


    //MARK: - Click Method

    @objc private func settingBtnClick(_ sender: UIButton) {
        UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
    }

    @objc private func observeAuthrizationStatusChange() {
        if TZImageManager.manager.authorizationStatusAuthorized() {
            _tipLabel?.removeFromSuperview()
            _settingBtn?.removeFromSuperview()
            _timer?.invalidate()
            _timer = nil
            self.pushPhotoPickerViewController()
        }
    }

    //MARK: - Private Method
    private func configNaviTitleAppearance() {

        var textAttrs = [NSAttributedString.Key: Any]()
        if let naviTitleColor = self.naviTitleColor {
            textAttrs[NSAttributedString.Key.foregroundColor] = naviTitleColor
        }
        if let naviTitleFont = self.naviTitleFont {
            textAttrs[NSAttributedString.Key.font] = naviTitleFont
        }
        self.navigationBar.titleTextAttributes = textAttrs
    }

    private func configBarButtonItemAppearance() {
        var barItem: UIBarButtonItem?
        if #available(iOS 9.0, *) {
            barItem = UIBarButtonItem.appearance(whenContainedInInstancesOf: [TZImagePickerController.classForCoder() as! UIAppearanceContainer.Type])
        } else {
            // Fallback on earlier versions
            barItem = UIBarButtonItem.appearance()
        }

        var textAttrs = [NSAttributedString.Key: Any]()
        if let barItemTextColor = self.barItemTextColor {
            textAttrs[NSAttributedString.Key.foregroundColor] = barItemTextColor
        }
        if let barItemTextFont = self.barItemTextFont {
            textAttrs[NSAttributedString.Key.font] = barItemTextFont
        }
        barItem?.setTitleTextAttributes(textAttrs, for: .normal)
    }

    @objc func cancelButtonClick() {
        if autoDismiss {
            self.dismiss(animated: true, completion: {
                self.callDelegateMethod()
            })
        } else {
            self.callDelegateMethod()
        }
    }

    func callDelegateMethod() {
        if (self.pickerDelegate?.responds(to: #selector(self.pickerDelegate?.tz_imagePickerControllerDidCancel(_:))))! {
            self.pickerDelegate?.tz_imagePickerControllerDidCancel!(self)
        }
        if self.imagePickerControllerDidCancelHandle != nil {
            self.imagePickerControllerDidCancelHandle?()
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













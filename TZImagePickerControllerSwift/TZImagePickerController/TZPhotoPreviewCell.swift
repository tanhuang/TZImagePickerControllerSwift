//
//  TZPhotoPreviewView.swift
//  TZImagePickerControllerSwift
//
//  Created by Huang.Tan on 2018/1/22.
//  Copyright © 2018年 Huang.Tan All rights reserved.
//

import UIKit
import Photos.PHAsset

class TZAssetPreviewCell: UICollectionViewCell {
    var model: TZAssetModel?
    var singleTapGestureBlock: (() -> (Swift.Void))?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black
        self.configSubviews()
        NotificationCenter.default.addObserver(self, selector: #selector(photoPreviewCollectionViewDidScroll), name: NSNotification.Name(rawValue: "photoPreviewCollectionViewDidScroll"), object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configSubviews() {


    }

    @objc func photoPreviewCollectionViewDidScroll() {

    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        debugPrint("释放了\(self.classForCoder)")
    }
}


class TZPhotoPreviewCell: TZAssetPreviewCell {


    var imageProgressUpdateBlock: ((_ progress: Double) -> (Swift.Void))?
    var previewView: TZPhotoPreviewView?

    var allowCrop: Bool = false {
        didSet {
            previewView?.allowCrop = allowCrop
        }
    }
    var cropRect: CGRect = CGRect.zero{
        didSet {
            previewView?.cropRect = cropRect
        }
    }

    override var model: TZAssetModel? {
        didSet {
            previewView?.asset = model?.asset
        }
    }

    override func configSubviews() {
        previewView = TZPhotoPreviewView()
        previewView?.singleTapGestureBlock = {[weak self] () -> (Void) in
            self?.singleTapGestureBlock?()
        }
        previewView?.imageProgressUpdateBlock = {[weak self] (progress) -> (Void) in
            self?.imageProgressUpdateBlock?(progress)
        }
        self.addSubview(previewView!)
    }

    func recoverSubviews() {
        previewView?.recoverSubviews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewView?.frame = self.bounds
    }

}



class TZPhotoPreviewView:  UIView, UIScrollViewDelegate {

    var imageView: UIImageView?
    var scrollView: UIScrollView?
    var imageContainerView: UIView?
    var progressView: TZProgressView?

    var allowCrop: Bool = false {
        didSet {
            if let _asset = self.asset {
                scrollView?.maximumZoomScale = allowCrop ? 4.0 : 2.5;
                let aspectRatio: CGFloat = CGFloat(_asset.pixelWidth / _asset.pixelHeight)
                // 优化超宽图片的显示
                if (aspectRatio > 1.5) {
                    self.scrollView?.maximumZoomScale *= aspectRatio / 1.5;
                }
            }
        }
    }
    var cropRect: CGRect = CGRect.zero

    var model: TZAssetModel? {
        didSet {
            scrollView?.setZoomScale(1.0, animated: false)
            if model?.type == .photoGif {
                _ = TZImageManager.manager.getPhoto(with: (model?.asset)!, networkAccessAllowed: false, completion: { (photo, info, isDegraded) -> (Void) in
                    self.imageView?.image = photo
                    self.resizeSubviews()
                    TZImageManager.manager.getOriginalPhotoData(self.model?.asset, completion: { (data, info, isDegraded) -> (Void) in
                        if !isDegraded! {
                            self.imageView?.image = UIImage.sd_tz_animated(GIFWithData: data)
                            self.resizeSubviews()
                        }
                    })
                }, progressHandler: { (progress, error, stop, info) -> (Void) in
                })
            } else {
                self.asset = model?.asset
            }
        }
    }
    var asset: PHAsset? {
        didSet {

            if (oldValue != nil) && (self.imageRequestID != nil) {
                PHImageManager.default().cancelImageRequest(imageRequestID!)
            }
            self.imageRequestID = TZImageManager.manager.getPhoto(with: asset!, networkAccessAllowed: true, completion: { (photo, info, isDegraded) -> (Void) in

                self.imageView?.image = photo
                self.resizeSubviews()
                self.progressView?.isHidden = true
                self.imageProgressUpdateBlock?(1)
                if !isDegraded! {
                    self.imageRequestID = 0
                }
            }, progressHandler: { (progress, error, stop, info) -> (Void) in
                var progress = progress!
                self.progressView?.isHidden = false
                self.bringSubviewToFront(self.progressView!)
                progress = progress > 0.02 ? progress : 0.02
                self.progressView?.progress = CGFloat(progress)
                self.imageProgressUpdateBlock?(progress)

                if progress >= 1 {
                    self.progressView?.isHidden = true
                    self.imageRequestID = 0
                }
            })
        }
    }

    var singleTapGestureBlock: (() -> (Swift.Void))?
    var imageProgressUpdateBlock: ((_ progress: Double) -> (Swift.Void))?
    var imageRequestID: Int32?

    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollView = UIScrollView()
        scrollView?.bouncesZoom = true;
        scrollView?.maximumZoomScale = 2.5;
        scrollView?.minimumZoomScale = 1.0;
        scrollView?.isMultipleTouchEnabled = true;
        scrollView?.delegate = self;
        scrollView?.scrollsToTop = false;
        scrollView?.showsHorizontalScrollIndicator = false;
        scrollView?.showsVerticalScrollIndicator = true;
        scrollView?.autoresizingMask = UIView.AutoresizingMask(rawValue: UIView.AutoresizingMask.flexibleWidth.rawValue | UIView.AutoresizingMask.flexibleHeight.rawValue)
        scrollView?.delaysContentTouches = false;
        scrollView?.canCancelContentTouches = true;
        scrollView?.alwaysBounceVertical = false;
        self.addSubview(scrollView!)

        imageContainerView = UIView()
        imageContainerView?.clipsToBounds = true;
        imageContainerView?.contentMode = .scaleAspectFill;
        scrollView?.addSubview(imageContainerView!)

        imageView = UIImageView()
        imageView?.backgroundColor = UIColor(white: 1, alpha: 0.5)
        imageView?.contentMode = .scaleAspectFill
        imageView?.clipsToBounds = true;
        imageContainerView?.addSubview(imageView!)

        let tap1 = UITapGestureRecognizer(target: self, action: #selector(singleTap(tap:)))
        self.addGestureRecognizer(tap1)

        let tap2 = UITapGestureRecognizer(target: self, action: #selector(doubleTap(tap:)))
        tap2.numberOfTapsRequired = 2;
        tap1.require(toFail: tap2)
        self.addGestureRecognizer(tap2)


        self.configProgressView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configProgressView() {
        progressView = TZProgressView()
        progressView?.isHidden = true
        self.addSubview(progressView!)
    }


    func recoverSubviews() {
        scrollView?.setZoomScale(0.1, animated: false)
        self.resizeSubviews()
    }

    func resizeSubviews() {
        imageContainerView?.frame.origin = CGPoint.zero;
        imageContainerView?.frame.size.width = (self.scrollView?.frame.width)!;

        let image = imageView?.image
        let image_height = (image?.size.height)!
        let image_width = (image?.size.width)!

        if (image_height / image_width > self.frame.height / (self.scrollView?.frame.width)!) {
            imageContainerView?.frame.size.height = floor(image_height / (image_width / (self.scrollView?.frame.width)!))
        } else {

            var height = image_height / image_width * (self.scrollView?.frame.width)!;
            if (height < 1 || height.isNaN) {
                height = self.frame.height;
            }
            height = floor(height);
            imageContainerView?.frame.size.height = height;
            imageContainerView?.center.y = self.frame.height / 2;
        }
        if ((imageContainerView?.frame.height)! > self.frame.height && (imageContainerView?.frame.height)! - self.frame.height <= 1) {
            imageContainerView?.frame.size.height = self.frame.height;
        }
        let contentSizeH = max((imageContainerView?.frame.height)!, self.frame.height)

        scrollView?.contentSize = CGSize(width: (self.scrollView?.frame.width)!, height: contentSizeH);
        scrollView?.scrollRectToVisible(self.bounds, animated: false)
        scrollView?.alwaysBounceVertical = (imageContainerView?.frame.height)! <= self.frame.height ? false : true
        imageView?.frame = (imageContainerView?.bounds)!;

        self.refreshScrollViewContentSize()
    }

    //MARK: - UITapGestureRecognizer Event
    @objc func singleTap(tap: UITapGestureRecognizer) {

        self.singleTapGestureBlock?()
    }

    @objc func doubleTap(tap: UITapGestureRecognizer) {
        if ((scrollView?.zoomScale)! > CGFloat(1.0)) {
            scrollView?.contentInset = UIEdgeInsets.zero;
            scrollView?.setZoomScale(1.0, animated: true)
        } else {
            let touchPoint = tap.location(in: self.imageView)
            let newZoomScale = scrollView?.maximumZoomScale;
            let xsize = self.frame.size.width / newZoomScale!;
            let ysize = self.frame.size.height / newZoomScale!;
            scrollView?.zoom(to: CGRect(x: touchPoint.x - xsize/2, y: touchPoint.y - ysize/2, width: xsize, height: ysize), animated: true)
        }
    }

    //MARK: - UIScrollerViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageContainerView
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.contentInset = UIEdgeInsets.zero
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        refreshImageContainerViewCenter()
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        refreshScrollViewContentSize()
    }

    //MARK: - Private
    private func refreshImageContainerViewCenter() {
        let offsetX = ((scrollView?.frame.width)! > (scrollView?.contentSize.width)!) ? (((scrollView?.frame.width)! - (scrollView?.contentSize.width)!) * 0.5) : 0.0;
        let offsetY = ((scrollView?.frame.height)! > (scrollView?.contentSize.height)!) ? (((scrollView?.frame.height)! - (scrollView?.contentSize.height)!) * 0.5) : 0.0
        self.imageContainerView?.center = CGPoint(x: (scrollView?.contentSize.width)! * 0.5 + offsetX, y: (scrollView?.contentSize.height)! * 0.5 + offsetY)
    }

    func refreshScrollViewContentSize() {
        if allowCrop {
            // 1.7.2 如果允许裁剪,需要让图片的任意部分都能在裁剪框内，于是对_scrollView做了如下处理：
            // 1.让contentSize增大(裁剪框右下角的图片部分)
            let contentWidthAdd = (self.scrollView?.frame.width)! - cropRect.maxX
            let contentHeightAdd = (min((imageContainerView?.frame.height)!, self.frame.height) - self.cropRect.size.height) / 2
            let newSizeW = (self.scrollView?.contentSize.width)! + contentWidthAdd
            let newSizeH = max((self.scrollView?.contentSize.height)!, self.frame.height) + contentHeightAdd
            scrollView?.contentSize = CGSize(width: newSizeW, height: newSizeH)
            scrollView?.alwaysBounceVertical = true
            // 2.让scrollView新增滑动区域（裁剪框左上角的图片部分）
            if (contentHeightAdd > 0 || contentWidthAdd > 0) {
                scrollView?.contentInset = UIEdgeInsets(top: contentHeightAdd, left: cropRect.origin.x, bottom: 0, right: 0)
            } else {
                scrollView?.contentInset = UIEdgeInsets.zero;
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        scrollView?.frame = CGRect(x: 10, y: 0, width: self.frame.width - 20, height: self.frame.height);
        let progressWH: CGFloat = 40;
        let progressX = (self.frame.width - progressWH) / 2;
        let progressY = (self.frame.height - progressWH) / 2;
        progressView?.frame = CGRect(x: progressX, y: progressY, width: progressWH, height: progressWH);

        self.recoverSubviews()
    }
}


class TZVideoPreviewCell: TZAssetPreviewCell {
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var playButton: UIButton?
    var cover: UIImage?

    override var model: TZAssetModel? {
        didSet {
            configMoviePlayer()
        }
    }

    override func configSubviews() {
        NotificationCenter.default.addObserver(self, selector: #selector(pausePlayerAndShowNaviBar), name: UIApplication.willResignActiveNotification, object: nil)
    }

    override func photoPreviewCollectionViewDidScroll() {
        self.pausePlayerAndShowNaviBar()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = self.bounds
        playButton?.frame = CGRect(x: 0, y: 64, width: frame.width, height: frame.height - 64 - 44)
    }

    func configMoviePlayer() {
        if player != nil {
            playerLayer?.removeFromSuperlayer()
            playerLayer = nil;
            player?.pause()
            player = nil
        }

        _ = TZImageManager.manager.getPhoto(with: (self.model?.asset)!, completion: { (photo, info, isDegraded) -> (Void) in
            self.cover = photo
        })

        TZImageManager.manager.getVideo(self.model?.asset, progressHandler: {
            (progress, error, stop, info) -> (Void) in

        }) { (playerItem, info) -> (Void) in
            DispatchQueue.main.async(execute: {
                self.player = AVPlayer(playerItem: playerItem)
                self.playerLayer = AVPlayerLayer(player: self.player!)
                self.playerLayer?.backgroundColor = UIColor.black.cgColor
                self.playerLayer?.frame = self.bounds
                self.layer.addSublayer(self.playerLayer!)
                self.configPlayButton()
                NotificationCenter.default.addObserver(self, selector: #selector(self.pausePlayerAndShowNaviBar), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
            })
        }
    }

    func configPlayButton() {
        if playButton != nil {
            playButton?.removeFromSuperview()
        }
        playButton = UIButton(type: .custom)
        playButton?.setImage(UIImage.imageNamedFromMyBundle(name: "MMVideoPreviewPlay"), for: .normal)
        playButton?.setImage(UIImage.imageNamedFromMyBundle(name: "MMVideoPreviewPlayHL"), for: .highlighted)
        playButton?.addTarget(self, action: #selector(playButtonClick), for: .touchUpInside)
        addSubview(playButton!)
    }

    @objc func playButtonClick() {
        let currentTime = player?.currentItem?.currentTime();
        let durationTime = player?.currentItem?.duration;
        if ((player?.rate)! == 0) {
            if ((currentTime?.value)! == durationTime?.value) {
                player?.currentItem?.seek(to: CMTimeMake(value: 0, timescale: 1))
            }
            player?.play()
            playButton?.setImage(nil, for: .normal)
            if !Bundle.TZ_isGlobalHideStatusBar() {
                UIApplication.shared.isStatusBarHidden = true
            }
            self.singleTapGestureBlock?()
        } else {
            self.pausePlayerAndShowNaviBar()
        }
    }

    @objc func pausePlayerAndShowNaviBar() {
        if ((player?.rate)! != 0.0) {
            player?.pause()
            playButton?.setImage(UIImage.imageNamedFromMyBundle(name: "MMVideoPreviewPlay"), for: .normal)
            self.singleTapGestureBlock?()
        }
    }


}


class TZGifPreviewCell: TZAssetPreviewCell {
    var previewView: TZPhotoPreviewView?

    override func configSubviews() {
        self.configPreviewView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewView?.frame = self.bounds
    }

    override var model: TZAssetModel? {
        didSet {
            previewView?.model = model
        }
    }

    func configPreviewView() {
        previewView = TZPhotoPreviewView()
        addSubview(previewView!)
        previewView?.singleTapGestureBlock = {[weak self] () -> (Void) in
            self?.singleTapGestureBlock?()
        }
    }
}










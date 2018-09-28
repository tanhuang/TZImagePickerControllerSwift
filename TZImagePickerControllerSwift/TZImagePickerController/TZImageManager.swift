//
//  TZImageManager.swift
//  TZImagePickerControllerSwift
//
//  Created by Huang.Tan on 2018/1/9.
//  Copyright © 2018年 Huang.Tan All rights reserved.
//

import UIKit
import Photos
import AssetsLibrary
import AVFoundation

public class TZImageManager: NSObject {

    public static let manager = TZImageManager()

    private override init() { }

    weak var pickerDelegate: TZImagePickerControllerDelegate?

    public var cachingImageManager = PHCachingImageManager()

    public var shouldFixOrientation: Bool = false

    /// Default is 600px / 默认600像素宽
    public var photoPreviewMaxWidth: CGFloat = 600
    /// The pixel width of output image, Default is 828px / 导出图片的宽度，默认828像素宽
    public var photoWidth: CGFloat = 828 {
        didSet {
            TZScreenWidth = photoWidth * 0.5
        }
    }

    /// Default is 4, Use in photos collectionView in TZPhotoPickerController
    /// 默认4列, TZPhotoPickerController中的照片collectionView
    public var columnNumber: Int = 4 {
        didSet {
            TZScreenWidth = UIScreen.main.bounds.width
            TZScreenScale = 2.0

            let margin: CGFloat = 4
            let itemWH = (TZScreenWidth - 2 * margin - 4) / CGFloat(columnNumber) - margin
            AssetGridThumbnailSize = CGSize(width: itemWH * TZScreenScale, height: itemWH * TZScreenScale)
        }
    }
    /// Sort photos ascending by modificationDate，Default is true
    /// 对照片排序，按修改时间升序，默认是YES。如果设置为NO,最新的照片会显示在最前面，内部的拍照按钮会排在第一个
    public var sortAscendingByModificationDate: Bool = true

    /// Minimum selectable photo width, Default is 0
    /// 最小可选中的图片宽度，默认是0，小于这个宽度的图片不可选中
    public var minPhotoWidthSelectable: CGFloat = 0
    public var minPhotoHeightSelectable: CGFloat = 0
    public var hideWhenCanNotSelect: Bool = false


    /// Default is YES, if set NO, user can't picking video.
    /// 默认为YES，如果设置为NO,用户将不能选择视频
    public var allowPickingVideo: Bool = true
    /// 默认为YES，如果设置为NO,用户将不能选择发送图片
    public var allowPickingImage: Bool = true

    private var TZScreenWidth: CGFloat = UIScreen.main.bounds.size.width
    private var TZScreenScale: CGFloat = 2.0
    private var AssetGridThumbnailSize: CGSize = .zero


    public func authorizationStatusAuthorized() -> Bool {
        let status = TZImageManager.authorizationStatus()
        if status == 0 {
            self.requestAuthorizationWithCompletion({ })
        }
        return status == 3
    }

    class public func authorizationStatus() -> Int {
        return PHPhotoLibrary.authorizationStatus().rawValue
    }

    public func requestAuthorizationWithCompletion(_ completion: @escaping () -> Swift.Void) {
        let callCompletionBlock = {
            DispatchQueue.main.async {
                completion()
            }
        }
        DispatchQueue.global().async {
            PHPhotoLibrary.requestAuthorization({ (status) in
                callCompletionBlock()
            })
        }
    }

    //MARK: - Get Album
    public func getCameraRollAlbum(allowPickingVideo: Bool, allowPickingImage: Bool, completion: @escaping (_ model: TZAlbumModel) -> Swift.Void) {
        
        let option = PHFetchOptions()
        if allowPickingVideo == false {
            option.predicate = NSPredicate(format: "mediaType == \(PHAssetMediaType.image.rawValue)")
        }
        if allowPickingImage == false {
            option.predicate = NSPredicate(format: "mediaType == \(PHAssetMediaType.video.rawValue)")
        }
        if self.sortAscendingByModificationDate == false {
            option.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: self.sortAscendingByModificationDate)]
        }
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.albumRegular, options: nil)
        smartAlbums.enumerateObjects { (collection, index, stop) in
            if self.isCameraRollAlbum(collection) {
                let fetchResult = PHAsset.fetchAssets(in: collection, options: option)
                let model = self.modelWithResult(result: fetchResult, name: collection.localizedTitle!, isCameraRoll: true)
                completion(model)
            }
        }
    }

    public func isCameraRollAlbum(_ metadata: PHCollection) -> Bool {
        if metadata.isMember(of: PHAssetCollection.classForCoder()) {
            let metadata = metadata as! PHAssetCollection
            var versionStr = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "")
            if versionStr.count <= 1 {
                versionStr = versionStr.appending("00")
            } else if versionStr.count <= 2 {
                versionStr = versionStr.appending("0")
            }
            let version = Int(versionStr) ?? 0
            if version >= 800 && version <= 802 {
                return metadata.assetCollectionSubtype == .smartAlbumRecentlyAdded
            } else {
                return metadata.assetCollectionSubtype == .smartAlbumUserLibrary
            }
        }
        return false;
    }


    public func getAllAlbums(allowPickingVideo: Bool, allowPickingImage: Bool, completion: @escaping ((_ array: [TZAlbumModel]) -> Swift.Void)) {
        var albumArr = [TZAlbumModel]()
        let option = PHFetchOptions()
        if !allowPickingVideo {
            option.predicate = NSPredicate(format: "mediaType == \(PHAssetMediaType.image.rawValue)")
        }
        if !allowPickingImage {
            option.predicate = NSPredicate(format: "mediaType == \(PHAssetMediaType.video.rawValue)")
        }
        if !self.sortAscendingByModificationDate {
            option.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: self.sortAscendingByModificationDate)]
        }
        // 我的照片流
        let myPhotoStreamAlbum = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.albumMyPhotoStream, options: nil)
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.albumRegular, options: nil)
        let topLevelUserCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        let syncedAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.albumSyncedAlbum, options: nil)
        let sharedAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.albumCloudShared, options: nil)
        let allAlbums = [myPhotoStreamAlbum, smartAlbums, topLevelUserCollections, syncedAlbums, sharedAlbums]

        for object in allAlbums {
            if !object.isKind(of: PHFetchResult<PHAssetCollection>.classForCoder()) {
                continue
            }

            let fetchResult = object as! PHFetchResult<PHAssetCollection>

            fetchResult.enumerateObjects({ (collection, index, stop) in
                print(collection);
                let tz_fetchResult = PHAsset.fetchAssets(in: collection , options: option)

                if tz_fetchResult.count < 1 {
                    return
                }

                //TODO: 差过滤相册
                if (self.pickerDelegate?.responds(to: #selector(self.pickerDelegate?.isAlbumCanSelect(albumName:result:))))! {
                    if !(self.pickerDelegate?.isAlbumCanSelect!(albumName: collection.localizedTitle!, result: tz_fetchResult))! {
                        return
                    }
                }

                if (collection.localizedTitle?.tz_containsString(string: "Hidden"))! || collection.localizedTitle == "已隐藏" {
                        return
                    }
                if (collection.localizedTitle?.tz_containsString(string: "Deleted"))! || collection.localizedTitle == "最近删除" {
                        return
                    }

                if collection.assetCollectionSubtype == .smartAlbumUserLibrary {
                    albumArr.insert(self.modelWithResult(result: tz_fetchResult, name: collection.localizedTitle!, isCameraRoll: true), at: 0)
                } else {
                    albumArr.append(self.modelWithResult(result: tz_fetchResult, name: collection.localizedTitle!, isCameraRoll: false))
                }
            })
        }

        if albumArr.count > 0 {
            completion(albumArr)
        }
    }

    public func isCameraRollAlbum(metadata: PHAssetCollection) -> Bool {
        return metadata.assetCollectionSubtype == PHAssetCollectionSubtype.smartAlbumUserLibrary
    }
    //MARK: - Get Assets
    /// Get Assets 获得照片数组
    public func getAssets(assetsFromFetchResult result: PHFetchResult<PHAsset>, allowPickingVideo: Bool, allowPickingImage: Bool, completion: @escaping ((_ models: Array<TZAssetModel>?) -> (Swift.Void))) {

        var photoArr = Array<TZAssetModel>()
        result.enumerateObjects { (asset, index, stop) in
            let model = self.asset(modelWithAsset: asset, allowPickingVideo: allowPickingVideo, allowPickingImage: allowPickingImage)
            if (model != nil) {
                photoArr.append(model!)
            }
        }
        completion(photoArr)
    }

    ///  Get asset at index 获得下标为index的单个照片
    ///  if index beyond bounds, return nil in callback 如果索引越界, 在回调中返回 nil
    public func getAsset(assetfromFetchResult result: PHFetchResult<PHAsset>, atIndex: Int, allowPickingVideo: Bool, allowPickingImage: Bool, completion: @escaping ((_ model: TZAssetModel?) -> (Swift.Void))) {
        if result.count < atIndex {
            completion(nil)
            return
        }
        let asset = result.object(at: atIndex)
        let model = self.asset(modelWithAsset: asset, allowPickingVideo: allowPickingVideo, allowPickingImage: allowPickingImage)

        completion(model)

    }

    public func asset(modelWithAsset asset: PHAsset, allowPickingVideo: Bool, allowPickingImage: Bool) -> TZAssetModel? {
        //TODO: 过滤照片
        var canSelect = true
        if (self.pickerDelegate?.responds(to: #selector(self.pickerDelegate?.isAssetCanSelect(asset:))))! {
            canSelect = (self.pickerDelegate?.isAssetCanSelect!(asset: asset))!
        }
        if !canSelect {
            return nil
        }

        let type = self.getAssetType(asset: asset)

        if (!allowPickingVideo && type == .video) { return nil }
        if (!allowPickingImage && type == .photo) { return nil }
        if (!allowPickingImage && type == .photoGif) { return nil }


        if self.hideWhenCanNotSelect {
            if !self.isPhoto(selectableWithAsset: asset) {
                return nil
            }
        }
        var timelength = type == .video ? "\(asset.duration)" : "0"
        timelength = self.getNewTimeFromDurationSecond(duration: (timelength as NSString).integerValue)
        let model = TZAssetModel(asset: asset, type: type, isSelected: false, timeLength: timelength)
        return model
    }

    public func getAssetType(asset: PHAsset) -> TZAssetModelMediaType {
        var type = TZAssetModelMediaType.photo
        switch asset.mediaType {
        case .audio: type = .audio
        case .video: type = .video
        case .image:
            if (asset.value(forKey: "filename") as! String).hasSuffix("GIF") {
                type = .photoGif
            }
            break
        default:
            type = .photo
        }
        return type
    }

    public func getNewTimeFromDurationSecond(duration: Int) -> String {
        var newTime = ""
        if duration < 10 {
            newTime = "0:0\(duration)"
        } else if duration < 60 {
            newTime = "0:\(duration)"
        } else {
            let min = duration / 60;
            let sec = duration - (min * 60);
            if (sec < 10) {
                newTime = "\(min):0\(sec)"
            } else {
                newTime = "\(min):\(sec)"
            }
        }
        return newTime
    }

    /// 检查照片大小是否满足最小要求
    public func isPhoto(selectableWithAsset asset: PHAsset) -> Bool {
        let photoSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        if self.minPhotoWidthSelectable > photoSize.width || self.minPhotoHeightSelectable > photoSize.height {
            return false
        }
        return true
    }

    public func getPhotos(bytesWithArray photos: Array<TZAssetModel>?, completion:  @escaping  ((_ totalBytes: String?) -> (Swift.Void))) {
        if (photos?.isEmpty)! {
            return
        }
        var dataLength = 0
        var assetCount = 0
        for model in photos! {
            let options = PHImageRequestOptions()
            options.resizeMode = .fast;
            PHImageManager.default().requestImageData(for: model.asset, options: options, resultHandler: { (imageData, dataUTI, orientation, info) in
                if model.type != .video {
                    dataLength += (imageData?.count)!
                }
                assetCount += 1
                if assetCount >= (photos?.count)! {
                    let bytes = self.getBytesFromDataLength(dataLength: Double(dataLength))
                    completion(bytes)
                }
            })
        }
    }

    public func getBytesFromDataLength(dataLength: Double) -> String {
        if dataLength >= 0.1 * (1024 * 1024) {
            let sizeKBDouble = dataLength / 1024.0 / 1024.0
            return "\(sizeKBDouble.rounded(toPlaces: 1))M"
        } else if dataLength >= 1024 {
            let sizeKBDouble = dataLength / 1024.0
            return "\(sizeKBDouble.rounded(toPlaces: 0))K"
        } else {
            return "\(dataLength)B"
        }
    }
    //MARK: - - Get Photo

    public func getPhoto(with asset: PHAsset, completion: @escaping ((_ photo: UIImage?, _ info: Dictionary<AnyHashable, Any>?, _ isDegraded: Bool?) -> (Swift.Void))) -> Int32 {
        var fullScreenWidth = TZScreenWidth
        if fullScreenWidth > photoPreviewMaxWidth {
            fullScreenWidth = photoPreviewMaxWidth
        }
        return self.getPhoto(with: asset, photoWidth: fullScreenWidth, networkAccessAllowed: true, completion: completion, progressHandler: { (progress, error, stop, info) -> (Void) in

        })
    }

    public func getPhoto(with asset: PHAsset, photoWidth: CGFloat, completion: @escaping ((_ photo: UIImage?, _ info: Dictionary<AnyHashable, Any>?, _ isDegraded: Bool?) -> (Swift.Void))) -> Int32 {
        return self.getPhoto(with: asset, photoWidth: photoWidth, networkAccessAllowed: true, completion: completion, progressHandler: { (progress, error, stop, info) -> (Void) in

        })
    }

    public func getPhoto(with asset: PHAsset, networkAccessAllowed: Bool, completion: @escaping ((_ photo: UIImage?, _ info: Dictionary<AnyHashable, Any>?, _ isDegraded: Bool?) -> (Swift.Void)), progressHandler: @escaping ((_ progress: Double?, _ error: Error?, _ stop: UnsafeMutablePointer<ObjCBool>, _ info: Dictionary<AnyHashable, Any>?) -> (Swift.Void))) -> Int32 {
        var fullScreenWidth = TZScreenWidth
        if fullScreenWidth > photoPreviewMaxWidth {
            fullScreenWidth = photoPreviewMaxWidth
        }
        return self.getPhoto(with: asset, photoWidth: photoWidth, networkAccessAllowed: networkAccessAllowed, completion: completion, progressHandler: progressHandler)
    }

    public func getPhoto(with asset: PHAsset, photoWidth: CGFloat, networkAccessAllowed: Bool, completion: @escaping ((_ photo: UIImage?, _ info: Dictionary<AnyHashable, Any>?, _ isDegraded: Bool?) -> (Swift.Void)), progressHandler: @escaping ((_ progress: Double?, _ error: Error?, _ stop: UnsafeMutablePointer<ObjCBool>, _ info: Dictionary<AnyHashable, Any>?) -> (Swift.Void))) -> Int32 {

        var imageSize = CGSize.zero
        if photoWidth < TZScreenWidth && photoWidth < photoPreviewMaxWidth {
            imageSize = AssetGridThumbnailSize
        } else {
            let aspectRatio: CGFloat = CGFloat(asset.pixelWidth) / CGFloat(asset.pixelHeight)
            var pixelWidth: CGFloat = photoWidth * TZScreenScale * 1.5;
            // 超宽图片
            if (aspectRatio > 1.8) {
                pixelWidth = pixelWidth * aspectRatio;
            }
            // 超高图片
            if (aspectRatio < 0.2) {
                pixelWidth = pixelWidth * 0.5;
            }
            let pixelHeight = pixelWidth / aspectRatio;
            imageSize = CGSize(width: pixelWidth, height: pixelHeight)
        }

        var image: UIImage?
        // 修复获取图片时出现的瞬间内存过高问题
        // 下面两行代码，来自hsjcom，他的github是：https://github.com/hsjcom 表示感谢
        let option = PHImageRequestOptions()
        option.resizeMode = .fast
        let imageRequestID = PHImageManager.default().requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFill, options: option, resultHandler: { (result, info) in

            guard var result_image = result, let _info = info else {
                return
            }
            image = result_image

            let isCancelled = _info[PHImageCancelledKey] as? Bool
            let isError = _info[PHImageErrorKey] as? Bool
            let downloadFinined = (isCancelled == nil || !isCancelled!) && (isError == nil || !isError!)
            if downloadFinined {
                result_image = self.fixOrientation(result_image)
                completion(image, info, info![PHImageResultIsDegradedKey] as? Bool)
            }

            // Download image from iCloud / 从iCloud下载图片
            guard let isCloud = _info[PHImageResultIsInCloudKey] as? Bool else {
                return
            }
            if isCloud && networkAccessAllowed {
                let options = PHImageRequestOptions()
                option.progressHandler = { (progress, error, stop, info) in
                    DispatchQueue.main.async(execute: {
                        progressHandler(progress, error, stop, info)
                    })
                }

                options.isNetworkAccessAllowed = true
                options.resizeMode = .fast
                PHImageManager.default().requestImageData(for: asset, options: options, resultHandler: { (imageData, dataUTI, orientation, info) in
                    var resultImage = UIImage(data: imageData!, scale: 0.1)
                    resultImage = self.scaleImage(resultImage, to: imageSize)
                    if resultImage == nil {
                        resultImage = image
                    }
                    resultImage = self.fixOrientation(resultImage!)
                    
                    completion(resultImage, info, false)
                })
            }
        })
        return imageRequestID
    }

    /// Get postImage / 获取封面图
    public func getPostImageWithAlbumModel(imageWithAlbumModel model: TZAlbumModel?, completion: @escaping ((_ photo: UIImage?) -> (Swift.Void))) {
        var asset = model?.result?.lastObject
        if !self.sortAscendingByModificationDate {
            asset = model?.result?.firstObject
        }
        _ = TZImageManager.manager.getPhoto(with: asset!, photoWidth: 80, networkAccessAllowed: true, completion: { (photo, info, isDegraded) -> (Void) in
            completion(photo)

        }, progressHandler:{
            (progress, error, stop, info) -> Void in

        })
    }
    /// Get Original Photo / 获取原图
    public func getOriginalPhoto(photoWithAsset asset: PHAsset?, completion: @escaping ((_ photo: UIImage?, _ info: Dictionary<AnyHashable, Any>?) -> (Swift.Void))) {
        self.getOriginalPhoto(photoWithAsset: asset) { (photo, info, isDegraded) -> (Void) in
            completion(photo, info)
        }
    }

    public func getOriginalPhoto(photoWithAsset asset: PHAsset?, newCompletion: @escaping ((_ photo: UIImage?, _ info: Dictionary<AnyHashable, Any>?, _ isDegraded: Bool?) -> (Swift.Void))) {
        let option = PHImageRequestOptions()
        option.isNetworkAccessAllowed = true
        option.resizeMode = .fast
        cachingImageManager.requestImage(for: asset!, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: option) { (result, info) in
            var result_image = result
            let downloadFinined = !(info![PHImageCancelledKey] != nil) && !(info![PHImageErrorKey] != nil)
            if downloadFinined && (result_image != nil) {
                result_image = self.fixOrientation(result_image!)
                let isDegraded: Bool = info![PHImageResultIsDegradedKey] as! Bool
                newCompletion(result_image, info, isDegraded)
            }
        }
    }

    public func getOriginalPhotoData(_ asset: PHAsset?, completion: @escaping (_ data: Data?, _ info: Dictionary<AnyHashable, Any>?, _ isDegraded: Bool?) -> (Swift.Void)) {
        let option = PHImageRequestOptions()
        option.isNetworkAccessAllowed = true
        option.resizeMode = .fast
        PHImageManager.default().requestImageData(for: asset!, options: option) { (imageData, dataUTI, orientation, info) in
            let downloadFinined = !(info![PHImageCancelledKey] != nil)  && !(info![PHImageErrorKey] != nil)
            if downloadFinined && imageData != nil {
                completion(imageData, info, false)
            }
        }
    }

    //MARK: - Save photo
    public func savePhotoWithImage(with image: UIImage?, location: CLLocation?, completion: @escaping (_ error: Error?) -> (Swift.Void)) {
//        let data = UIImageJPEGRepresentation(image!, 0.9)
        if #available(iOS 9.0, *) {
            PHPhotoLibrary.shared().performChanges({
//                let options = PHAssetResourceCreationOptions()
//                options.shouldMoveFile = true
                let request = PHAssetCreationRequest.creationRequestForAsset(from: image!)
                
                if location != nil {
                    request.location = location;
                }
                request.creationDate = Date()
            }) { (success, error) in
                DispatchQueue.main.async(execute: {
                    if error == nil {
                        completion(nil)
                    } else {
                        completion(error)
                        debugPrint("保存图片失败 ：\(error!)")
                    }
                })
            }
        } else {
            // Fallback on earlier versions
            let assetLibrary = ALAssetsLibrary()
            assetLibrary.writeImage(toSavedPhotosAlbum: image?.cgImage, orientation: ALAssetOrientation(rawValue: (image?.imageOrientation.rawValue)!)!, completionBlock: { (assetURL, error) in
                if error != nil {
                    completion(error)
                    debugPrint(" \n 保存图片失败 ：\(String(describing: error?.localizedDescription))")
                } else {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: {
                        completion(nil)
                    })
                }
            })
        }
    }
    //MARK: - Get Video
    public func getVideo(_ asset: PHAsset?, progressHandler: @escaping ((_ progress: Double?, _ error: Error?, _ stop: UnsafeMutablePointer<ObjCBool>?, _ info: Dictionary<AnyHashable, Any>?) -> (Swift.Void)), completion: @escaping ((_ playerItem: AVPlayerItem?, _ info: Dictionary<AnyHashable, Any>?) -> (Swift.Void))) {
        let option = PHVideoRequestOptions()
        option.isNetworkAccessAllowed = true
        option.progressHandler = { (progress, error, stop, info) in
            DispatchQueue.main.async(execute: {
                progressHandler(progress, error, stop, info)
            })
        }
        PHImageManager.default().requestPlayerItem(forVideo: asset!, options: option) { (playerItem, info) in
            guard playerItem != nil, info != nil else {
                return
            }
            completion(playerItem, info)
        }
    }
    //MARK: - Export video
    public func getVideoOutput(_ asset: PHAsset?, completion: ((_ outputPath: String?) -> (Swift.Void))?) {
        let options = PHVideoRequestOptions()
        options.version = .original
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestAVAsset(forVideo: asset!, options: options) { (avasset, audioMix, info) in
            self.startExportVideoAsset(avasset as? AVURLAsset, completion: completion)
        }
    }

    public func startExportVideoAsset(_ videoAsset: AVURLAsset?, completion: ((_ outputPath: String?) -> (Swift.Void))?) {
        // Find compatible presets by video asset.
        let presets = AVAssetExportSession.exportPresets(compatibleWith: videoAsset!)

        // Begin to compress video
        // Now we just compress to low resolution if it supports
        // If you need to upload to the server, but server does't support to upload by streaming,
        // You can compress the resolution to lower. Or you can support more higher resolution.
        if presets.contains(AVAssetExportPreset640x480) {
            let session = AVAssetExportSession(asset: videoAsset!, presetName: AVAssetExportPreset640x480)

            let formater = DateFormatter()
            formater.dateFormat = "yyyy-MM-dd-HH:mm:ss-SSS"
            let outputPath = NSHomeDirectory().appending("/tmp/output-\(formater.string(from: Date())).mp4")
            debugPrint("ideo outputPath = \(outputPath)")

            session?.outputURL = URL(fileURLWithPath: outputPath)
            // Optimize for network use.
            session?.shouldOptimizeForNetworkUse = true;

            let supportedTypeArray = session?.supportedFileTypes

            if (supportedTypeArray?.contains(AVFileType.mp4))! {
                session?.outputFileType = .mp4;
            } else if (supportedTypeArray?.count == 0) {
                debugPrint(" \n No supported file types 视频类型暂不支持导出");
                return;
            } else {
                session?.outputFileType = supportedTypeArray?.first
            }

            let tmp_path = NSHomeDirectory().appending("/tmp")
            if  !FileManager.default.fileExists(atPath: tmp_path) {
               try? FileManager.default.createDirectory(atPath: tmp_path, withIntermediateDirectories: true, attributes: nil)
            }

            let videoComposition = self.fixedComposition(videoAsset)
            if !(videoComposition?.renderSize.width.isZero)! {
                // 修正视频转向
                session?.videoComposition = videoComposition;
            }
            
            // Begin to export video to the output path asynchronously.
            session?.exportAsynchronously(completionHandler: {
                debugPrint(session?.status ?? "视频状态为空")
                switch session?.status {
                case .completed?:
                    DispatchQueue.main.async(execute: {
                        completion?(outputPath)
                    })
                    break
                default:
                    break
                }
            })
        }
    }

    public func modelWithResult(result: PHFetchResult<PHAsset>, name: String, isCameraRoll: Bool) -> TZAlbumModel {
        let model = TZAlbumModel()
        model.result = result
        model.name = name
        model.isCameraRoll = isCameraRoll
        model.count = result.count
        return model
    }

    public func scaleImage(_ image: UIImage?, to size: CGSize) -> UIImage? {
        guard let _image = image else {
            return nil
        }
        if _image.size.width > size.width {
            UIGraphicsBeginImageContext(size)
            _image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage
        } else {
            return image
        }
    }

    public func fixedComposition(_ videoAsset: AVAsset?) -> AVMutableVideoComposition? {
        let videoComposition = AVMutableVideoComposition()

        // 视频转向
        let degrees = self.degressFromVideoFile(asset: videoAsset!)

        if (degrees != 0) {
            let translateToCenter: CGAffineTransform?
            let mixedTransform: CGAffineTransform?
            videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30);

            let tracks = videoAsset?.tracks(withMediaType: .video)
            let videoTrack = tracks?.first

            let roateInstruction = AVMutableVideoCompositionInstruction()
            roateInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: (videoAsset?.duration)!)
            let roateLayerInstruction = AVMutableVideoCompositionLayerInstruction.init(assetTrack: videoTrack!)
            if (degrees == 90) {
                // 顺时针旋转90°
                translateToCenter = CGAffineTransform.init(translationX: (videoTrack?.naturalSize.height)!, y: 0)
                mixedTransform = translateToCenter?.rotated(by: CGFloat(Float.pi * 0.5))
                videoComposition.renderSize = CGSize(width: (videoTrack?.naturalSize.height)!, height: (videoTrack?.naturalSize.width)!)
                roateLayerInstruction.setTransform(mixedTransform!, at: CMTime.zero)
            } else if(degrees == 180){
                // 顺时针旋转180°
                translateToCenter = CGAffineTransform.init(translationX: (videoTrack?.naturalSize.width)!, y: (videoTrack?.naturalSize.height)!)
                mixedTransform = translateToCenter?.rotated(by: CGFloat(Float.pi))
                videoComposition.renderSize = CGSize(width: (videoTrack?.naturalSize.width)!, height: (videoTrack?.naturalSize.height)!)
                roateLayerInstruction.setTransform(mixedTransform!, at: CMTime.zero)
            } else if(degrees == 270){
                // 顺时针旋转270°
                translateToCenter = CGAffineTransform.init(translationX: 0, y: (videoTrack?.naturalSize.width)!)
                mixedTransform = translateToCenter?.rotated(by: CGFloat(Float.pi / 2 * 3))
                videoComposition.renderSize = CGSize(width: (videoTrack?.naturalSize.height)!, height: (videoTrack?.naturalSize.width)!)
                roateLayerInstruction.setTransform(mixedTransform!, at: CMTime.zero)
            }

            roateInstruction.layerInstructions = [roateLayerInstruction];
            // 加入视频方向信息
            videoComposition.instructions = [roateInstruction];
        }
        return videoComposition;
    }


    /// 获取视频角度
    public func degressFromVideoFile(asset: AVAsset) -> Int {
        var degress = 0
        let tracks = asset.tracks(withMediaType: .video)
        if tracks.count > 0 {
            let videoTrack = tracks[0]
            let t = videoTrack.preferredTransform
            if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
                // Portrait
                degress = 90;
            } else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
                // PortraitUpsideDown
                degress = 270;
            } else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
                // LandscapeRight
                degress = 0;
            } else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
                // LandscapeLeft
                degress = 180;
            }
        }
        return degress
    }

    /// 修正图片方向
    public func fixOrientation(_ aImage: UIImage) -> UIImage {
        if self.shouldFixOrientation == false { return aImage }
         // No-op if the orientation is already correct
        if aImage.imageOrientation == .up { return aImage }

        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.

        var transform = CGAffineTransform.identity
        switch aImage.imageOrientation {
        case .down, .downMirrored:
            transform = transform.scaledBy(x: aImage.size.width, y: aImage.size.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
            break
        case .left, .leftMirrored:
            transform = transform.scaledBy(x: aImage.size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi / 2))
            break
        case .right, .rightMirrored:
            transform = transform.scaledBy(x: 0, y: aImage.size.height)
            transform = transform.rotated(by: -CGFloat(Double.pi / 2))
            break
        default:  break
        }

        switch aImage.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.scaledBy(x: aImage.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)

            break
        case .leftMirrored, .rightMirrored:
            transform = transform.scaledBy(x: aImage.size.height, y: 0)
            transform = CGAffineTransform(scaleX: -1, y: 1)
            break
        default:  break
        }

        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.

        let ctx = CGContext(data: nil, width: Int(aImage.size.width), height: Int(aImage.size.height), bitsPerComponent: (aImage.cgImage?.bitsPerComponent)!, bytesPerRow: 0, space: (aImage.cgImage?.colorSpace)!, bitmapInfo: (aImage.cgImage?.bitmapInfo.rawValue)!)

        ctx!.concatenate(transform);
        switch (aImage.imageOrientation) {
        case .left, .leftMirrored, .right, .rightMirrored:
            // Grr...
            ctx?.draw(aImage.cgImage!, in: CGRect(x: 0, y: 0, width: aImage.size.height, height: aImage.size.width))
            break;

        default:
            ctx?.draw(aImage.cgImage!, in: CGRect(x: 0, y: 0, width: aImage.size.width, height: aImage.size.height))
            break;
        }

        // And now we just create a new UIImage from the drawing context
        let cgimg = ctx!.makeImage();
        let img = UIImage(cgImage: cgimg!)
        return img;
    }
}












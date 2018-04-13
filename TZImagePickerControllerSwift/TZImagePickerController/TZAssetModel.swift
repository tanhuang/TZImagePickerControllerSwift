//
//  TZAssetModel.swift
//  TZImagePickerControllerSwift
//
//  Created by Huang.Tan on 2018/1/9.
//  Copyright © 2018年 Huang.Tan All rights reserved.
//

import UIKit
import Photos.PHAsset

public enum TZAssetModelMediaType: Int {
    case photo = 0
    case livePhoto
    case photoGif
    case video
    case audio
}


public class TZAssetModel: NSObject {
    public var asset: PHAsset
    public var isSelected: Bool
    public var type: TZAssetModelMediaType
    public var timeLength: String

    public init(asset: PHAsset, type: TZAssetModelMediaType, isSelected: Bool, timeLength: String) {
        self.asset = asset
        self.type = type
        self.isSelected = isSelected
        self.timeLength = timeLength
    }

}


public class TZAlbumModel: NSObject {

    public var name: String = ""       ///< The album name
    public var count: Int = 0       ///< Count of photos the album contain

    public var models: [TZAssetModel]?
    public var selectedCount: Int = 0

    public var isCameraRoll: Bool = false

    public var result: PHFetchResult<PHAsset>? {
        didSet {
            let allowPickingImage = TZImageManager.manager.allowPickingImage
            let allowPickingVideo = TZImageManager.manager.allowPickingVideo

            TZImageManager.manager.getAssets(assetsFromFetchResult: result!, allowPickingVideo: allowPickingVideo, allowPickingImage: allowPickingImage) { (models) -> (Void) in
                self.models = models
                if self.selectedModels != nil {
                    self.checkSelectedModels()
                }
            }
        }
    }             ///< PHFetchResult<PHAsset>

    public var selectedModels: [TZAssetModel]? {
        didSet {
            if self.models != nil {
                self.checkSelectedModels()
            }
        }
    }

    private func checkSelectedModels() {
        self.selectedCount = 0;
        var selectedAssets = [PHAsset]()

        _ = self.selectedModels!.map({ selectedAssets.append($0.asset) })

        _ = self.models!.map { model in
            if selectedAssets.contains(model.asset) {
                self.selectedCount += 1
            }
        }
    }

}





//
//  TZAssetModel.swift
//  TZImagePickerControllerSwift
//
//  Created by 希达 on 2018/1/9.
//  Copyright © 2018年 Tan.huang. All rights reserved.
//

import UIKit
import Photos.PHAsset

enum TZAssetModelMediaType: Int {
    case photo = 0
    case livePhoto
    case photoGif
    case video
    case audio
}

class TZAssetModel: NSObject {
    var asset: PHAsset
    var isSelected: Bool
    var type: TZAssetModelMediaType
    var timeLength: String

    init(asset: PHAsset, type: TZAssetModelMediaType, isSelected: Bool, timeLength: String) {
        self.asset = asset
        self.type = type
        self.isSelected = isSelected
        self.timeLength = timeLength
    }

}


class TZAlbumModel: NSObject {

    var name: String = ""       ///< The album name
    var count: Int = 0       ///< Count of photos the album contain

    var models: [TZAssetModel]?
    var selectedCount: Int = 0

    var isCameraRoll: Bool = false

    var result: PHFetchResult<PHAsset>? {
        didSet {
            let allowPickingImage = UserDefaults.standard.object(forKey: "tz_allowPickingImage") as! Bool
            let allowPickingVideo = UserDefaults.standard.object(forKey: "tz_allowPickingVideo") as! Bool

            TZImageManager.manager.getAssets(assetsFromFetchResult: result!, allowPickingVideo: allowPickingVideo, allowPickingImage: allowPickingImage) { (models) -> (Void) in
                self.models = models
                if self.selectedModels != nil {
                    self.checkSelectedModels()
                }
            }
        }
    }             ///< PHFetchResult<PHAsset>

    var selectedModels: [TZAssetModel]? {
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





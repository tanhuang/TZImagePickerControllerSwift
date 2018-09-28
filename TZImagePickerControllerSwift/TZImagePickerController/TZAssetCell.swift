//
//  TZAssetCell.swift
//  TZImagePickerControllerSwift
//
//  Created by Huang.Tan on 2018/1/22.
//  Copyright © 2018年 Huang.Tan All rights reserved.
//

import UIKit
import Photos

enum TZAssetCellType: Int {
    case photo = 0
    case livePhoto
    case photoGif
    case video
    case audio
}

protocol TZAssetCellDelegate: NSObjectProtocol {

    func tz_assetCell(_ cell: TZAssetCell, _ model: TZAssetModel, _ isSelect: Bool)

}

class TZAssetCell: UICollectionViewCell {

    weak var delegate: TZAssetCellDelegate?

    lazy var selectPhotoButton: UIButton = {
        let selectPhotoButton = UIButton()
        selectPhotoButton.addTarget(self, action: #selector(selectPhotoButtonClick(sender:)), for: .touchUpInside)
        self.contentView.addSubview(selectPhotoButton)
        return selectPhotoButton
    }()

    var type: TZAssetCellType? {
        didSet {
            if type == .photo || type == .livePhoto || (type == .photoGif && !self.allowPickingGif || self.allowPickingMultipleVideo) {
                selectImageView.isHidden = false
                selectPhotoButton.isHidden = false
                bottomView.isHidden = true
            } else {
                selectImageView.isHidden = true
                selectPhotoButton.isHidden = true
            }

            if type == .video {
                self.bottomView.isHidden = false;
                self.timeLength.text = model?.timeLength;
                self.videoImgView.isHidden = false;
                self.timeLength.frame.origin.x = self.videoImgView.frame.maxX
                self.timeLength.textAlignment = .right
            } else if type == .photoGif && self.allowPickingGif {
                self.bottomView.isHidden = false;
                self.timeLength.text = "GIF"
                self.videoImgView.isHidden = true
                self.timeLength.frame.origin.x = 5
                self.timeLength.textAlignment = .left
            }
        }
    }
    var allowPickingGif: Bool = false
    var allowPickingMultipleVideo: Bool = false
//    var representedAssetIdentifier: String?
    var imageRequestID: Int32 = 0

    var photoSelImageName: String?
    var photoDefImageName: String?

    var showSelectBtn: Bool? {
        didSet {
            if !self.selectPhotoButton.isHidden {
                self.selectPhotoButton.isHidden = !showSelectBtn!
            }
            if !self.selectImageView.isHidden {
                self.selectImageView.isHidden = !showSelectBtn!
            }
        }
    }
    var allowPreview: Bool = false

    // The photo / 照片
    lazy private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)

        contentView.bringSubviewToFront(selectImageView)
        contentView.bringSubviewToFront(bottomView)
        return imageView
    }()

    lazy private var selectImageView: UIImageView = {
        let selectImageView = UIImageView()
        contentView.addSubview(selectImageView)
        return selectImageView
    }()
    lazy private var bottomView: UIView = {
        let bottomView = UIView()
        bottomView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        contentView.addSubview(bottomView)
        return bottomView
    }()

    lazy private var timeLength: UILabel = {
        let timeLength = UILabel()
        timeLength.font = UIFont.systemFont(ofSize: 11)
        timeLength.textColor = UIColor.white
        timeLength.textAlignment = .right
        bottomView.addSubview(timeLength)
        return timeLength
    }()

    lazy private var videoImgView: UIImageView = {
        let videoImgView = UIImageView()
        videoImgView.image = UIImage.imageNamedFromMyBundle(name: "VideoSendIcon")
        bottomView.addSubview(videoImgView)
        return  videoImgView
    }()
    lazy private var progressView: TZProgressView = {
        let progressView = TZProgressView()
        progressView.isHidden = true
        self.addSubview(progressView)
        return progressView
    }()
    private var bigImageRequestID: Int32?

    var representedAssetIdentifier: String!

    var model: TZAssetModel? {
        didSet {
            let imageRequestID = TZImageManager.manager.getPhoto(with: (model?.asset)!, photoWidth: self.frame.width, networkAccessAllowed: false, completion: { (photo, info, isDegraded) -> (Void) in

                self.progressView.isHidden = true
                self.imageView.alpha = 1.0

                if self.representedAssetIdentifier == self.model?.asset.localIdentifier {
                    self.imageView.image = photo
                } else {
                    PHImageManager.default().cancelImageRequest(self.imageRequestID)
                }
                
                if !isDegraded! {
                    self.imageRequestID = 0
                }
            }, progressHandler: {
                (progress, error, stop, info) -> Void in

            })

            if imageRequestID != 0 && self.imageRequestID != 0 && (imageRequestID != self.imageRequestID) {
                PHImageManager.default().cancelImageRequest(self.imageRequestID)
            }
            self.imageRequestID = imageRequestID
            self.selectPhotoButton.isSelected = (model?.isSelected)!
            self.selectImageView.image = self.selectPhotoButton.isSelected ? UIImage.imageNamedFromMyBundle(name: photoSelImageName!) : UIImage.imageNamedFromMyBundle(name: photoDefImageName!)
            self.type = TZAssetCellType(rawValue: (model?.type.rawValue)!)
//            self.type = (model?.type.hashValue).map { TZAssetCellType(rawValue: $0) }!

            if !TZImageManager.manager.isPhoto(selectableWithAsset: (model?.asset)!) {
                if self.selectImageView.isHidden == false {
                    self.selectImageView.isHidden = true
                    self.selectPhotoButton.isHidden = true
                }
            }
            if (model?.isSelected)! {
                self.fetchBigImage()
            }
            self.setNeedsLayout()
        }
    }

    func fetchBigImage() {
        self.bigImageRequestID = TZImageManager.manager.getPhoto(with: (model?.asset)!, networkAccessAllowed: true, completion: { (photo, info, isDegraded) -> (Void) in
            self.hideProgressView()
        }, progressHandler: { (progress, error, stop, info) -> (Void) in
            if (self.model?.isSelected)! {
                let time = progress! > 0.02 ? progress! : 0.02
                self.progressView.progress = CGFloat(time)
                self.progressView.isHidden = false
                self.imageView.alpha = 0.4
                if time >= 1 {
                    self.hideProgressView()
                }
            } else {
                stop.pointee = true
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        })
    }

    @objc func selectPhotoButtonClick(sender: UIButton) {

        self.delegate?.tz_assetCell(self, self.model!, sender.isSelected)

        self.selectImageView.image = sender.isSelected ? UIImage.imageNamedFromMyBundle(name: photoSelImageName!) : UIImage.imageNamedFromMyBundle(name: photoDefImageName!)
        if sender.isSelected {
            UIView.showOscillatoryAnimationWithLayer(layer: self.selectImageView.layer, type: .bigger)
            self.fetchBigImage()
        } else {
            if bigImageRequestID != nil  {
                PHImageManager.default().cancelImageRequest(bigImageRequestID!)
                self.hideProgressView()
            }
        }
    }

    func hideProgressView() {
        self.progressView.isHidden = true
        self.imageView.alpha = 1.0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if self.allowPreview {
            selectPhotoButton.frame = CGRect(x: self.frame.width - 44, y: 0, width: 44, height: 44)
        } else {
            selectPhotoButton.frame = self.bounds
        }
        selectImageView.frame = CGRect(x: self.frame.width - 27, y: 0, width: 27, height: 27)
        imageView.frame = self.bounds

        let progressWH: CGFloat = 20
        let progressXY = (self.frame.width - progressWH) / 2
        progressView.frame = CGRect(x: progressXY, y: progressXY, width: progressWH, height: progressWH)

        bottomView.frame = CGRect(x: 0, y: self.frame.height - 17, width: self.frame.width, height: 17)
        videoImgView.frame = CGRect(x: 8, y: 0, width: 17, height: 17)
        timeLength.frame = CGRect(x: self.videoImgView.frame.maxX, y: 0, width: self.frame.width - self.videoImgView.frame.maxX - 5, height: 17)

        self.type = TZAssetCellType(rawValue: (self.model?.type.rawValue)!)
        let isSelectedBtn = self.showSelectBtn
        self.showSelectBtn = isSelectedBtn
    }
}


class TZAlbumCell: UITableViewCell {
    var model: TZAlbumModel? {
        didSet {
            let nameString = NSMutableAttributedString(string: (model?.name)!, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.black])
            let countString = NSMutableAttributedString(string: "  (\((model?.count)!))", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            nameString.append(countString)
            self.titleLabel.attributedText = nameString
            TZImageManager.manager.getPostImageWithAlbumModel(imageWithAlbumModel: model) { (postImage) -> (Void) in
                self.posterImageView.image = postImage
            }
            
            if model?.selectedCount != 0 {
                self.selectedCountButton.isHidden = false
                self.selectedCountButton.setTitle("\((model?.selectedCount)!)", for: .normal)
            } else {
                self.selectedCountButton.isHidden = true
            }
        }
    }
    
    lazy var selectedCountButton: UIButton = {
        let selectedCountButton = UIButton()
        selectedCountButton.layer.cornerRadius = 12
        selectedCountButton.clipsToBounds = true
        selectedCountButton.backgroundColor = UIColor.red
        selectedCountButton.setTitleColor(UIColor.white, for: .normal)
        selectedCountButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        contentView.addSubview(selectedCountButton)
        return selectedCountButton
    }()

    lazy private var posterImageView: UIImageView = {
        let posterImageView = UIImageView()
        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        contentView.addSubview(posterImageView)
        return posterImageView
    }()

    lazy private var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        titleLabel.textColor = UIColor.black
        titleLabel.textAlignment = .left
        contentView.addSubview(titleLabel)
        return titleLabel
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        selectedCountButton.frame = CGRect(x: self.frame.width - 24 - 30, y: 23, width: 24, height: 24)
        let titleHeight = ceil(self.titleLabel.font.lineHeight)
        titleLabel.frame = CGRect(x: 80, y: (self.frame.height - titleHeight) / 2, width: self.frame.width - 80 - 50, height: titleHeight)
        posterImageView.frame = CGRect(x: 0, y: 0, width: 70, height: 70)
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
    }

}

class TZAssetCameraCell: UICollectionViewCell {
    var imageView: UIImageView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        imageView = UIImageView()
        imageView?.backgroundColor = UIColor(white: 1.000, alpha: 0.5)
        self.addSubview(imageView!)
        self.clipsToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView?.frame = self.bounds
    }

}












//
//  TZTestCell.swift
//  TZImagePickerControllerSwift
//
//  Created by Huang.Tan on 2018/1/3.
//  Copyright © 2018年 Huang.Tan All rights reserved.
//

import UIKit
import Photos.PHAsset

class TZTestCell: UICollectionViewCell {

    var imageView: UIImageView?
    var videoImageView: UIImageView?
    var deleteBtn: UIButton?
    var gifLable: UILabel?

    var row: Int? {
        didSet {
            deleteBtn?.tag = row!
        }
    }

    var asset: PHAsset? {
        didSet {
            self.videoImageView?.isHidden = asset?.mediaType != .video
            self.gifLable?.isHidden = !(asset?.value(forKey: "filename") as! String).contains("GIF")
        }
    }


    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = UIColor.white

        configView()

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configView() {
        imageView = UIImageView(frame: contentView.bounds)
        imageView?.backgroundColor = UIColor(white: 1, alpha: 0.5)
        imageView?.contentMode = .scaleAspectFit
        contentView.addSubview(imageView!)
        imageView?.clipsToBounds = false

        let width = contentView.frame.width * 0.33
        videoImageView = UIImageView(frame: CGRect(x: width, y: width, width: width, height: width))
        videoImageView?.image = UIImage.imageNamedFromMyBundle(name: "MMVideoPreviewPlay")
        videoImageView?.contentMode = .scaleAspectFill
        videoImageView?.isHidden = true
        contentView.addSubview(videoImageView!)

        deleteBtn = UIButton(frame: CGRect(x: contentView.frame.width - 36, y: 0, width: 36, height: 36))
        deleteBtn?.setImage(UIImage(named: "photo_delete"), for: .normal)
        deleteBtn?.imageEdgeInsets = UIEdgeInsetsMake(-10, 0, 0, -10)
        deleteBtn?.alpha = 0.6
        contentView.addSubview(deleteBtn!)

        gifLable = UILabel(frame: CGRect(x: contentView.frame.width - 25, y: contentView.frame.height - 14, width: 25, height: 14))
        gifLable?.text = "GIF"
        gifLable?.textColor = UIColor.white
        gifLable?.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        gifLable?.textAlignment = .center
        gifLable?.font = UIFont.systemFont(ofSize: 10)
        contentView.addSubview(gifLable!)

    }

    @objc func snapshotView() -> UIView {
        let snapshotView = UIView()

        var cellSnapshotView: UIView?

        if self.responds(to: #selector(snapshotView(afterScreenUpdates:))) {
            cellSnapshotView = self.snapshotView(afterScreenUpdates: false)
        } else {
            let size = CGSize(width: bounds.width + 20, height: bounds.height + 20)
            UIGraphicsBeginImageContextWithOptions(size, self.isOpaque, 0)
            self.layer.render(in: UIGraphicsGetCurrentContext()!)
            let cellSnapshotImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            cellSnapshotView = UIImageView(image: cellSnapshotImage)
        }

        snapshotView.frame = CGRect(x: 0, y: 0, width: (cellSnapshotView?.frame.width)!, height: (cellSnapshotView?.frame.height)!)
        cellSnapshotView?.frame = CGRect(x: 0, y: 0, width: (cellSnapshotView?.frame.width)!, height: (cellSnapshotView?.frame.height)!)
        snapshotView.addSubview(cellSnapshotView!)

        return snapshotView;
    }

}







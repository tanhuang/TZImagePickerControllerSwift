//
//  TZAlbumPickerController.swift
//  TZImagePickerControllerSwift
//
//  Created by Huang.Tan on 2018/1/24.
//  Copyright © 2018年 Huang.Tan All rights reserved.
//

import UIKit

public class TZAlbumPickerController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    public var columnNumber: Int = 0

    private var tableView: UITableView?
    private var isFirstAppear: Bool = false
    private var albumArr = Array<TZAlbumModel>()

    override public func viewDidLoad() {
        super.viewDidLoad()

        isFirstAppear = true
        view.backgroundColor = UIColor.white

        guard let imagePickerVc = self.navigationController as? TZImagePickerController else { return }

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: imagePickerVc.cancelBtnTitleStr, style: .plain, target: imagePickerVc, action: #selector(imagePickerVc.cancelButtonClick))
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let imagePickerVc = self.navigationController as? TZImagePickerController else { return }

        imagePickerVc.hideProgressHUD()
        if imagePickerVc.allowTakePicture {
            self.navigationItem.title = Bundle.tz_localizedString(forKey: "Photos")
        } else if imagePickerVc.allowPickingVideo {
            self.navigationItem.title = Bundle.tz_localizedString(forKey: "Videos")
        }

        if self.isFirstAppear && (imagePickerVc.navLeftBarButtonSettingBlock == nil) {
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: Bundle.tz_localizedString(forKey: "Back"), style: .plain, target: nil, action: nil)
            self.isFirstAppear = false
        }

        configTableView()
    }

    public func configTableView() {
        guard let imagePickerVc = self.navigationController as? TZImagePickerController else { return }
        DispatchQueue.global().async {
            TZImageManager.manager.getAllAlbums(allowPickingVideo: imagePickerVc.allowPickingVideo, allowPickingImage: imagePickerVc.allowPickingImage, completion: { models in
                self.albumArr = models
                _ = self.albumArr.map { $0.selectedModels = imagePickerVc.selectedModels }
            })
            DispatchQueue.main.async(execute: {
                if self.tableView == nil {
                    self.tableView = UITableView(frame: CGRect.zero, style: .plain)
                    self.tableView?.rowHeight = 70
                    self.tableView?.tableFooterView = UIView()
                    self.tableView?.dataSource = self
                    self.tableView?.delegate = self
                    self.tableView?.register(TZAlbumCell.classForCoder(), forCellReuseIdentifier: "TZAlbumCell")
                    self.view.addSubview(self.tableView!)
                } else {
                    self.tableView?.reloadData()
                }
            })
        }
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.albumArr.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TZAlbumCell") as! TZAlbumCell
        let imagePickerVc = self.navigationController as? TZImagePickerController
        cell.selectedCountButton.backgroundColor = imagePickerVc?.oKButtonTitleColorNormal
        cell.model = albumArr[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let photoPickerVc = TZPhotoPickerController()
        photoPickerVc.columnNumber = self.columnNumber
        photoPickerVc.model = albumArr[indexPath.row]
        self.navigationController?.pushViewController(photoPickerVc, animated: true)
    }

    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        var top: CGFloat = 0
        var tableViewHeight: CGFloat = 0
        let naviBarHeight: CGFloat = (navigationController?.navigationBar.frame.height)!
        let isStatusBarHidden = UIApplication.shared.isStatusBarHidden
        if (navigationController?.navigationBar.isTranslucent)! {
            top = naviBarHeight;
            if !isStatusBarHidden { top += 20 }
            tableViewHeight = self.view.frame.height - top;
        } else {
            tableViewHeight = self.view.frame.height
        }
        tableView?.frame = CGRect(x: 0, y: top, width: self.view.frame.width, height: tableViewHeight)
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

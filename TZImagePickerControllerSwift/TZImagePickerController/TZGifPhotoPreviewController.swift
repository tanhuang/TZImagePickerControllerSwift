//
//  TZGifPhotoPreviewController.swift
//  TZImagePickerControllerSwift
//
//  Created by Huang.Tan on 2018/1/22.
//  Copyright © 2018年 Huang.Tan All rights reserved.
//

import UIKit

public class TZGifPhotoPreviewController: UIViewController {

    public var model: TZAssetModel?


    private var _toolBar: UIView?
    private var _doneButton: UIButton?
    private var _progress: UIProgressView?

    private var _previewView: TZPhotoPreviewView?

    private var _originStatusBarStyle: UIStatusBarStyle?

    override public func viewDidLoad() {
        super.viewDidLoad()


        view.backgroundColor = UIColor.black
        let tzImagePickerVc = self.navigationController as? TZImagePickerController
        if tzImagePickerVc != nil {
            self.navigationItem.title = "GIF\((tzImagePickerVc?.previewBtnTitleStr)!)"
        }
        self.configPreviewView()
        self.configBottomToolBar()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _originStatusBarStyle = UIApplication.shared.statusBarStyle
        UIApplication.shared.statusBarStyle = .lightContent
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.statusBarStyle = _originStatusBarStyle!
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        _previewView?.frame = self.view.bounds;
        _previewView?.scrollView?.frame = self.view.bounds;
        _doneButton?.frame = CGRect(x: self.view.frame.width - 44 - 12, y: 0, width: 44, height: 44);
        _toolBar?.frame = CGRect(x: 0, y: self.view.frame.height - 44, width: self.view.frame.width, height: 44);
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    public func configPreviewView() {
        _previewView = TZPhotoPreviewView(frame: CGRect.zero)
        _previewView?.model = self.model;
        _previewView?.singleTapGestureBlock = {[weak self] () -> (Void) in
            self?.signleTapAction()
        }
        view.addSubview(_previewView!)
    }

    public func configBottomToolBar() {
        _toolBar = UIView(frame: CGRect.zero)
        _toolBar?.backgroundColor = UIColor(red: 34 / 255.0, green: 34 / 255.0, blue: 34 / 255.0, alpha: 0.7)

        _doneButton = UIButton(type: .custom)
        _doneButton?.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        _doneButton?.addTarget(self, action: #selector(doneButtonClick), for: .touchUpInside)

        let tzImagePickerVc = self.navigationController as? TZImagePickerController
        if tzImagePickerVc != nil {
            _doneButton?.setTitle(tzImagePickerVc?.doneBtnTitleStr, for: .normal)
            _doneButton?.setTitleColor(tzImagePickerVc?.oKButtonTitleColorNormal, for: .normal)
        } else {
            _doneButton?.setTitle(Bundle.tz_localizedString(forKey: "Done"), for: .normal)
            _doneButton?.setTitleColor(UIColor(red: 83 / 255.0, green: 179 / 255.0, blue: 17 / 255.0, alpha: 1), for: .normal)
        }
        _toolBar?.addSubview(_doneButton!)

        let byteLabel = UILabel()
        byteLabel.textColor = UIColor.white
        byteLabel.font = UIFont.systemFont(ofSize: 13)
        byteLabel.frame = CGRect(x: 10, y: 0, width: 100, height: 44)
        TZImageManager.manager.getPhotos(bytesWithArray: [model!]) { (totalBytes) -> (Void) in
            byteLabel.text = totalBytes
        }

        _toolBar?.addSubview(byteLabel)
        view.addSubview(_toolBar!)

    }

    //MARK: - Click Event
    public func signleTapAction() {
        _toolBar?.isHidden = !(_toolBar?.isHidden)!
        navigationController?.isNavigationBarHidden = (_toolBar?.isHidden)!

        if !Bundle.TZ_isGlobalHideStatusBar() {
            UIApplication.shared.isStatusBarHidden = (_toolBar?.isHidden)!
        }
    }

    @objc func doneButtonClick() {
        let tzImagePickerVc = self.navigationController as? TZImagePickerController
        if tzImagePickerVc != nil {
            if (tzImagePickerVc?.autoDismiss)! {
                self.navigationController?.dismiss(animated: true, completion: {
                    self.callDelegateMethod()
                })
            }
        } else {
            dismiss(animated: true, completion: {
                self.callDelegateMethod()
            })
        }
    }

    public func callDelegateMethod() {

        let imagePickerVc = self.navigationController as? TZImagePickerController
        let animatedImage = _previewView?.imageView?.image
        
        if (imagePickerVc?.pickerDelegate?.responds(to: #selector(imagePickerVc?.pickerDelegate?.imagePickerController(_:didFinishPickingGifImage:sourceAssets:))))! {
            imagePickerVc?.pickerDelegate?.imagePickerController!(imagePickerVc!, didFinishPickingGifImage: animatedImage!, sourceAssets: (model?.asset)!)
        }

        imagePickerVc?.didFinishPickingGifImageHandle?(animatedImage!, (model?.asset)!);
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

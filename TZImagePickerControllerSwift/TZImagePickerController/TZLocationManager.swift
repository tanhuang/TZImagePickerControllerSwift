//
//  TZLocationManager.swift
//  TZImagePickerControllerSwift
//
//  Created by 希达 on 2018/1/22.
//  Copyright © 2018年 Tan.huang. All rights reserved.
//

import UIKit
import CoreLocation

class TZLocationManager: NSObject, CLLocationManagerDelegate {

    static var manager: TZLocationManager = {
        let manager = TZLocationManager()
        manager.locationManager = CLLocationManager()
        manager.locationManager?.requestAlwaysAuthorization()
        return manager
    }()

    private override init() {  }


    var locationManager: CLLocationManager?

    /// 定位成功的回调block
    var success: ((_ location: CLLocation?, _ oldLocation: CLLocation?) -> (Swift.Void))?
    /// 编码成功的回调block
    var geocode: ((_ geocodeArray: Array<CLPlacemark>?) -> (Swift.Void))?
    /// 定位失败的回调block
    var failure: ((_ error: Error?) -> (Swift.Void))?

    /// 开始定位
    func startLocation() {
        self.locationManager?.delegate = self
        self.startLocation(successBlock: nil, failureBlock: nil, geocoderBlock: nil)
    }

    func startLocation(successBlock: ((_ location: CLLocation?, _ oldLocation: CLLocation?) -> (Swift.Void))?, failureBlock: ((_ error: Error?) -> (Swift.Void))?, geocoderBlock: ((_ geocoderArray: Array<CLPlacemark>?) -> (Swift.Void))?) {
        self.locationManager?.delegate = self
        self.locationManager?.stopUpdatingLocation()
        self.success = successBlock
        self.geocode = geocoderBlock
        self.failure = failureBlock
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager .stopUpdatingLocation()

        success?(locations.last, locations.first)

        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(locations.last!, completionHandler: { (array, error) in
            self.locationManager?.delegate = nil
            self.geocode?(array)
        })
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if error.localizedDescription == kCLErrorDomain { // 用户禁止定位权限
            debugPrint("用户禁止定位权限 = \(error.localizedDescription)")
            self.locationManager?.delegate = nil
            return
        }
        failure?(error)
    }

}







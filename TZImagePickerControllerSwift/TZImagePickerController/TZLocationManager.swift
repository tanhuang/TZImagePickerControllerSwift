//
//  TZLocationManager.swift
//  TZImagePickerControllerSwift
//
//  Created by Huang.Tan on 2018/1/22.
//  Copyright © 2018年 Huang.Tan All rights reserved.
//

import UIKit
import CoreLocation

class TZLocationManager: NSObject, CLLocationManagerDelegate {

    static var manager: TZLocationManager = {
        let manager = TZLocationManager()
        manager.locationManager = CLLocationManager()
        manager.locationManager?.requestAlwaysAuthorization()
        manager.locationManager?.delegate = manager
        return manager
    }()

    private override init() { }


    var locationManager: CLLocationManager?

    /// 定位成功的回调block
    var success: ((_ location: CLLocation?, _ oldLocation: CLLocation?) -> (Swift.Void))?
    /// 编码成功的回调block
    var geocode: ((_ geocodeArray: Array<CLPlacemark>?) -> (Swift.Void))?
    /// 定位失败的回调block
    var failure: ((_ error: Error?) -> (Swift.Void))?

    /// 开始定位
    func startLocation(successBlock: @escaping ((_ location: CLLocation?, _ oldLocation: CLLocation?) -> (Swift.Void)), failureBlock: @escaping ((_ error: Error?) -> (Swift.Void)), geocoderBlock: @escaping ((_ geocoderArray: Array<CLPlacemark>?) -> (Swift.Void))) {
        self.locationManager?.startUpdatingLocation()
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







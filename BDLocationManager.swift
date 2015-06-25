//
//  BDLocationManager.swift
//  testLocation
//
//  Created by zhaoxiaolu on 15/6/4.
//  Copyright (c) 2015年 zhaoxiaolu. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation

/**
*  获取定位状态协议
*/
@objc protocol LocationManagerStatus{
    
    /**
    定位成功
    
    :param: location 经纬度对象
    */
    func getLocationSuccess(location:CLLocation)
    
    /**
    定位失败
    */
    func getLocationFailure()
    
    /**
    如果定位服务被禁止
    */
    optional func deniedLocation()
    
}

/**
*  封装cllocationmanager
*/
class BDLocationManager: NSObject, CLLocationManagerDelegate {
    var locationList:NSArray!
    var locationManager:CLLocationManager!
    var statusDelegate:LocationManagerStatus!
    var locationStatus:Bool = true
    /**
    单例
    
    :returns: BDLocationManager
    */
    func sharedManager() -> BDLocationManager {
        struct zxlSingle{
            static var predicate:dispatch_once_t = 0;
            static var manager:BDLocationManager? = nil
        }
        dispatch_once(&zxlSingle.predicate,{
            zxlSingle.manager = BDLocationManager()
            zxlSingle.manager?.locationManager = CLLocationManager()
            zxlSingle.manager?.locationManager.delegate = zxlSingle.manager
            zxlSingle.manager?.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            zxlSingle.manager?.locationManager.distanceFilter = 1000
            
        })
        return zxlSingle.manager!
    }
    
    /**
    开始定位
    */
    func startLocation() {
        if self.checkGps() {
            if self.locationManager.respondsToSelector("requestAlwaysAuthorization") {
                self.locationManager.requestAlwaysAuthorization()
            }
            self.locationManager.startUpdatingLocation()
        } else {
            println("权限被禁止，请在\"设置-隐私-定位服务\"中进行授权")
        }
    }
    
    /**
    检查定位服务
    
    :returns: bool
    */
    func checkGps() ->Bool {
        var authStatus:CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        
        //确定用户的定位服务启用
        if !CLLocationManager.locationServicesEnabled() {
            return false
        }
        
        switch authStatus {
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            return true
        case .NotDetermined:
            return true
        case .Restricted, .Denied:
            self.statusDelegate.deniedLocation!()
            return false
        }
        
    }
    
    /**
    停止定位
    */
    func stopLocation() {
        self.locationManager.stopUpdatingLocation()
    }
    
    /**
    获取最新的定位的经纬度
    
    :returns: 经纬度
    */
    func lastestLocation() -> CLLocationCoordinate2D {
        if self.locationStatus {
            if BDLocationManager().sharedManager().locationList == nil {
                return CLLocationCoordinate2D(latitude: 0, longitude: 0)
            } else {
                var currLocation:CLLocation = BDLocationManager().sharedManager().locationList.lastObject as! CLLocation
                var currCoordinate:CLLocationCoordinate2D = currLocation.coordinate
                return currCoordinate
            }
        } else {
            return CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
    }
    
    /**
    记录定位是否成功
    
    :returns: bool
    */
    func getLocationStatus() -> Bool {
        return self.locationStatus
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        self.locationStatus = true
        var location:CLLocation = locations[locations.count-1] as! CLLocation
        self.statusDelegate.getLocationSuccess(location)
        self.locationList = locations
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        self.locationStatus = false
        self.locationList = []
        self.statusDelegate.getLocationFailure()
    }
    
}

//
//  TipKitWrapper.swift
//  MAGE
//
//  Created by Brent Michalski on 5/20/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import TipKit
import UIKit

@objc public class TipKitWrapper: NSObject {
    
    @objc public static func configureTipKit() {
        try? Tips.configure()
    }
    
    @objc public static func showTip(type: Int, on viewController: UIViewController, sourceView: UIView) {
        let tip: any Tip
        
        switch type {
            case 0:  tip = ConnectionTip()
            case 1:  tip = LocationServicesTip()
            case 2:  tip = ObservationServicesTip()
            case 3:  tip = DataSynchronizationTip()
            case 6:  tip = LocationDisplayTip()
            case 16: tip = ChangePasswordTip()
            case 99: tip = ServerURLTip()
        
            default:
                print("Unsupported tip type \(type)")
                tip = ConnectionTip()
        }
        
        Task { @MainActor in
            for await shouldDisplay in tip.shouldDisplayUpdates {
                if shouldDisplay {
                    let tipController = TipUIPopoverViewController(tip, sourceItem: sourceView)
                    viewController.present(tipController, animated: true)
                }
            }
        }
    }
    
    @objc public static func resetTips() {
        try? Tips.resetDatastore()
    }
}

// 0 - kConnection
struct ConnectionTip: Tip {
    var title: Text { Text("Offline") }
    var message: Text? { Text("Reconnect to the internet to sync observations and get updates.") }
    var image: Image? { Image(systemName: "wifi.exclamationmark") }
}

// 1 - kLocationServices
struct LocationServicesTip: Tip {
    var title: Text { Text("Location Services") }
    var message: Text? { Text("Enable location services so your observations are automatically tagged.") }
    var image: Image? { Image(systemName: "location.circle") }
}

// 2 - kObservationServices
struct ObservationServicesTip: Tip {
    var title: Text { Text("Observations") }
    var message: Text? { Text("Observation fetching settings, watch for battery drain.") }
    var image: Image? { Image(systemName: "eye.circle") }
}

// 3 - kDataSynchronization
struct DataSynchronizationTip: Tip {
    var title: Text { Text("Data Synchronization") }
    var message: Text? { Text("Shorter intervals cause more battery drain.") }
    var image: Image? { Image(systemName: "battery.circle") }
}

// 6 - kLocationDisplay
struct LocationDisplayTip: Tip {
    var title: Text { Text("Your Location") }
    var message: Text? { Text("Allow others to see where you are during missions.") }
    var image: Image? { Image(systemName: "location.fill") }
}

// 16 - kChangePassword
struct ChangePasswordTip: Tip {
    var title: Text { Text("Keep Your Account Secure") }
    var message: Text? { Text("Change your password periodically to protect access.") }
    var image: Image? { Image(systemName: "lock.fill") }
}



// 6 - kMediaPhoto
struct PhotoUploadTip: Tip {
    var title: Text { Text("Photo Quality") }
    var message: Text? { Text("Choose a photo upload size to balance clarity and speed.") }
    var image: Image? { Image(systemName: "photo.fill") }
}

// 99 -
struct ServerURLTip: Tip {
    var title: Text { Text("Getting Started") }
    var message: Text? { Text("Paste or type your MAGE server's URL here. It should start with https://") }
    var image: Image? { Image(systemName: "brain") }
}

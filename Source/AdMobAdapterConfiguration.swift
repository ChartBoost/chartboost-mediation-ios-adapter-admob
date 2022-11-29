//
//  AdMobAdapterConfiguration.swift
//  AdMobAdapter
//
//  Created by Alex Rice on 10/11/22.
//

import Foundation
import GoogleMobileAds

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
public class AdMobAdapterConfiguration {
    /// Google's identifier for your test device can be found in the console output from their SDK
    public static func setTestDeviceID(_ id: String?) {
        if let id = id {
            GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [id]
        } else {
            GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = []
        }
    }
}

// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
import GoogleMobileAds
import os.log

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
@objc public class AdMobAdapterConfiguration: NSObject {

    private static let log = OSLog(subsystem: "com.chartboost.mediation.adapter.admob", category: "Configuration")

    /// Google's identifier for your test device can be found in the console output from their SDK
    @objc public static func setTestDeviceID(_ id: String?) {
        if let id = id {
            GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [id]
        } else {
            GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = []
        }
        if #available(iOS 12.0, *) {
            os_log(.debug, log: log, "AdMob SDK test device ID set to %{public}s", id ?? "nil")
        }
    }
}

// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
import GoogleMobileAds
import os.log

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
@objc public class AdMobAdapterConfiguration: NSObject {

    /// The version of the partner SDK.
    @objc static var partnerSDKVersion: String {
        let versionNumber = GADMobileAds.sharedInstance().versionNumber
        return "\(versionNumber.majorVersion).\(versionNumber.minorVersion).\(versionNumber.patchVersion)"
    }

    /// The version of the adapter.
    /// It should have either 5 or 6 digits separated by periods, where the first digit is Chartboost Mediation SDK's major version, the last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `<Chartboost Mediation major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.<Partner build version>.<Adapter build version>` where `.<Partner build version>` is optional.
    @objc static let adapterVersion = "4.11.2.0.0"

    /// The partner's unique identifier.
    @objc static let partnerID = "admob"

    /// The human-friendly partner name.
    @objc static let partnerDisplayName = "AdMob"

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

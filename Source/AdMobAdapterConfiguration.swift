// Copyright 2022-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import GoogleMobileAds

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
@objc public class AdMobAdapterConfiguration: NSObject, PartnerAdapterConfiguration {
    /// The version of the partner SDK.
    @objc public static var partnerSDKVersion: String {
        let versionNumber = MobileAds.shared.versionNumber
        return "\(versionNumber.majorVersion).\(versionNumber.minorVersion).\(versionNumber.patchVersion)"
    }

    /// The version of the adapter.
    /// It should have either 5 or 6 digits separated by periods, where the first digit is Chartboost Mediation SDK's major version, the 
    /// last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `<Chartboost Mediation major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.
    /// <Partner build version>.<Adapter build version>` where `.<Partner build version>` is optional.
    @objc public static let adapterVersion = "5.12.5.0.0"

    /// The partner's unique identifier.
    @objc public static let partnerID = "admob"

    /// The human-friendly partner name.
    @objc public static let partnerDisplayName = "AdMob"

    /// Google's identifier for your test device can be found in the console output from their SDK
    @objc public static var testDeviceIdentifiers: [String]? {
        get {
            MobileAds.shared.requestConfiguration.testDeviceIdentifiers
        }
        set {
            MobileAds.shared.requestConfiguration.testDeviceIdentifiers = newValue
            log("Test device IDs set to \(newValue?.description ?? "nil")")
        }
    }
}

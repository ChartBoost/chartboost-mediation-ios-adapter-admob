//
// AdMobAdapter.swift
// AdMobAdapter
//
// Created by Alex Rice on 10/01/22
//

import Foundation
import GoogleMobileAds
import HeliumSdk

enum Constants {
    // Note that this string is the name of a Google class, not our adapter class name
    static let adMobClassName = "GADMobileAds"
    // A Google-specified dictionary key, also used as a key for that value when stored locally
    static let isHybridKey = "is_hybrid_setup"
    // A Google-specified dictionary key
    static let reqId = "placement_request_id"
}

final class AdMobAdapter: PartnerAdapter {
    
    /// The version of the partner SDK.
    let partnerSDKVersion = "9.1.0"
    
    /// The version of the adapter.
    /// It should have 6 digits separated by periods, where the first digit is Helium SDK's major version, the last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `"<Helium major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.<Partner build version>.<Adapter build version>"`.
    var adapterVersion = "4.9.1.0.0.0"
    
    /// The partner's unique identifier.
    var partnerIdentifier = "admob"
    
    /// The human-friendly partner name.
    var partnerDisplayName = "AdMob"
    
    /// Parameters that should be included in all ad requests
    let sharedExtras = GADExtras()
    
    /// The designated initializer for the adapter.
    /// Helium SDK will use this constructor to create instances of conforming types.
    /// - parameter storage: An object that exposes storage managed by the Helium SDK to the adapter.
    /// It includes a list of created `PartnerAd` instances. You may ignore this parameter if you don't need it.
    init(storage: PartnerAdapterStorage) {
        // no-op
    }
    
    /// Does any setup needed before beginning to load ads.
    /// - parameter configuration: Configuration data for the adapter to set up.
    /// - parameter completion: Closure to be performed by the adapter when it's done setting up. It should include an error indicating the cause for failure or `nil` if the operation finished successfully.
    func setUp(with configuration: PartnerConfiguration, completion: @escaping (Error?) -> Void) {
        log(.setUpStarted)

        // Exit early if GoogleMobileAds SDK has already been initalized
        let statuses = GADMobileAds.sharedInstance().initializationStatus
        guard let status = statuses.adapterStatusesByClassName[Constants.adMobClassName],
                  status.state == GADAdapterInitializationState.notReady else {
            log("Redundant call to initalize GoogleMobileAds was ignored")
            // We should log either success or failure before returning, and this is more like success.
            log(.setUpSucceded)
            return
        }
        
        // Disable Google mediation since Helium is the mediator
        GADMobileAds.sharedInstance().disableMediationInitialization()
        
        GADMobileAds.sharedInstance().start { initStatus in
            let statuses = initStatus.adapterStatusesByClassName
            if statuses[Constants.adMobClassName]?.state == .ready {
                self.log(.setUpSucceded)
                completion(nil)
            } else {
                let error = self.error(.setUpFailure,
                                       description: "AdMob adapter status was \(String(describing: statuses[Constants.adMobClassName]?.state))")
                self.log(.setUpFailed(error))
                completion(error)
            }
        }
    }
    
    /// Fetches bidding tokens needed for the partner to participate in an auction.
    /// - parameter request: Information about the ad load request.
    /// - parameter completion: Closure to be performed with the fetched info.
    func fetchBidderInformation(request: PreBidRequest, completion: @escaping ([String: String]?) -> Void) {
        log(.fetchBidderInfoStarted(request))
        log(.fetchBidderInfoSucceeded(request))
        completion([:])
    }
    
    /// Indicates if GDPR applies or not and the user's GDPR consent status.
    /// - parameter applies: `true` if GDPR applies, `false` if not, `nil` if the publisher has not provided this information.
    /// - parameter status: One of the `GDPRConsentStatus` values depending on the user's preference.
    func setGDPR(applies: Bool?, status: GDPRConsentStatus) {
        if applies == true && status != .granted {
            // Set "npa" to "1" by merging with the existing extras dictionary if it's non-nil and overwriting the old value if keys collide
            sharedExtras.additionalParameters = (sharedExtras.additionalParameters ?? [:]).merging(["npa":"1"], uniquingKeysWith: { (_, new) in new })
            log(.privacyUpdated(setting: "npa", value: "1"))
        } else {
            // If GDPR doesn't apply or status is '.granted', then remove the "non-personalized ads" flag
            sharedExtras.additionalParameters?["npa"] = nil
            log(.privacyUpdated(setting: "npa", value: "nil"))
        }
    }
    
    /// Indicates the CCPA status both as a boolean and as an IAB US privacy string.
    /// - parameter hasGivenConsent: A boolean indicating if the user has given consent.
    /// - parameter privacyString: An IAB-compliant string indicating the CCPA status.
    func setCCPA(hasGivenConsent: Bool, privacyString: String) {
        // https://developers.google.com/admob/ios/ccpa#rdp_signal_2
        // Invert the boolean, because "has given consent" is the opposite of "needs Restricted Data Processing"
        log(.privacyUpdated(setting: "gap_rdp", value: !hasGivenConsent))
        UserDefaults.standard.set(!hasGivenConsent, forKey: "gad_rdp")
    }
    
    /// Indicates if the user is subject to COPPA or not.
    /// - parameter isChildDirected: `true` if the user is subject to COPPA, `false` otherwise.
    func setCOPPA(isChildDirected: Bool) {
        log(.privacyUpdated(setting: "ChildDirectedTreatment", value: isChildDirected))
        GADMobileAds.sharedInstance().requestConfiguration.tag(forChildDirectedTreatment: isChildDirected)
    }
    
    /// Creates a new ad object in charge of communicating with a single partner SDK ad instance.
    /// Helium SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Helium SDK takes care of storing and disposing of ad instances so you don't need to.
    /// `invalidate()` is called on ads before disposing of them in case partners need to perform any custom logic before the object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerAd {
        // Here you must create a PartnerAd object and return it or throw an error.
        // You'll have to define your custom type that conforms to PartnerAd. Depending on how you organize your code you may have one single PartnerAdapter type, or multiple ones depending on ad format.
        
        switch request.format {
        case .banner:
            return AdMobAdapterBannerAd(adapter: self, request: request, delegate: delegate, extras: sharedExtras)
        case .interstitial:
            return AdMobAdapterInterstitialAd(adapter: self, request: request, delegate: delegate, extras: sharedExtras)
        case .rewarded:
            return AdMobAdapterRewardedAd(adapter: self, request: request, delegate: delegate, extras: sharedExtras)
        }
    }
    
}

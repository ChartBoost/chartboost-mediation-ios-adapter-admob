//
//  AdMobAdapter.swift
//  AdMobAdapter
//
//  Created by Alex Rice on 9/16/22.
//

import Foundation
import GoogleMobileAds
import HeliumSdk


final class AdMobAdapter: NSObject, ModularPartnerAdapter {
    
    /// The semantic version number of the partner SDK
    let partnerSDKVersion = GADMobileAds.sharedInstance().sdkVersion
    
    /// The first number is Helium SDK's major version. The next 3 numbers are the partner SDK version. The last number is the build version of the adapter.
    let adapterVersion = "4.9.1.0.0"
    
    /// The partner's identifier.
    var partnerIdentifier = "admob"
    
    /// The partner's name in a human-friendly version.
    var partnerDisplayName = "AdMob"
    
    /// Created ad adapter instances, keyed by the request identifier.
    /// You should not generally need to modify this property in your adapter implementation, since it is managed by the
    /// `ModularPartnerAdapter` itself on its default implementation for `PartnerAdapter` load, show and invalidate methods.
    var adAdapters: [String : PartnerAdAdapter] = [:]

    private var gdprApplies: Bool?
    private var gdprStatus: GDPRConsentStatus = .unknown
    
    /// Additional parameters to send with the ad request
    var extras = GADExtras()
    
    /// Initialize the AdMob SDK so that it's ready to request and display ads.
    /// - Parameters:
    ///   - configuration: The necessary initialization data provided by Helium.
    ///   - completion: Handler to notify Helium of task completion.
    func setUp(with configuration: PartnerConfiguration, completion: @escaping (Error?) -> Void) {
        log(.setUpStarted)
        
        // Disable Google mediation since Helium is the mediator
        GADMobileAds.sharedInstance().disableMediationInitialization()

        // Note that this string is the name of a Google class, not our adapter class name
        let adMobClassName = "GADMobileAds"
        GADMobileAds.sharedInstance().start { initStatus in
            let statuses = initStatus.adapterStatusesByClassName
            if statuses[adMobClassName]?.state == .ready {
                self.log(.setUpSucceded)
                completion(nil)
            } else {
                let error = self.error(.setUpFailure,
                                       description: "AdMob adapter status was \(String(describing: statuses[adMobClassName]?.state))")
                self.log(.setUpFailed(error))
                completion(error)
            }
        }
    }
    
    func fetchBidderInformation(request: PreBidRequest, completion: @escaping ([String : String]) -> Void) {
        log(.fetchBidderInfoStarted(request))
        log(.fetchBidderInfoSucceeded(request))
        completion([:])
    }
    
    func makeAdAdapter(request: PartnerAdLoadRequest, partnerAdDelegate: PartnerAdDelegate) throws -> PartnerAdAdapter {
        switch request.format {
        case .banner:
            return AdMobBannerAdAdapter(adapter: self, request: request, partnerAdDelegate: partnerAdDelegate, extras: extras)
        case .interstitial:
            return AdMobInterstitialAdAdapter(adapter: self, request: request, partnerAdDelegate: partnerAdDelegate, extras: extras)
        case .rewarded:
            return AdMobRewardedAdAdapter(adapter: self, request: request, partnerAdDelegate: partnerAdDelegate, extras: extras)
        }
    }
    
    func setGDPRApplies(_ applies: Bool) {
        gdprApplies = applies
        updateGDPRConsent()
    }
    
    func setGDPRConsentStatus(_ status: GDPRConsentStatus) {
        gdprStatus = status
        updateGDPRConsent()
    }
    
    private func updateGDPRConsent() {
        // If we haven't received consent, we don't assume it's granted.
        // If gdprApplies is .unknown, we play it safe because it might apply.
        // If the user consents to tracking, we allow tracking in all cases.
        // If GDPR doesn't apply, it doesn't matter whether the user consents.
        //           Y N ?
        // .granted  _ _ _
        // .denied   X _ X
        // .unknown  X _ X
        
        // Non-personalized ads are specified by the presense of the key "npa" set to "1" https://developers.google.com/admob/ump/ios/quick-start#forward-consent
        // Allow personalized ads if the user consents or gdprApplies has been set to false
        if gdprApplies == false || gdprStatus == .granted {
            extras.additionalParameters?["npa"] = nil
            log(.privacyUpdated(setting: "npa", value: "nil"))
        } else {
            // Set "npa" to "1" by merging with the existing extras dictionary if it's non-nil and overwriting the old value if keys collide
            extras.additionalParameters = (extras.additionalParameters ?? [:]).merging(["npa":"1"], uniquingKeysWith: { (_, new) in new })
            log(.privacyUpdated(setting: "npa", value: "1"))
        }
    }
    
    func setCCPAConsent(hasGivenConsent: Bool, privacyString: String?) {
        // https://developers.google.com/admob/ios/ccpa#rdp_signal_2
        // Invert the boolean, because "has given consent" is the opposite of "needs Restricted Data Processing"
        log(.privacyUpdated(setting: "gap_rdp", value: !hasGivenConsent))
        UserDefaults.standard.set(!hasGivenConsent, forKey: "gad_rdp")
    }
    
    func setUserSubjectToCOPPA(_ isSubject: Bool) {
        log(.privacyUpdated(setting: "ChildDirectedTreatment", value: isSubject))
        GADMobileAds.sharedInstance().requestConfiguration.tag(forChildDirectedTreatment: isSubject)
    }

}

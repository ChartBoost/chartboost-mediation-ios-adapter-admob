//
//  AdMobAdapter.swift
//  AdMobAdapter
//
//  Created by Alex Rice on 9/16/22.
//
import Foundation
import HeliumSdk
import UIKit
import GoogleMobileAds


final class AdMobAdapter: NSObject, ModularPartnerAdapter {

    let partnerSDKVersion = GADMobileAds.sharedInstance().sdkVersion
    let adapterVersion = "4.\(GADMobileAds.sharedInstance().sdkVersion).0"  //TODO: check that this works, and also consider that it may be overly-clever and I should just hard-code the value
    var partnerIdentifier = "admob"
    var partnerDisplayName = "Google Mobile Ads"
    
    var adAdapters: [String : PartnerAdAdapter] = [:]

    
    // In the objc adapter, _isSubjectToGDPR was initialized to NO.
    private var gdprApplies: Bool = false  // TODO: is this the correct default?
    private var gdprStatus: GDPRConsentStatus = .unknown
    // Additional parameters to send with the ad request
    var extras = GADExtras()
    
    ///
    class func setTestDeviceId(_ id: String) {
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ id ]
    }
    
    /// Initialize the AdMob SDK so that it's ready to request and display ads.
    /// - Parameters:
    ///   - configuration: The necessary initialization data provided by Helium.
    ///   - completion: Handler to notify Helium of task completion.
    func setUp(with configuration: PartnerConfiguration, completion: @escaping (Error?) -> Void) {
        log(.setUpStarted)
        // Note that this constant is the name of a Google class, not our adapter class name
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
        if gdprApplies && gdprStatus != .granted{
            // Specifying non-personalized ads as described at https://developers.google.com/admob/ump/ios/quick-start#forward-consent
            
            // Set key "npa" to "1" by merging with the existing extras dictionary if it's non-nil and overwriting the old value if keys collide
            extras.additionalParameters = (extras.additionalParameters ?? [:]).merging(["npa":"1"], uniquingKeysWith: { (_, new) in new })
        }
    }
    
    func setCCPAConsent(hasGivenConsent: Bool, privacyString: String?) {
        // https://developers.google.com/admob/ios/ccpa#rdp_signal_2
        // Invert the boolean, because "has given consent" is the opposite of "needs Restricted Data Processing"
        UserDefaults.standard.set(!hasGivenConsent, forKey: "gad_rdp")
    }
    
    func setUserSubjectToCOPPA(_ isSubject: Bool) {
        GADMobileAds.sharedInstance().requestConfiguration.tag(forChildDirectedTreatment: isSubject)
    }

}

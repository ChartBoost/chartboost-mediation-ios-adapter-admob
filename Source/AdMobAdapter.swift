// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import GoogleMobileAds

// Magic Strings that shouldn't be changed because they're defined by Google, not Chartboost Mediation.
enum GoogleStrings {
    static let ccpaKey = "gap_rdp"
    static let adMobClassName = "GADMobileAds"
    static let gdprKey = "npa"
    static let isHybridKey = "is_hybrid_setup"
    static let reqIdKey = "placement_request_id"
}

final class AdMobAdapter: PartnerAdapter {
    /// The adapter configuration type that contains adapter and partner info.
    /// It may also be used to expose custom partner SDK options to the publisher.
    var configuration: PartnerAdapterConfiguration.Type { AdMobAdapterConfiguration.self }

    /// Parameters that should be included in all ad requests
    let sharedExtras = GADExtras()
    
    /// The designated initializer for the adapter.
    /// Chartboost Mediation SDK will use this constructor to create instances of conforming types.
    /// - parameter storage: An object that exposes storage managed by the Chartboost Mediation SDK to the adapter.
    /// It includes a list of created `PartnerAd` instances. You may ignore this parameter if you don't need it.
    init(storage: PartnerAdapterStorage) {
        sharedExtras.additionalParameters = ["platform_name": "chartboost"]
    }
    
    /// Does any setup needed before beginning to load ads.
    /// - parameter configuration: Configuration data for the adapter to set up.
    /// - parameter completion: Closure to be performed by the adapter when it's done setting up. It should include an error indicating the cause for failure or `nil` if the operation finished successfully.
    func setUp(with configuration: PartnerConfiguration, completion: @escaping (Result<PartnerDetails, Error>) -> Void) {
        log(.setUpStarted)

        // Disable Google mediation since Chartboost Mediation is the mediator
        GADMobileAds.sharedInstance().disableMediationInitialization()

        // Apply initial consents
        setConsents(configuration.consents, modifiedKeys: Set(configuration.consents.keys))
        setIsUserUnderage(configuration.isUserUnderage)

        // Exit early if GoogleMobileAds SDK has already been initalized
        let statuses = GADMobileAds.sharedInstance().initializationStatus
        guard let status = statuses.adapterStatusesByClassName[GoogleStrings.adMobClassName],
                  status.state == GADAdapterInitializationState.notReady else {
            log("Redundant call to initalize GoogleMobileAds was ignored")
            // We should log either success or failure before returning, and this is more like success.
            log(.setUpSucceded)
            completion(.success([:]))
            return
        }

        GADMobileAds.sharedInstance().start { initStatus in
            let statuses = initStatus.adapterStatusesByClassName
            if statuses[GoogleStrings.adMobClassName]?.state == .ready {
                self.log(.setUpSucceded)
                completion(.success([:]))
            } else {
                let error = self.error(.initializationFailureUnknown,
                                       description: "AdMob adapter status was \(String(describing: statuses[GoogleStrings.adMobClassName]?.state))")
                self.log(.setUpFailed(error))
                completion(.failure(error))
            }
        }
    }
    
    /// Fetches bidding tokens needed for the partner to participate in an auction.
    /// - parameter request: Information about the ad load request.
    /// - parameter completion: Closure to be performed with the fetched info.
    func fetchBidderInformation(request: PartnerAdPreBidRequest, completion: @escaping (Result<[String: String], Error>) -> Void) {
        // AdMob does not use a bidding token
        log(.fetchBidderInfoNotSupported)
        completion(.success([:]))
    }
    
    /// Indicates that the user consent has changed.
    /// - parameter consents: The new consents value, including both modified and unmodified consents.
    /// - parameter modifiedKeys: A set containing all the keys that changed.
    func setConsents(_ consents: [ConsentKey: ConsentValue], modifiedKeys: Set<ConsentKey>) {
        if modifiedKeys.contains(configuration.partnerID) || modifiedKeys.contains(ConsentKeys.gdprConsentGiven) {
            updateGPDR()
        }
        if modifiedKeys.contains(ConsentKeys.ccpaOptIn) {
            updateCCPA()
        }

        func updateGPDR() {
            // Use a partner-specific consent if available, falling back to the general GDPR consent if not
            if (consents[configuration.partnerID] ?? consents[ConsentKeys.gdprConsentGiven]) == ConsentValues.denied {
                // The "npa" parameter is an internal AdMob feature not publicly documented, and is subject to change.
                // Set "npa" to "1" by merging with the existing extras dictionary if it's non-nil and overwriting the old value if keys collide
                sharedExtras.additionalParameters = (sharedExtras.additionalParameters ?? [:]).merging([GoogleStrings.gdprKey:"1"], uniquingKeysWith: { (_, new) in new })
                log(.privacyUpdated(setting: GoogleStrings.gdprKey, value: "1"))
            } else {
                // If GDPR status is granted or the info is not provided then remove the "non-personalized ads" flag
                sharedExtras.additionalParameters?[GoogleStrings.gdprKey] = nil
                log(.privacyUpdated(setting: GoogleStrings.gdprKey, value: nil))
            }
        }

        func updateCCPA() {
            // See https://developers.google.com/admob/ios/privacy/ccpa
            let needsRestrictedDataProcessing: Bool?
            switch consents[ConsentKeys.ccpaOptIn] {
            case ConsentValues.granted:
                needsRestrictedDataProcessing = false
            case ConsentValues.denied:
                needsRestrictedDataProcessing = true
            default:
                needsRestrictedDataProcessing = nil
            }
            if let needsRestrictedDataProcessing {
                UserDefaults.standard.set(needsRestrictedDataProcessing, forKey: GoogleStrings.ccpaKey)
            } else {
                UserDefaults.standard.removeObject(forKey: GoogleStrings.ccpaKey)
            }
            log(.privacyUpdated(setting: GoogleStrings.ccpaKey, value: needsRestrictedDataProcessing))
        }
    }

    /// Indicates that the user is underage signal has changed.
    /// - parameter isUserUnderage: `true` if the user is underage as determined by the publisher, `false` otherwise.
    func setIsUserUnderage(_ isUserUnderage: Bool) {
        // See https://developers.google.com/admob/ios/api/reference/Classes/GADRequestConfiguration#-tagforchilddirectedtreatment:
        log(.privacyUpdated(setting: "ChildDirectedTreatment", value: isUserUnderage))
        GADMobileAds.sharedInstance().requestConfiguration.tagForChildDirectedTreatment = NSNumber(booleanLiteral: isUserUnderage)
    }

    /// Creates a new banner ad object in charge of communicating with a single partner SDK ad instance.
    /// Chartboost Mediation SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Chartboost Mediation SDK takes care of storing and disposing of ad instances so you don't need to.
    /// ``PartnerAd/invalidate()`` is called on ads before disposing of them in case partners need to perform any custom logic before the
    /// object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// Chartboost Mediation SDK will always call this method from the main thread.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeBannerAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerBannerAd {
        // This partner supports multiple loads for the same partner placement.
        AdMobAdapterBannerAd(adapter: self, request: request, delegate: delegate, extras: sharedExtras)
    }

    /// Creates a new ad object in charge of communicating with a single partner SDK ad instance.
    /// Chartboost Mediation SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Chartboost Mediation SDK takes care of storing and disposing of ad instances so you don't need to.
    /// ``PartnerAd/invalidate()`` is called on ads before disposing of them in case partners need to perform any custom logic before the
    /// object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeFullscreenAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerFullscreenAd {
        // This partner supports multiple loads for the same partner placement.
        switch request.format {
        case PartnerAdFormats.interstitial:
            return AdMobAdapterInterstitialAd(adapter: self, request: request, delegate: delegate, extras: sharedExtras)
        case PartnerAdFormats.rewarded:
            return AdMobAdapterRewardedAd(adapter: self, request: request, delegate: delegate, extras: sharedExtras)
        case PartnerAdFormats.rewardedInterstitial:
            return AdMobAdapterRewardedInterstitialAd(adapter: self, request: request, delegate: delegate, extras: sharedExtras)
        default:
            throw error(.loadFailureUnsupportedAdFormat)
        }
    }
    
    /// Maps a partner load error to a Chartboost Mediation error code.
    /// Chartboost Mediation SDK calls this method when a load completion is called with a partner error.
    ///
    /// A default implementation is provided that returns `nil`.
    /// Only implement if the partner SDK provides its own list of error codes that can be mapped to Chartboost Mediation's.
    /// If some case cannot be mapped return `nil` to let Chartboost Mediation choose a default error code.
    func mapLoadError(_ error: Error) -> ChartboostMediationError.Code? {
        guard (error as NSError).domain == GADErrorDomain,
              let code = GADErrorCode(rawValue: (error as NSError).code) else {
            return nil
        }
        switch code {
        case .invalidRequest:
            return .loadFailureInvalidAdRequest
        case .noFill:
            return .loadFailureNoFill
        case .networkError:
            return .loadFailureNetworkingError
        case .serverError:
            return .loadFailureServerError
        case .osVersionTooLow:
            return .loadFailureOSVersionNotSupported
        case .timeout:
            return .loadFailureTimeout
        case .mediationDataError:
            return .loadFailureUnknown
        case .mediationAdapterError:
            return .loadFailureUnknown
        case .mediationInvalidAdSize:
            return .loadFailureInvalidBannerSize
        case .internalError:
            return .loadFailureUnknown
        case .invalidArgument:
            return .loadFailureUnknown
        case .receivedInvalidResponse:
            return .loadFailureInvalidBidResponse
        case .mediationNoFill:
            return .loadFailureNoFill
        case .adAlreadyUsed:
            return .loadFailureLoadInProgress
        case .applicationIdentifierMissing:
            return .loadFailureInvalidCredentials
        @unknown default:
            return nil
        }
    }
    
    /// Maps a partner show error to a Chartboost Mediation error code.
    /// Chartboost Mediation SDK calls this method when a show completion is called with a partner error.
    ///
    /// A default implementation is provided that returns `nil`.
    /// Only implement if the partner SDK provides its own list of error codes that can be mapped to Chartboost Mediation's.
    /// If some case cannot be mapped return `nil` to let Chartboost Mediation choose a default error code.
    func mapShowError(_ error: Error) -> ChartboostMediationError.Code? {
        guard (error as NSError).domain == GADErrorDomain,
              let code = GADPresentationErrorCode(rawValue: (error as NSError).code) else {
            return nil
        }
        switch code {
        case .codeAdNotReady:
            return .showFailureAdNotReady
        case .codeAdTooLarge:
            return .showFailureUnsupportedAdSize
        case .codeInternal:
            return .showFailureUnknown
        case .codeAdAlreadyUsed:
            return .showFailureUnknown
        case .notMainThread:
            return .showFailureException
        case .mediation:
            return .showFailureUnknown
        @unknown default:
            return nil
        }
    }
}

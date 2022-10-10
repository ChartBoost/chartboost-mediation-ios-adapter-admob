//
//  AdMobInterstitialAdAdapter.swift
//  AdMobAdapter
//
//  Created by Alex Rice on 10/05/22.
//

import Foundation
import GoogleMobileAds
import HeliumSdk

class AdMobInterstitialAdAdapter: AdMobAdAdapter, PartnerAdAdapter {
    
    // The AdMob Ad Object
    var ad: GADInterstitialAd?
    
    /// A PartnerAd object with a placeholder (nil) ad object.
    private lazy var partnerAd = PartnerAd(ad: ad, details: [:], request: request)
        
    /// Loads an ad.
    /// - note: Do not call this method directly, `ModularPartnerAdapter` will take care of it when needed.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        loadCompletion = completion
        
        let adMobRequest = GADRequest()
        adMobRequest.requestAgent = "Helium"
        adMobRequest.register(self.sharedExtras)
        
        GADInterstitialAd.load(withAdUnitID:self.request.partnerPlacement,
                                request: adMobRequest) { [weak self] ad, error in
            guard let self = self else { return }
            if let error = error {
                self.log(.loadFailed(self.request, error: error))
                completion(.failure(error))
            }
            self.ad = ad
            ad?.fullScreenContentDelegate = self
            completion(.success(self.partnerAd))
        }
    }
    
    /// Shows a loaded ad.
    /// - note: Do not call this method directly, `ModularPartnerAdapter` will take care of it when needed.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        showCompletion = completion
        guard let ad = partnerAd.ad as? GADInterstitialAd else {
            let error = error(.showFailure(partnerAd), description: "Ad instance is nil/not an GADInterstitialAd.")
            log(.showFailed(partnerAd, error: error))
            return
        }
        
        DispatchQueue.main.async {
            ad.present(fromRootViewController: viewController)
        }
    }
}

extension AdMobInterstitialAdAdapter: GADFullScreenContentDelegate {
    
    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        log(.didTrackImpression(partnerAd))
        partnerAdDelegate?.didTrackImpression(partnerAd)
    }
    
    func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        log(.didClick(partnerAd, error: nil))
        partnerAdDelegate?.didClick(partnerAd)
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        loadCompletion?(.failure(self.error(.showFailure(partnerAd), description: error.localizedDescription)))
            ?? log(.loadResultIgnored)
    }
    
    // Google has deprecated adDidPresentFullScreenContent and says to use this delegate method instead
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        // TODO: ???
    }
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        log(.didDismiss(partnerAd, error: nil))
        partnerAdDelegate?.didDismiss(partnerAd, error: nil)
    }
}

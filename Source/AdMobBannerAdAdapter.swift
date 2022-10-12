//
//  AdMobBannerAdAdapter.swift
//  AdMobAdapter
//
//  Created by Alex Rice on 10/05/22.
//

import Foundation
import GoogleMobileAds
import HeliumSdk

class AdMobBannerAdAdapter: AdMobAdAdapter, PartnerAdAdapter {
    
    /// The AdMob Ad Object
    var ad: GADBannerView?
    
    /// The completion for the ongoing load operation.
    var loadCompletion: ((Result<PartnerAd, Error>) -> Void)?
    
    /// A PartnerAd object with a placeholder (nil) ad object.
    private lazy var partnerAd = PartnerAd(ad: ad, details: [:], request: request)
    
    /// Loads an ad.
    /// - note: Do not call this method directly, `ModularPartnerAdapter` will take care of it when needed.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerAd, Error>) -> Void) {
        loadCompletion = completion

        // Banner ads auto-show after loading, so we must have a ViewController
        guard viewController != nil else {
            let error = error(.noViewController)
            log(.loadFailed(request, error: error))
            completion(.failure(error))
            return
        }

        let adMobRequest = GADRequest()
        adMobRequest.requestAgent = "Helium"
        adMobRequest.register(self.sharedExtras)
        
        let placementID = request.partnerPlacement

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let size = self.gadAdSizeFrom(cgSize: self.request.size)
            self.ad = GADBannerView(adSize: size)
            self.ad?.adUnitID = placementID
            self.ad?.isAutoloadEnabled = false
            self.ad?.delegate = self
            self.ad?.rootViewController = viewController
            self.ad?.load(adMobRequest)
        }
    }
    
    /// Shows a loaded ad.
    /// - note: Do not call this method directly, `ModularPartnerAdapter` will take care of it when needed.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<HeliumSdk.PartnerAd, Error>) -> Void) {
        // Banner ads do not require a show() method, but this stub is needed for conformance to PartnerAdAdapter
    }
    
    func gadAdSizeFrom(cgSize: CGSize?) -> GADAdSize {
        guard let size = cgSize else { return GADAdSizeInvalid }
        switch (size.width, size.height) {
        case (320, 50):
            return GADAdSizeBanner
        case (300, 250):
            return GADAdSizeMediumRectangle
        case (728, 90):
            return GADAdSizeLeaderboard
        default:
            return GADAdSizeInvalid
        }
    }
}

extension AdMobBannerAdAdapter: GADBannerViewDelegate {

    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        // Report load success
        loadCompletion?(.success(partnerAd)) ?? log(.loadResultIgnored)
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        // Report load failure
        let heliumError = self.error(.loadFailure(request), error: error)
        loadCompletion?(.failure(heliumError)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        self.partnerAdDelegate?.didTrackImpression(self.partnerAd) ?? log(.delegateUnavailable)
    }

    func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
        self.partnerAdDelegate?.didClick(self.partnerAd) ?? log(.delegateUnavailable)
    }
}

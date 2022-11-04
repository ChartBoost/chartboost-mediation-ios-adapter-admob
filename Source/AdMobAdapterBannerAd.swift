//
// AdMobAdapterInterstitialAd.swift
// AdMobAdapter
//
// Created by Alex Rice on 10/02/22
//

import Foundation
import GoogleMobileAds
import HeliumSdk

class AdMobAdapterBannerAd: AdMobAdapterAd, PartnerAd {
    
    /// The partner ad view to display inline. E.g. a banner view.
    /// Should be nil for full-screen ads.
    var inlineView: UIView?
    
    // The AdMob Ad Object
    var ad: GADBannerView?
    
    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        loadCompletion = completion

        // Banner ads auto-show after loading, so we must have a ViewController
        guard viewController != nil else {
            let error = error(.noViewController)
            log(.loadFailed(error))
            completion(.failure(error))
            return
        }
        
        let adMobRequest = generateRequest()
        
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
    /// It will never get called for banner ads. You may leave the implementation blank for that ad format.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        // no-op
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

extension AdMobAdapterBannerAd: GADBannerViewDelegate {

    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        log(.loadSucceeded)
        self.inlineView = bannerView
        loadCompletion?(.success([:])) ?? log(.loadResultIgnored)
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        // Report load failure
        let error = self.error(.loadFailure)
        loadCompletion?(.failure(error)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        self.delegate?.didTrackImpression(self, details: [:]) ?? log(.delegateUnavailable)
    }

    func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
        self.delegate?.didClick(self, details: [:]) ?? log(.delegateUnavailable)
    }
}

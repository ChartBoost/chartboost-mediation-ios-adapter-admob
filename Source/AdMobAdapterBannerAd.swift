// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import GoogleMobileAds

class AdMobAdapterBannerAd: AdMobAdapterAd, PartnerBannerAd {
    /// The partner ad view to display inline. E.g. a banner view.
    /// Should be nil for full-screen ads.
    var view: UIView?

    /// The loaded partner ad banner size.
    /// Should be `nil` for full-screen ads.
    var size: PartnerBannerSize?

    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerDetails, Error>) -> Void) {
        log(.loadStarted)
        loadCompletion = completion

        // Banner ads auto-show after loading, so we must have a ViewController
        guard viewController != nil else {
            let error = error(.loadFailureViewControllerNotFound)
            log(.loadFailed(error))
            completion(.failure(error))
            return
        }
        
        let bannerView = GADBannerView(adSize: gadAdSize(from: request.bannerSize))
        bannerView.adUnitID = request.partnerPlacement
        bannerView.isAutoloadEnabled = false
        bannerView.delegate = self
        bannerView.rootViewController = viewController
        view = bannerView

        let adMobRequest = generateRequest()
        bannerView.load(adMobRequest)
    }
    
    private func gadAdSize(from requestedSize: BannerSize?) -> GADAdSize {
        guard let requestedSize else { return GADAdSizeInvalid }

        if requestedSize.type == .fixed {
            // Fixed size banner
            switch requestedSize.size.height {
            case 50..<90:
                return GADAdSizeBanner
            case 90..<250:
                return GADAdSizeLeaderboard
            case 250...:
                return GADAdSizeMediumRectangle
            default:
                return GADAdSizeBanner
            }
        } else {
            // Adaptive banner
            return GADInlineAdaptiveBannerAdSizeWithWidthAndMaxHeight(requestedSize.size.width, requestedSize.size.height)
        }
    }
}

extension AdMobAdapterBannerAd: GADBannerViewDelegate {

    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        log(.loadSucceeded)

        // From https://developers.google.com/admob/ios/api/reference/Functions:
        // "The exact size of the ad returned is passed through the banner’s ad size delegate and
        // is indicated by the banner’s intrinsicContentSize."
        bannerSize = PartnerBannerSize(
            size: bannerView.intrinsicContentSize,
            type: GADAdSizeIsFluid(bannerView.adSize) ? .adaptive : .fixed
        )
        loadCompletion?(.success([:])) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        log(.loadFailed(error))
        loadCompletion?(.failure(error)) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        log(.didTrackImpression)
        self.delegate?.didTrackImpression(self, details: [:]) ?? log(.delegateUnavailable)
    }

    func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
        self.delegate?.didClick(self, details: [:]) ?? log(.delegateUnavailable)
    }
}

// Copyright 2022-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import GoogleMobileAds

class AdMobAdapterBannerAd: AdMobAdapterAd, PartnerBannerAd {
    /// The partner banner ad view to display.
    var view: UIView?

    /// The loaded partner ad banner size.
    var size: PartnerBannerSize?

    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Error?) -> Void) {
        log(.loadStarted)
        loadCompletion = completion

        // Banner ads auto-show after loading, so we must have a ViewController
        guard viewController != nil else {
            let error = error(.loadFailureViewControllerNotFound)
            log(.loadFailed(error))
            completion(error)
            return
        }

        // Fail if we cannot fit a fixed size banner in the requested size.
        guard
            let requestedSize = request.bannerSize,
            let gadSize = requestedSize.gadAdSize
        else {
            let error = error(.loadFailureInvalidBannerSize)
            log(.loadFailed(error))
            completion(error)
            return
        }

        let bannerView = BannerView(adSize: gadSize)
        bannerView.adUnitID = request.partnerPlacement
        bannerView.isAutoloadEnabled = false
        bannerView.delegate = self
        bannerView.rootViewController = viewController
        view = bannerView

        let adMobRequest = generateRequest()
        bannerView.load(adMobRequest)
    }
}

extension AdMobAdapterBannerAd: BannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        log(.loadSucceeded)

        // From https://developers.google.com/admob/ios/api/reference/Functions:
        // "The exact size of the ad returned is passed through the banner’s ad size delegate and
        // is indicated by the banner’s intrinsicContentSize."
        size = PartnerBannerSize(
            size: bannerView.intrinsicContentSize,
            type: isAdSizeFluid(size: bannerView.adSize) ? .adaptive : .fixed
        )
        loadCompletion?(nil) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        log(.loadFailed(error))
        loadCompletion?(error) ?? log(.loadResultIgnored)
        loadCompletion = nil
    }

    func bannerViewDidRecordImpression(_ bannerView: BannerView) {
        log(.didTrackImpression)
        self.delegate?.didTrackImpression(self) ?? log(.delegateUnavailable)
    }

    func bannerViewDidRecordClick(_ bannerView: BannerView) {
        self.delegate?.didClick(self) ?? log(.delegateUnavailable)
    }
}

extension BannerSize {
    fileprivate var gadAdSize: AdSize? {
        if self.type == .adaptive {
            return inlineAdaptiveBanner(width: self.size.width, maxHeight: self.size.height)
        }
        switch self {
        case .standard:
            return AdSizeBanner
        case .medium:
            return AdSizeMediumRectangle
        case .leaderboard:
            return AdSizeLeaderboard
        default:
            return nil
        }
    }
}

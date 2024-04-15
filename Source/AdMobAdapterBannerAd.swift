// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import GoogleMobileAds

class AdMobAdapterBannerAd: AdMobAdapterAd, PartnerAd {
    /// The partner ad view to display inline. E.g. a banner view.
    /// Should be nil for full-screen ads.
    var inlineView: UIView?
    
    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented on. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        log(.loadStarted)
        loadCompletion = completion

        // Banner ads auto-show after loading, so we must have a ViewController
        guard viewController != nil else {
            let error = error(.loadFailureViewControllerNotFound)
            log(.loadFailed(error))
            completion(.failure(error))
            return
        }
        
        let bannerView = GADBannerView(adSize: gadAdSizeFrom(cgSize: request.size, format: request.format))
        bannerView.adUnitID = request.partnerPlacement
        bannerView.isAutoloadEnabled = false
        bannerView.delegate = self
        bannerView.rootViewController = viewController
        inlineView = bannerView
        
        let adMobRequest = generateRequest()
        bannerView.load(adMobRequest)
    }
    
    /// Shows a loaded ad.
    /// It will never get called for banner ads. You may leave the implementation blank for that ad format.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        // no-op
    }
    
    private func gadAdSizeFrom(cgSize: CGSize?, format: AdFormat) -> GADAdSize {
        guard let size = cgSize else { return GADAdSizeInvalid }

        if format == .banner {
            // Fixed size banner
            switch size.height {
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
            return GADInlineAdaptiveBannerAdSizeWithWidthAndMaxHeight(size.width, size.height)
        }
    }
}

extension AdMobAdapterBannerAd: GADBannerViewDelegate {

    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        log(.loadSucceeded)

        // From https://developers.google.com/admob/ios/api/reference/Functions:
        // "The exact size of the ad returned is passed through the banner’s ad size delegate and
        // is indicated by the banner’s intrinsicContentSize."
        let loadedSize = bannerView.intrinsicContentSize
        let partnerDetails = [
            "bannerWidth": "\(loadedSize.width)",
            "bannerHeight": "\(loadedSize.height)",
            // Determine if this is a fluid size ad or not. If the frame of a non-fluid adaptive ad
            // is changed by even 1px, it will trigger a reload, so we want to avoid this by
            // returning fixed in this case.
            // 0 for fixed size banner, 1 for adaptive banner.
            "bannerType": GADAdSizeIsFluid(bannerView.adSize) ? "1" : "0"
        ]
        loadCompletion?(.success(partnerDetails)) ?? log(.loadResultIgnored)
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

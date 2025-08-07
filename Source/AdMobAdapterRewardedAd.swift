// Copyright 2022-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import GoogleMobileAds

final class AdMobAdapterRewardedAd: AdMobAdapterAd, PartnerFullscreenAd {
    // The AdMob Ad Object
    var ad: RewardedAd?

    /// Loads an ad.
    /// - parameter viewController: The view controller on which the ad will be presented. Needed on load for some banners.
    /// - parameter completion: Closure to be performed once the ad has been loaded.
    func load(with viewController: UIViewController?, completion: @escaping (Error?) -> Void) {
        log(.loadStarted)

        let adMobRequest = generateRequest()
        RewardedAd.load(
            with: self.request.partnerPlacement,
            request: adMobRequest
        ) { [weak self] ad, error in
            guard let self else { return }
            if let error {
                self.log(.loadFailed(error))
                completion(error)
                return
            }
            self.ad = ad
            ad?.fullScreenContentDelegate = self
            self.log(.loadSucceeded)
            completion(error)
        }
    }

    /// Shows a loaded ad.
    /// Chartboost Mediation SDK will always call this method from the main thread.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(with viewController: UIViewController, completion: @escaping (Error?) -> Void) {
        log(.showStarted)

        guard let ad else {
            let error = error(.showFailureAdNotReady)
            log(.showFailed(error))
            completion(error)
            return
        }
        showCompletion = completion

        ad.present(from: viewController) { [weak self] in
            guard let self else { return }
            self.log(.didReward)
            self.delegate?.didReward(self) ?? self.log(.delegateUnavailable)
        }
    }
}

extension AdMobAdapterRewardedAd: FullScreenContentDelegate {
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        log(.didTrackImpression)
        delegate?.didTrackImpression(self) ?? log(.delegateUnavailable)
    }

    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        log(.didClick(error: nil))
        delegate?.didClick(self) ?? log(.delegateUnavailable)
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        log(.showFailed(error))
        showCompletion?(error) ?? log(.showResultIgnored)
        showCompletion = nil
    }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        log(.showSucceeded)
        showCompletion?(nil) ?? log(.showResultIgnored)
        showCompletion = nil
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        log(.didDismiss(error: nil))
        delegate?.didDismiss(self, error: nil) ?? log(.delegateUnavailable)
    }
}

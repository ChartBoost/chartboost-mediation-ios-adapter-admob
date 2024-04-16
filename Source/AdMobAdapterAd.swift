// Copyright 2022-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import Foundation
import GoogleMobileAds

class AdMobAdapterAd: NSObject {
    /// The partner adapter that created this ad.
    let adapter: PartnerAdapter

    /// Extra ad information provided by the partner.
    var details: PartnerDetails = [:]

    /// The ad load request associated to the ad.
    /// It should be the one provided on `PartnerAdapter.makeAd(request:delegate:)`.
    let request: PartnerAdLoadRequest

    /// The partner ad delegate to send ad life-cycle events to.
    /// It should be the one provided on `PartnerAdapter.makeAd(request:delegate:)`.
    weak var delegate: PartnerAdDelegate?

    /// The completion for the ongoing load operation.
    var loadCompletion: ((Result<PartnerDetails, Error>) -> Void)?

    /// The completion for the ongoing show operation.
    var showCompletion: ((Result<PartnerDetails, Error>) -> Void)?
    
    /// "extra" parameters that should be included in all ad requests
    let sharedExtras: GADExtras

    init(adapter: PartnerAdapter,
         request: PartnerAdLoadRequest,
         delegate: PartnerAdDelegate,
         extras: GADExtras) {
        self.adapter = adapter
        self.request = request
        self.delegate = delegate
        self.sharedExtras = extras
    }
    
    /// Configure the request object that will be sent to AdMob
    func generateRequest() -> GADRequest {
        let adMobRequest = GADRequest()
        adMobRequest.requestAgent = "Chartboost"
        
        var parameters: [String: Any] = [:]
        if let isHybrid = request.partnerSettings[GoogleStrings.isHybridKey] as? Bool,
            isHybrid == true {
            parameters[GoogleStrings.isHybridKey] = true
            
            // IFF we received the "is hybrid" flag set to True, we should also include the
            // request identifier, as per HB-4131
            parameters[GoogleStrings.reqIdKey] = request.identifier
        }
        
        // Generate the extras payload
        // If extras.additionalParameters is nill, we will merge with an empty dictionary instead
        let mergedParameters = (sharedExtras.additionalParameters ?? [:]).merging(parameters) { old, new in
            // There's no anticipated scenario where duplicate keys would exist here, but we still
            // have to include a closure specifying which value should win if there's a key collison
            return new
        }
        
        let extras = GADExtras()
        extras.additionalParameters = mergedParameters
        adMobRequest.register(extras)
        return adMobRequest
    }
}

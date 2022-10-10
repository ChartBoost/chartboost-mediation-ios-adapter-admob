//
//  AdMobAdAdapter.swift
//  AdMobAdapter
//
//  Created by Alex Rice on 10/03/22.
//

import Foundation
import GoogleMobileAds
import HeliumSdk

class AdMobAdAdapter: NSObject {

    /// The associated partner adapter.
    let adapter: PartnerAdapter
    
    /// The ad request containing data relevant to this ad
    let request: PartnerAdLoadRequest
    
    /// The partner ad delegate to send ad life-cycle events to.
    weak var partnerAdDelegate: PartnerAdDelegate?
    
    /// The completion for the ongoing load operation.
    var loadCompletion: ((Result<PartnerAd, Error>) -> Void)?
    
    /// The completion for the ongoing show operation.
    var showCompletion: ((Result<PartnerAd, Error>) -> Void)?
    
    /// Pointer to 'extras' that should be included in all ad requests
    let sharedExtras: GADExtras
    
    required init(adapter: PartnerAdapter,
                  request: PartnerAdLoadRequest,
                  partnerAdDelegate: PartnerAdDelegate,
                  extras: GADExtras) {
        self.adapter = adapter
        self.request = request
        self.partnerAdDelegate = partnerAdDelegate
        self.sharedExtras = extras
    }
}



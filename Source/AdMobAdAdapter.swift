//
//  AdMobAdAdapter.swift
//  AdMobAdapter
//
//  Created by Alex Rice on 10/03/22.
//

import Foundation
import HeliumSdk
import GoogleMobileAds

class AdMobAdAdapter: NSObject {
    
    /// The associated partner adapter.
    internal let adapter: PartnerAdapter
    
    /// The ad request containing data relevant to this ad
    internal let request: PartnerAdLoadRequest
    
    /// The partner ad delegate to send ad life-cycle events to.
    internal weak var partnerAdDelegate: PartnerAdDelegate?
    
    /// The completion for the ongoing load operation.
    internal var loadCompletion: ((Result<PartnerAd, Error>) -> Void)?
    
    /// The completion for the ongoing show operation.
    internal var showCompletion: ((Result<PartnerAd, Error>) -> Void)?
    
    /// Pointer to 'extras' that should be included in all ad requests
    internal let sharedExtras: GADExtras
    
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



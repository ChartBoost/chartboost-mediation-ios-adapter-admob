Pod::Spec.new do |spec|
  spec.name        = 'ChartboostHeliumAdapterAdMob'
  spec.version     = '4.1.0.0.0'
  spec.license     = { :type => 'MIT', :file => 'LICENSE.md' }
  spec.homepage    = 'https://github.com/ChartBoost/helium-ios-adapter-admob'
  spec.authors     = { 'Chartboost' => 'https://www.chartboost.com/' }
  spec.summary     = 'Helium iOS SDK Google AdMob adapter.'
  spec.description = 'Google AdMob Adapters for mediating through Helium. Supported ad formats: Banner, Interstitial, and Rewarded.'

  # Source
  spec.module_name  = 'HeliumAdapterAdMob'
  spec.source       = { :git => 'https://github.com/ChartBoost/helium-ios-adapter-admob.git', :tag => '1.0.0' }
  spec.source_files = 'Source/**/*.{h,m,swift}'

  # Minimum supported versions
  spec.swift_version         = '5.0'
  spec.ios.deployment_target = '10.0'

  # System frameworks used
  spec.ios.frameworks = ['Foundation', 'UIKit']
  
  # This adapter compatible with all Helium 4.X versions of the SDK.
  spec.dependency 'ChartboostHelium', '~> 4.0'

  # Replace this with the partner network SDK and version that this adapter is
  # certified to work with.
  #spec.dependency 'PartnerNetworkSDK', '1.0.0' 
end

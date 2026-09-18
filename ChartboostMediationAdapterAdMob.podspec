Pod::Spec.new do |spec|
  spec.name        = 'ChartboostMediationAdapterAdMob'
  spec.version     = '5.13.6.0.0'
  spec.license     = { :type => 'MIT', :file => 'LICENSE.md' }
  spec.homepage    = 'https://github.com/ChartBoost/chartboost-mediation-ios-adapter-admob'
  spec.authors     = { 'Chartboost' => 'https://www.chartboost.com/' }
  spec.summary     = 'Chartboost Mediation iOS SDK Google AdMob adapter.'
  spec.description = 'Google AdMob Adapters for mediating through Chartboost Mediation. Supported ad formats: Banner, Interstitial, and Rewarded.'

  # Source
  spec.module_name  = 'ChartboostMediationAdapterAdMob'
  spec.source       = { :git => 'https://github.com/ChartBoost/chartboost-mediation-ios-adapter-admob.git', :tag => spec.version }
  spec.source_files = 'Source/**/*.{swift}'
  spec.resource_bundles = { 'ChartboostMediationAdapterAdMob' => ['PrivacyInfo.xcprivacy'] }

  # Minimum supported versions
  spec.swift_version         = '5.0'
  spec.ios.deployment_target = '13.0'

  # System frameworks used
  spec.ios.frameworks = ['Foundation', 'UIKit']

  # Dependencies
  spec.dependency 'ChartboostMediationSDK', '~> 5.0'
  spec.dependency 'Google-Mobile-Ads-SDK', '~> 13.6.0'

  spec.static_framework = true
end

# Uncomment the next line to define a global platform for your project

source 'https://github.com/appodeal/CocoaPods.git'
source 'https://cdn.cocoapods.org/'

platform :ios, '11.0'
	
use_frameworks!

def appodeal
    pod 'APDAdColonyAdapter', '3.0.2.1'
    pod 'BidMachineAdColonyAdapter', '~> 2.0.0.0'
    pod 'APDAdjustAdapter', '3.0.2.1'
    pod 'APDAppLovinAdapter', '3.0.2.1'
    pod 'APDAppsFlyerAdapter', '3.0.2.1'
    pod 'APDBidMachineAdapter', '3.0.2.1' # Required
    pod 'BidMachineAmazonAdapter', '~> 2.0.0.0'
    pod 'BidMachineCriteoAdapter', '~> 2.0.0.0'
    pod 'BidMachineSmaatoAdapter', '~> 2.0.0.0'
    pod 'BidMachineTapjoyAdapter', '~> 2.0.0.0'
    pod 'BidMachinePangleAdapter', '~> 2.0.0.0'
    pod 'BidMachineNotsyAdapter', '~> 2.0.0.4'
    pod 'APDGoogleAdMobAdapter', '3.0.2.1'
    pod 'APDIABAdapter', '3.0.2.1' # Required
    pod 'APDIronSourceAdapter', '3.0.2.1'
    pod 'APDMetaAudienceNetworkAdapter', '3.0.2.1'
    pod 'BidMachineMetaAudienceAdapter', '~> 2.0.0.0'
    pod 'APDMyTargetAdapter', '3.0.2.1'
    pod 'BidMachineMyTargetAdapter', '~> 2.0.0.2'
    pod 'APDStackAnalyticsAdapter', '3.0.2.1' # Required
    pod 'APDUnityAdapter', '3.0.2.1'
    pod 'APDVungleAdapter', '3.0.2.1'
    pod 'BidMachineVungleAdapter', '~> 2.0.0.1'
    pod 'APDYandexAdapter', '3.0.2.1'
end

target 'CapGen' do
  # Comment the next line if you don't want to use dynamic frameworks

  appodeal

  target 'CapGenTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'CapGenUITests' do
    # Pods for testing
  end
  
  # post_install do |installer|
  #   targetsToFix = ["React-Core-AccessibilityResources", "EXConstants-EXConstants"];
  #   installer.generated_projects.each do |project|
  #     project.targets.each do |target|
  #       if targetsToFix.include? target.name
  #         puts "Set development team for target #{target.name}"
  #         target.build_configurations.each do |config|
  #           config.build_settings["DEVELOPMENT_TEAM"] = "Y5N6F2G6M7"
  #           config.build_settings["CODE_SIGN_IDENTITY"] = "Apple Distribution";
  #           config.build_settings["CODE_SIGN_STYLE"] = "Manual";
  #         end
  #       end
  #     end
  #   end
  # end
end
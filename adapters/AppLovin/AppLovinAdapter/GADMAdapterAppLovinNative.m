//
//  GADMAdapterAppLovinNative.m
//  SDK Network Adapters Test App
//
//  Created by Santosh Bagadi on 4/11/18.
//  Copyright © 2018 AppLovin Corp. All rights reserved.
//

#import "GADMAdapterAppLovinNative.h"

#import <AppLovinSDK/AppLovinSDK.h>
#import "GADMAdapterAppLovin.h"
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinUtils.h"
#import "GADMAdapterAppLovinExtras.h"
#import "GADMAdapterAppLovinQueue.h"
#import "GADMAppLovinMediatedNativeUnifiedAd.h"
#import "GADMAppLovinMediatedNativeAppInstallAd.h"

@interface GADMAdapterAppLovinNative () <ALNativeAdLoadDelegate, ALNativeAdPrecacheDelegate>

@property(nonatomic, weak) id<GADMAdNetworkConnector> connector;
@property(nonatomic, strong) ALSdk *sdk;
@property(nonatomic, strong) NSArray *adTypes;

@end

@implementation GADMAdapterAppLovinNative

+ (NSString *)adapterVersion {
  return GADMAdapterAppLovinConstant.adapterVersion;
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    self.connector = connector;
    self.sdk = [GADMAdapterAppLovinUtils retrieveSDKFromCredentials:connector.credentials];

    if (!self.sdk) {
      [GADMAdapterAppLovinUtils log:@"Failed to initialize SDK"];
    }
  }
  return self;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  NSLog(@"Incorrect class called for banner request. Use GADMAdapterAppLovin for banner ad"
        @" requeests.");
  NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.errorDomain
                                       code:kGADErrorInvalidRequest userInfo:nil];
  [self.connector adapter:self didFailAd:error];
}

- (void)getInterstitial {
  NSLog(@"Incorrect class called for banner request. Use GADMAdapterAppLovin for interstitial ad"
        @" requeests.");
  NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.errorDomain
                                       code:kGADErrorInvalidRequest userInfo:nil];
  [self.connector adapter:self didFailAd:error];
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMAdapterAppLovinExtras class];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
}

- (void)getNativeAdWithAdTypes:(NSArray *)adTypes options:(NSArray *)options {
  if (!([adTypes containsObject:kGADAdLoaderAdTypeUnifiedNative]
        || [adTypes containsObject:kGADAdLoaderAdTypeNativeAppInstall])) {
    NSError *error = [NSError errorWithDomain: GADMAdapterAppLovinConstant.errorDomain
                                         code: kGADErrorInvalidRequest userInfo: nil];
    [self.connector adapter:self didFailAd:error];
    return;
  }

  self.adTypes = adTypes;

  [[ALSdk shared].nativeAdService loadNativeAdGroupOfCount:1 andNotify:self];
}

- (void)stopBeingDelegate {
  self.connector = nil;
}

#pragma mark - AppLovin Native Load Delegate Methods

- (void)nativeAdService:(nonnull ALNativeAdService *)service
didFailToLoadAdsWithError
                       :(NSInteger)code {
  [self notifyFailureWithErrorCode:[GADMAdapterAppLovinUtils toAdMobErrorCode:(int)code]];
}

- (void)nativeAdService:(nonnull ALNativeAdService *)service didLoadAds:(nonnull NSArray *)ads {
  if (ads.count < 1) {
    [self notifyFailureWithErrorCode:kGADErrorMediationNoFill];
    return;
  }

  [service precacheResourcesForNativeAd:[ads firstObject] andNotify:self];
}

#pragma mark - AppLovin Native Ad Precache Delegate Methods

- (void)nativeAdService:(nonnull ALNativeAdService *)service
didFailToPrecacheImagesForAd
                       :(nonnull ALNativeAd *)ad
              withError:(NSInteger)errorCode {
  [self notifyFailureWithErrorCode:[GADMAdapterAppLovinUtils toAdMobErrorCode:(int)errorCode]];
}

- (void)nativeAdService:(nonnull ALNativeAdService *)service
didFailToPrecacheVideoForAd
                       :(nonnull ALNativeAd *)ad
              withError:(NSInteger)errorCode {
  [self notifyFailureWithErrorCode:[GADMAdapterAppLovinUtils toAdMobErrorCode:(int)errorCode]];
}

- (void)nativeAdService:(nonnull ALNativeAdService *)service
 didPrecacheImagesForAd:(nonnull ALNativeAd *)ad {
  if ([self.adTypes containsObject:kGADAdLoaderAdTypeUnifiedNative]
      && [GADMAdapterAppLovinUtils containsRequiredUnifiesNativeAssets:ad]) {
    GADMAppLovinMediatedNativeUnifiedAd *unifiedNativeAd =
        [[GADMAppLovinMediatedNativeUnifiedAd alloc] initWithNativeAd:ad];
    if (unifiedNativeAd) {
      [self.connector adapter:self didReceiveMediatedUnifiedNativeAd:unifiedNativeAd];
      return;
    }
  } else if ([self.adTypes containsObject:kGADAdLoaderAdTypeNativeAppInstall]
             && [GADMAdapterAppLovinUtils containsRequiredAppInstallNativeAssets:ad]) {
    GADMAppLovinMediatedNativeAppInstallAd *appInstallNativeAd =
        [[GADMAppLovinMediatedNativeAppInstallAd alloc] initWithNativeAd:ad];
    if (appInstallNativeAd) {
      [self.connector adapter:self didReceiveMediatedNativeAd:appInstallNativeAd];
      return;
    }
  }

  [self notifyFailureWithErrorCode:kGADErrorNoFill];
}

- (void)nativeAdService:(nonnull ALNativeAdService *)service
  didPrecacheVideoForAd:(nonnull ALNativeAd *)ad {
}

- (void)notifyFailureWithErrorCode:(NSInteger)errorCode {
  NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.errorDomain
                                       code:errorCode
                                   userInfo:nil];
  [self.connector adapter:self didFailAd:error];
}

@end

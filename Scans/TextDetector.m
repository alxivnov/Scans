//
//  TextDetector.m
//  Scans
//
//  Created by Alexander Ivanov on 02.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "TextDetector.h"

#import "Reachability.h"

#import <Crashlytics/Crashlytics.h>

@interface TextDetector ()
@property (strong, nonatomic) NSMutableArray<PHAsset *> *assets;

@property (assign, nonatomic) NSUInteger count;

@property (assign, nonatomic) BOOL processing;
@end

@implementation TextDetector

- (instancetype)init {
	self = [super init];

	if (self)
		self.assets = [[LIB fetchAssetsToDetect] mutableCopy];

	return self;
}

- (NSUInteger)count {
	return self.isProcessing ? _count : self.assets.count;
}

- (NSUInteger)index {
	return self.isProcessing ? _count - self.assets.count : NSNotFound;
}

- (BOOL)isProcessing {
	return self.processing;
}

- (void)setProcessing:(BOOL)processing {
	if (_processing == processing)
		return;

	_processing = processing;

	_count = self.assets.count;
}

- (void)process:(void(^)(BOOL))handler {
	PHAsset *asset = [self.assets fifo];
	if (!asset)
		return;

	BOOL networkAccessAllowed = [UIApplication sharedApplication].isActive || [[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == ReachableViaWiFi;
	
	[LIB detectTextRectanglesForAsset:asset networkAccessAllowed:networkAccessAllowed handler:^(FIRVisionText *result) {
		if (handler)
			handler(result.blocks.count > 0);

		[Answers logCustomEventWithName:@"Detect text" customAttributes:@{ @"count" : @(result.blocks.count) }];
	}];
}

- (void)startProcessing:(void(^)(BOOL success))handler {
	if (self.isProcessing)
		return;

	self.processing = self.assets.count > 0;

	[GCD global:^{
		while (self.isProcessing)
			[self process:^(BOOL success) {
				if (self.assets.count == 0)
					self.processing = NO;

				if (handler)
					handler(success);
			}];
	}];
}

- (void)stopProcessing {
	if (!self.isProcessing)
		return;

	self.processing = NO;
}

- (void)process:(NSTimeInterval)seconds handler:(void (^)(void))handler {
	NSDate *date = [NSDate dateWithTimeIntervalSinceNow:seconds];

	[GCD global:^{
		while (date.timeIntervalSinceNow > 0.0 && self.assets.count)
			[self process:Nil];

		if (handler)
			handler();
	}];
}

@end

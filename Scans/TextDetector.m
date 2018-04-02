//
//  TextDetector.m
//  Scans
//
//  Created by Alexander Ivanov on 02.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "TextDetector.h"

@interface TextDetector ()
@property (strong, nonatomic) NSMutableArray<PHAsset *> *assets;

@property (assign, nonatomic) NSUInteger count;

@property (assign, nonatomic) BOOL isProcessing;
@end

@implementation TextDetector

- (instancetype)init {
	self = [super init];

	if (self)
		[self prepare];

	return self;
}

- (void)prepare {
	NSArray *assets = [LIB fetchAssetsToDetect];

	self.assets = [assets mutableCopy];

	self.count = assets.count;
}

- (void)process:(void(^)(PHAsset *asset))handler {
	PHAsset *asset = [(NSMutableArray *)self.assets fifo];
	if (!asset)
		return;

	[LIB detectTextRectanglesForAsset:asset handler:handler];
}

- (void)startProcessing:(void(^)(PHAsset *asset))handler {
	if (self.isProcessing)
		return;

	self.isProcessing = self.assets.count > 0;

	[GCD global:^{
		while (self.isProcessing && self.assets.count)
			[self process:^(PHAsset *asset) {
				if (!self.assets.count)
					self.isProcessing = NO;

				if (handler)
					handler(asset);
			}];
	}];
}

- (void)stopProcessing {
	if (!self.isProcessing)
		return;

	self.isProcessing = NO;

	[self prepare];
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

- (NSUInteger)index {
	return self.isProcessing ? self.count - self.assets.count : NSNotFound;
}

@end

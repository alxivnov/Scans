//
//  TextDetector.m
//  Scans
//
//  Created by Alexander Ivanov on 27.03.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "TextDetector.h"

@interface TextDetector ()
@property (strong, nonatomic) PHAssetCollection *album;
@property (strong, nonatomic) NSManagedObjectContext *context;

@property (assign, nonatomic) CGSize size;
@property (strong, nonatomic) PHImageRequestOptions *options;

@property (strong, nonatomic) NSMutableArray<PHAsset *> *assets;
@end

@implementation TextDetector

- (instancetype)initWithAlbum:(PHAssetCollection *)album context:(NSManagedObjectContext *)context {
	self = [super init];

	if (self) {
		self.album = album;
		self.context = context;

		[self prepare];
	}

	return self;
}

- (void)prepare {
	CGFloat max = fmax([UIScreen mainScreen].nativeBounds.size.width, [UIScreen mainScreen].nativeBounds.size.height);
	self.size = CGSizeMake(max, max);

	PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
	options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
	options.networkAccessAllowed = YES;
	options.synchronous = YES;

	NSArray *IDs = [[self.context fetchAssetsWithAlbumIdentifier:self.album.localIdentifier] map:^id(Asset *obj) {
		return obj.assetIdentifier;
	}];
	PHFetchResult *fetch = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:[PHFetchOptions fetchOptionsWithPredicate:Nil sortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO] ]]];
	NSArray *array = [fetch.array query:^BOOL(PHAsset *obj) {
		return ![IDs containsObject:obj.localIdentifier];
	}];

	self.assets = array.count ? [array mutableCopy] : Nil;
}

- (void)process:(void(^)(PHAsset *asset))completion {
	PHAsset *asset = [(NSMutableArray *)self.assets fifo];

	[[PHImageManager defaultManager] requestImageForAsset:asset targetSize:self.size contentMode:PHImageContentModeAspectFill options:self.options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
		[result detectTextRectanglesWithOptions:@{ VNImageOptionReportCharacterBoxes : @YES } completionHandler:^(NSArray<VNTextObservation *> *results) {
			if (results.count) {
				[PHPhotoLibrary insertAssets:@[ asset ] atIndexes:Nil intoAssetCollection:self.album completionHandler:^(BOOL success) {
					if (completion)
						completion(asset);

					[self.context saveAssetWithIdentifier:asset.localIdentifier albumIdentifier:self.album.localIdentifier observations:results];
				}];
			} else {
				if (completion)
					completion(Nil);

				[self.context saveAssetWithIdentifier:asset.localIdentifier albumIdentifier:self.album.localIdentifier observations:results];
			}
		}];
	}];
}

@end

//
//  PhotoLibrary.m
//  Scans
//
//  Created by Alexander Ivanov on 31.03.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "PhotoLibrary.h"

#import "Model+Convenience.h"

@interface PhotoLibrary ()
@property (strong, nonatomic) NSPersistentContainer *db;

@property (strong, nonatomic) PHCachingImageManager *cache;
@property (strong, nonatomic) PHAssetCollection *album;
@property (strong, nonatomic) PHFetchResult *fetch;

@property (assign, nonatomic) CGSize largeSize;
@property (assign, nonatomic) CGSize smallSize;
@end

@implementation PhotoLibrary

@synthesize cache = _cache;
@synthesize album = _album;
@synthesize fetch = _fetch;

- (void)setAlbum:(PHAssetCollection *)album {
	_album = album;

	if (_album) {
		_cache = [[PHCachingImageManager alloc] init];

		_fetch = [PHAsset fetchAssetsInAssetCollection:_album options:[PHFetchOptions fetchOptionsWithPredicate:Nil sortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES] ]]];

		[_cache startCachingImagesForAssets:_fetch.array targetSize:self.smallSize contentMode:PHImageContentModeAspectFill options:Nil];
	} else {
		_cache = Nil;

		_fetch = Nil;
	}
}

- (void)prep:(void (^)(void))handler {
	NSString *albumIdentifier = [self.db.viewContext fetchLastAlbum].albumIdentifier;

	self.album = [PHAssetCollection fetchAssetCollectionWithLocalIdentifier:albumIdentifier options:Nil];

	if (self.album) {
		if (handler)
			handler();
	} else {
		[PHPhotoLibrary createAssetCollectionWithTitle:@"Scans" completionHandler:^(NSString *localIdentifier) {
			self.album = [PHAssetCollection fetchAssetCollectionWithLocalIdentifier:localIdentifier options:Nil];

			if (handler)
				handler();

			[self.db.viewContext saveAlbumWithIdentifier:localIdentifier];
		}];
	}
}

- (instancetype)init {
	self = [super init];

	if (self)
		[NSPersistentContainer loadPersistentContainerWithName:@"Scans" completionHandler:^(NSPersistentContainer *container) {
			self.db = container;

			CGFloat max = fmax([UIScreen mainScreen].nativeBounds.size.width, [UIScreen mainScreen].nativeBounds.size.height);
			self.largeSize = CGSizeMake(max, max);
			
			CGFloat scale = [UIScreen mainScreen].nativeScale;
			self.smallSize = CGSizeScale(CGSizeMake(93.0, 93.0), scale, scale);

			if (PHPhotoLibraryAuthorized(NSNotFound))
				[self prep:Nil];

			[container.persistentStoreDescriptions.firstObject.URL.absoluteString log:@"Core Data URL:"];
		}];

	return self;
}

- (NSUInteger)count {
	return self.fetch.count;
}

- (PHAsset *)assetAtIndex:(NSUInteger)index {
	return idx(self.fetch, index);
}

- (void)requestAuthorization:(void (^)(PHAuthorizationStatus))handler {
	[PHPhotoLibrary requestAuthorizationIfNeeded:^(PHAuthorizationStatus status) {
		if (PHPhotoLibraryAuthorized(status))
			[self prep:^{
				if (handler)
					handler(status);
			}];
		else
			if (handler)
				handler(status);
	}];
}

- (void)createAssetWithImage:(UIImage *)image {
	if (!image)
		return;

	[PHPhotoLibrary createAssetWithImage:image completionHandler:^(NSString *localIdentifier) {
		PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifier:localIdentifier options:Nil].firstObject;
		if (!asset)
			return;

		[image detectTextRectanglesWithOptions:@{ VNImageOptionReportCharacterBoxes : @YES } completionHandler:^(NSArray<VNTextObservation *> *results) {
			if (results)
				[PHPhotoLibrary insertAssets:@[ asset ] atIndexes:Nil intoAssetCollection:self.album completionHandler:^(BOOL success) {
					[self.db.viewContext saveAssetWithIdentifier:asset.localIdentifier albumIdentifier:self.album.localIdentifier observations:results];
				}];
			else
				[self.db.viewContext saveAssetWithIdentifier:asset.localIdentifier albumIdentifier:self.album.localIdentifier observations:results];
		}];
	}];
}

- (PHImageRequestID)requestSmallImageAtIndex:(NSUInteger)index resultHandler:(void (^)(UIImage *, PHImageRequestID))resultHandler {
	PHAsset *asset = idx(self.fetch, index);
	if (!asset)
		return PHInvalidImageRequestID;

	PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
	options.networkAccessAllowed = YES;

	return [self.cache requestImageForAsset:asset targetSize:self.smallSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
		if(resultHandler)
			resultHandler(result, [info[PHImageResultRequestIDKey] intValue]);
	}];
}

- (PHImageRequestID)requestLargeImageForAsset:(PHAsset *)asset resultHandler:(void (^)(UIImage *, BOOL))resultHandler progressHandler:(PHAssetImageProgressHandler)progressHandler {
	if (!asset)
		return PHInvalidImageRequestID;

	PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
	options.networkAccessAllowed = YES;
	options.progressHandler = progressHandler;

	return [self.cache requestImageForAsset:asset targetSize:self.largeSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
		if (resultHandler)
			resultHandler(result, [info[PHImageResultIsDegradedKey] boolValue]);
	}];
}

- (PHImageRequestID)detectTextRectanglesForAsset:(PHAsset *)asset handler:(void (^)(PHAsset *))handler {
	PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
	options.networkAccessAllowed = YES;
	options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
//	options.synchronous = YES;

	return [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:LIB.largeSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
		[result detectTextRectanglesWithOptions:@{ VNImageOptionPreferBackgroundProcessing : @YES, VNImageOptionReportCharacterBoxes : @YES } completionHandler:^(NSArray<VNTextObservation *> *results) {
			if (results.count) {
				[PHPhotoLibrary insertAssets:@[ asset ] atIndexes:Nil intoAssetCollection:LIB.album completionHandler:^(BOOL success) {
					if (handler)
						handler(results.count ? asset : Nil);

					[LIB.db.viewContext saveAssetWithIdentifier:asset.localIdentifier albumIdentifier:LIB.album.localIdentifier observations:results];
				}];
			} else {
				if (handler)
					handler(Nil);

				[LIB.db.viewContext saveAssetWithIdentifier:asset.localIdentifier albumIdentifier:LIB.album.localIdentifier observations:results];
			}
		}];
	}];
}

- (NSArray<PHAsset *> *)fetchAssetsToDetect {
	NSArray *assetIdentifiers = [[LIB.db.viewContext fetchAssetsWithAlbumIdentifier:LIB.album.localIdentifier] map:^id(Asset *obj) {
		return obj.assetIdentifier;
	}];
	PHFetchResult *fetch = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:[PHFetchOptions fetchOptionsWithPredicate:Nil sortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO] ]]];
	return [fetch.array query:^BOOL(PHAsset *obj) {
		return ![assetIdentifiers containsObject:obj.localIdentifier];
	}];
}

- (NSArray<VNTextObservation *> *)fetchObservationsWithAssetIdentifier:(NSString *)assetIdentifier {
	return assetIdentifier ? [[self.db.viewContext fetchObservationsWithAlbumIdentifier:self.album.localIdentifier assetIdentifier:assetIdentifier] map:^id(Observation *obj) {
		return obj.observation;
	}] : Nil;
}

- (void)deleteAsset:(PHAsset *)asset fromLibrary:(BOOL)fromLibrary handler:(void (^)(BOOL))handler {
	if (!asset)
		return;

	if (fromLibrary)
		[PHPhotoLibrary deleteAssets:@[ asset ] completionHandler:handler];
	else
		[PHPhotoLibrary removeAssets:@[ asset ] fromAssetCollection:self.album completionHandler:handler];
}

- (PHFetchResultChangeDetails *)performFetchResultChanges:(PHChange *)changeInstance {
	PHFetchResultChangeDetails *changes = [changeInstance changeDetailsForFetchResult:self.fetch];
	if (!changes)
		return Nil;

	self.fetch = changes.fetchResultAfterChanges;

	[self.cache startCachingImagesForAssets:changes.insertedObjects targetSize:self.smallSize contentMode:PHImageContentModeAspectFill options:Nil];

	return changes;
}

__static(PhotoLibrary *, instance, [[PhotoLibrary alloc] init])

@end

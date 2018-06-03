//
//  PhotoLibrary.m
//  Scans
//
//  Created by Alexander Ivanov on 31.03.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "PhotoLibrary.h"

#import "FIRVision+Convenience.h"

@interface PhotoLibrary ()
@property (strong, nonatomic) NSPersistentContainer *db;

@property (strong, nonatomic) PHCachingImageManager *cache;
@property (strong, nonatomic) PHAssetCollection *album;
@property (strong, nonatomic) PHFetchResult *fetch;

@property (assign, nonatomic) CGSize largeSize;
@property (assign, nonatomic) CGSize smallSize;

@property (strong, nonatomic) NSArray<Observation *> *observations;
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

- (void)setSearch:(NSString *)search {
	_search = search;

	self.observations = search.length ? [[self.db.viewContext fetchObservationsWithAlbumIdentifier:self.album.localIdentifier label:search] dictionaryWithKey:^id<NSCopying>(Observation *obj) {
		return obj.assetIdentifier;
	}].allValues : Nil;
}

- (NSUInteger)count {
	return self.observations ? self.observations.count : self.fetch.count;
}

- (PHAsset *)assetAtIndex:(NSUInteger)index {
	return self.observations ? [PHAsset fetchAssetWithLocalIdentifier:idx(self.observations, index).assetIdentifier options:Nil] : idx(self.fetch, index);
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
		PHAsset *asset = [PHAsset fetchAssetWithLocalIdentifier:localIdentifier options:Nil];
		if (!asset)
			return;

		NSArray<FIRVisionLabel *> *labels = [[FIRVisionLabelDetector labelDetector] detectInImage:image];
		[image detectTextRectanglesWithOptions:@{ VNImageOptionReportCharacterBoxes : @YES } completionHandler:^(NSArray<VNTextObservation *> *results) {
			if (results)
				[PHPhotoLibrary insertAssets:@[ asset ] atIndexes:Nil intoAssetCollection:self.album completionHandler:^(BOOL success) {
					[self.db.viewContext saveAssetWithIdentifier:asset.localIdentifier albumIdentifier:self.album.localIdentifier observations:results labels:labels];
				}];
			else
				[self.db.viewContext saveAssetWithIdentifier:asset.localIdentifier albumIdentifier:self.album.localIdentifier observations:results labels:labels];
		}];
	}];
}

- (PHImageRequestID)requestSmallImageAtIndex:(NSUInteger)index resultHandler:(void (^)(UIImage *, PHImageRequestID))resultHandler {
	PHAsset *asset = [self assetAtIndex:index];
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

- (PHImageRequestID)detectTextRectanglesForAsset:(PHAsset *)asset handler:(void (^)(NSArray<id<FIRVisionText>> *))handler {
	PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
	options.networkAccessAllowed = YES;
	options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
	options.synchronous = YES;

	NSString *assetIdentifier = asset.localIdentifier;
	return [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:LIB.largeSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *result, NSDictionary *info) {
		NSArray<id<FIRVisionText>> *texts = [[FIRVisionTextDetector textDetector] detectInImage:result];
		NSArray<FIRVisionLabel *> *labels = [[FIRVisionLabelDetector labelDetector] detectInImage:result];
//		NSArray<VNTextObservation *> *results = [result detectTextRectanglesWithOptions:@{ VNImageOptionPreferBackgroundProcessing : @YES, VNImageOptionReportCharacterBoxes : @YES }];

		if (texts.count) {
			[PHPhotoLibrary insertAssets:@[ asset ] atIndexes:Nil intoAssetCollection:LIB.album completionHandler:^(BOOL success) {
				if (handler)
					handler(texts);

				if (result)
					[LIB.db.viewContext saveAssetWithIdentifier:assetIdentifier albumIdentifier:LIB.album.localIdentifier texts:texts labels:labels size:result.size];
			}];
		} else {
			if (handler)
				handler(texts);

			if (result)
				[LIB.db.viewContext saveAssetWithIdentifier:assetIdentifier albumIdentifier:LIB.album.localIdentifier texts:texts labels:labels size:result.size];
		}
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

- (NSArray<Observation *> *)fetchObservationsWithAssetIdentifier:(NSString *)assetIdentifier {
	return assetIdentifier ? [self.db.viewContext fetchObservationsWithAlbumIdentifier:self.album.localIdentifier assetIdentifier:assetIdentifier] : Nil;
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
	if (changes)
		self.fetch = changes.fetchResultAfterChanges;

	if (changes.insertedIndexes.count)
		[self.cache startCachingImagesForAssets:changes.insertedObjects targetSize:self.smallSize contentMode:PHImageContentModeAspectFill options:Nil];

	return changes;
}

__static(PhotoLibrary *, instance, [[PhotoLibrary alloc] init])

@end

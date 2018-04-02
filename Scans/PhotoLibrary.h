//
//  PhotoLibrary.h
//  Scans
//
//  Created by Alexander Ivanov on 31.03.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CoreGraphics+Convenience.h"
#import "Photos+Convenience.h"
#import "Vision+Convenience.h"

#define LIB [PhotoLibrary instance]

@interface PhotoLibrary : NSObject
@property (assign, nonatomic, readonly) NSUInteger count;
- (PHAsset *)assetAtIndex:(NSUInteger)index;

- (void)requestAuthorization:(void (^)(PHAuthorizationStatus status))handler;

- (void)createAssetWithImage:(UIImage *)image;

- (PHImageRequestID)requestSmallImageAtIndex:(NSUInteger)index resultHandler:(void (^)(UIImage *result, PHImageRequestID requestID))resultHandler;
- (PHImageRequestID)requestLargeImageForAsset:(PHAsset *)asset resultHandler:(void (^)(UIImage *result, BOOL isDegraded))resultHandler progressHandler:(PHAssetImageProgressHandler)progressHandler;

- (PHImageRequestID)detectTextRectanglesForAsset:(PHAsset *)asset handler:(void (^)(PHAsset *asset))handler;
- (NSArray<PHAsset *> *)fetchAssetsToDetect;

- (NSArray<VNTextObservation *> *)fetchObservationsWithAssetIdentifier:(NSString *)assetIdentifier;
- (void)deleteAsset:(PHAsset *)asset fromLibrary:(BOOL)fromLibrary handler:(void (^)(BOOL success))handler;

- (PHFetchResultChangeDetails *)performFetchResultChanges:(PHChange *)changeInstance;

+ (instancetype)instance;
@end

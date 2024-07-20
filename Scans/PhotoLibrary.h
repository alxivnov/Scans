//
//  PhotoLibrary.h
//  Scans
//
//  Created by Alexander Ivanov on 31.03.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Model+Convenience.h"

#import "CoreGraphics+Convenience.h"
#import "Photos+Convenience.h"
#import "Vision+Convenience.h"

#define LIB [PhotoLibrary instance]

@interface PhotoLibrary : NSObject
@property (assign, nonatomic, readonly) NSUInteger count;
- (PHAsset *)assetAtIndex:(NSUInteger)index;

@property (strong, nonatomic, readonly) NSSet<NSString *> *localIdentifiers;

- (void)requestAuthorization:(void (^)(PHAuthorizationStatus status))handler;

- (void)createAssetWithImage:(UIImage *)image;

- (PHImageRequestID)requestSmallImageForAsset:(PHAsset *)asset resultHandler:(void (^)(UIImage *result, PHImageRequestID requestID))resultHandler;
- (PHImageRequestID)requestLargeImageForAsset:(PHAsset *)asset resultHandler:(void (^)(UIImage *result, BOOL isDegraded))resultHandler progressHandler:(PHAssetImageProgressHandler)progressHandler;

//- (PHImageRequestID)detectTextRectanglesForAsset:(PHAsset *)asset networkAccessAllowed:(BOOL)networkAccessAllowed handler:(void (^)(FIRVisionText *result))handler;
- (PHImageRequestID)detectTextRectanglesForAsset:(PHAsset *)asset networkAccessAllowed:(BOOL)networkAccessAllowed handler:(void (^)(NSArray<VNRecognizedTextObservation *> *result))handler;
- (NSArray<PHAsset *> *)fetchAssetsToDetect;

- (NSArray<Observation *> *)fetchObservationsWithLabel:(NSString *)label;

- (NSArray<Observation *> *)fetchObservationsWithAssetIdentifier:(NSString *)assetIdentifier;
- (void)deleteAsset:(PHAsset *)asset fromLibrary:(BOOL)fromLibrary handler:(void (^)(BOOL success))handler;

- (PHFetchResultChangeDetails *)performFetchResultChanges:(PHChange *)changeInstance;

+ (instancetype)instance;
@end

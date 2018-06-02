//
//  Model+Convenience.h
//  Scans
//
//  Created by Alexander Ivanov on 01.03.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "Scans+CoreDataModel.h"

#import "CoreData+Convenience.h"
#import "Vision+Convenience.h"

#import "FIRVision+Convenience.h"

@interface Observation (VNTextObservation)

@property (strong, nonatomic) VNTextObservation *observation;

@end

@interface Label (FIRVisionLabel)

@property (assign, nonatomic) CGRect frame;

@end

@interface NSManagedObjectContext (Model)

- (Album *)fetchLastAlbum;
- (NSArray<Asset *> *)fetchAssetsWithAlbumIdentifier:(NSString *)albumIdentifier;
- (NSArray<Observation *> *)fetchObservationsWithAlbumIdentifier:(NSString *)albumIdentifier assetIdentifier:(NSString *)assetIdentifier;
- (NSArray<Observation *> *)fetchObservationsWithAlbumIdentifier:(NSString *)albumIdentifier label:(NSString *)label;

- (Album *)saveAlbumWithIdentifier:(NSString *)albumIdentifier;
- (Asset *)saveAssetWithIdentifier:(NSString *)assetIdentifier albumIdentifier:(NSString *)albumIdentifier observations:(NSArray<VNTextObservation *> *)observations labels:(NSArray<FIRVisionLabel *> *)labels;
- (Asset *)saveAssetWithIdentifier:(NSString *)assetIdentifier albumIdentifier:(NSString *)albumIdentifier texts:(NSArray<id<FIRVisionText>> *)texts labels:(NSArray<FIRVisionLabel *> *)labels size:(CGSize)size;

@end

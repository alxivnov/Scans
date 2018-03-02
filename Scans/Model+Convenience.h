//
//  Model+Convenience.h
//  Scans
//
//  Created by Alexander Ivanov on 01.03.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "Scans+CoreDataModel.h"

#import <Vision/Vision.h>

#import "CoreData+Convenience.h"

@interface Observation (VNTextObservation)

@property (strong, nonatomic) VNTextObservation *observation;

@end

@interface NSManagedObjectContext (Model)

- (Album *)saveAlbumWithIdentifier:(NSString *)albumIdentifier creationDate:(NSDate *)creationDate;

- (Asset *)saveAssetWithIdentifier:(NSString *)assetIdentifier albumIdentifier:(NSString *)albumIdentifier observations:(NSArray *)observations;

@end

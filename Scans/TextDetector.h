//
//  TextDetector.h
//  Scans
//
//  Created by Alexander Ivanov on 27.03.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NSArray+Convenience.h"
#import "Photos+Convenience.h"
#import "Vision+Convenience.h"

#import "Model+Convenience.h"

@interface TextDetector : NSObject

@property (strong, nonatomic, readonly) NSArray<PHAsset *> *assets;

- (instancetype)initWithAlbum:(PHAssetCollection *)album context:(NSManagedObjectContext *)context;

- (void)process:(void(^)(PHAsset *asset))completion;

@end

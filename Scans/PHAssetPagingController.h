//
//  PHAssetPagingController.h
//  Scans
//
//  Created by Alexander Ivanov on 27.02.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIPagingController.h"

@import Photos;

@interface PHAssetPagingController : UIPagingController

@property (strong, nonatomic) PHAssetCollection *album;
@property (strong, nonatomic) PHFetchResult *fetch;
@property (assign, nonatomic) NSIndexPath *indexPath;

@end

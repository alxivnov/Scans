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

@property (strong, nonatomic) NSArray<PHAsset *> *assets;
@property (assign, nonatomic) NSIndexPath *indexPath;

@end

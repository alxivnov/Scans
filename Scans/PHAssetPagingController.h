//
//  PHAssetPagingController.h
//  Scans
//
//  Created by Alexander Ivanov on 27.02.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIPageViewController+Convenience.h"

@interface PHAssetPagingController : UIPagingController

@property (assign, nonatomic) NSIndexPath *indexPath;

@end

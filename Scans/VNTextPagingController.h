//
//  UIImagePagingController.h
//  Scans
//
//  Created by Alexander Ivanov on 27.02.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Model+Convenience.h"

#import "UIPageViewController+Convenience.h"

@interface VNTextPagingController : UIPagingController

@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) NSArray<Observation *> *observations;
@property (assign, nonatomic) NSIndexPath *indexPath;

@end

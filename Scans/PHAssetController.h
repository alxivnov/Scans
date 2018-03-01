//
//  UIImageViewController.h
//  Scans
//
//  Created by Alexander Ivanov on 23.11.2017.
//  Copyright © 2017 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIImageController.h"
#import "Photos+Convenience.h"

@interface PHAssetController : UIImageController
@property (strong, nonatomic) PHAssetCollection *album;
@property (strong, nonatomic) PHAsset *asset;
@end

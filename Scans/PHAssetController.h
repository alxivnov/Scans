//
//  UIImageViewController.h
//  Scans
//
//  Created by Alexander Ivanov on 23.11.2017.
//  Copyright © 2017 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PhotoLibrary.h"

#import "UIImageController.h"

@interface PHAssetController : UIImageController
@property (strong, nonatomic) PHAsset *asset;
@end

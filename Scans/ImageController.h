//
//  UIImageViewController.h
//  Scans
//
//  Created by Alexander Ivanov on 23.11.2017.
//  Copyright © 2017 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Photos+Convenience.h"

@interface ImageController : UIViewController
@property (strong, nonatomic) PHAsset *image;
@end

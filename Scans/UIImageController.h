//
//  UIImageController.h
//  Scans
//
//  Created by Alexander Ivanov on 22.02.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NSObject+Convenience.h"
#import "UIActivityViewController+Convenience.h"
#import "UIScrollView+Convenience.h"

@interface UIImageController : UIViewController
@property (strong, nonatomic, readonly) UIScrollView *scrollView;

@property (strong, nonatomic) UIImageView *imageView;

@property (strong, nonatomic) UIImage *image;
@end

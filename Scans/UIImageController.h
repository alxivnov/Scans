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
#import "UICenteredScrollView.h"

@interface UIImageController : UIViewController
@property (strong, nonatomic) UIImage *image;

- (void)fill;
- (void)fit;
@end

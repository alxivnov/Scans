//
//  AVCaptureViewController.h
//  Scans
//
//  Created by Alexander Ivanov on 16.03.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>

#import "CoreGraphics+Convenience.h"
#import "Dispatch+Convenience.h"
#import "QuartzCore+Convenience.h"
#import "Vision+Convenience.h"
#import "AVCaptureSession+Convenience.h"

@interface VNDetectRectanglesViewController : AVCapturePhotoViewController

@property (strong, nonatomic, readonly) CAShapeLayer *shapeLayer;

@end

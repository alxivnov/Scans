//
//  AVCaptureViewController.h
//  Scans
//
//  Created by Alexander Ivanov on 16.03.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>

#import "NSObject+Convenience.h"
#import "CoreGraphics+Convenience.h"
#import "Dispatch+Convenience.h"
#import "Vision+Convenience.h"

@interface AVCapturePhotoViewController : UIViewController

@property (copy, nonatomic) void (^capturePhotoHandler)(AVCapturePhoto *photo);

@end

@interface VNDetectRectanglesViewController : AVCapturePhotoViewController

@end

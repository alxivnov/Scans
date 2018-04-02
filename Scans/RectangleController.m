//
//  AVCaptureViewController.m
//  Scans
//
//  Created by Alexander Ivanov on 16.03.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "RectangleController.h"

#warning Focus
#warning Flash

#define CGPointRotate(point) CGPointMake(point.y, point.x)

@interface RectangleController () <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (strong, nonatomic, readonly) AVCaptureVideoDataOutput *videoDataOutput;

@property (strong, nonatomic) VNSequenceRequestHandler *handler;
@property (strong, nonatomic) VNDetectRectanglesRequest *request;

@property (strong, nonatomic) CAShapeLayer *shapeLayer;

@property (strong, nonatomic) NSDate *date;
@end

@implementation RectangleController

__synthesize(AVCaptureVideoDataOutput *, videoDataOutput, [AVCaptureVideoDataOutput videoDataOutputWithSampleBufferDelegate:self queue:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)])

__synthesize(VNSequenceRequestHandler *, handler, [[VNSequenceRequestHandler alloc] init])

__synthesize(VNDetectRectanglesRequest *, request, ({
	__weak RectangleController *__self = self;
	VNDetectRectanglesRequest *request = [VNDetectRectanglesRequest requestWithCompletionHandler:^(NSArray *results) {
		VNRectangleObservation *rect = results.firstObject;
		if (rect) {
			CGPoint topLeft = [__self.previewLayer pointForCaptureDevicePointOfInterest:CGPointMake(rect.topLeft.x, 1.0 - rect.topLeft.y)];
			CGPoint topRight = [__self.previewLayer pointForCaptureDevicePointOfInterest:CGPointMake(rect.topRight.x, 1.0 - rect.topRight.y)];
			CGPoint bottomRight = [__self.previewLayer pointForCaptureDevicePointOfInterest:CGPointMake(rect.bottomRight.x, 1.0 - rect.bottomRight.y)];
			CGPoint bottomLeft = [__self.previewLayer pointForCaptureDevicePointOfInterest:CGPointMake(rect.bottomLeft.x, 1.0 - rect.bottomLeft.y)];

			CGMutablePathRef path = CGPathCreateMutable();
			CGPathMoveToPoint(path, Nil, topLeft.x, topLeft.y);
			CGPathAddLineToPoint(path, Nil, topRight.x, topRight.y);
			CGPathAddLineToPoint(path, Nil, bottomRight.x, bottomRight.y);
			CGPathAddLineToPoint(path, Nil, bottomLeft.x, bottomLeft.y);
			CGPathAddLineToPoint(path, Nil, topLeft.x, topLeft.y);

			[GCD main:^{
				[__self.shapeLayer addAnimationFromValue:(__bridge id)__self.shapeLayer.path toValue:(__bridge id)path forKey:CALayerKeyPath];

				__self.shapeLayer.path = path;
			}];
		} else {
			__self.date = Nil;

			[GCD main:^{
				__self.shapeLayer.path = Nil;
			}];
		}

//		[rect log:@"requestWithCompletionHandler:"];
	}];
	request.preferBackgroundProcessing = YES;
	request;
}))

__synthesize(CAShapeLayer *, shapeLayer, ({
	CAShapeLayer *layer = [[CAShapeLayer alloc] init];
	layer.frame = self.view.bounds;
	layer.lineWidth = 2.0;
	layer.fillColor = Nil;
	layer.strokeColor = self.view.tintColor.CGColor;
	layer;
}))

- (void)viewDidLoad {
	[super viewDidLoad];

	[self.previewLayer.session addOutput:self.videoDataOutput];

	[self.view.layer addSublayer:self.shapeLayer];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];

	self.handler = Nil;
	self.request = Nil;
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	// Doherty Threshold 0.4
	// HPM Eye movement time 0.2
	if (self.date && [self.date timeIntervalSinceNow] > -0.2)
		return;

	CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

	self.date = [self.handler performRequests:@[ self.request ] onCVPixelBuffer:pixelBuffer] ? [NSDate date] : Nil;
}

- (instancetype)initWithHandler:(void (^)(UIImage *))handler {
	self = [self init];

	if (self)
		self.capturePhotoHandler = ^(AVCapturePhoto *photo) {
			UIImage *image = photo.image;
//			image = [image drawImage:Nil];
			[image detectRectanglesWithOptions:Nil completionHandler:^(NSArray<VNRectangleObservation *> *results) {
				UIImage *temp = [image imageWithRectangle:results.firstObject];

				if (handler)
					handler(temp);
			}];
		};

	return self;
}

@end

//
//  AVCaptureViewController.m
//  Scans
//
//  Created by Alexander Ivanov on 16.03.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "RectangleController.h"

#import "PhotoLibrary.h"

#import <Crashlytics/Crashlytics.h>

#warning Focus
#warning Flash

#define CGPointRotate(point) CGPointMake(point.y, point.x)

@interface RectangleController () <AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UIButton *captureButton;

@property (strong, nonatomic, readonly) AVCaptureSession *session;

@property (strong, nonatomic, readonly) AVCaptureDeviceInput *deviceInput;
@property (strong, nonatomic, readonly) AVCapturePhotoOutput *photoOutput;

@property (strong, nonatomic, readonly) AVCaptureVideoPreviewLayer *previewLayer;


@property (strong, nonatomic, readonly) AVCaptureVideoDataOutput *videoDataOutput;

@property (strong, nonatomic) VNSequenceRequestHandler *handler;
@property (strong, nonatomic) VNDetectRectanglesRequest *request;

@property (strong, nonatomic) CAShapeLayer *shapeLayer;

@property (strong, nonatomic) NSDate *date;
@end

@implementation RectangleController

__synthesize(AVCaptureSession *, session, [AVCaptureSession sessionWithPreset:AVCaptureSessionPresetPhoto])
__synthesize(AVCaptureDeviceInput *, deviceInput, [AVCaptureDeviceInput deviceInputWithMediaType:AVMediaTypeVideo])
__synthesize(AVCapturePhotoOutput *, photoOutput, [[AVCapturePhotoOutput alloc] init])

__synthesize(AVCaptureVideoPreviewLayer *, previewLayer, ({
	AVCaptureVideoPreviewLayer *layer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
	layer.frame = self.view.bounds;
	layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	layer;
}))

__synthesize(AVCaptureVideoDataOutput *, videoDataOutput, [AVCaptureVideoDataOutput videoDataOutputWithSampleBufferDelegate:self queue:Nil])

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

	[self.previewView.layer insertSublayer:self.previewLayer atIndex:0];
	[self.previewView.layer insertSublayer:self.shapeLayer atIndex:1];

	self.captureButton.layer.borderColor = [UIColor grayColor].CGColor;
	self.captureButton.layer.borderWidth = 4.0;
	self.captureButton.layer.cornerRadius = self.captureButton.frame.size.height / 2.0;


	[Answers logContentViewWithName:@"RectangleController" contentType:@"VC" contentId:Nil customAttributes:Nil];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	[AVCaptureDevice requestAccessIfNeededForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
		AVCaptureSession *session = self.session;
		AVCaptureInput *deviceInput = self.deviceInput;
		AVCaptureOutput *photoOutput = self.photoOutput;
		AVCaptureOutput *videoDataOutput = self.videoDataOutput;

		if (deviceInput && ![session.inputs containsObject:deviceInput])
			[session addInput:deviceInput];
		if (photoOutput && ![session.outputs containsObject:photoOutput])
			[session addOutput:photoOutput];
		if (videoDataOutput && ![session.outputs containsObject:videoDataOutput])
			[session addOutput:videoDataOutput];
		if (deviceInput && photoOutput && videoDataOutput && !session.isRunning)
			[session startRunning];

		[GCD main:^{
			self.previewLayer.frame = self.previewView.bounds;
			self.shapeLayer.frame = self.previewView.bounds;
		}];

		[Answers logCustomEventWithName:@"Camera access" customAttributes:@{ @"granted" : @(granted) }];
	}];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	AVCaptureSession *session = self.session;
	if (session.isRunning)
		[session stopRunning];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];

	AVCaptureSession *session = self.session;
	if (session.isRunning)
		[session stopRunning];

	self.handler = Nil;
	self.request = Nil;
}

- (IBAction)capture:(UIButton *)sender {
	[self.photoOutput capturePhotoWithSettings:[AVCapturePhotoSettings photoSettings] delegate:self];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
	UIImage *image = photo.image;
//	image = [image drawImage:Nil];
	[image detectRectanglesWithOptions:Nil completionHandler:^(NSArray<VNRectangleObservation *> *results) {
		UIImage *temp = [image imageWithRectangle:results.firstObject];

		[LIB createAssetWithImage:temp];
	}];

	[error log:@"didFinishProcessingPhoto:"];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
//	Doherty Threshold 0.4
//	HPM Eye movement time 0.2
	if (self.date && [self.date timeIntervalSinceNow] > -0.2)
		return;

	CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

	self.date = [self.handler performRequests:@[ self.request ] onCVPixelBuffer:pixelBuffer] ? [NSDate date] : Nil;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

@end

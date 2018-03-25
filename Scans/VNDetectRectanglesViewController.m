//
//  AVCaptureViewController.m
//  Scans
//
//  Created by Alexander Ivanov on 16.03.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "VNDetectRectanglesViewController.h"

@implementation AVCaptureSession (Convenience)

+ (instancetype)sessionWithPreset:(AVCaptureSessionPreset)sessionPreset {
	AVCaptureSession *session = [[AVCaptureSession alloc] init];
	if (!sessionPreset)
		return session;

	if ([session canSetSessionPreset:sessionPreset])
		session.sessionPreset = sessionPreset;
	else
		return Nil;

	return session;
}

@end

@implementation AVCaptureDeviceInput (Convenience)

+ (instancetype)deviceInputWithDevice:(AVCaptureDevice *)device {
	if (!device)
		return Nil;

	NSError *error = Nil;
	AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
	[error log:@"deviceInputWithDevice:"];

	return input;
}

+ (instancetype)deviceInputWithMediaType:(AVMediaType)mediaType {
	return mediaType ? [self deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:mediaType]] : Nil;
}

+ (instancetype)deviceInputWithUniqueID:(NSString *)deviceUniqueID {
	return deviceUniqueID ? [self deviceInputWithDevice:[AVCaptureDevice deviceWithUniqueID:deviceUniqueID]] : Nil;
}

+ (instancetype)deviceInputWithDeviceType:(AVCaptureDeviceType)deviceType mediaType:(AVMediaType)mediaType position:(AVCaptureDevicePosition)position {
	return deviceType ? [self deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithDeviceType:deviceType mediaType:mediaType position:position]] : Nil;
}

@end

@implementation AVCaptureVideoDataOutput (Convenience)

+ (instancetype)videoDataOutputWithSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)sampleBufferDelegate queue:(dispatch_queue_t)sampleBufferCallbackQueue {
	AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
	[output setSampleBufferDelegate:sampleBufferDelegate queue:sampleBufferCallbackQueue];
	return output;
}

@end

@implementation UIButton (Convenience)

+ (instancetype)buttonWithFrame:(CGRect)frame title:(NSString *)title target:(id)target action:(SEL)action {
	UIButton *button = [[UIButton alloc] initWithFrame:frame];
	[button setTitle:title forState:UIControlStateNormal];
	[button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
	button.layer.borderColor = button.currentTitleColor.CGColor;
	button.layer.borderWidth = 2.0;
	button.layer.cornerRadius = 22.0;
	return button;
}

@end

@interface AVCapturePhotoViewController () <AVCapturePhotoCaptureDelegate>
@property (strong, nonatomic, readonly) UIButton *doneButton;
@property (strong, nonatomic, readonly) UIButton *cancelButton;

@property (strong, nonatomic, readonly) AVCaptureSession *session;
@property (strong, nonatomic, readonly) AVCaptureDeviceInput *deviceInput;
@property (strong, nonatomic, readonly) AVCapturePhotoOutput *photoOutput;

@property (strong, nonatomic, readonly) AVCaptureVideoPreviewLayer *previewLayer;
@end

@implementation AVCapturePhotoViewController

__synthesize(UIButton *, doneButton, [UIButton buttonWithFrame:CGRectMake(20.0, self.view.bounds.size.height - 44.0 - 30.0, 88.0, 44.0) title:@"Done" target:self action:@selector(done:)])

- (IBAction)done:(UIButton *)sender {
	[self.photoOutput capturePhotoWithSettings:[AVCapturePhotoSettings photoSettings] delegate:self];
}

__synthesize(UIButton *, cancelButton, [UIButton buttonWithFrame:CGRectMake(self.view.bounds.size.width - 88.0 - 20.0, self.view.bounds.size.height - 44.0 - 30.0, 88.0, 44.0) title:@"Cancel" target:self action:@selector(cancel:)])

- (IBAction)cancel:(UIButton *)sender {
	[self dismissViewControllerAnimated:YES completion:Nil];
}


__synthesize(AVCaptureSession *, session, [AVCaptureSession sessionWithPreset:AVCaptureSessionPresetPhoto])
__synthesize(AVCaptureDeviceInput *, deviceInput, [AVCaptureDeviceInput deviceInputWithMediaType:AVMediaTypeVideo])
__synthesize(AVCapturePhotoOutput *, photoOutput, [[AVCapturePhotoOutput alloc] init])

__synthesize(AVCaptureVideoPreviewLayer *, previewLayer, ({
	AVCaptureVideoPreviewLayer *layer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
	layer.frame = self.view.bounds;
	layer;
}))

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

	[self.view addSubview:self.doneButton];
	[self.view addSubview:self.cancelButton];

	[self.session addInput:self.deviceInput];
	[self.session addOutput:self.photoOutput];
	[self.session startRunning];

	[self.view.layer addSublayer:self.previewLayer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

	[self.session stopRunning];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
	if (self.capturePhotoHandler)
		self.capturePhotoHandler(photo);

	[self dismissViewControllerAnimated:YES completion:Nil];

	[error log:@"didFinishProcessingPhoto:"];
}

@end

#warning Rectangle
#warning Focus
#warning Flash

#define CGPointRotate(point) CGPointMake(point.y, point.x)

@interface VNDetectRectanglesViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (strong, nonatomic, readonly) AVCaptureVideoDataOutput *videoDataOutput;

@property (strong, nonatomic) VNSequenceRequestHandler *handler;
@property (strong, nonatomic) VNDetectRectanglesRequest *request;

@property (strong, nonatomic) CAShapeLayer *shapeLayer;

@property (assign, nonatomic) BOOL detecting;
@end

@implementation VNDetectRectanglesViewController

__synthesize(AVCaptureVideoDataOutput *, videoDataOutput, [AVCaptureVideoDataOutput videoDataOutputWithSampleBufferDelegate:self queue:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)])

__synthesize(VNSequenceRequestHandler *, handler, [[VNSequenceRequestHandler alloc] init])

__synthesize(VNDetectRectanglesRequest *, request, ({
	__weak VNDetectRectanglesViewController *__self = self;
	[VNDetectRectanglesRequest requestWithCompletionHandler:^(NSArray *results) {
		VNRectangleObservation *rect = results.firstObject;

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
			self.shapeLayer.path = path;
		}];

		__self.detecting = NO;

		[rect log:@"requestWithCompletionHandler:"];
	}];
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

	[self.session addOutput:self.videoDataOutput];

	[self.view.layer addSublayer:self.shapeLayer];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];

	self.handler = Nil;
	self.request = Nil;
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
//	if (self.detecting)
//		return;

	CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

	self.detecting = [self.handler performRequests:@[ self.request ] onCVPixelBuffer:pixelBuffer];
}

@end

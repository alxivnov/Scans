//
//  UIImageViewController.m
//  Scans
//
//  Created by Alexander Ivanov on 23.11.2017.
//  Copyright © 2017 Alexander Ivanov. All rights reserved.
//

#import "ImageController.h"

#import "CoreImage+Convenience.h"
#import "Dispatch+Convenience.h"
#import "NSObject+Convenience.h"
#import "UICenteredScrollView.h"
#import "UIImage+Convenience.h"

#warning Center!
#warning Fill!
#warning Load indicator!

@interface ImageController () <UIScrollViewDelegate>
@property (strong, nonatomic, readonly) UIScrollView *scrollView;

@property (strong, nonatomic) NSArray<CIFeature *> *textFeatures;
@end

@implementation ImageController

__synthesize(UIScrollView *, scrollView, cls(UIScrollView, self.view))

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

	self.scrollView.delegate = self;

	self.scrollView.bouncesZoom = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	[segue.destinationViewController forwardSelector:@selector(setImage:) withObject:self.image nextTarget:Nil];
	[segue.destinationViewController forwardSelector:@selector(setTextFeatures:) withObject:self.textFeatures nextTarget:Nil];
}

- (void)setImage:(UIImage *)image {
	_image = image;

	[[self.view viewWithTag:UICenteredScrollViewTag] removeFromSuperview];

	if (!image)
		return;

	UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
	imageView.tag = UICenteredScrollViewTag;

	[self.scrollView addSubview:imageView];

	self.scrollView.contentSize = imageView.image.size;
	self.scrollView.maximumZoomScale = 2.0;
	self.scrollView.minimumZoomScale = fmin(fmin(self.scrollView.bounds.size.width / self.scrollView.contentSize.width, self.scrollView.bounds.size.height / self.scrollView.contentSize.height), 1.0);
	self.scrollView.zoomScale = self.scrollView.minimumZoomScale;

//	imageView.center = self.scrollView.center;

	[GCD global:^{
		NSDate *date = [NSDate date];
		self.textFeatures = [[self.image filterWithName:@"CIColorMonochrome"] featuresOfType:CIDetectorTypeText options:@{ CIDetectorMinFeatureSize : @0.0, CIDetectorAccuracy : CIDetectorAccuracyLow }];
		NSLog(@"sec: %f", [[NSDate date] timeIntervalSinceDate:date]);

		[GCD main:^{
			UIImage *image = [UIImage imageWithSize:imageView.image.size draw:^(CGContextRef context) {
				[imageView.image drawAtPoint:CGPointZero];

				CGContextSetStrokeColorWithColor(context, self.view.tintColor.CGColor);
				CGContextSetLineWidth(context, 4.0);

				for (CIFeature *feature in self.textFeatures)
					CGContextStrokeRect(context, [self.image boundsForFeature:feature]);
			}];
			imageView.image = image;

			self.toolbarItems[1].enabled = self.textFeatures.count;
			self.toolbarItems[1].title = [NSString stringWithFormat:@"Features: %lu", self.textFeatures.count];
		}];
	}];

	/*
	 [self.manager requestImageForAsset:self.assets[indexPath.row] targetSize:self.screenSize contentMode:PHImageContentModeAspectFill options:[PHImageRequestOptions optionsWithNetworkAccessAllowed:YES synchronous:NO progressHandler:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
	 [GCD main:^{
	 segue.destinationViewController.navigationController.navigationBar.progress = progress;
	 }];
	 }] resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
	 [GCD main:^{
	 segue.destinationViewController.navigationItem.title = [info[@"PHImageFileURLKey"] lastPathComponent];
	 }];
	 }];
	 */
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return [self.view viewWithTag:UICenteredScrollViewTag];
}

@end

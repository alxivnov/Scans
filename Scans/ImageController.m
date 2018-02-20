//
//  UIImageViewController.m
//  Scans
//
//  Created by Alexander Ivanov on 23.11.2017.
//  Copyright © 2017 Alexander Ivanov. All rights reserved.
//

#import "ImageController.h"

#import "Global.h"

#import "CoreImage+Convenience.h"
#import "Dispatch+Convenience.h"
#import "UICenteredScrollView.h"
#import "UIImage+Convenience.h"
#import "UINavigationController+Convenience.h"

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

- (void)setImage:(PHAsset *)image {
	_image = image;

	PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
	options.networkAccessAllowed = YES;
	options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
		[GCD main:^{
			[self.navigationController.navigationBar setProgress:progress animated:YES];
		}];

		[error log:@"progressHandler:"];
	};
	[GLOBAL.manager requestImageForAsset:self.image targetSize:GLOBAL.screenSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
		[GCD main:^{
			[[self.view viewWithTag:UICenteredScrollViewTag] removeFromSuperview];

			if (!result)
				return;

			UIImageView *imageView = [[UIImageView alloc] initWithImage:result];
			imageView.tag = UICenteredScrollViewTag;

			CGFloat scale = fmin(self.scrollView.bounds.size.width / result.size.width, self.scrollView.bounds.size.height / result.size.height);

			if ([info[PHImageResultIsDegradedKey] boolValue])
				imageView.frame = CGRectMake(0.0, 0.0, result.size.width * scale, result.size.height * scale);
			else
				[GCD global:^{
					self.textFeatures = [[result filterWithName:@"CIColorMonochrome"] featuresOfType:CIDetectorTypeText options:@{ CIDetectorMinFeatureSize : @0.0, CIDetectorAccuracy : CIDetectorAccuracyLow }];
//					NSLog(@"sec: %f", [[NSDate date] timeIntervalSinceDate:date]);

					[GCD main:^{
						UIImage *image = [UIImage imageWithSize:imageView.image.size draw:^(CGContextRef context) {
							[imageView.image drawAtPoint:CGPointZero];

							CGContextSetStrokeColorWithColor(context, self.view.tintColor.CGColor);
							CGContextSetLineWidth(context, 4.0);

							for (CIFeature *feature in self.textFeatures)
								CGContextStrokeRect(context, [result boundsForFeature:feature]);
						}];
						imageView.image = image;

						self.toolbarItems[1].enabled = self.textFeatures.count;
						self.toolbarItems[1].title = [NSString stringWithFormat:@"Features: %lu", self.textFeatures.count];
					}];
				}];

			[self.scrollView addSubview:imageView];

			self.scrollView.contentSize = imageView.image.size;
			self.scrollView.maximumZoomScale = 2.0;
			self.scrollView.minimumZoomScale = fmin(scale, 1.0);
			self.scrollView.zoomScale = self.scrollView.minimumZoomScale;

//			imageView.center = self.scrollView.center;
		}];
	}];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return [self.view viewWithTag:UICenteredScrollViewTag];
}

@end

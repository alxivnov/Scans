//
//  UIImageController.m
//  Scans
//
//  Created by Alexander Ivanov on 22.02.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "UIImageController.h"

#import "CoreGraphics+Convenience.h"
#import "UIGestureRecognizer+Convenience.h"

@interface UIImageController () <UIScrollViewDelegate>

@end

@implementation UIImageController

__synthesize(UIScrollView *, scrollView, cls(UIScrollView, self.view))

__synthesize(UIView *, contentView, ({
	UIView *contentView = [[UIView alloc] initWithFrame:CGRectZero];
	contentView.tag = UICenteredScrollViewTag;

	[self.scrollView addSubview:contentView];

	contentView;
}))

__synthesize(UIImageView *, imageView, ({
	UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
	imageView.clipsToBounds = YES;
	imageView.contentMode = UIViewContentModeScaleAspectFill;

	[self.contentView addSubview:imageView];

	imageView;
}))

- (UIImage *)image {
	return self.imageView.image;
}

- (void)setImage:(UIImage *)image {
	self.imageView.image = image;

	if (self.imageView.frame.size.width == 0.0 || self.imageView.frame.size.height == 0.0) {
		self.contentView.frame = self.imageView.frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);

		self.scrollView.contentSize = image.size;
		self.scrollView.maximumZoomScale = fmax(1.0, self.scrollView.fillZoom);
		self.scrollView.minimumZoomScale = self.scrollView.fitZoom;
		self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
		
		[self.scrollView.panGestureRecognizer addTarget:self action:@selector(panAction:)];
		[self.scrollView.pinchGestureRecognizer addTarget:self action:@selector(pinchAction:)];
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

	self.scrollView.alwaysBounceVertical = YES;
	self.scrollView.bouncesZoom = YES;

	self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

	self.scrollView.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return [self.view viewWithTag:UICenteredScrollViewTag];
}

- (IBAction)panAction:(UIPanGestureRecognizer *)sender {
	if (sender.state != UIGestureRecognizerStateEnded)
		return;

	CGPoint translation = [sender translationInView:sender.view];
	if (fabs(translation.x) >= translation.y)
		return;

	if (self.navigationController.viewControllers.count > 1)
		[self.navigationController popViewControllerAnimated:YES];
	else
		[self.presentingViewController dismissViewControllerAnimated:YES completion:Nil];
}

- (IBAction)pinchAction:(UIPinchGestureRecognizer *)sender {
	if (sender.state != UIGestureRecognizerStateEnded)
		return;

	if (sender.scale > 1.0)
		return;

	if (self.navigationController.viewControllers.count > 1)
		[self.navigationController popViewControllerAnimated:YES];
	else
		[self.presentingViewController dismissViewControllerAnimated:YES completion:Nil];
}

- (IBAction)shareAction:(UIBarButtonItem *)sender {
	[self presentActivityWithActivityItems:@[ self.image ]];
}

@end

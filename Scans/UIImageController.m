//
//  UIImageController.m
//  Scans
//
//  Created by Alexander Ivanov on 22.02.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "UIImageController.h"

#import "UIGestureRecognizer+Convenience.h"

@interface UIImageController () <UIScrollViewDelegate>

@end

@implementation UIImageController

__synthesize(UIScrollView *, scrollView, cls(UIScrollView, self.view))

- (UIImageView *)imageView {
	return cls(UIImageView, [self.view viewWithTag:UICenteredScrollViewTag]);
}

- (UIImage *)image {
	return self.imageView.image;
}

- (void)setImage:(UIImage *)image {
	if (self.imageView) {
		self.imageView.image = image;
	} else if (image) {
		UIImageView *imageView = [[UIImageView alloc] initWithImage:image];

		imageView.tag = UICenteredScrollViewTag;

		[self.scrollView addSubview:imageView];

		self.scrollView.contentSize = imageView.image.size;
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

#warning Fix Zooming of observations!
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return [self.view viewWithTag:UICenteredScrollViewTag];
}

- (IBAction)panAction:(UIPanGestureRecognizer *)sender {
	if (sender.state != UIGestureRecognizerStateEnded)
		return;

	CGPoint translation = [sender translationInView:sender.view];
	if (fabs(translation.x) >= translation.y)
		return;

	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)pinchAction:(UIPinchGestureRecognizer *)sender {
	if (sender.state != UIGestureRecognizerStateEnded)
		return;

	if (sender.scale > 1.0)
		return;

	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)shareAction:(UIBarButtonItem *)sender {
	[self presentActivityWithActivityItems:@[ self.image ]];
}

@end

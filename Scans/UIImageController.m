//
//  UIImageController.m
//  Scans
//
//  Created by Alexander Ivanov on 22.02.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "UIImageController.h"

@interface UIImageController () <UIScrollViewDelegate>
@property (strong, nonatomic, readonly) UIScrollView *scrollView;

@property (strong, nonatomic) UIImageView *imageView;
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
		self.scrollView.maximumZoomScale = fmax(fmax(self.scrollView.bounds.size.width / self.imageView.image.size.width, self.scrollView.bounds.size.height / self.imageView.image.size.height), 2.0);
		self.scrollView.minimumZoomScale = fmin(fmin(self.scrollView.bounds.size.width / self.imageView.image.size.width, self.scrollView.bounds.size.height / self.imageView.image.size.height), 1.0);
		self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
	}
}

- (void)fill {
	self.scrollView.zoomScale = fmax(self.scrollView.bounds.size.width / self.imageView.image.size.width, self.scrollView.bounds.size.height / self.imageView.image.size.height);
}

- (void)fit {
	self.scrollView.zoomScale = fmin(self.scrollView.bounds.size.width / self.imageView.image.size.width, self.scrollView.bounds.size.height / self.imageView.image.size.height);
}

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

@end
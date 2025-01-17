//
//  UIImagePagingController.m
//  Scans
//
//  Created by Alexander Ivanov on 27.02.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "VNTextPagingController.h"

#import "NSArray+Convenience.h"
#import "NSObject+Convenience.h"
#import "UIViewController+Convenience.h"
#import "CoreGraphics+Convenience.h"
#import "Vision+Convenience.h"

#import "UIImageController.h"

@interface VNTextPagingController ()

@end

@implementation VNTextPagingController

- (UIViewController *)viewControllerForIndex:(NSUInteger)index {
	Observation *observation = idx(self.observations, index);
	if (!observation)
		return Nil;

	UIImageController *vc = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"UIImageController"];
	vc.image = [self.image imageWithObservation:observation.observation];
	vc.view.tag = index;

	Label *label = cls(Label, observation);
	vc.navigationItem.title = label.text ?: @"";

	return vc;
}

- (NSUInteger)indexForViewController:(UIViewController *)viewController {
	UIImageController *vc = cls(UIImageController, viewController);
	if (!vc.image)
		return NSNotFound;

	return vc.view.tag;
}

- (NSUInteger)numberOfPages {
	return self.observations.count;
}

- (NSUInteger)currentPage {
	return self.viewControllers.count > 0 ? super.currentPage : self.indexPath.item;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

- (UIView *)transitionViewForView:(UIView *)view {
	UIImageController *vc = self.viewControllers.firstObject;
	UIImageView *imageView = vc.imageView;
	if (view == Nil)
		imageView.tag = self.currentPage;
	return imageView;
}

- (CGRect)transitionFrameForView:(UIView *)view {
	UIImageView *imageView = cls(UIImageView, view);
	if (!imageView)
		return CGRectNull;

	CGSize size = imageView.image.size;
	size = CGSizeAspectFit(size, self.view.bounds.size);
	CGRect rect = CGRectMakeWithSize(size);
	rect = CGRectCenterInSize(rect, self.view.bounds.size);
	return rect;
}

@end

//
//  PHAssetPagingController.m
//  Scans
//
//  Created by Alexander Ivanov on 27.02.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "PHAssetPagingController.h"

#import "CollectionTransition.h"

#import "PHAssetController.h"

@interface PHAssetPagingController () <CollectionTransitionDelegate>

@end

@implementation PHAssetPagingController

- (UIViewController *)viewControllerForIndex:(NSUInteger)index {
	PHAsset *asset = idx(self.fetch, index);
	if (!asset)
		return Nil;

	PHAssetController *vc = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"PHAssetController"];
	vc.album = self.album;
	vc.asset = asset;
	vc.view.tag = index;
	return vc;
}

- (NSUInteger)indexForViewController:(UIViewController *)viewController {
	PHAssetController *vc = cls(PHAssetController, viewController);
	if (!vc.asset)
		return NSNotFound;

	return vc.view.tag;
}

- (NSUInteger)numberOfPages {
	return self.fetch.count;
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

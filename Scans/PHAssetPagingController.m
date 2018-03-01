//
//  PHAssetPagingController.m
//  Scans
//
//  Created by Alexander Ivanov on 27.02.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "PHAssetPagingController.h"

#import "PHAssetController.h"

@interface PHAssetPagingController ()

@end

@implementation PHAssetPagingController

- (UIViewController *)viewControllerForIndex:(NSUInteger)index {
	PHAsset *asset = idx(self.assets, index);
	if (!asset)
		return Nil;

	PHAssetController *vc = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"PHAssetController"];
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

- (NSUInteger)initialIndex {
	return self.indexPath.item;
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

@end
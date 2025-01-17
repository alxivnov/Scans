//
//  NavigationController.m
//  Scans
//
//  Created by Alexander Ivanov on 24.02.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "NavigationController.h"

#import "CollectionTransition.h"

#import "UIGestureRecognizer+Convenience.h"
#import "UIViewController+Convenience.h"

@interface NavigationController () <UINavigationControllerDelegate>
@property (assign, nonatomic) BOOL statusBarHidden;

//@property (strong, nonatomic, readonly) UIPanTransition *modalTransition;

@property (strong, nonatomic, readonly) CollectionTransition *collectionTransition;
@end

@implementation NavigationController

//__synthesize(UIPanTransition *, modalTransition, [UIPanTransition gestureTransition:Nil])
__synthesize(CollectionTransition *, collectionTransition, [CollectionTransition gestureTransition:Nil])

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

	self.delegate = self;

//	[self.barHideOnTapGestureRecognizer addTarget:self action:@selector(hideBarsTap:)];
/*
	if (self.modalPresentationStyle == UIModalPresentationFullScreen) {
		self.containingViewController.transitioningDelegate = self.modalTransition;

		[self.navigationBar addPanWithTarget:self];

		[cls(UIScrollView, self.lastViewController.view).panGestureRecognizer addTarget:self action:@selector(panAction:)];

		self.delegate = self;
	}
*/
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
/*
- (void)panAction:(UIPanGestureRecognizer *)sender {
	if (sender.state == UIGestureRecognizerStateBegan && 0.0 - cls(UIScrollView, sender.view).contentOffset.y >= cls(UIScrollView, sender.view).contentInset.top) {
		__block id <UIViewControllerTransitioningDelegate> transition = self.containingViewController.transitioningDelegate = [UIPanTransition gestureTransition:sender];

		[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
			transition = self.containingViewController.transitioningDelegate = Nil;
		}];
	}
}
*/
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
/*
- (IBAction)hideBarsTap:(UITapGestureRecognizer *)sender {
	[self setNeedsStatusBarAppearanceUpdate];
}

- (BOOL)prefersStatusBarHidden {
	return self.navigationBarHidden;
}
*/
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
	BOOL isPage = [viewController isKindOfClass:[UIPageViewController class]];

	[navigationController setNavigationBarHidden:isPage animated:animated];

	[navigationController setToolbarHidden:isPage || viewController.toolbarItems.count == 0 animated:animated];
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
	BOOL isPage = [viewController isKindOfClass:[UIPageViewController class]];

	navigationController.hidesBarsOnTap = isPage;
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
//	return Nil;
	return (operation == UINavigationControllerOperationPush && [toVC isKindOfClass:[UIPageViewController class]]) || (operation == UINavigationControllerOperationPop && [fromVC isKindOfClass:[UIPageViewController class]]) ? self.collectionTransition : Nil;
}

@end

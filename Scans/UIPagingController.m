//
//  UIPagingController.m
//  Scans
//
//  Created by Alexander Ivanov on 27.02.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "UIPagingController.h"

@interface UIPagingController ()

@end

@implementation UIPagingController

- (UIViewController *)viewControllerForIndex:(NSUInteger)index {
	return Nil;
}

- (NSUInteger)indexForViewController:(UIViewController *)viewController {
	return NSNotFound;
}

- (NSUInteger)initialIndex {
	return 0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

	self.dataSource = self;
	self.delegate = self;

	[self setViewControllers:@[ [self viewControllerForIndex:[self initialIndex]] ] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:Nil];
	[self pageViewController:self didFinishAnimating:YES previousViewControllers:@[ ] transitionCompleted:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
	NSUInteger index = [self indexForViewController:viewController];

	return [self viewControllerForIndex:index + 1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
	NSUInteger index = [self indexForViewController:viewController];

	return [self viewControllerForIndex:index - 1];
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
	if (!completed)
		return;

	self.navigationItem.title = self.viewControllers.firstObject.navigationItem.title;
	self.navigationItem.rightBarButtonItems = self.viewControllers.firstObject.navigationItem.rightBarButtonItems;
	self.toolbarItems = self.viewControllers.firstObject.toolbarItems;
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

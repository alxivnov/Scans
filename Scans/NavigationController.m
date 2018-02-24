//
//  NavigationController.m
//  Scans
//
//  Created by Alexander Ivanov on 24.02.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "NavigationController.h"

#import "UIGestureRecognizer+Convenience.h"
#import "UIGestureTransition.h"
#import "UIViewController+Convenience.h"

@interface NavigationController ()
@property (strong, nonatomic, readonly) UIPanTransition *transition;
@end

@implementation NavigationController

__synthesize(UIPanTransition *, transition, [UIPanTransition gestureTransition:Nil])

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

	self.delegate = self;

	if (self.modalPresentationStyle == UIModalPresentationFullScreen) {
		self.containingViewController.transitioningDelegate = self.transition;

		[self.navigationBar addPanWithTarget:self];

		[cls(UIScrollView, self.lastViewController.view).panGestureRecognizer addTarget:self action:@selector(pan:)];

		self.delegate = self;
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)pan:(UIPanGestureRecognizer *)sender {
	if (sender.state == UIGestureRecognizerStateBegan && 0.0 - cls(UIScrollView, sender.view).contentOffset.y >= cls(UIScrollView, sender.view).contentInset.top) {
		__block id <UIViewControllerTransitioningDelegate> transition = self.containingViewController.transitioningDelegate = [UIPanTransition gestureTransition:sender];

		[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
			transition = self.containingViewController.transitioningDelegate = Nil;
		}];
	}
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
	navigationController.toolbarHidden = viewController.toolbarItems.count == 0;
}

@end

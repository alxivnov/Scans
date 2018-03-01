//
//  UIPagingController.h
//  Scans
//
//  Created by Alexander Ivanov on 27.02.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIPagingController : UIPageViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

- (UIViewController *)viewControllerForIndex:(NSUInteger)index;

- (NSUInteger)indexForViewController:(UIViewController *)viewController;

- (NSUInteger)initialIndex;

@end

//
//  CollectionTransition.m
//  Scans
//
//  Created by Alexander Ivanov on 01.03.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "CollectionTransition.h"

@implementation CollectionTransition

- (void)updateInteractiveTransition:(CGFloat)percentComplete {
	self.fromView.alpha = 1.0 - percentComplete;
	self.toView.alpha = percentComplete;
}

- (CGFloat)interactiveTransitionPercentComplete:(UIGestureRecognizer *)gestureRecognizer {
	UIPanGestureRecognizer *sender = cls(UIPanGestureRecognizer, gestureRecognizer);

	CGPoint transition = [sender translationInView:gestureRecognizer.view];

	return transition.y / self.containerView.bounds.size.height;
}

- (CGFloat)interactiveTransitionPercentVelocity:(UIGestureRecognizer *)gestureRecognizer {
	UIPanGestureRecognizer *sender = cls(UIPanGestureRecognizer, gestureRecognizer);

	CGPoint velocity = [sender velocityInView:gestureRecognizer.view];

	return velocity.y / self.containerView.bounds.size.height;
}

@end

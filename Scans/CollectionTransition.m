//
//  CollectionTransition.m
//  Scans
//
//  Created by Alexander Ivanov on 01.03.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "CollectionTransition.h"

@interface CollectionTransition ()
@property (strong, nonatomic) UIView *scaleView;

@property (strong, nonatomic) UIView *from;
@property (strong, nonatomic) UIView *to;

@property (assign, nonatomic) CGRect fromFrame;
@property (assign, nonatomic) CGRect toFrame;
@end

@implementation CollectionTransition

- (void)startInteractiveTransition {
	[super startInteractiveTransition];

	BOOL unwind = self.fromViewController.presentingViewController == self.toViewController;

	UIView *fromView = [self.fromViewController forwardSelector:@selector(transitionViewForView:) withObject:Nil nextTarget:UIViewControllerNextTarget(YES)];
	UIViewController *fromVC = [self.fromViewController firstViewControllerRespondingToSelector:@selector(transitionFrameForView:) next:^UIViewController *(UIViewController *viewController) {
		return unwind ? viewController.nextViewController : viewController.prevViewController;
	}];
	if (fromVC)
		self.fromFrame = [(id<CollectionTransitionDelegate>)fromVC transitionFrameForView:Nil];
	if (CGRectIsEmpty(self.fromFrame) && fromView)
		self.fromFrame = [self.containerView convertRect:fromView.frame fromView:fromView.superview];

	UIView *toView = [self.toViewController forwardSelector:@selector(transitionViewForView:) withObject:fromView nextTarget:UIViewControllerNextTarget(YES)];
	UIViewController *toVC = [self.toViewController firstViewControllerRespondingToSelector:@selector(transitionFrameForView:) next:^UIViewController *(UIViewController *viewController) {
		return unwind ? viewController.prevViewController : viewController.nextViewController;
	}];
	if (toVC)
		self.toFrame = [(id<CollectionTransitionDelegate>)toVC transitionFrameForView:fromView];
	if (CGRectIsEmpty(self.toFrame) && toView)
		self.toFrame = [self.containerView convertRect:toView.frame fromView:toView.superview];

	self.scaleView = [fromView copy];
	self.scaleView.frame = self.fromFrame;
	[self.containerView addSubview:self.scaleView];

	fromView.hidden = YES;
	toView.hidden = YES;

	self.from = fromView;
	self.to = toView;
}

- (void)endInteractiveTransition:(BOOL)didComplete {
	[super endInteractiveTransition:didComplete];

	UIView *fromView = self.from ?: [self.fromViewController forwardSelector:@selector(transitionViewForView:) withObject:Nil nextTarget:UIViewControllerNextTarget(YES)];
	fromView.hidden = NO;

	UIView *toView = self.to ?: [self.toViewController forwardSelector:@selector(transitionViewForView:) withObject:fromView nextTarget:UIViewControllerNextTarget(YES)];
	toView.hidden = NO;

	[self.scaleView removeFromSuperview];
	self.scaleView = Nil;

	self.fromFrame = CGRectNull;
	self.toFrame = CGRectNull;
}

- (void)updateInteractiveTransition:(CGFloat)percentComplete {
	CGFloat percentIncomplete = 1.0 - percentComplete;

	self.fromView.alpha = percentIncomplete;
	self.toView.alpha = percentComplete;

	self.scaleView.frame = CGRectMake(self.toFrame.origin.x * percentComplete + self.fromFrame.origin.x * percentIncomplete, self.toFrame.origin.y * percentComplete + self.fromFrame.origin.y * percentIncomplete, self.toFrame.size.width * percentComplete + self.fromFrame.size.width * percentIncomplete, self.toFrame.size.height * percentComplete + self.fromFrame.size.height * percentIncomplete);
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

@implementation UIView (Copy)

- (id)copy {
	UIView *view = [[[self class] alloc] initWithFrame:self.frame];
	view.clipsToBounds = self.clipsToBounds;
	view.contentMode = self.contentMode;
	return view;
}

@end

@implementation UIImageView (Copy)

- (id)copy {
	UIImageView *copy = [super copy];
	copy.image = self.image;
	return copy;
}

@end

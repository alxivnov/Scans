//
//  CollectionTransition.h
//  Scans
//
//  Created by Alexander Ivanov on 01.03.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "UIGestureTransition.h"

#import "CoreGraphics+Convenience.h"

@protocol CollectionTransitionDelegate

- (UIView *)transitionViewForView:(UIView *)view;

@optional

- (CGRect)transitionFrameForView:(UIView *)view;

@end

@interface CollectionTransition : UIGestureTransition

@end

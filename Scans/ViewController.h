//
//  ViewController.h
//  Scans
//
//  Created by Alexander Ivanov on 23.11.2017.
//  Copyright © 2017 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Global.h"

#import "UIView+Convenience.h"

@interface ViewController : UICollectionViewController

@property (strong, nonatomic, readonly) UICollectionViewFlowLayout *flowLayout;
@property (assign, nonatomic, readonly) CGSize cellSize;

- (void)scrollToItem:(NSUInteger)item animated:(BOOL)animated;

@property (strong, nonatomic, readonly) PHAssetCollection *album;
@property (strong, nonatomic, readonly) PHFetchResult *fetch;

@end


//
//  CollectionController.h
//  Scans
//
//  Created by Alexander Ivanov on 23.07.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CollectionTransition.h"

#import "PhotoLibrary.h"

#import <Crashlytics/Crashlytics.h>

@interface CollectionController : UICollectionViewController

@property (strong, nonatomic, readonly) UICollectionViewFlowLayout *flowLayout;

@property (strong, nonatomic) NSIndexPath *indexPath;

- (PHAsset *)assetAtIndex:(NSUInteger)index;

@end

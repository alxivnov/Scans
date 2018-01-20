//
//  FeaturesController.h
//  Scans
//
//  Created by Alexander Ivanov on 23.11.2017.
//  Copyright © 2017 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FeaturesController : UICollectionViewController
@property (strong, nonatomic) UIImage *image;

@property (strong, nonatomic) NSArray<CITextFeature *> *textFeatures;
@end

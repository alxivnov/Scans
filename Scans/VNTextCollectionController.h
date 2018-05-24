//
//  FeaturesController.h
//  Scans
//
//  Created by Alexander Ivanov on 23.11.2017.
//  Copyright © 2017 Alexander Ivanov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Model+Convenience.h"

@interface VNTextCollectionController : UICollectionViewController

@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) NSArray<Observation *> *observations;

@end

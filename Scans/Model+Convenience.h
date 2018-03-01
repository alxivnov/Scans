//
//  Model+Convenience.h
//  Scans
//
//  Created by Alexander Ivanov on 01.03.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "Scans+CoreDataModel.h"
#import <Vision/Vision.h>

@interface Observation (VNTextObservation)

@property (strong, nonatomic) VNTextObservation *observation;

@end

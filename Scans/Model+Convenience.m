//
//  Model+Convenience.m
//  Scans
//
//  Created by Alexander Ivanov on 01.03.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "Model+Convenience.h"

@implementation Observation (VNTextObservation)

- (VNTextObservation *)observation {
	return [VNTextObservation observationWithBoundingBox:CGRectMake(self.x, self.y, self.width, self.height)];
}

- (void)setObservation:(VNDetectedObjectObservation *)observation {
	self.x = observation.boundingBox.origin.x;
	self.y = observation.boundingBox.origin.y;
	self.width = observation.boundingBox.size.width;
	self.height = observation.boundingBox.size.height;
}

@end

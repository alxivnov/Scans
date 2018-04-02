//
//  TextDetector.h
//  Scans
//
//  Created by Alexander Ivanov on 02.04.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PhotoLibrary.h"

@interface TextDetector : NSObject
- (void)startProcessing:(void(^)(PHAsset *asset))handler;
- (void)stopProcessing;

- (void)process:(NSTimeInterval)seconds handler:(void(^)(void))handler;

@property (assign, nonatomic, readonly) NSUInteger count;
@property (assign, nonatomic, readonly) NSUInteger index;

@property (assign, nonatomic, readonly) BOOL isProcessing;
@end

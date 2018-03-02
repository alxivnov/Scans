//
//  Global.h
//  Scans
//
//  Created by Alexander Ivanov on 20.02.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Model+Convenience.h"

#import "Affiliates+Convenience.h"
#import "Photos+Convenience.h"
#import "NSDictionary+Convenience.h"
#import "NSObject+Convenience.h"

#define GLOBAL [Global global]

@interface Global : NSObject

@property (strong, nonatomic, readonly) NSDictionary *affiliateInfo;

@property (strong, nonatomic, readonly) PHCachingImageManager *manager;

@property (strong, nonatomic, readonly) NSPersistentContainer *container;

@property (assign, nonatomic, readonly) CGSize screenSize;

+ (instancetype)global;

@end

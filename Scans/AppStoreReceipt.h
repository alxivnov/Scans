//
//  AppStoreReceipt.h
//  Scans
//
//  Created by Alexander Ivanov on 09.07.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppStoreReceipt : NSObject

@property (strong, nonatomic, readonly) NSDictionary *receipt;

- (NSDate *)expiresDate:(NSString *)productIdentifier;
- (BOOL)autoRenewStatus:(NSString *)productIdentifier;

- (BOOL)verifyReceipt:(BOOL)exclude handler:(void (^)(NSDictionary *receipt))handler;

+ (instancetype)instance;

@end

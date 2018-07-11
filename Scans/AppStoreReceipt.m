//
//  AppStoreReceipt.m
//  Scans
//
//  Created by Alexander Ivanov on 09.07.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "AppStoreReceipt.h"

#import "StoreKit+Convenience.h"
#import "NSURLSession+Convenience.h"

@interface AppStoreReceipt ()
@property (strong, nonatomic) NSDictionary *receipt;
@end

@implementation AppStoreReceipt

- (NSDictionary *)receipt {
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"receipt"];
}

- (void)setReceipt:(NSDictionary *)receipt {
	[[NSUserDefaults standardUserDefaults] setObject:receipt forKey:@"receipt"];
}

- (NSDate *)expiresDate:(NSString *)productIdentifier {
	NSDictionary *receipt = productIdentifier ? ([[AppStoreReceipt instance].receipt[@"latest_receipt_info"] lastObject:^BOOL(NSDictionary *obj) {
		return [obj[@"product_id"] isEqualToString:productIdentifier];
	}] ?: [[AppStoreReceipt instance].receipt[@"receipt"][@"in_app"] lastObject:^BOOL(NSDictionary *obj) {
		return [obj[@"product_id"] isEqualToString:productIdentifier];
	}]) : ([[AppStoreReceipt instance].receipt[@"latest_receipt_info"] lastObject] ?: [[AppStoreReceipt instance].receipt[@"receipt"][@"in_app"] lastObject]);

	return receipt ? [NSDate dateWithTimeIntervalSince1970:[receipt[@"expires_date_ms"] integerValue] / 1000.0] : Nil;
}

- (BOOL)autoRenewStatus:(NSString *)productIdentifier {
	NSDictionary *receipt = [[AppStoreReceipt instance].receipt[@"pending_renewal_info"] lastObject:^BOOL(NSDictionary *obj) {
		return [obj[@"auto_renew_product_id"] isEqualToString:productIdentifier];
	}];

	return [receipt[@"auto_renew_status"] boolValue];
}

- (BOOL)verifyReceipt:(BOOL)exclude handler:(void (^)(NSDictionary *))handler {
	NSData *data = [NSBundle mainBundle].appStoreReceipt;
	NSString *receipt = [data base64EncodedStringWithOptions:0];
	if (!receipt)
		return NO;

	NSDictionary *json = @{ @"receipt" : receipt, @"sandbox" : @(IS_DEBUGGING), @"exclude" : @(exclude) };
	NSURL *url = [NSURL URLWithString:@"https://apptag.me/scans/verifyReceipt.php"];
	[url sendRequestWithMethod:@"POST" header:Nil json:json completion:^(id json, NSURLResponse *response) {
		NSDictionary *dic = cls(NSDictionary, json);

		if (handler)
			handler([dic[@"status"] integerValue] ? Nil : dic);

		if (dic)
			self.receipt = dic;
	}];

	return YES;
}

__static(AppStoreReceipt *, instance, [[self alloc] init])

@end

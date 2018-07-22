//
//  SubscriptionsController.m
//  Scans
//
//  Created by Alexander Ivanov on 22.07.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "SubscriptionsController.h"

#import "Answers+Convenience.h"
#import "NSFormatter+Convenience.h"
#import "SafariServices+Convenience.h"
#import "StoreKit+Convenience.h"
#import "UIButton+Convenience.h"

#import "AppStoreReceipt.h"

#define IAP_BACKGROUND_MONTHLY @"com.alexivanov.scans.background.monthly"
#define IAP_BACKGROUND_YEARLY @"com.alexivanov.scans.background.yearly"

@interface SubscriptionsController () <SKProductsRequestDelegate>
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *monthButton;
@property (weak, nonatomic) IBOutlet UIButton *yearButton;
@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
@property (weak, nonatomic) IBOutlet UILabel *yearLabel;

@property (strong, nonatomic, readonly) NSArray *productIdentifiers;
@property (strong, nonatomic) SKProductsRequest *productsRequest;

@property (strong, nonatomic) NSDictionary<NSString *, NSDictionary *> *iaps;
@end

@implementation SubscriptionsController

__synthesize(NSArray *, productIdentifiers, (@[ IAP_BACKGROUND_MONTHLY, IAP_BACKGROUND_YEARLY ]))

- (NSDictionary<NSString *, NSDictionary *> *)iaps {
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"iaps"];
}

- (void)setIaps:(NSDictionary<NSString *, NSDictionary *> *)iaps {
	[[NSUserDefaults standardUserDefaults] setObject:iaps forKey:@"iaps"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

	self.monthButton.titleLabel.numberOfLines = 0;
	self.yearButton.titleLabel.numberOfLines = 0;
	self.monthButton.titleLabel.textAlignment = NSTextAlignmentCenter;
	self.yearButton.titleLabel.textAlignment = NSTextAlignmentCenter;
	[self.monthButton layoutVertically:-8.0];
	[self.yearButton layoutVertically:-8.0];

	[self reloadIaps];
	
	self.productsRequest = [SKProductsRequest startRequestWithProductIdentifiers:self.productIdentifiers delegate:self];

	[[AppStoreReceipt instance] verifyReceipt:NO handler:^(NSDictionary *receipt) {
		[GCD main:^{
			[self reloadIaps];
		}];
	}];
}

- (void)reloadIap:(NSString *)productIdentifier {
	NSDictionary *iap = self.iaps[productIdentifier];

	NSDate *expiresDate = [[AppStoreReceipt instance] expiresDate:productIdentifier];
	BOOL autoRenewStatus = [[AppStoreReceipt instance] autoRenewStatus:productIdentifier];

	SKPaymentTransaction *transaction = [[SKPaymentQueue defaultQueue].transactions lastObject:^BOOL(SKPaymentTransaction *obj) {
		return [obj.payment.productIdentifier isEqualToString:productIdentifier];
	}];
	SKPaymentTransactionState transactionState = transaction ? transaction.transactionState : NSNotFound;

	UIButton *button = [productIdentifier isEqualToString:IAP_BACKGROUND_MONTHLY] ? self.monthButton : [productIdentifier isEqualToString:IAP_BACKGROUND_YEARLY] ? self.yearButton : Nil;
	[button setTitle:[NSString stringWithFormat:@"%@\n%@", iap[@"localizedTitle"], iap[@"localizedPrice"]]];
	[button layoutVertically:-8.0];

	UILabel *label = [productIdentifier isEqualToString:IAP_BACKGROUND_MONTHLY] ? self.monthLabel : [productIdentifier isEqualToString:IAP_BACKGROUND_YEARLY] ? self.yearLabel : Nil;
	label.text = transactionState == SKPaymentTransactionStatePurchasing ? @"Purchasing..." : transactionState == SKPaymentTransactionStateDeferred ? @"Deferred" : expiresDate ? [NSString stringWithFormat:expiresDate.timeIntervalSinceNow > 0.0 ? (autoRenewStatus ? @"Renews on %@" : @"Expires on %@") : (autoRenewStatus ? @"Renewed on %@" : @"Expired on %@"), [expiresDate descriptionForDate:NSDateFormatterMediumStyle andTime:NSDateFormatterShortStyle]] : @"Subscription";

	BOOL active = transactionState == SKPaymentTransactionStatePurchasing || transactionState == SKPaymentTransactionStateDeferred || expiresDate.timeIntervalSinceNow > 0.0;
	button.enabled = !active;
	label.textColor = active ? [UIColor whiteColor] : [UIColor lightGrayColor];
}

- (void)reloadIaps {
	[self reloadIap:IAP_BACKGROUND_MONTHLY];
	[self reloadIap:IAP_BACKGROUND_YEARLY];

	self.descriptionLabel.text = self.iaps[IAP_BACKGROUND_MONTHLY][@"localizedDescription"] ?: self.iaps[IAP_BACKGROUND_YEARLY][@"localizedDescription"];
}

- (void)requestProduct:(NSString *)productIdentifier {
	NSDictionary *iap = self.iaps[productIdentifier];

	self.productsRequest = [SKProductsRequest startRequestWithProductIdentifier:iap[@"productIdentifier"] delegate:self];

	[Answers logAddToCartWithPrice:[iap[@"price"] decimalNumber] currency:iap[@"currencyCode"] itemName:iap[@"localizedTitle"] itemType:Nil itemId:iap[@"productIdentifier"] customAttributes:Nil];
}

- (IBAction)monthAction:(UIButton *)sender {
	[self requestProduct:IAP_BACKGROUND_MONTHLY];
}

- (IBAction)yearAction:(UIButton *)sender {
	[self requestProduct:IAP_BACKGROUND_YEARLY];
}

- (IBAction)restoreAction:(UIButton *)sender {
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (IBAction)termsOfUseAction:(UIButton *)sender {
#warning Terms!

	[self presentSafariWithURL:[NSURL URLWithString:@"https://apptag.me/scans/terms.txt"] entersReaderIfAvailable:YES];
}

- (IBAction)privacyPolicyAction:(UIButton *)sender {
	[self presentSafariWithURL:[NSURL URLWithString:@"https://apptag.me/scans/privacy.txt"] entersReaderIfAvailable:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
	self.productsRequest = Nil;

	NSUInteger count = response.products.count + response.invalidProductIdentifiers.count;
	if (count == 1) {
		SKProduct *product = response.products.firstObject;

		[[SKPaymentQueue defaultQueue] addPaymentWithProduct:product];

		[Answers logStartCheckoutWithPrice:product.price currency:product.currencyCode itemCount:Nil customAttributes:Nil];
	} else if (count == 2) {
		self.iaps = [response.products dictionaryWithKey:^id<NSCopying>(SKProduct *obj) {
			return obj.productIdentifier;
		} value:^id(SKProduct *obj, id<NSCopying> key, id val) {
			NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:6];
			dic[@"localizedTitle"] = obj.localizedTitle;
			dic[@"localizedPrice"] = obj.localizedPrice;
			dic[@"localizedDescription"] = obj.localizedDescription;
			dic[@"productIdentifier"] = obj.productIdentifier;
			dic[@"price"] = obj.price;
			dic[@"currencyCode"] = obj.currencyCode;
			return dic;
		}];

		[GCD main:^{
			[self reloadIaps];
		}];
	}
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
	self.productsRequest = Nil;

	[error log:@"request:didFailWithError:"];
}


- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
	for (SKPaymentTransaction *transaction in transactions)
		if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
			NSDictionary *iap = self.iaps[transaction.payment.productIdentifier];

			[Answers logPurchaseWithPrice:[iap[@"price"] decimalNumber] currency:iap[@"currencyCode"] success:@YES itemName:iap[@"localizedTitle"] itemType:Nil itemId:iap[@"productIdentifier"] customAttributes:Nil];
		}

	[GCD main:^{
		[self reloadIaps];
	}];
}

@end

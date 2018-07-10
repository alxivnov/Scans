//
//  AboutController.m
//  Scans
//
//  Created by Alexander Ivanov on 24.02.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "AboutController.h"

#import "Affiliates+Convenience.h"
#import "Answers+Convenience.h"
#import "MessageUI+Convenience.h"
#import "NSBundle+Convenience.h"
#import "NSFormatter+Convenience.h"
#import "NSObject+Convenience.h"
#import "NSURLSession+Convenience.h"
#import "QuartzCore+Convenience.h"
#import "StoreKit+Convenience.h"
#import "UIActivityViewController+Convenience.h"
#import "UIApplication+Convenience.h"
#import "UITableView+Convenience.h"
#import "UITableViewCell+Convenience.h"
#import "UIView+Convenience.h"

#import "AppStoreReceipt.h"

#define IAP_BACKGROUND_MONTHLY @"com.alexivanov.scans.background.monthly"
#define IAP_BACKGROUND_YEARLY @"com.alexivanov.scans.background.yearly"

#define APP_ID 1352799843
#define DEV_ID 734258593

#define IDX_IAPS 1
#define IDX_APPS 5

@interface AboutController () <SKProductsRequestDelegate>
@property (strong, nonatomic, readonly) NSDictionary *affiliateInfo;

@property (strong, nonatomic) NSArray<NSDictionary *> *apps;

@property (strong, nonatomic, readonly) NSArray *productIdentifiers;
@property (strong, nonatomic) SKProductsRequest *productsRequest;

@property (strong, nonatomic) NSDictionary<NSString *, NSDictionary *> *iaps;
@end

@implementation AboutController

__synthesize(NSDictionary *, affiliateInfo, [[NSDictionary dictionaryWithProvider:@"10603809" affiliate:@"1l3voBu"] dictionaryWithObject:@"write-review" forKey:@"action"])

- (NSArray<NSDictionary *> *)apps {
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"apps"];
}

- (void)setApps:(NSArray<NSDictionary *> *)apps {
	[[NSUserDefaults standardUserDefaults] setObject:apps forKey:@"apps"];
}

__synthesize(NSArray *, productIdentifiers, (@[ IAP_BACKGROUND_MONTHLY, IAP_BACKGROUND_YEARLY ]))

- (NSDictionary<NSString *, NSDictionary *> *)iaps {
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"iaps"];
}

- (void)setIaps:(NSDictionary<NSString *, NSDictionary *> *)iaps {
	[[NSUserDefaults standardUserDefaults] setObject:iaps forKey:@"iaps"];
}

- (IBAction)refreshAction:(UIRefreshControl *)sender {
	[AFMediaItem lookup:@{ KEY_ID : @(DEV_ID), KEY_MEDIA : kMediaSoftware, KEY_ENTITY : kEntitySoftware } handler:^(NSArray<AFMediaItem *> *results) {
		self.apps = [results map:^id(AFMediaItem *obj) {
			return [obj.wrapperType isEqualToString:kMediaSoftware] && obj.trackId.unsignedIntegerValue != APP_ID ? obj.dictionary : Nil;
		}];

		if (self.apps.count)
			[GCD main:^{
				if (self.tableView.numberOfSections > 4)
					[self.tableView reloadSection:4];
				else
					[self.tableView insertSection:4];

				[sender endRefreshing];
			}];
	}];

	self.productsRequest = [SKProductsRequest startRequestWithProductIdentifiers:self.productIdentifiers delegate:self];

	if (sender)
		[[AppStoreReceipt instance] verifyReceipt:NO handler:^(NSDictionary *receipt) {
			[GCD main:^{
				[self.tableView reloadSection:1];

				[sender endRefreshing];
			}];
		}];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

	[self addRefreshTarget:self action:@selector(refreshAction:)];

	[self refreshAction:Nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return IDX_APPS + (self.apps.count ? 1 : 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return section == IDX_APPS ? self.apps.count : section == IDX_IAPS ? (self.iaps.count + 1) : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:indexPath.section == IDX_IAPS && indexPath.row == self.iaps.count ? @"1*" : str(indexPath.section) forIndexPath:indexPath];
    
    // Configure the cell...
	if (indexPath.section == 0 && indexPath.row == 0) {
		cell.textLabel.text = [NSBundle bundleDisplayName];
		cell.detailTextLabel.text = [NSBundle bundleShortVersionString];
	} else if (indexPath.section == IDX_IAPS && indexPath.row < self.iaps.count) {
		NSString *productIdentifier = self.productIdentifiers[indexPath.row];
		NSDictionary *iap = self.iaps[productIdentifier];

		NSDate *expiresDate = [[AppStoreReceipt instance] expiresDate:productIdentifier];
		BOOL autoRenewStatus = [[AppStoreReceipt instance] autoRenewStatus:productIdentifier];

		SKPaymentTransaction *transaction = [[SKPaymentQueue defaultQueue].transactions lastObject:^BOOL(SKPaymentTransaction *obj) {
			return [obj.payment.productIdentifier isEqualToString:productIdentifier];
		}];
		SKPaymentTransactionState transactionState = transaction ? transaction.transactionState : NSNotFound;

		cell.textLabel.text = iap[@"localizedTitle"];
		cell.detailTextLabel.text = transactionState == SKPaymentTransactionStatePurchasing ? @"Purchasing..." : transactionState == SKPaymentTransactionStateDeferred ? @"Deferred" : expiresDate ? [NSString stringWithFormat:expiresDate.timeIntervalSinceNow > 0.0 ? (autoRenewStatus ? @"Renews on %@" : @"Expires on %@") : (autoRenewStatus ? @"Renewed on %@" : @"Expired on %@"), [expiresDate descriptionForDate:NSDateFormatterMediumStyle andTime:NSDateFormatterShortStyle]] : @"Subscription";
		cell.accessoryLabel.text = iap[@"localizedPrice"];
		[cell.accessoryLabel sizeToFit];

		cell.imageView.image = [UIImage image:[productIdentifier isEqualToString:IAP_BACKGROUND_MONTHLY] ? @"month-subscription" : [productIdentifier isEqualToString:IAP_BACKGROUND_YEARLY] ? @"year-subscription" : @"moneybox-fill"];
	} else if (indexPath.section == IDX_APPS && indexPath.row < self.apps.count) {
		NSDictionary *app = self.apps[indexPath.row];

		NSArray *titles = [app.trackName componentsSeparatedByString:@" - "];
		cell.textLabel.text = titles.count > 1 ? titles.firstObject : app.trackName;
		cell.detailTextLabel.text = titles.count > 1 ? titles.lastObject : app.genres.firstObject;

		NSUInteger tag = indexPath.section << 16 | indexPath.row;
		cell.imageView.tag = tag;
/*		NSURL *url = URL_CACHE(app.artworkUrl100);
		if (url.isExistingFile)
			cell.imageView.image = [[UIImage image:url] imageWithSize:CGSizeMake(30.0, 30.0) mode:UIImageScaleAspectFit];
		else
*/			[app.artworkUrl100 cache:^(NSURL *url) {
				[GCD main:^{
					UIImageView *imageView = [tableView cellForRowAtIndexPath:indexPath].imageView;
					if (imageView.tag == tag)
						imageView.image = [[UIImage image:url] imageWithSize:CGSizeMake(30.0, 30.0) mode:UIImageScaleAspectFit];
				}];
			}];
	}

	[cell.imageView.layer roundCorners:indexPath.section == IDX_APPS ? 6.0 : 0.0];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

	if (indexPath.section == 0 && indexPath.row == 0)
		cell.detailTextLabel.text = [cell.detailTextLabel.text isEqualToString:[NSBundle bundleVersion]] ? [NSBundle bundleShortVersionString] : [NSBundle bundleVersion];
	else if (indexPath.section == IDX_IAPS && indexPath.row < self.iaps.count) {
		NSDictionary *iap = self.iaps[self.productIdentifiers[indexPath.row]];

		self.productsRequest = [SKProductsRequest startRequestWithProductIdentifier:iap[@"productIdentifier"] delegate:self];

		[Answers logAddToCartWithPrice:[iap[@"price"] decimalNumber] currency:iap[@"currencyCode"] itemName:iap[@"localizedTitle"] itemType:Nil itemId:iap[@"productIdentifier"] customAttributes:Nil];
	} else if (indexPath.section == IDX_IAPS && indexPath.row == self.iaps.count)
		[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
	else if (indexPath.section == 2 && indexPath.row == 0)
		[self presentMailComposeWithRecipients:arr_(cell.detailTextLabel.text) subject:[NSBundle bundleDisplayNameAndShortVersion] body:Nil attachments:dic_(@"screenshot.jpg", [[self.presentingViewController.view snapshotImageAfterScreenUpdates:YES] jpegRepresentation]) completionHandler:Nil];
	else if (indexPath.section == 3 && indexPath.row == 0)
		[self presentWebActivityWithActivityItems:@[ [NSBundle bundleDisplayName], [NSURL URLForMobileAppWithIdentifier:APP_ID affiliateInfo:self.affiliateInfo] ] excludedTypes:Nil completionHandler:^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
			[Answers logInviteWithMethod:activityType customAttributes:@{ @"version" : [NSBundle bundleVersion], @"success" : completed ? @"YES" : @"NO", @"error" : [activityError debugDescription] ?: STR_EMPTY }];
		}];
	else if (indexPath.section == 4 && indexPath.row == 0)
		[UIApplication openURL:[NSURL URLForMobileAppWithIdentifier:APP_ID affiliateInfo:self.affiliateInfo] options:Nil completionHandler:^(BOOL success) {

		}];
	else if (indexPath.section == IDX_APPS && indexPath.row < self.apps.count)
		[self presentProductWithIdentifier:[self.apps[indexPath.row].trackId integerValue] parameters:self.affiliateInfo];

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return section == IDX_IAPS ? @"BACKGROUND SCANNING" : section == 2 ? @"FEEDBACK" : section == 3 ? @"SHARE" : section == 4 ? @"RATE" : section == IDX_APPS ? @"APPS" : Nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	return section == IDX_IAPS ? (self.iaps.allValues.firstObject[@"localizedDescription"] ?: @"Enable scanning for text in the background.") : Nil;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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
			[self.tableView reloadSection:1];

			[self.refreshControl endRefreshing];
		}];
	}
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
	self.productsRequest = Nil;
	
	[error log:@"request:didFailWithError:"];

	[GCD main:^{
		[self.refreshControl endRefreshing];
	}];
}


- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
	for (SKPaymentTransaction *transaction in transactions)
		if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
			NSDictionary *iap = self.iaps[transaction.payment.productIdentifier];

			[Answers logPurchaseWithPrice:[iap[@"price"] decimalNumber] currency:iap[@"currencyCode"] success:@YES itemName:iap[@"localizedTitle"] itemType:Nil itemId:iap[@"productIdentifier"] customAttributes:Nil];
		}

	[GCD main:^{
		[self.tableView reloadSection:1];
	}];
}

@end

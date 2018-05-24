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
#import "NSObject+Convenience.h"
#import "NSURLSession+Convenience.h"
#import "QuartzCore+Convenience.h"
#import "StoreKit+Convenience.h"
#import "UIActivityViewController+Convenience.h"
#import "UIApplication+Convenience.h"
#import "UIView+Convenience.h"

#define APP_ID 1352799843
#define DEV_ID 734258593

@interface AboutController ()
@property (strong, nonatomic, readonly) NSDictionary *affiliateInfo;

@property (strong, nonatomic) NSArray<AFMediaItem *> *apps;
@end

@implementation AboutController

__synthesize(NSDictionary *, affiliateInfo, [[NSDictionary dictionaryWithProvider:@"10603809" affiliate:@"1l3voBu"] dictionaryWithObject:@"write-review" forKey:@"action"])

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;


	NSURL *url = [[NSFileManager URLForDirectory:NSCachesDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%ul.plist", DEV_ID]];
	self.apps = [[NSArray arrayWithContentsOfURL:url] map:^id(id obj) {
		return [[AFMediaItem alloc] initWithDictionary:obj];
	}];

	[AFMediaItem lookup:@{ KEY_ID : @(DEV_ID), KEY_MEDIA : kMediaSoftware, KEY_ENTITY : kEntitySoftware } handler:^(NSArray<AFMediaItem *> *results) {
		self.apps = [results query:^BOOL(AFMediaItem *obj) {
			return [obj.wrapperType isEqualToString:kMediaSoftware] && obj.trackId.unsignedIntegerValue != APP_ID;
		}];
		[[self.apps map:^id(AFMediaItem *obj) {
			return obj.dictionary;
		}] writeToURL:url];

		if (self.apps.count)
			[GCD main:^{
				if (self.tableView.numberOfSections > 4)
					[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationAutomatic];
				else
					[self.tableView insertSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationAutomatic];
			}];
	}];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 4 + (self.apps.count ? 1 : 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return section == 4 ? self.apps.count : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:str(indexPath.section) forIndexPath:indexPath];
    
    // Configure the cell...
	if (indexPath.section == 0 && indexPath.row == 0) {
		cell.textLabel.text = [NSBundle bundleDisplayName];
		cell.detailTextLabel.text = [NSBundle bundleShortVersionString];
	} else if (indexPath.section == 4) {
		AFMediaItem *app = self.apps[indexPath.row];

		NSArray *titles = [app.trackName componentsSeparatedByString:@" - "];
		cell.textLabel.text = titles.count > 1 ? titles.firstObject : app.trackName;
		cell.detailTextLabel.text = titles.count > 1 ? titles.lastObject : [app.dictionary[@"genres"] firstObject];
		if (URL_CACHE(app.artworkUrl100).isExistingFile)
			cell.imageView.image = [[UIImage image:URL_CACHE(app.artworkUrl100)] imageWithSize:CGSizeMake(30.0, 30.0) mode:UIImageScaleAspectFit];
		else
			[app.artworkUrl100 cache:^(NSURL *url) {
				[GCD main:^{
					cell.imageView.image = [[UIImage image:url] imageWithSize:CGSizeMake(30.0, 30.0) mode:UIImageScaleAspectFit];
				}];
			}];
	}

	[cell.imageView.layer roundCorners:indexPath.section == 4 ? 6.0 : 0.0];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

	if (indexPath.section == 0 && indexPath.row == 0)
		cell.detailTextLabel.text = [cell.detailTextLabel.text isEqualToString:[NSBundle bundleVersion]] ? [NSBundle bundleShortVersionString] : [NSBundle bundleVersion];
	else if (indexPath.section == 1 && indexPath.row == 0)
		[self presentMailComposeWithRecipients:arr_(cell.detailTextLabel.text) subject:[NSBundle bundleDisplayNameAndShortVersion] body:Nil attachments:dic_(@"screenshot.jpg", [[self.presentingViewController.view snapshotImageAfterScreenUpdates:YES] jpegRepresentation]) completionHandler:Nil];
	else if (indexPath.section == 2 && indexPath.row == 0)
		[self presentWebActivityWithActivityItems:@[ [NSBundle bundleDisplayName], [NSURL URLForMobileAppWithIdentifier:APP_ID affiliateInfo:self.affiliateInfo] ] excludedTypes:Nil completionHandler:^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
			[Answers logInviteWithMethod:activityType customAttributes:@{ @"version" : [NSBundle bundleVersion], @"success" : completed ? @"YES" : @"NO", @"error" : [activityError debugDescription] ?: STR_EMPTY }];
		}];
	else if (indexPath.section == 3 && indexPath.row == 0)
		[UIApplication openURL:[NSURL URLForMobileAppWithIdentifier:APP_ID affiliateInfo:self.affiliateInfo] options:Nil completionHandler:^(BOOL success) {

		}];
	else if (indexPath.section == 4)
		[self presentProductWithIdentifier:[self.apps[indexPath.row].trackId integerValue] parameters:Nil];

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return section == 1 ? @"FEEDBACK" : section == 2 ? @"SHARE" : section == 3 ? @"RATE" : section == 4 ? @"APPS" : Nil;
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

@end

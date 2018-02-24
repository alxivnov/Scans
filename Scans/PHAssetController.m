//
//  UIImageViewController.m
//  Scans
//
//  Created by Alexander Ivanov on 23.11.2017.
//  Copyright © 2017 Alexander Ivanov. All rights reserved.
//

#import "PHAssetController.h"

#import "Global.h"

#import "CoreImage+Convenience.h"
#import "Dispatch+Convenience.h"
#import "NSFormatter+Convenience.h"
#import "UIAlertController+Convenience.h"
#import "UICenteredScrollView.h"
#import "UIImage+Convenience.h"
#import "UINavigationController+Convenience.h"

@interface PHAssetController ()
@property (strong, nonatomic) NSArray<VNObservation *> *observations;
@end

@implementation PHAssetController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setAsset:(PHAsset *)asset {
	_asset = asset;

	PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
	options.networkAccessAllowed = YES;
	options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
		[GCD main:^{
			[self.navigationController.navigationBar setProgress:progress animated:YES];
		}];

		[error log:@"progressHandler:"];
	};
	[GLOBAL.manager requestImageForAsset:asset targetSize:GLOBAL.screenSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
		[GCD main:^{
			self.image = result;

			if (!result)
				return;

			if ([info[PHImageResultIsDegradedKey] boolValue])
				[self fit];
			else
				[result detectTextRectanglesWithOptions:@{ VNImageOptionReportCharacterBoxes : @YES } handler:^(NSArray<VNTextObservation *> *results) {
					self.observations = results;

					if (!results)
						return;

					UIImage *image = [UIImage imageWithSize:result.size draw:^(CGContextRef context) {
						[result drawAtPoint:CGPointZero];

						CGContextSetStrokeColorWithColor(context, self.view.tintColor.CGColor);
						CGContextSetLineWidth(context, 4.0);

						for (VNTextObservation *observation in results)
							CGContextStrokeRect(context, CGRectInset([result boundsForObservation:observation], -4.0, -4.0));
					}];

					UIImage *circle = [UIImage image:@"circle"];
					UIImage *observations = results ? [UIImage imageWithSize:circle.size draw:^(CGContextRef context) {
						[circle drawInRect:CGRectMake(0.0, 0.0, circle.size.width, circle.size.height)];

						NSAttributedString *string = [[NSAttributedString alloc] initWithString:str(results.count) attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]] }];
						[string drawAtPoint:CGPointMake((circle.size.width - string.size.width) / 2.0, (circle.size.height - string.size.height) / 2.0)];
					}] : Nil;

					[GCD main:^{
						self.image = image;

						self.navigationItem.rightBarButtonItem.image = observations ?: circle;
						self.navigationItem.rightBarButtonItem.enabled = observations != Nil;
					}];
				}];
		}];
	}];

	self.navigationItem.title = [asset.creationDate descriptionForDate:NSDateFormatterMediumStyle andTime:NSDateFormatterShortStyle];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	[segue.destinationViewController forwardSelector:@selector(setImage:) withObject:self.image nextTarget:Nil];
	[segue.destinationViewController forwardSelector:@selector(setObservations:) withObject:self.observations nextTarget:Nil];
}

- (IBAction)observationsAction:(UIBarButtonItem *)sender {
	[self performSegueWithIdentifier:@"observations" sender:sender];
}

- (IBAction)trashAction:(UIBarButtonItem *)sender {
	[self presentSheetWithTitle:Nil message:Nil cancelActionTitle:@"Cancel" destructiveActionTitle:@"Delete" otherActionTitles:Nil from:Nil completion:^(UIAlertController *instance, NSInteger index) {
		if (index == UIAlertActionDestructive)
			return;
	}];
}

@end

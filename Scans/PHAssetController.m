//
//  UIImageViewController.m
//  Scans
//
//  Created by Alexander Ivanov on 23.11.2017.
//  Copyright © 2017 Alexander Ivanov. All rights reserved.
//

#import "PHAssetController.h"

#import "Global.h"

#import "Dispatch+Convenience.h"
#import "NSFormatter+Convenience.h"
#import "UIAlertController+Convenience.h"
#import "UIImage+Convenience.h"
#import "UINavigationController+Convenience.h"
#import "Vision+Convenience.h"

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

			[self fit];

			if (![info[PHImageResultIsDegradedKey] boolValue])
				[GCD global:^{
					self.observations = [[GLOBAL.container.viewContext executeFetchRequestWithEntityName:@"Observation" predicateWithFormat:@"localIdentifier = %@", self.asset.localIdentifier] map:^id(Observation *obj) {
						return obj.observation;
					}];

					if (!self.observations.count)
						return;

					UIImage *circle = [UIImage image:@"circle"];
					UIImage *observations = [UIImage imageWithSize:circle.size draw:^(CGContextRef context) {
						[circle drawInRect:CGRectMake(0.0, 0.0, circle.size.width, circle.size.height)];

						NSAttributedString *string = [[NSAttributedString alloc] initWithString:str(self.observations.count) attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]] }];
						[string drawAtPoint:CGPointMake((circle.size.width - string.size.width) / 2.0, (circle.size.height - string.size.height) / 2.0)];
					}];

					[GCD main:^{
						for (VNTextObservation *observation in self.observations) {
							CGRect bounds = observation.bounds;
							bounds.origin.x *= self.scrollView.contentSize.width;
							bounds.origin.y *= self.scrollView.contentSize.height;
							bounds.size.width *= self.scrollView.contentSize.width;
							bounds.size.height *= self.scrollView.contentSize.height;
							bounds.origin.x += self.imageView.frame.origin.x;
							bounds.origin.y += self.imageView.frame.origin.y;

							UIView *view = [[UIView alloc] initWithFrame:CGRectInset(bounds, 2.0, 2.0)];
							view.layer.borderColor = self.view.tintColor.CGColor;
							view.layer.borderWidth = 2.0;
							[self.scrollView addSubview:view];
						}

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
			[PHPhotoLibrary deleteAssets:@[ self.asset ] completionHandler:^(BOOL success) {
				if (success)
					[GCD main:^{
						[self.navigationController popViewControllerAnimated:YES];
					}];
			}];
	}];
}

@end

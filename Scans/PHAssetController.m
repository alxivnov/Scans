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
#import "NSArray+Convenience.h"
#import "NSFormatter+Convenience.h"
#import "UIAlertController+Convenience.h"
#import "UIImage+Convenience.h"
#import "UINavigationController+Convenience.h"
#import "Vision+Convenience.h"

@interface PHAssetController () <PHPhotoLibraryChangeObserver>
@property (strong, nonatomic) NSArray<VNTextObservation *> *observations;
@end

@implementation PHAssetController

- (UIImage *)imageWithCount:(NSUInteger)count {
	UIImage *img = [UIImage image:@"circle-line"];
	NSAttributedString *str = [[NSAttributedString alloc] initWithString:str(count) attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]] }];
	CGPoint loc = CGPointMake((img.size.width - str.size.width) / 2.0, (img.size.height - str.size.height) / 2.0);
	return [img drawImage:^(CGContextRef context) {
		[str drawAtPoint:loc];
	}];
}

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

	if (self.image)
		return;

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
			if (!result)
				return;

			self.image = result;

			self.scrollView.zoomScale = self.scrollView.fitZoom;

			if ([info[PHImageResultIsDegradedKey] boolValue])
				return;

			[GCD global:^{
				self.observations = [[GLOBAL.container.viewContext fetchObservationsWithAlbumIdentifier:self.album.localIdentifier assetIdentifier:self.asset.localIdentifier] map:^id(Observation *obj) {
					return obj.observation;
				}];

				if (!self.observations.count)
					return;

				UIImage *image = [self imageWithCount:self.observations.count];

				[GCD main:^{
					self.navigationItem.rightBarButtonItem.image = image;
					self.navigationItem.rightBarButtonItem.enabled = self.observations.count > 0;

					for (VNTextObservation *observation in self.observations) {
						CGFloat width = 2.0 / self.scrollView.zoomScale;

						CGRect bounds = observation.bounds;
						bounds = CGRectScale(bounds, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
						bounds = CGRectOffsetOrigin(bounds, self.imageView.frame.origin);
						bounds = CGRectInset(bounds, -width, -width);

						UIView *view = [[UIView alloc] initWithFrame:bounds];
						view.layer.borderColor = self.view.tintColor.CGColor;
						view.layer.borderWidth = width;
						[self.contentView addSubview:view];
					}
				}];
			}];
		}];
	}];

	self.navigationItem.title = [asset.creationDate descriptionForDate:NSDateFormatterMediumStyle andTime:NSDateFormatterShortStyle];

	idx(self.toolbarItems, 2).image = [UIImage image:self.asset.isFavorite ? @"like-fill" : @"like-line"];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	[segue.destinationViewController forwardSelector:@selector(setImage:) withObject:self.image nextTarget:Nil];
	[segue.destinationViewController forwardSelector:@selector(setObservations:) withObject:self.observations nextTarget:Nil];
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
	[[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];

	PHObjectChangeDetails *change = [changeInstance changeDetailsForObject:self.asset];

	[GCD main:^{
		self.asset = change.objectAfterChanges;

		idx(self.toolbarItems, 2).image = [UIImage image:self.asset.isFavorite ? @"like-fill" : @"like-line"];
	}];
}

- (IBAction)favoriteAction:(UIBarButtonItem *)sender {
	[[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];

	[PHPhotoLibrary toggleFavoriteOnAsset:self.asset completionHandler:Nil];
}

- (IBAction)trashAction:(UIBarButtonItem *)sender {
	[self presentSheetWithTitle:Nil message:Nil cancelActionTitle:@"Cancel" destructiveActionTitle:@"Delete" otherActionTitles:@[ @"Remove from Scans" ] from:Nil completion:^(UIAlertController *instance, NSInteger index) {
		if (index == UIAlertActionDestructive)
			[PHPhotoLibrary deleteAssets:@[ self.asset ] completionHandler:^(BOOL success) {
				if (success)
					[GCD main:^{
						[self.navigationController popViewControllerAnimated:YES];
					}];
			}];
		else if (index == 0)
			[PHPhotoLibrary removeAssets:@[ self.asset ] fromAssetCollection:self.album completionHandler:^(BOOL success) {
				if (success)
					[GCD main:^{
						[self.navigationController popViewControllerAnimated:YES];
					}];
			}];
	}];
}

@end

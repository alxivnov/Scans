//
//  ViewController.m
//  Scans
//
//  Created by Alexander Ivanov on 23.11.2017.
//  Copyright © 2017 Alexander Ivanov. All rights reserved.
//

#import "ViewController.h"

#import "CoreGraphics+Convenience.h"
#import "CoreImage+Convenience.h"
#import "Dispatch+Convenience.h"
#import "Photos+Convenience.h"
#import "NSObject+Convenience.h"
#import "UINavigationController+Convenience.h"

// 0.4
#warning Process images in a queue.
// 0.5
#warning Add text images to an album.
// 0.6
#warning Process images in background.
// 0.7
#warning Improve collection transition.
// 0.8
#warning Add empty state.
// 0.9
#warning Add icon and logotype.
// 1.0
#warning Add sharing, image and about info.
#warning Release.

/*
#warning Save text features to Core Data.
// 0.5
#warning OCR features.
// 0.6
#warning Search.
// 0.7
#warning Detect keywords.
// 0.8
#warning Sync keywords to Photo Library.
// 0.9
#warning Add In-App Purchase.
// 1.0
#warning Improve collection UI on different devices.
#warning Fix loading of images.
*/
@interface ViewController ()
@property (strong, nonatomic) PHFetchResult *photos;

@property (strong, nonatomic, readonly) PHCachingImageManager *manager;

@property (strong, nonatomic, readonly) NSMutableArray *scans;
@end

@implementation ViewController

static NSString * const reuseIdentifier = @"Cell";

__synthesize(PHCachingImageManager *, manager, [[PHCachingImageManager alloc] init])

__synthesize(NSMutableArray *, scans, [[NSMutableArray alloc] init])

- (void)viewDidLoad {
	[super viewDidLoad];

	// Uncomment the following line to preserve selection between presentations
	// self.clearsSelectionOnViewWillAppear = NO;

	// Register cell classes
//	[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];

	// Do any additional setup after loading the view.

	if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
		[self refreshAction:Nil];

		self.navigationItem.rightBarButtonItem.enabled = NO;
/*
		PHFetchResult<PHAssetCollection *> *assets = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[ @"Scans" ] options:Nil];
		if (!assets.count)
			[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
				[PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:@"Scans"];
			} completionHandler:^(BOOL success, NSError * _Nullable error) {
				[error log:@"creationRequestForAssetCollectionWithTitle:"];
			}];
 */
	}
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

 #pragma mark - Navigation

 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	 NSIndexPath *indexPath = [self.collectionView indexPathForCell:sender];

	 [self.manager requestImageForAsset:self.scans[indexPath.row] targetSize:[UIScreen mainScreen].nativeBounds.size contentMode:PHImageContentModeAspectFill options:[PHImageRequestOptions optionsWithNetworkAccessAllowed:YES synchronous:NO progressHandler:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
		 [GCD main:^{
			 segue.destinationViewController.navigationController.navigationBar.progress = progress;
		 }];
	 }] resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
		 [GCD main:^{
			 [segue.destinationViewController forwardSelector:@selector(setImage:) withObject:result nextTarget:Nil];

			 segue.destinationViewController.navigationItem.title = [info[@"PHImageFileURLKey"] lastPathComponent];
		 }];
	 }];
 }

#pragma mark <UICollectionViewDataSource>
/*
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
#warning Incomplete implementation, return the number of sections
	return 0;
}
*/

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return self.scans.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];

	// Configure the cell
	UIImageView *imageView = cell.contentView.subviews.firstObject;
	imageView.tag = [self.manager requestImageForAsset:self.scans[indexPath.item] targetSize:CGSizeScale(imageView.frame.size, [UIScreen mainScreen].scale) contentMode:PHImageContentModeAspectFill options:Nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
		NSInteger tag = [info[PHImageResultRequestIDKey] integerValue];

		[GCD main:^{
			if (imageView.tag == tag)
				imageView.image = result;
		}];
	}];

	return cell;
}

- (IBAction)refreshAction:(UIBarButtonItem *)sender {
	[PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
		if (status != PHAuthorizationStatusAuthorized)
			return;

		CGSize size = [UIScreen mainScreen].nativeBounds.size;
		if (size.height > size.width)
			size.width = size.height;
		else
			size.height = size.width;

		self.photos = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:[PHFetchOptions fetchOptionsWithPredicate:Nil sortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES] ]]];

		[self.manager startCachingImagesForAssets:self.photos.array targetSize:size contentMode:PHImageContentModeAspectFill options:Nil];

		for (NSInteger index = 0; index < /*self.photos.count*/10; index++) {
			[self.manager requestImageForAsset:self.photos[index] targetSize:size contentMode:PHImageContentModeAspectFill options:[PHImageRequestOptions optionsWithNetworkAccessAllowed:YES synchronous:YES] resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
				NSArray<CIFeature *> *features = [[result filterWithName:@"CIColorMonochrome"] featuresOfType:CIDetectorTypeText options:@{ CIDetectorMinFeatureSize : @0.0, CIDetectorAccuracy : CIDetectorAccuracyHigh }];

				if (features.count) {
					[self.scans insertObject:self.photos[index] atIndex:0];

					[GCD main:^{
						[self.collectionView insertItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:0 inSection:0] ]];
					}];
				}

				[GCD main:^{
					self.navigationController.navigationBar.progress = (index + 1.0) / self.photos.count;
				}];
			}];
		}
	}];
}

#pragma mark <UICollectionViewDelegate>

/*
 // Uncomment this method to specify if the specified item should be highlighted during tracking
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
 return YES;
 }
 */

/*
 // Uncomment this method to specify if the specified item should be selected
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
 return YES;
 }
 */

/*
 // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
 return NO;
 }

 - (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
 return NO;
 }

 - (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {

 }
 */

@end

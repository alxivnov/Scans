//
//  ViewController.m
//  Scans
//
//  Created by Alexander Ivanov on 23.11.2017.
//  Copyright © 2017 Alexander Ivanov. All rights reserved.
//

#import "ViewController.h"

#import "Global.h"

#import "CoreGraphics+Convenience.h"
#import "Dispatch+Convenience.h"

#import "CoreImage+Convenience.h"
#import "NSArray+Convenience.h"
#import "UINavigationController+Convenience.h"

// 0.6
#warning Process images in background mode.
// 0.7
#warning Improve navigation transition.
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
@interface ViewController () <PHPhotoLibraryChangeObserver>
@property (assign, nonatomic) CGSize cellSize;

@property (strong, nonatomic) PHAssetCollection *collection;
@property (strong, nonatomic) PHFetchResult *assets;
@end

@implementation ViewController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
	[super viewDidLoad];

	// Uncomment the following line to preserve selection between presentations
	// self.clearsSelectionOnViewWillAppear = NO;

	// Register cell classes
//	[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];

	// Do any additional setup after loading the view.

	self.cellSize = CGSizeScale(cls(UICollectionViewFlowLayout,  self.collectionView.collectionViewLayout).itemSize, [UIScreen mainScreen].nativeScale);

	[[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
	[PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
		if (status != PHAuthorizationStatusAuthorized)
			return;

		self.collection = [PHAssetCollection fetchAssetCollectionWithLocalIdentifier:GLOBAL.albumIdentifier options:Nil];
		if (self.collection) {
			self.assets = [PHAsset fetchAssetsInAssetCollection:self.collection options:[PHFetchOptions fetchOptionsWithPredicate:Nil sortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES] ]]];

			[GLOBAL.manager startCachingImagesForAssets:self.assets.array targetSize:self.cellSize contentMode:PHImageContentModeAspectFill options:Nil];

			[GCD main:^{
				[self.collectionView reloadData];
			}];
		} else {
			[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
				GLOBAL.albumIdentifier = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:@"Scans"].placeholderForCreatedAssetCollection.localIdentifier;
			} completionHandler:^(BOOL success, NSError * _Nullable error) {
				self.collection = [PHAssetCollection fetchAssetCollectionWithLocalIdentifier:GLOBAL.albumIdentifier options:Nil];

				[error log:@"creationRequestForAssetCollectionWithTitle:"];
			}];
		}
	}];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

 #pragma mark - Navigation

 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	 NSIndexPath *indexPath = [self.collectionView indexPathForCell:sender];

	 [segue.destinationViewController forwardSelector:@selector(setImage:) withObject:self.assets[indexPath.row] nextTarget:Nil];
 }

#pragma mark <UICollectionViewDataSource>
/*
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
#warning Incomplete implementation, return the number of sections
	return 0;
}
*/

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return self.assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];

	// Configure the cell
	UIImageView *imageView = cell.contentView.subviews.firstObject;
	imageView.tag = [GLOBAL.manager requestImageForAsset:self.assets[indexPath.item] targetSize:self.cellSize contentMode:PHImageContentModeAspectFill options:Nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
		NSInteger tag = [info[PHImageResultRequestIDKey] integerValue];

		[GCD main:^{
			if (imageView.tag == tag)
				imageView.image = result;
		}];
	}];

	return cell;
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
	PHFetchResultChangeDetails *changes = [changeInstance changeDetailsForFetchResult:self.assets];
	if (!changes)
		return;

	self.assets = changes.fetchResultAfterChanges;

	[GLOBAL.manager startCachingImagesForAssets:changes.insertedObjects targetSize:self.cellSize contentMode:PHImageContentModeAspectFill options:Nil];

	[GCD main:^{
		[self.collectionView performFetchResultChanges:changes inSection:0];
	}];
}

- (IBAction)refreshAction:(UIBarButtonItem *)sender {
	[GCD global:^{
		NSMutableArray *array = [NSMutableArray array];

		NSDate *endDate = self.collection.endDate ?: [self.assets.lastObject creationDate];
		PHFetchResult *newer = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:[PHFetchOptions fetchOptionsWithPredicate:endDate ? [NSPredicate predicateWithFormat:@"creationDate > %@", endDate] : Nil sortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES] ]]];
		[array addObjectsFromArray:newer.array];

		NSDate *startDate = self.collection.startDate ?: [self.assets.firstObject creationDate];
		PHFetchResult *older = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:[PHFetchOptions fetchOptionsWithPredicate:startDate ? [NSPredicate predicateWithFormat:@"creationDate < %@", startDate] : Nil sortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO] ]]];
		[array addObjectsFromArray:older.array];

		PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
		options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
		options.networkAccessAllowed = YES;
		options.synchronous = YES;

		NSUInteger count = MIN(10, array.count);
		for (NSInteger index = 0; index < count; index++)
			[GLOBAL.manager requestImageForAsset:array[index] targetSize:GLOBAL.screenSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
				NSArray<CIFeature *> *features = [[result filterWithName:@"CIColorMonochrome"] featuresOfType:CIDetectorTypeText options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh, CIDetectorMinFeatureSize : @0.0, CIDetectorReturnSubFeatures : @YES, /*CIDetectorMaxFeatureCount : @1*/ }];

				if (features.count)
					[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
						[[PHAssetCollectionChangeRequest changeRequestForAssetCollection:self.collection] insertAssets:@[ array[index] ]];
					} completionHandler:^(BOOL success, NSError * _Nullable error) {
						[error log:@"insertAssets:"];
					}];

				[GCD main:^{
					[self.navigationController.navigationBar setProgress:(index + 1.0) / count animated:YES];
				}];
			}];
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

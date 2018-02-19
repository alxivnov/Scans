//
//  ViewController.m
//  Scans
//
//  Created by Alexander Ivanov on 23.11.2017.
//  Copyright © 2017 Alexander Ivanov. All rights reserved.
//

#import "ViewController.h"

#import "CoreGraphics+Convenience.h"
#import "Dispatch+Convenience.h"
#import "Photos+Convenience.h"
#import "NSObject+Convenience.h"

#import "CoreImage+Convenience.h"
#import "NSArray+Convenience.h"
#import "UINavigationController+Convenience.h"

// 0.5
#warning View images.
#warning Watch for changes.
#warning Scan in both directions.
// 0.6
#warning Process images in background mode.
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
@property (assign, nonatomic) CGSize cellSize;
@property (assign, nonatomic) CGSize screenSize;

@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) PHAssetCollection *collection;
@property (strong, nonatomic) PHFetchResult *assets;

@property (strong, nonatomic, readonly) PHCachingImageManager *manager;

@property (strong, nonatomic, readonly) NSMutableArray<PHAsset *> *tempAssets;
@end

@implementation ViewController

static NSString * const reuseIdentifier = @"Cell";

- (NSString *)identifier {
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"albumIdentifier"];
}

- (void)setIdentifier:(NSString *)identifier {
	[[NSUserDefaults standardUserDefaults] setObject:identifier forKey:@"albumIdentifier"];
}

__synthesize(PHCachingImageManager *, manager, [[PHCachingImageManager alloc] init])

__synthesize(NSMutableArray *, tempAssets, [[NSMutableArray alloc] init])

- (void)viewDidLoad {
	[super viewDidLoad];

	// Uncomment the following line to preserve selection between presentations
	// self.clearsSelectionOnViewWillAppear = NO;

	// Register cell classes
//	[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];

	// Do any additional setup after loading the view.

	self.cellSize = CGSizeScale(cls(UICollectionViewFlowLayout,  self.collectionView.collectionViewLayout).itemSize, [UIScreen mainScreen].nativeScale);

	CGFloat max = fmax([UIScreen mainScreen].nativeBounds.size.width, [UIScreen mainScreen].nativeBounds.size.height);
	self.screenSize = CGSizeMake(max, max);

	[PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
		if (status != PHAuthorizationStatusAuthorized)
			return;

		self.collection = [PHAssetCollection fetchAssetCollectionWithLocalIdentifier:self.identifier options:Nil];
		if (self.collection) {
			self.assets = [PHAsset fetchAssetsInAssetCollection:self.collection options:[PHFetchOptions fetchOptionsWithPredicate:Nil sortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES] ]]];

			[self.manager startCachingImagesForAssets:self.assets.array targetSize:self.cellSize contentMode:PHImageContentModeAspectFill options:Nil];

			[self.tempAssets setArray:self.assets.array];

			[GCD main:^{
				[self.collectionView reloadData];
			}];
		} else {
			[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
				self.identifier = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:@"Scans"].placeholderForCreatedAssetCollection.localIdentifier;
			} completionHandler:^(BOOL success, NSError * _Nullable error) {
				self.collection = [PHAssetCollection fetchAssetCollectionWithLocalIdentifier:self.identifier options:Nil];

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

	 [segue.destinationViewController forwardSelector:@selector(setImage:) withObject:self.tempAssets[indexPath.row] nextTarget:Nil];
 }

#pragma mark <UICollectionViewDataSource>
/*
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
#warning Incomplete implementation, return the number of sections
	return 0;
}
*/

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return self.tempAssets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];

	// Configure the cell
	UIImageView *imageView = cell.contentView.subviews.firstObject;
	imageView.tag = [self.manager requestImageForAsset:self.tempAssets[indexPath.item] targetSize:self.cellSize contentMode:PHImageContentModeAspectFill options:Nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
		NSInteger tag = [info[PHImageResultRequestIDKey] integerValue];

		[GCD main:^{
			if (imageView.tag == tag)
				imageView.image = result;
		}];
	}];

	return cell;
}

- (IBAction)refreshAction:(UIBarButtonItem *)sender {
	[GCD global:^{
		NSDate *date = self.tempAssets.firstObject.creationDate;
		PHFetchResult *assets = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:[PHFetchOptions fetchOptionsWithPredicate:date ? [NSPredicate predicateWithFormat:@"creationDate < %@", date] : Nil sortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO] ]]];

		PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
		options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
		options.networkAccessAllowed = YES;
		options.synchronous = YES;

		NSUInteger count = 10;//assets.count;
		for (NSInteger index = 0; index < count; index++)
			[self.manager requestImageForAsset:assets[index] targetSize:self.screenSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
				NSArray<CIFeature *> *features = [[result filterWithName:@"CIColorMonochrome"] featuresOfType:CIDetectorTypeText options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh, CIDetectorMinFeatureSize : @0.0, CIDetectorReturnSubFeatures : @YES }];

				if (features.count)
					[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
						[[PHAssetCollectionChangeRequest changeRequestForAssetCollection:self.collection] insertAssets:@[ assets[index] ]];
					} completionHandler:^(BOOL success, NSError * _Nullable error) {
						@synchronized(self) {
							[self.tempAssets insertObject:assets[index] atIndex:0];

							[GCD main:^{
								[self.collectionView insertItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:0 inSection:0] ]];
							}];
						}

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

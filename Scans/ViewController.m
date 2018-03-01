//
//  ViewController.m
//  Scans
//
//  Created by Alexander Ivanov on 23.11.2017.
//  Copyright © 2017 Alexander Ivanov. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <PHPhotoLibraryChangeObserver>
@property (assign, nonatomic) CGSize cellSize;

@property (strong, nonatomic) PHAssetCollection *album;
@property (strong, nonatomic) PHFetchResult *fetch;
@end

@implementation ViewController

static NSString * const reuseIdentifier = @"Cell";

- (UICollectionViewFlowLayout *)flowLayout {
	return cls(UICollectionViewFlowLayout, self.collectionView.collectionViewLayout);
}

- (void)scrollToItem:(NSUInteger)item animated:(BOOL)animated {
	if ([self.collectionView numberOfItemsInSection:0] > item)
		[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:animated];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	// Uncomment the following line to preserve selection between presentations
	// self.clearsSelectionOnViewWillAppear = NO;

	// Register cell classes
//	  [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];

	// Do any additional setup after loading the view.

	self.cellSize = CGSizeScale(self.flowLayout.itemSize, [UIScreen mainScreen].nativeScale);

#warning If not authorized show empty state!

	[PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
		if (status != PHAuthorizationStatusAuthorized)
			return;

		Album *album = [GLOBAL.container.viewContext executeFetchRequestWithEntityName:@"Album" lastObject:@"creationDate"];

		self.album = [PHAssetCollection fetchAssetCollectionWithLocalIdentifier:album.localIdentifier options:Nil];
		if (self.album) {
			self.fetch = [PHAsset fetchAssetsInAssetCollection:self.album options:[PHFetchOptions fetchOptionsWithPredicate:Nil sortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES] ]]];

			[GCD main:^{
				[self.collectionView reloadData];

				[self scrollToItem:self.fetch.count - 1 animated:NO];
			}];

			[GLOBAL.manager startCachingImagesForAssets:self.fetch.array targetSize:self.cellSize contentMode:PHImageContentModeAspectFill options:Nil];
		} else {
			[PHPhotoLibrary createAssetCollectionWithTitle:@"Scans" completionHandler:^(NSString *localIdentifier) {
				if (!localIdentifier)
					return;

				Album *album = [Album insertInManagedObjectContext:GLOBAL.container.viewContext];
				album.localIdentifier = localIdentifier;
				album.creationDate = [NSDate date];
				[GLOBAL.container.viewContext save];

				self.album = [PHAssetCollection fetchAssetCollectionWithLocalIdentifier:localIdentifier options:Nil];
			}];
		}

		[[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
	}];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

 #pragma mark - Navigation

 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	 if ([segue.identifier isEqualToString:@"asset"]) {
		 NSIndexPath *indexPath = [self.collectionView indexPathForCell:sender];

		 [segue.destinationViewController forwardSelector:@selector(setAssets:) withObject:self.fetch nextTarget:Nil];
		 [segue.destinationViewController forwardSelector:@selector(setIndexPath:) withObject:indexPath nextTarget:Nil];
	 }
 }

- (IBAction)done:(UIStoryboardSegue *)sender {
	
}

#pragma mark <UICollectionViewDataSource>
/*
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
#warning Incomplete implementation, return the number of sections
	return 0;
}
*/

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return self.fetch.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];

	// Configure the cell
	UIImageView *imageView = cell.contentView.subviews.firstObject;
	imageView.tag = [GLOBAL.manager requestImageForAsset:self.fetch[indexPath.item] targetSize:self.cellSize contentMode:PHImageContentModeAspectFill options:Nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
		NSInteger tag = [info[PHImageResultRequestIDKey] integerValue];

		[GCD main:^{
			if (imageView.tag == tag)
				imageView.image = result;
		}];
	}];

	return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	UICollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"footer" forIndexPath:indexPath];

	UILabel *label = [view subview:UIViewSubview(UILabel)];
	label.text = [NSString stringWithFormat:@"%lu %@", self.fetch.count, self.navigationItem.title.lowercaseString];
	return view;
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
	PHFetchResultChangeDetails *changes = [changeInstance changeDetailsForFetchResult:self.fetch];
	if (!changes)
		return;

	@synchronized(self) {
		self.fetch = changes.fetchResultAfterChanges;

		[GCD main:^{
			[self.collectionView performFetchResultChanges:changes inSection:0];
		}];
	}

	[GLOBAL.manager startCachingImagesForAssets:changes.insertedObjects targetSize:self.cellSize contentMode:PHImageContentModeAspectFill options:Nil];
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

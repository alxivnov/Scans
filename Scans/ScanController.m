//
//  ScanController.m
//  Scans
//
//  Created by Alexander Ivanov on 01.03.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "ScanController.h"

#import "NSArray+Convenience.h"
#import "Vision+Convenience.h"

@interface ScanController ()
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UIButton *headerButton;
@property (weak, nonatomic) IBOutlet UIProgressView *headerProgress;

@property (strong, nonatomic) NSMutableArray<PHAsset *> *refresh;
@end

@implementation ScanController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
//    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    // Do any additional setup after loading the view.

	self.flowLayout.sectionHeadersPinToVisibleBounds = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>
/*
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
#warning Incomplete implementation, return the number of sections
    return 0;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
#warning Incomplete implementation, return the number of items
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    
    return cell;
}
*/
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	if ([kind isEqualToString:UICollectionElementKindSectionFooter])
		return [super collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];

	NSMutableArray *array = [NSMutableArray array];
	NSDate *startDate = self.album.startDate ?: [self.fetch.firstObject creationDate];
	NSDate *endDate = self.album.endDate ?: [self.fetch.lastObject creationDate];
	if (startDate && endDate) {
		PHFetchResult *newer = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:[PHFetchOptions fetchOptionsWithPredicate:[NSPredicate predicateWithFormat:@"creationDate > %@", endDate] sortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES] ]]];
		[array addObjectsFromArray:newer.array];

		PHFetchResult *older = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:[PHFetchOptions fetchOptionsWithPredicate:[NSPredicate predicateWithFormat:@"creationDate < %@", startDate] sortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO] ]]];
		[array addObjectsFromArray:older.array];
	} else {
		PHFetchResult *older = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:[PHFetchOptions fetchOptionsWithPredicate:Nil sortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO] ]]];
		[array addObjectsFromArray:older.array];
	}

	self.refresh = array.count > 0 ? array : Nil;

	UICollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"header" forIndexPath:indexPath];
	UILabel *label = [view subview:UIViewSubview(UILabel)];
	label.text = [NSString stringWithFormat:@"Scan %lu new photos from Library", array.count];
	return view;
}

- (void)refreshHeaderWithIndex:(NSUInteger)index count:(NSUInteger)count {
	if (count == 0) {
		self.flowLayout.headerReferenceSize = CGSizeZero;
	} else {
		self.flowLayout.headerReferenceSize = self.flowLayout.footerReferenceSize;

		self.headerLabel.text = index == 0 ? [NSString stringWithFormat:@"Scan %lu new photos from Library", count] : [NSString stringWithFormat:@"%lu / %lu", index, count];

		self.headerButton.titleLabel.text = index == 0 ? @"Scan" : @"Stop";

		self.headerProgress.progress = (float)index / (float)count;
	}
}

- (IBAction)refreshAction:(UIButton *)sender {
	sender.titleLabel.text = [sender.titleLabel.text isEqualToString:@"Stop"] ? @"Scan" : @"Stop";

	if ([sender.titleLabel.text isEqualToString:@"Stop"])
		[GCD global:^{
			PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
			options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
			options.networkAccessAllowed = YES;
			options.synchronous = YES;

//			NSUInteger count = MIN(10, array.count);
			for (NSInteger index = 0; index < self.refresh.count && [sender.titleLabel.text isEqualToString:@"Stop"]; index++) {
				PHAsset *asset = self.refresh[index];

				NSUInteger item = self.fetch.count && [self.fetch.lastObject creationDate].timeIntervalSinceReferenceDate < asset.creationDate.timeIntervalSinceReferenceDate ? self.fetch.count : 0;

				[GCD main:^{
					[[PHImageManager defaultManager] requestImageForAsset:asset targetSize:GLOBAL.screenSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
						[result detectTextRectanglesWithOptions:@{ VNImageOptionReportCharacterBoxes : @YES } handler:^(NSArray<VNTextObservation *> *results) {
							if (results)
								[PHPhotoLibrary insertAssets:@[ asset ] atIndexes:[NSIndexSet indexSetWithIndex:item] intoAssetCollection:self.album completionHandler:^(BOOL success) {
									if (item)
										GLOBAL.albumEndDate = asset.creationDate;
									else
										GLOBAL.albumStartDate = asset.creationDate;
								}];
						}];
					}];

					[self refreshHeaderWithIndex:index + 1 count:self.refresh.count];

					if (self.fetch.count)
						[self scrollToItem:item ? item - 1 : 0 animated:YES];
				}];
			}
		}];
	else
		[self refreshHeaderWithIndex:0 count:self.refresh.count];
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

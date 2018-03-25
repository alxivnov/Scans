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

@property (assign, nonatomic) BOOL scanning;
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

	NSArray *ids = [[GLOBAL.container.viewContext fetchAssetsWithAlbumIdentifier:self.album.localIdentifier] map:^id(Asset *obj) {
		return obj.assetIdentifier;
	}];
	PHFetchResult *fetch = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:[PHFetchOptions fetchOptionsWithPredicate:Nil sortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO] ]]];
	NSArray *array = [fetch.array query:^BOOL(PHAsset *obj) {
		return ![ids containsObject:obj.localIdentifier];
	}];

	self.refresh = array.count > 0 ? [array mutableCopy] : Nil;

	UICollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"header" forIndexPath:indexPath];
	self.headerLabel = [view subview:UIViewSubview(UILabel)];
	self.headerButton = [view subview:UIViewSubview(UIButton)];
	self.headerProgress = [view subview:UIViewSubview(UIProgressView)];
	self.headerLabel.text = [NSString stringWithFormat:@"Scan %lu new photos from Library", array.count];
	return view;
}

- (void)refreshHeaderWithIndex:(NSUInteger)index count:(NSUInteger)count {
	if (count == 0) {
		self.flowLayout.headerReferenceSize = CGSizeZero;
	} else {
		self.flowLayout.headerReferenceSize = self.flowLayout.footerReferenceSize;

		self.headerLabel.text = index == NSNotFound ? [NSString stringWithFormat:@"Scan %lu new photos from Library", count] : [NSString stringWithFormat:@"%lu / %lu", index, count];

		[self.headerButton setTitle:index == NSNotFound ? @"Scan" : @"Stop" forState:UIControlStateNormal];

		[self.headerProgress setProgress:(float)index / (float)count animated:YES];

		if (index == count)
			self.headerProgress.progress = 0;
	}
}

- (IBAction)refreshAction:(UIButton *)sender {
	self.scanning = [sender.titleLabel.text isEqualToString:@"Scan"];

	[sender setTitle:self.scanning ? @"Stop" : @"Scan" forState:UIControlStateNormal];

	if (self.scanning)
		[GCD global:^{
			PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
			options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
			options.networkAccessAllowed = YES;
			options.synchronous = YES;

			for (NSInteger index = 0; index <= self.refresh.count && self.scanning; index++) {
				PHAsset *asset = idx(self.refresh, index);

				NSUInteger item = asset ? self.fetch.count && [self.fetch.lastObject creationDate].timeIntervalSinceReferenceDate < asset.creationDate.timeIntervalSinceReferenceDate ? self.fetch.count - 1 : 0 : NSNotFound;

				if (asset)
					[[PHImageManager defaultManager] requestImageForAsset:asset targetSize:GLOBAL.screenSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
						[result detectTextRectanglesWithOptions:@{ VNImageOptionReportCharacterBoxes : @YES } completionHandler:^(NSArray<VNTextObservation *> *results) {
							if (results)
								[PHPhotoLibrary insertAssets:@[ asset ] atIndexes:[NSIndexSet indexSetWithIndex:item ? item + 1 : 0] intoAssetCollection:self.album completionHandler:^(BOOL success) {
									[GLOBAL.container.viewContext saveAssetWithIdentifier:asset.localIdentifier albumIdentifier:self.album.localIdentifier observations:results];
								}];
							else
								[GLOBAL.container.viewContext saveAssetWithIdentifier:asset.localIdentifier albumIdentifier:self.album.localIdentifier observations:results];
						}];
					}];

				[GCD main:^{
					[self scrollToItem:item animated:YES];

					[self refreshHeaderWithIndex:self.scanning ? index : NSNotFound count:self.refresh.count];
				}];
			}
		}];
	else
		[self refreshHeaderWithIndex:NSNotFound count:self.refresh.count];
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

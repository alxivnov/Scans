//
//  ViewController.m
//  Scans
//
//  Created by Alexander Ivanov on 23.11.2017.
//  Copyright © 2017 Alexander Ivanov. All rights reserved.
//

#import "ViewController.h"

#import "CollectionTransition.h"
#import "TextDetector.h"
#import "RectangleController.h"

#import "UIView+Convenience.h"

@interface ViewController () <PHPhotoLibraryChangeObserver, CollectionTransitionDelegate>
@property (strong, nonatomic) IBOutlet UIView *emptyState;

@property (strong, nonatomic) TextDetector *detector;

@property (strong, nonatomic) NSIndexPath *indexPath;
@end

@implementation ViewController

static NSString * const reuseIdentifier = @"Cell";

- (UICollectionViewFlowLayout *)flowLayout {
	return cls(UICollectionViewFlowLayout, self.collectionView.collectionViewLayout);
}

- (void)updateHeader:(UICollectionReusableView *)header footer:(UICollectionReusableView *)footer {
	if (self.detector.count) {
		if (!header)
			header = [self.collectionView supplementaryViewForElementKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];

		[[header subview:UIViewSubview(UILabel)] setText:self.detector.isProcessing ? [NSString stringWithFormat:@"%lu / %lu", self.detector.index, self.detector.count] : [NSString stringWithFormat:@"Scan %lu new photos from Library", self.detector.count]];
		[[header subview:UIViewSubview(UIButton)] setTitle:self.detector.isProcessing ? @"Stop" : @"Scan" forState:UIControlStateNormal];
		[[header subview:UIViewSubview(UIProgressView)] setProgress:self.detector.isProcessing ? (1.0 + self.detector.index) / self.detector.count : 0.0 animated:self.detector.isProcessing];

		self.flowLayout.headerReferenceSize = self.flowLayout.footerReferenceSize;
	} else {
		self.flowLayout.headerReferenceSize = CGSizeZero;
	}

	if (!footer)
		footer = [self.collectionView supplementaryViewForElementKind:UICollectionElementKindSectionFooter atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
	[[footer subview:UIViewSubview(UILabel)] setText:LIB.count ? [NSString stringWithFormat:@"%lu %@", LIB.count, self.navigationItem.title.lowercaseString] : Nil];
}

- (void)reloadData:(PHAuthorizationStatus)status {
	self.collectionView.backgroundView = PHPhotoLibraryAuthorized(status) ? Nil : self.emptyState;

	if (self.collectionView.backgroundView)
		return;

	[self.collectionView reloadData];

	if (LIB.count)
		[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:LIB.count - 1 inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];

	[[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];

	self.detector = [[TextDetector alloc] init];

	[self updateHeader:Nil footer:Nil];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	// Uncomment the following line to preserve selection between presentations
	// self.clearsSelectionOnViewWillAppear = NO;

	// Register cell classes
//	  [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];

	// Do any additional setup after loading the view.

	self.flowLayout.sectionHeadersPinToVisibleBounds = YES;

	[self reloadData:NSNotFound];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

 #pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"asset"]) {
		self.indexPath = [self.collectionView indexPathForCell:sender];

		[segue.destinationViewController forwardSelector:@selector(setIndexPath:) withObject:self.indexPath nextTarget:Nil];
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
	return LIB.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];

	// Configure the cell
	UIImageView *imageView = cell.contentView.subviews.firstObject;
	imageView.tag = [LIB requestSmallImageAtIndex:indexPath.item resultHandler:^(UIImage * result, PHImageRequestID requestID) {
		[GCD main:^{
			if (imageView.tag == requestID)
				imageView.image = result;
		}];
	}];

	return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	UICollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:[kind isEqualToString:UICollectionElementKindSectionHeader] ? @"header" : @"footer" forIndexPath:indexPath];

	if ([kind isEqualToString:UICollectionElementKindSectionHeader])
		[self updateHeader:view footer:Nil];
	else
		[self updateHeader:Nil footer:view];

	return view;
}

- (IBAction)requestAction:(UIButton *)sender {
	[LIB requestAuthorization:^(PHAuthorizationStatus status) {
		[GCD main:^{
			[self reloadData:status];
		}];
	}];
}

- (IBAction)refreshAction:(UIButton *)sender {
	if (self.detector.isProcessing)
		[self.detector stopProcessing];
	else
		[self.detector startProcessing:^(PHAsset *asset) {
			[GCD main:^{
				[self updateHeader:Nil footer:Nil];
			}];
		}];

	[self updateHeader:Nil footer:Nil];
}

- (IBAction)cameraAction:(UIBarButtonItem *)sender {
	RectangleController *vc = [[RectangleController alloc] initWithHandler:^(UIImage *image) {
		[LIB createAssetWithImage:image];
	}];

	[self presentViewController:vc animated:YES completion:Nil];

	vc.doneButton.layer.borderColor = vc.shapeLayer.strokeColor = self.navigationController.navigationBar.tintColor.CGColor;
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
	[GCD main:^{
		@synchronized(self) {
			PHFetchResultChangeDetails *changes = [LIB performFetchResultChanges:changeInstance];
			
			[self.collectionView performFetchResultChanges:changes inSection:0];
		}

		if (changes.insertedIndexes.count)
			[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:changes.insertedIndexes.firstIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
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

- (UIView *)transitionViewForView:(UIView *)view {
	UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:view ? [NSIndexPath indexPathForItem:view.tag inSection:0] : self.indexPath];
	UIImageView *imageView = [cell subview:UIViewSubview(UIImageView)];
	imageView.tag = self.indexPath.item;
	return imageView;
}

@end

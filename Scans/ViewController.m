//
//  ViewController.m
//  Scans
//
//  Created by Alexander Ivanov on 23.11.2017.
//  Copyright © 2017 Alexander Ivanov. All rights reserved.
//

#import "ViewController.h"

#import "TextDetector.h"

#import "UIScrollView+Convenience.h"
#import "UIView+Convenience.h"
#import "UIViewController+Convenience.h"

@implementation UICollectionView (Scroll)

- (void)scrollToSupplementaryElementOfKind:(NSString *)kind inSection:(NSInteger)section animated:(BOOL)animated {
	if (self.numberOfSections == 0)
		return;

	[self scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:kind == UICollectionElementKindSectionHeader ? 0 : [self numberOfItemsInSection:section] - 1 inSection:section] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:animated];

	UICollectionViewLayoutAttributes *attr = [self layoutAttributesForSupplementaryElementOfKind:kind atIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
	if (attr)
		[self setContentOffset:CGPointMake(self.contentOffset.x, attr.frame.origin.y) animated:animated];
}

@end

@interface ViewController () <PHPhotoLibraryChangeObserver>
@property (strong, nonatomic) IBOutlet UIView *emptyState;

@property (strong, nonatomic) TextDetector *detector;
@end

@implementation ViewController

- (void)setDetector:(TextDetector *)detector {
	_detector = detector;

	[self updateFooter:Nil];
	[self updateHeader:Nil];
}

- (void)updateFooter:(UICollectionReusableView *)footer {
	if (!footer)
		footer = [self.collectionView supplementaryViewForElementKind:UICollectionElementKindSectionFooter atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];

	[[footer subview:UIViewIsKindOfClass(UILabel)] setText:LIB.count ? [NSString stringWithFormat:@"%lu %@", LIB.count, self.navigationItem.title.lowercaseString] : Nil];
}

- (void)updateHeader:(UICollectionReusableView *)header {
	if (self.detector.isProcessing || self.detector.count) {
		if (!header)
			header = [self.collectionView supplementaryViewForElementKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];

		[[header subview:UIViewIsKindOfClass(UILabel)] setText:self.detector.isProcessing ? [NSString stringWithFormat:@"%lu / %lu", self.detector.index, self.detector.count] : [NSString stringWithFormat:@"Scan %lu new photos from Library", self.detector.count]];
		[[header subview:UIViewIsKindOfClass(UIButton)] setTitle:self.detector.isProcessing ? @"Stop" : @"Scan" forState:UIControlStateNormal];
		[[header subview:UIViewIsKindOfClass(UIProgressView)] setProgress:self.detector.isProcessing ? (float)self.detector.index / (float)self.detector.count : 0.0 animated:self.detector.isProcessing];

		self.flowLayout.headerReferenceSize = self.flowLayout.footerReferenceSize;
	} else {
		self.flowLayout.headerReferenceSize = CGSizeZero;
	}
}

- (void)reloadData:(PHAuthorizationStatus)status {
	self.collectionView.backgroundView = PHPhotoLibraryAuthorized(status) ? Nil : self.emptyState;
	if (self.collectionView.backgroundView)
		return;

	[self.collectionView reloadData];

	if (LIB.count)
		[self.collectionView scrollToSupplementaryElementOfKind:UICollectionElementKindSectionFooter inSection:0 animated:NO];

	[[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];

	self.detector = [[TextDetector alloc] init];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	// Uncomment the following line to preserve selection between presentations
	// self.clearsSelectionOnViewWillAppear = NO;

	// Register cell classes
//	[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];

	// Do any additional setup after loading the view.

	self.flowLayout.sectionHeadersPinToVisibleBounds = YES;

	[self reloadData:NSNotFound];


//	[Answers logContentViewWithName:@"ViewController" contentType:@"VC" contentId:Nil customAttributes:Nil];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark <UICollectionViewDataSource>
/*
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
#warning Incomplete implementation, return the number of sections
	return 0;
}
*/

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	UICollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:[kind isEqualToString:UICollectionElementKindSectionHeader] ? @"header" : @"footer" forIndexPath:indexPath];

	if ([kind isEqualToString:UICollectionElementKindSectionHeader])
		[self updateHeader:view];
	else
		[self updateFooter:view];

	return view;
}

- (IBAction)requestAction:(UIButton *)sender {
	[LIB requestAuthorization:^(PHAuthorizationStatus status) {
		[GCD main:^{
			[self reloadData:status];
		}];

//		[Answers logCustomEventWithName:@"Photos authorization" customAttributes:@{ @"success" : status == PHAuthorizationStatusAuthorized ? @YES : @NO }];
	}];
}

- (IBAction)refreshAction:(UIButton *)sender {
	if (self.detector.isProcessing)
		[self.detector stopProcessing];
	else
		[self.detector startProcessing:^(BOOL success) {
			[GCD main:^{
				[self updateHeader:Nil];
			}];
		}];

	[self updateHeader:Nil];
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
	[GCD main:^{
		@synchronized(self) {
			PHFetchResultChangeDetails *changes = [LIB performFetchResultChanges:changeInstance];

			[self.collectionView performFetchResultChanges:changes inSection:0 completion:^(BOOL finished) {
				if (changes.insertedIndexes.count)
					[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:changes.insertedIndexes.firstIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];

//				[self updateHeader:Nil];
				[self updateFooter:Nil];
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

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

#import "UISearchController+Convenience.h"
#import "UIView+Convenience.h"
#import "UIViewController+Convenience.h"

#import <Crashlytics/Crashlytics.h>

@interface ViewController () <PHPhotoLibraryChangeObserver, UISearchResultsUpdating, CollectionTransitionDelegate>
@property (strong, nonatomic) IBOutlet UIView *emptyState;

@property (strong, nonatomic) TextDetector *detector;

@property (strong, nonatomic) NSIndexPath *indexPath;

@property (strong, nonatomic, readonly) UICollectionViewFlowLayout *flowLayout;
@end

@implementation ViewController

static NSString * const reuseIdentifier = @"Cell";

- (UICollectionViewFlowLayout *)flowLayout {
	return cls(UICollectionViewFlowLayout, self.collectionView.collectionViewLayout);
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
	LIB.search = searchController.searchBar.text;

	[self.collectionView reloadData];

	[self updateFooter:Nil];
}

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
		[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:LIB.count - 1 inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];

	[[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];

	self.detector = [[TextDetector alloc] init];

	self.searchResultsUpdater = self;
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


	[Answers logContentViewWithName:@"ViewController" contentType:@"VC" contentId:Nil customAttributes:Nil];
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

		[segue.destinationViewController forwardSelector:@selector(setIndexPath:) withObject:self.indexPath nextTarget:UIViewControllerNextTarget(NO)];

		segue.destinationViewController.transitioningDelegate = [self.navigationController forwardSelector:@selector(collectionTransition) nextTarget:Nil];
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

		[Answers logCustomEventWithName:@"Photos authorization" customAttributes:@{ @"success" : status == PHAuthorizationStatusAuthorized ? @YES : @NO }];
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

- (IBAction)searchAction:(UIBarButtonItem *)sender {
//	self.navigationItem.searchController.active = YES;

	[self.navigationItem.searchController.searchBar becomeFirstResponder];
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
	[GCD main:^{
		@synchronized(self) {
			PHFetchResultChangeDetails *changes = [LIB performFetchResultChanges:changeInstance];

			if (LIB.search) {
				[self.collectionView reloadData];
			} else {
				[self.collectionView performFetchResultChanges:changes inSection:0 completion:^(BOOL finished) {
					if (changes.insertedIndexes.count)
						[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:changes.insertedIndexes.firstIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];

//					[self updateHeader:Nil];
					[self updateFooter:Nil];
				}];
			}
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

- (UIView *)transitionViewForView:(UIView *)view {
	UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:view ? [NSIndexPath indexPathForItem:view.tag inSection:0] : self.indexPath];
	UIImageView *imageView = [cell subview:UIViewIsKindOfClass(UIImageView)];
	imageView.tag = self.indexPath.item;
	return imageView;
}

@end

//
//  ScanController.m
//  Scans
//
//  Created by Alexander Ivanov on 01.03.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "ScanController.h"

#import "TextDetector.h"

@interface ScanController ()
@property (strong, nonatomic) TextDetector *detector;

@property (assign, nonatomic) NSUInteger scanning;
@end

@implementation ScanController

static NSString * const reuseIdentifier = @"Cell";

- (void)updateHeader:(UICollectionReusableView *)header {
	if (self.detector.assets.count) {
		if (!header)
			header = [self.collectionView supplementaryViewForElementKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];

		UILabel *label = [header subview:UIViewSubview(UILabel)];
		UIButton *button = [header subview:UIViewSubview(UIButton)];
		UIProgressView *progress = [header subview:UIViewSubview(UIProgressView)];

		NSUInteger index = self.scanning - self.detector.assets.count + 1;
		NSUInteger count = self.scanning;

		label.text = self.scanning ? [NSString stringWithFormat:@"%lu / %lu", index, count] : [NSString stringWithFormat:@"Scan %lu new photos from Library", self.detector.assets.count];
		[button setTitle:self.scanning ? @"Stop" : @"Scan" forState:UIControlStateNormal];
		[progress setProgress:self.scanning ? (float)index / (float)count : 0.0 animated:self.scanning];

		self.flowLayout.headerReferenceSize = self.flowLayout.footerReferenceSize;
	} else {
		self.flowLayout.headerReferenceSize = CGSizeZero;
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
//    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    // Do any additional setup after loading the view.

	self.flowLayout.sectionHeadersPinToVisibleBounds = YES;

	self.detector = [[TextDetector alloc] initWithAlbum:self.album context:GLOBAL.container.viewContext];
	[self updateHeader:Nil];
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

	UICollectionReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"header" forIndexPath:indexPath];
	[self updateHeader:header];
	return header;
}

- (IBAction)refreshAction:(UIButton *)sender {
	if (self.scanning) {
		self.scanning = 0;

		self.detector = [[TextDetector alloc] initWithAlbum:self.album context:GLOBAL.container.viewContext];
		[self updateHeader:Nil];
	} else {
		self.scanning = self.detector.assets.count;

		[self updateHeader:Nil];

		[GCD global:^{
			while (self.detector.assets.count && self.scanning)
				[self.detector process:^(PHAsset *asset) {
					NSUInteger index = asset ? self.fetch.count && [self.fetch.lastObject creationDate].timeIntervalSinceReferenceDate < asset.creationDate.timeIntervalSinceReferenceDate ? self.fetch.count : 0 : NSNotFound;

					[GCD main:^{
						[self scrollToItem:index animated:YES];

						[self updateHeader:Nil];
					}];
				}];
		}];
	}
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

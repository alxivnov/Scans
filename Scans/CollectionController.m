//
//  CollectionController.m
//  Scans
//
//  Created by Alexander Ivanov on 23.07.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "CollectionController.h"

@interface CollectionController () <CollectionTransitionDelegate>
@property (strong, nonatomic) IBOutlet UIView *emptyState;
@end

@implementation CollectionController

static NSString * const reuseIdentifier = @"Cell";

- (UICollectionViewFlowLayout *)flowLayout {
	return cls(UICollectionViewFlowLayout, self.collectionView.collectionViewLayout);
}

- (PHAsset *)assetAtIndex:(NSUInteger)index {
	return [LIB assetAtIndex:index];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
//	[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    // Do any additional setup after loading the view.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	// Get the new view controller using [segue destinationViewController].
	// Pass the selected object to the new view controller.

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
	imageView.tag = [LIB requestSmallImageForAsset:[self assetAtIndex:indexPath.item] resultHandler:^(UIImage * result, PHImageRequestID requestID) {
		[GCD main:^{
			if (imageView.tag == requestID)
				imageView.image = result;
		}];
	}];

	return cell;
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

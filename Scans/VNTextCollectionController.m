//
//  FeaturesController.m
//  Scans
//
//  Created by Alexander Ivanov on 23.11.2017.
//  Copyright © 2017 Alexander Ivanov. All rights reserved.
//

#import "VNTextCollectionController.h"

#import "CollectionTransition.h"

#import "NSObject+Convenience.h"
#import "UIView+Convenience.h"
#import "Vision+Convenience.h"

@interface VNTextCollectionController () <CollectionTransitionDelegate>
@property (strong, nonatomic) NSIndexPath *indexPath;
@end

@implementation VNTextCollectionController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
//    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	self.indexPath = [self.collectionView indexPathForCell:sender];

	[segue.destinationViewController forwardSelector:@selector(setImage:) withObject:self.image nextTarget:Nil];
	[segue.destinationViewController forwardSelector:@selector(setObservations:) withObject:self.observations nextTarget:Nil];
	[segue.destinationViewController forwardSelector:@selector(setIndexPath:) withObject:self.indexPath nextTarget:Nil];
}

#pragma mark <UICollectionViewDataSource>
/*
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
#warning Incomplete implementation, return the number of sections
    return 0;
}
*/

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.observations.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
	UIImageView *imageView = cell.contentView.subviews.firstObject;
	imageView.image = [self.image imageWithObservation:self.observations[indexPath.item]];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	UICollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"footer" forIndexPath:indexPath];
	
	UILabel *label = [view subview:UIViewIsKindOfClass(UILabel)];
	label.text = [NSString stringWithFormat:@"%lu %@", self.observations.count, self.navigationItem.title.lowercaseString];
	return view;
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

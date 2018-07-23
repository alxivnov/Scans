//
//  SearchController.m
//  Scans
//
//  Created by Alexander Ivanov on 22.07.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "SearchController.h"

#import "UISearchController+Convenience.h"

@interface SearchController () <UISearchResultsUpdating>
@property (strong, nonatomic) NSArray<Observation *> *observations;

@property (strong, nonatomic) NSString *search;
@end

@implementation SearchController

- (PHAsset *)assetAtIndex:(NSUInteger)index {
	return [PHAsset fetchAssetWithLocalIdentifier:idx(self.observations, index).assetIdentifier options:Nil];
}

- (void)setSearch:(NSString *)search {
	_search = search;

	if (search.length) {
		NSArray<Observation *> *arr = [LIB fetchObservationsWithLabel:search];
		NSDictionary *dic = [arr dictionaryWithKey:^id<NSCopying>(Observation *obj) {
			return obj.assetIdentifier;
		} value:^id(Observation *obj, id<NSCopying> key, id val) {
			if (val)
				return val;

			if ([LIB.localIdentifiers containsObject:obj.assetIdentifier])
				return obj;

			return Nil;
		}];
		self.observations = dic.allValues;
	} else {
		self.observations = Nil;
	}
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
	self.search = searchController.searchBar.text;

	[self.collectionView reloadData];

//	[self updateFooter:Nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
//	[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    // Do any additional setup after loading the view.

	self.searchResultsUpdater = self;


	[Answers logContentViewWithName:@"ViewController" contentType:@"VC" contentId:Nil customAttributes:Nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	if (!self.navigationItem.searchController.searchBar.text.length)
		self.navigationItem.hidesSearchBarWhenScrolling = NO;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	if (!self.navigationItem.searchController.searchBar.text.length)
		self.navigationItem.hidesSearchBarWhenScrolling = YES;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.

	[super prepareForSegue:segue sender:sender];

	if ([segue.identifier isEqualToString:@"asset"])
		[segue.destinationViewController forwardSelector:@selector(setObservations:) withObject:self.observations nextTarget:UIViewControllerNextTarget(NO)];
}

- (IBAction)delete:(UIStoryboardSegue *)sender {
	NSIndexPath *indexPath = [sender.sourceViewController forwardSelector:@selector(indexPath) nextTarget:UIViewControllerNextTarget(YES)];
	if (indexPath) {
		self.observations = [self.observations arrayByRemovingObjectAtIndex:indexPath.item];

		[self.collectionView deleteItemsAtIndexPaths:@[ indexPath ]];
	} else {
		self.search = self.search;
	}
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

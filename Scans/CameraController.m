//
//  CameraController.m
//  Scans
//
//  Created by Alexander Ivanov on 13.03.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "CameraController.h"

#import "UIImagePickerController+Convenience.h"
#import "CoreImage+Convenience.h"
#import "Vision+Convenience.h"

@interface CameraController ()

@end

@implementation CameraController

- (IBAction)cameraAction:(UIBarButtonItem *)sender {
	[self presentImagePickerWithSourceType:UIImagePickerControllerSourceTypeCamera mediaTypes:Nil from:sender completion:^(UIImage *image) {
		[image detectRectanglesWithOptions:Nil completionHandler:^(NSArray<VNRectangleObservation *> *results) {
			VNRectangleObservation *rectangle = results.firstObject;
			if (!rectangle)
				return;

			UIImage *corrected = [image filterWithName:@"CIPerspectiveCorrection" parameters:@{ @"inputTopLeft" : [[CIVector alloc] initWithCGPoint:CGPointScale(rectangle.topLeft, image.size.width, image.size.height)], @"inputTopRight" : [[CIVector alloc] initWithCGPoint:CGPointScale(rectangle.topRight, image.size.width, image.size.height)], @"inputBottomRight" : [[CIVector alloc] initWithCGPoint:CGPointScale(rectangle.bottomRight, image.size.width, image.size.height)], @"inputBottomLeft" : [[CIVector alloc] initWithCGPoint:CGPointScale(rectangle.bottomLeft, image.size.width, image.size.height)] }];
			if (!corrected)
				return;

			[PHPhotoLibrary createAssetWithImage:image completionHandler:^(NSString *localIdentifier) {
				PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifier:localIdentifier options:Nil].firstObject;
				if (!asset)
					return;

				[image detectTextRectanglesWithOptions:@{ VNImageOptionReportCharacterBoxes : @YES } completionHandler:^(NSArray<VNTextObservation *> *results) {
					if (results)
						[PHPhotoLibrary insertAssets:@[ asset ] atIndexes:Nil intoAssetCollection:self.album completionHandler:^(BOOL success) {
							[GLOBAL.container.viewContext saveAssetWithIdentifier:asset.localIdentifier albumIdentifier:self.album.localIdentifier observations:results];
						}];
					else
						[GLOBAL.container.viewContext saveAssetWithIdentifier:asset.localIdentifier albumIdentifier:self.album.localIdentifier observations:results];
				}];
			}];
		}];
	}];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Do any additional setup after loading the view.
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

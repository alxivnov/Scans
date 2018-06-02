//
//  Model+Convenience.m
//  Scans
//
//  Created by Alexander Ivanov on 01.03.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "Model+Convenience.h"

@implementation Observation (VNTextObservation)

- (VNTextObservation *)observation {
	return [VNTextObservation observationWithBoundingBox:CGRectMake(self.x, self.y, self.width, self.height)];
}

- (void)setObservation:(VNTextObservation *)observation {
	self.x = observation.boundingBox.origin.x;
	self.y = observation.boundingBox.origin.y;
	self.width = observation.boundingBox.size.width;
	self.height = observation.boundingBox.size.height;
}

@end

@implementation Label (FIRVisionLabel)

- (CGRect)frame {
	return CGRectMake(self.x, self.y, self.width, self.height);
}

- (void)setFrame:(CGRect)frame {
	self.x = frame.origin.x;
	self.y = frame.origin.y;
	self.width = frame.size.width;
	self.height = frame.size.height;
}

@end

@implementation NSManagedObjectContext (Model)

- (Album *)fetchLastAlbum {
	return [Album executeFetchRequestInContext:self lastObject:@"creationDate"];
}

- (NSArray<Asset *> *)fetchAssetsWithAlbumIdentifier:(NSString *)albumIdentifier {
	return [Asset executeFetchRequestInContext:self predicateWithFormat:@"albumIdentifier = %@", albumIdentifier];
}

- (NSArray<Observation *> *)fetchObservationsWithAlbumIdentifier:(NSString *)albumIdentifier assetIdentifier:(NSString *)assetIdentifier {
	return [Observation executeFetchRequestInContext:self predicateWithFormat:@"(albumIdentifier = %@) && (assetIdentifier = %@)", albumIdentifier, assetIdentifier];
}

- (NSArray<Observation *> *)fetchObservationsWithAlbumIdentifier:(NSString *)albumIdentifier label:(NSString *)label {
	return [Observation executeFetchRequestInContext:self predicateWithFormat:@"(albumIdentifier = %@) && (text like %@)", albumIdentifier, [NSString stringWithFormat:@"*%@*", label]];
}

- (Album *)saveAlbumWithIdentifier:(NSString *)albumIdentifier {
	if (!albumIdentifier)
		return Nil;

	Album *album = [Album insertInContext:self];
	album.albumIdentifier = albumIdentifier;
	album.creationDate = [NSDate date];

	[self save];

	return album;
}

- (Asset *)saveAssetWithIdentifier:(NSString *)assetIdentifier albumIdentifier:(NSString *)albumIdentifier observations:(NSArray<VNTextObservation *> *)observations labels:(NSArray<FIRVisionLabel *> *)labels {
	Asset *asset = [Asset insertInContext:self];
	asset.assetIdentifier = assetIdentifier;
	asset.albumIdentifier = albumIdentifier;
	asset.numberOfObservations = observations.count;
	asset.numberOfLabels = labels.count;

	for (VNTextObservation *observation in observations) {
		Observation *obj = [Observation insertInContext:self];
		obj.albumIdentifier = albumIdentifier;
		obj.assetIdentifier = assetIdentifier;
		obj.observation = observation;
	}

	for (FIRVisionLabel *label in labels) {
		Label *obj = [Label insertInContext:self];
		obj.albumIdentifier = albumIdentifier;
		obj.assetIdentifier = assetIdentifier;
		obj.frame = label.frame;
		obj.confidence = label.confidence;
		obj.entityID = label.entityID;
		obj.text = label.label;
	}

	[self save];

	return asset;
}

- (Asset *)saveAssetWithIdentifier:(NSString *)assetIdentifier albumIdentifier:(NSString *)albumIdentifier texts:(NSArray<id<FIRVisionText>> *)texts labels:(NSArray<FIRVisionLabel *> *)labels size:(CGSize)size {
	Asset *asset = [Asset insertInContext:self];
	asset.assetIdentifier = assetIdentifier;
	asset.albumIdentifier = albumIdentifier;
	asset.numberOfObservations = texts.count;
	asset.numberOfLabels = labels.count;

	for (id<FIRVisionText> text in texts) {
		NSArray<id<FIRVisionText>> *lines = ret(text, lines);
		if (!lines)
			lines = @[ text ];

		for (id<FIRVisionText> line in lines) {
			Label *obj = [Label insertInContext:self];
			obj.albumIdentifier = albumIdentifier;
			obj.assetIdentifier = assetIdentifier;
			CGRect frame = line.frame;
			frame.origin.x /= size.width;
			frame.origin.y = 1.0 - (frame.origin.y + frame.size.height) / size.height;
			frame.size.width /= size.width;
			frame.size.height /= size.height;
			obj.frame = frame;
			obj.text = line.text;
		}
	}

	for (FIRVisionLabel *label in labels) {
		Label *obj = [Label insertInContext:self];
		obj.albumIdentifier = albumIdentifier;
		obj.assetIdentifier = assetIdentifier;
		obj.frame = label.frame;
		obj.confidence = label.confidence;
		obj.entityID = label.entityID;
		obj.text = label.label;
	}

	[self save];

	return asset;
}

@end

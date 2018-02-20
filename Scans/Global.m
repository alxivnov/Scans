//
//  Global.m
//  Scans
//
//  Created by Alexander Ivanov on 20.02.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "Global.h"

@implementation Global

- (NSString *)albumIdentifier {
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"albumIdentifier"];
}

- (void)setAlbumIdentifier:(NSString *)albumIdentifier {
	[[NSUserDefaults standardUserDefaults] setObject:albumIdentifier forKey:@"albumIdentifier"];
}

__synthesize(PHCachingImageManager *, manager, [[PHCachingImageManager alloc] init])

@synthesize screenSize = _screenSize;

- (CGSize)screenSize {
	if (CGSizeEqualToSize(_screenSize, CGSizeZero)) {
		CGFloat max = fmax([UIScreen mainScreen].nativeBounds.size.width, [UIScreen mainScreen].nativeBounds.size.height);
		_screenSize = CGSizeMake(max, max);
	}

	return _screenSize;
}

__static(Global *, global, [[self alloc] init])

@end

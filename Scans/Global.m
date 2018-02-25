//
//  Global.m
//  Scans
//
//  Created by Alexander Ivanov on 20.02.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "Global.h"

@implementation Global

__synthesize(NSDictionary *, affiliateInfo, [[NSDictionary dictionaryWithProvider:@"10603809" affiliate:@"1l3voBu"] dictionaryWithObject:@"write-review" forKey:@"action"])

__synthesize(PHCachingImageManager *, manager, [[PHCachingImageManager alloc] init])

@synthesize screenSize = _screenSize;

- (CGSize)screenSize {
	if (CGSizeEqualToSize(_screenSize, CGSizeZero)) {
		CGFloat max = fmax([UIScreen mainScreen].nativeBounds.size.width, [UIScreen mainScreen].nativeBounds.size.height);
		_screenSize = CGSizeMake(max, max);
	}

	return _screenSize;
}

- (NSString *)albumIdentifier {
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"albumIdentifier"];
}

- (void)setAlbumIdentifier:(NSString *)albumIdentifier {
	[[NSUserDefaults standardUserDefaults] setObject:albumIdentifier forKey:@"albumIdentifier"];
}

__static(Global *, global, [[self alloc] init])

@end

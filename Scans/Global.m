//
//  Global.m
//  Scans
//
//  Created by Alexander Ivanov on 20.02.2018.
//  Copyright © 2018 Alexander Ivanov. All rights reserved.
//

#import "Global.h"

#define __defaults(type, get, set) - (type)get { return [[NSUserDefaults standardUserDefaults] objectForKey:@"##get"]; } - (void)set:(type)get { [[NSUserDefaults standardUserDefaults] setObject:get forKey:@"##get"]; }

@interface Global ()
@property (assign, nonatomic) CGSize screenSize;
@end

@implementation Global

__synthesize(NSDictionary *, affiliateInfo, [[NSDictionary dictionaryWithProvider:@"10603809" affiliate:@"1l3voBu"] dictionaryWithObject:@"write-review" forKey:@"action"])

__synthesize(PHCachingImageManager *, manager, [[PHCachingImageManager alloc] init])

__synthesize(NSPersistentContainer *, container, [NSPersistentContainer persistentContainerWithName:@"Scans"])

- (instancetype)init {
	self = [super init];

	if (self) {
		[self.container loadPersistentStores:^(NSPersistentStoreDescription *description) {
			[description.URL.absoluteString log:@"Core Data URL:"];
		}];

		CGFloat max = fmax([UIScreen mainScreen].nativeBounds.size.width, [UIScreen mainScreen].nativeBounds.size.height);
		self.screenSize = CGSizeMake(max, max);
	}

	return self;
}

__static(Global *, global, [[self alloc] init])

@end

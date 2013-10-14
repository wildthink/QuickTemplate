//
//  NSFoundation+Extra.h
//  QuickTemplate
//
//  Created by Jason Jobe on 9/22/13.
//  Copyright (c) 2013 Jason Jobe. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *ScopeParentKey;

@interface NSArray (Stack)
- top;
@end


@interface NSMutableArray (Stack)
- pop;
- (void) push:item;
@end


@interface NSDictionary (ISScope)

- (NSDictionary*)popScope;
- (NSDictionary*)pushScope:(NSDictionary*)newValues;

@end
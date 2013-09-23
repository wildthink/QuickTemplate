//
//  NSArray+Stack.m
//  QuickTemplate
//
//  Created by Jason Jobe on 9/22/13.
//  Copyright (c) 2013 Jason Jobe. All rights reserved.
//

#import "NSArray+Stack.h"

@implementation NSArray (Stack)

- top {
    NSInteger ndx = [self count];
    return (ndx == 0 ? nil : [self objectAtIndex:(ndx - 1)]);
}

@end


@implementation NSMutableArray (Stack)

- pop {
    id last = [self lastObject];
    [self removeLastObject];
    return last;
}

- (void) push:item {
    [self addObject:item];
}

@end

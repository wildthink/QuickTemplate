//
//  WTIterator.m
//  WTTAL
//
//  Created by Jason Jobe on 10/30/05.
//  Copyright (c) 2005, 2013 Jason Jobe. All rights reserved.
//

#import "WTIterator.h"


@implementation WTIterator

+ iteratorWithArray:(NSArray*)nobs {
  return [[[self class] alloc] initWithArray:nobs];
}

- initWithArray:(NSArray*)nobs
{
  self.objects = nobs;
  self.count = [nobs count];
  return self;
}


-(BOOL)start { return (self.nextIndex == 1); }
-(BOOL)end   { return (self.nextIndex == self.count); }

-(BOOL)odd  { return (self.nextIndex % 2 ? YES : NO); }
-(BOOL)even { return (self.nextIndex % 2 ? NO : YES); }

-(NSUInteger)index { return self.nextIndex - 1; }
-(NSUInteger)number { return self.nextIndex; }
-(NSUInteger)length { return self.count; }

- nextObject
{
  if (self.nextIndex < self.count)
    return [self.objects objectAtIndex:(self.nextIndex++)];
  else
    return nil;
}

- currentObject
{
	NSInteger ndx;
	
	if (self.nextIndex == 0) {
		ndx = 0;
	} else if (self.nextIndex -1 < self.count) {
		ndx = self.nextIndex - 1;
	} else {
		ndx = -1;
	}
	return (ndx < 0 ? nil : [self.objects objectAtIndex:(self.nextIndex - 1)]);
}

@end


@implementation NSArray (WTIterator)
-(WTIterator*)iterator {
  return [WTIterator iteratorWithArray:self];
}
@end

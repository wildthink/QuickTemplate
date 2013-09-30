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
  objects = nobs;
  count = [nobs count];
  return self;
}


-(BOOL)start { return (nextIndex == 1); }
-(BOOL)end   { return (nextIndex == count); }

-(BOOL)odd  { return (nextIndex % 2 ? YES : NO); }
-(BOOL)even { return (nextIndex % 2 ? NO : YES); }

-(unsigned)index { return nextIndex - 1; }
-(unsigned)number { return nextIndex; }
-(unsigned)length { return count; }
-(unsigned)count { return count; }

- nextObject
{
  if (nextIndex < count)
    return [objects objectAtIndex:(nextIndex++)];
  else
    return nil;
}

- currentObject
{
	int ndx;
	
	if (nextIndex == 0) {
		ndx = 0;
	} else if (nextIndex -1 < count) {
		ndx = nextIndex - 1;
	} else {
		ndx = -1;
	}
	return (ndx < 0 ? nil : [objects objectAtIndex:(nextIndex - 1)]);
}

@end


@implementation NSArray (WTIterator)
-(WTIterator*)iterator {
  return [WTIterator iteratorWithArray:self];
}
@end

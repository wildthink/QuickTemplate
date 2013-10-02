//
//  WTIterator.h
//  WTTAL
//
//  Created by Jason Jobe on 10/30/05.
//  Copyright (c) 2005, 2013 Jason Jobe. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 The following information is available from a Loop Iterator:
 index - repetition number, starting from zero.
 number - repetition number, starting from one.
 even - true for even-indexed repetitions (0, 2, 4, ...).
 odd - true for odd-indexed repetitions (1, 3, 5, ...).
 start - true for the starting repetition (index 0).
 end - true for the ending, or final, repetition.
 length - length of the sequence, which will be the total number of repetitions.
 letter - count reps with lower-case letters: "a" - "z", "aa" - "az", "ba" - "bz", ..., "za" - "zz", "aaa" - "aaz", and so forth.
 Letter - upper-case version of letter.
   */


@interface WTIterator : NSObject

@property (strong, nonatomic) NSArray *objects;
@property (assign, nonatomic) NSUInteger nextIndex;
@property (assign, nonatomic) NSUInteger count;

+ iteratorWithArray:(NSArray*)nobs;
- initWithArray:(NSArray*)nobs;

-(BOOL)start;
-(BOOL)end;

-(BOOL)odd;
-(BOOL)even;
-(NSUInteger)index;
-(NSUInteger)number;
-(NSUInteger)length;

- currentObject;
- nextObject;

  // -(NSString*)letter;
  // -(NSString*)Letter;
  // -(NSString*)romanLetter;


@end

@interface NSArray (WTIterator)
-(WTIterator*)iterator;
@end

//
//  RHIntervalTreeUnitTests.m
//  RHIntervalTreeUnitTests
//
//  Created by Richard Heard on 28/02/13.
//  Copyright (c) 2013 Richard Heard. All rights reserved.
//

#import "RHIntervalTreeUnitTests.h"
#import "RHIntervalTree.h"


#include <stdlib.h>
#include <time.h>

@implementation RHIntervalTreeUnitTests

-(void)setUp{
    [super setUp];
    
    //seed random
    srand((unsigned)time(NULL));
    
}

-(void)tearDown{
    // Tear-down code here.
    
    [super tearDown];
}


-(void)testRHIntervalTreePerformanceAndAccuracy{

    NSMutableArray *intervals = [NSMutableArray array];
    NSMutableArray *queries = [NSMutableArray array];
    
    // generate a test set of target intervals
    for (int i = 0; i < 10000; ++i) {
        [intervals addObject:RHRandomInterval(100000, 1000, 100000+1, @"true")];
    }
    
    // and queries
    for (int i = 0; i < 10000; ++i) {
        [queries addObject:RHRandomInterval(100000, 1000, 100000+1, @"true")];
    }

    

    // using brute-force search
    NSMutableArray *bruteForceCounts = [NSMutableArray array];
    clock_t t0 = clock() / (CLOCKS_PER_SEC / 1000);

    for (RHInterval *query in queries) {
        NSMutableArray *results = [NSMutableArray array];
        for (RHInterval *interval in intervals) {
            if (interval.start >= query.start && interval.stop <= query.stop) {
                [results addObject:interval];
            }
        }
        [bruteForceCounts addObject:[NSNumber numberWithUnsignedInteger:results.count]];
    }
    clock_t t1 = clock() / (CLOCKS_PER_SEC / 1000);
    clock_t difference = t1 - t0;
    NSLog(@"brute force:\t %li ms", difference);
    
    
    // using the interval tree (contained)
    RHIntervalTree *tree = [[RHIntervalTree alloc] initWithIntervalObjects:intervals];
    NSMutableArray *treeCounts = [NSMutableArray array];
    t0 = clock() / (CLOCKS_PER_SEC / 1000);
    
    for (RHInterval *query in queries) {
        NSArray *results = [tree containedObjectsBetweenStart:query.start andStop:query.stop];
        [treeCounts addObject:[NSNumber numberWithUnsignedInteger:results.count]];
    }
    t1 = clock() / (CLOCKS_PER_SEC / 1000);
    difference = t1 - t0;
    NSLog(@"interval tree:\t %li ms", difference);
    

     // check that the same number of results are returned
    STAssertEquals(treeCounts.count, bruteForceCounts.count, @"should have same number of results");
    for (NSUInteger i = 0; i < treeCounts.count; ++i) {
        STAssertEqualObjects([treeCounts objectAtIndex:i], [bruteForceCounts objectAtIndex:i], @"should have same number of results");
    }
    
}


-(void)testRHInterval{
    NSString *testObject = @"test";
    
    RHInterval *interval = [RHInterval intervalWithRange:NSMakeRange(5, 5) object:testObject];
    STAssertTrue(interval.start == 5, @"start is not right");
    STAssertTrue(interval.stop == 9, @"end is not right");
    STAssertTrue(NSEqualRanges(interval.range, NSMakeRange(5, 5)), @"range is not right");
    STAssertEqualObjects(interval.object, testObject, @"object is not right");
        
    interval = [RHInterval intervalWithStart:5 stop:10 object:testObject];
    STAssertTrue(interval.start == 5, @"start is not right");
    STAssertTrue(interval.stop == 10, @"end is not right");
    STAssertTrue(NSEqualRanges(interval.range, NSMakeRange(5, 6)), @"range is not right");
    STAssertEqualObjects(interval.object, testObject, @"object is not right");
    
    STAssertThrows([RHInterval intervalWithRange:NSMakeRange(0, 0) object:nil], @"didnt throw exception for zero range and nil object");
    
}

-(void)testRHIntervalTreeMinMax{
    NSString *testObject = @"test";

    NSArray *intervals = [NSArray arrayWithObjects:
                         [RHInterval intervalWithRange:NSMakeRange(5, 5) object:testObject],
                         [RHInterval intervalWithRange:NSMakeRange(5, 5) object:testObject],
                         [RHInterval intervalWithRange:NSMakeRange(5, 5) object:testObject],
                         [RHInterval intervalWithRange:NSMakeRange(5, 5) object:testObject],
                         [RHInterval intervalWithRange:NSMakeRange(7, 100) object:testObject],
                         [RHInterval intervalWithRange:NSMakeRange(5, 5) object:testObject],
                         [RHInterval intervalWithRange:NSMakeRange(5, 5) object:testObject],
                         [RHInterval intervalWithRange:NSMakeRange(2, 5) object:testObject],
                         [RHInterval intervalWithRange:NSMakeRange(5, 5) object:testObject],
                         nil];
    
    RHIntervalTree *tree = [[RHIntervalTree alloc] initWithIntervalObjects:intervals];

    
    STAssertTrue(tree.minStart == 2, @"minStart is not right");
    STAssertTrue(tree.maxStop == 106, @"maxStop is not right");
    [tree release];
}


-(void)testRHIntervalTreeContained{
    NSString *testObject = @"test";
    NSString *overlappingObject = @"overlap";
    
    NSArray *intervals = [NSArray arrayWithObjects:
                          [RHInterval intervalWithRange:NSMakeRange(1, 1) object:testObject],
                          [RHInterval intervalWithRange:NSMakeRange(3, 1) object:testObject],
                          [RHInterval intervalWithRange:NSMakeRange(5, 1) object:testObject],
                          [RHInterval intervalWithRange:NSMakeRange(7, 1) object:testObject],
                          [RHInterval intervalWithRange:NSMakeRange(9, 1) object:testObject],
                          [RHInterval intervalWithRange:NSMakeRange(11,1) object:overlappingObject],
                          [RHInterval intervalWithRange:NSMakeRange(13,1) object:overlappingObject],
                          [RHInterval intervalWithRange:NSMakeRange(15,2) object:testObject],
                          [RHInterval intervalWithRange:NSMakeRange(12,2) object:overlappingObject],
                          nil];
    
    RHIntervalTree *tree = [[RHIntervalTree alloc] initWithIntervalObjects:intervals];

    
    NSArray *results = [tree containedObjectsBetweenStart:10 andStop:15];
    STAssertTrue(results.count == 3, @"count is not right");

    for (RHInterval *obj in results) {
        STAssertEqualObjects(overlappingObject, [obj object], @"contained object was not right");
    }
        
    [tree release];
}

-(void)testRHIntervalTreeOverlapping{
    NSString *testObject = @"test";
    NSString *overlappingObject = @"overlap";
    
    NSArray *intervals = [NSArray arrayWithObjects:
                          [RHInterval intervalWithRange:NSMakeRange(1, 1) object:testObject],
                          [RHInterval intervalWithRange:NSMakeRange(3, 1) object:testObject],
                          [RHInterval intervalWithRange:NSMakeRange(5, 1) object:testObject],
                          [RHInterval intervalWithRange:NSMakeRange(7, 1) object:testObject],
                          [RHInterval intervalWithRange:NSMakeRange(9, 1) object:testObject],
                          [RHInterval intervalWithRange:NSMakeRange(11,1) object:overlappingObject],
                          [RHInterval intervalWithRange:NSMakeRange(13,1) object:overlappingObject],
                          [RHInterval intervalWithRange:NSMakeRange(15,2) object:overlappingObject],
                          [RHInterval intervalWithRange:NSMakeRange(12,2) object:overlappingObject],
                          nil];
    
    RHIntervalTree *tree = [[RHIntervalTree alloc] initWithIntervalObjects:intervals];
    


    NSArray *results = [tree overlappingObjectsBetweenStart:10 andStop:15];
    STAssertTrue(results.count == 4, @"overlapping count is not right");
    
    for (RHInterval *obj in results) {
        STAssertEqualObjects(overlappingObject, [obj object], @"overlapping object was not right");
    }
    
    [tree release];
}



#pragma mark - misc

NSInteger RHRandomKey(NSInteger floor, NSInteger ceiling){
    NSInteger range = ceiling - floor;
    return floor + range * ((double) rand() / (double) (RAND_MAX + 1.0));
}

RHInterval * RHRandomInterval(NSInteger maxStart, NSInteger maxLength, NSInteger maxStop, id value){
    NSInteger start = RHRandomKey(0, maxStart);
    
    NSInteger stop = MIN(RHRandomKey(start, start + maxLength), maxStop);
    
    return [RHInterval intervalWithStart:start stop:stop object:value];
    
}

@end

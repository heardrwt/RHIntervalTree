//
//  RHIntervalTree.mm
//  RHIntervalTree
//
//  Created by Richard Heard on 28/02/13.
//  Copyright (c) 2013 Richard Heard. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions
//  are met:
//  1. Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//  notice, this list of conditions and the following disclaimer in the
//  documentation and/or other materials provided with the distribution.
//  3. The name of the author may not be used to endorse or promote products
//  derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
//  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
//  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//


#import "RHIntervalTree.h"
#import "IntervalTree.h"

@implementation RHIntervalTree{
    NSInteger _min;
    NSInteger _max;
    
    NSArray *_intervals;
    IntervalTree<RHInterval*> *_intervalTree;
}

-(id)initWithIntervalObjects:(NSArray *)intervals{
    if (!intervals) [NSException raise:NSInvalidArgumentException format:@"intervals must not be nil"];
    
    self = [super init];
    if (self){
        
        //setup our min and max values
        _min = NSIntegerMax;
        _max = NSIntegerMin;
        
        //hold onto the array until we are dealloc'd
        _intervals = [intervals copy];
        
        //setup the interval tree
        vector<Interval<RHInterval*> > intervalsVector;
        
        for (RHInterval *interval in _intervals) {
            intervalsVector.push_back(Interval<RHInterval*>(interval.start, interval.stop, interval));
            
            if (interval.stop > _max) _max = interval.stop;
            if (interval.start < _min) _min = interval.start;
        }
        
        _intervalTree = new IntervalTree<RHInterval*>(intervalsVector);
    }
    return self;
}

-(void)dealloc{
    delete _intervalTree;
    [_intervals release]; _intervals = nil;
    [super dealloc];
}

#pragma mark counts;
-(NSInteger)minStart{
    return _min;
}
-(NSInteger)maxStop{
    return _max;
}


#pragma mark - interval objects
-(NSArray*)allObjects{
    return _intervals;
}

-(NSArray*)containedObjectsInRange:(NSRange)range{
    return [self containedObjectsBetweenStart:range.location andStop:range.location + range.length];
}

-(NSArray*)containedObjectsBetweenStart:(NSInteger)start andStop:(NSInteger)stop{
    vector<Interval<RHInterval*> > resultsVector;
    _intervalTree->findContained(start, stop, resultsVector);
    
    NSMutableArray *mutableResults = [NSMutableArray arrayWithCapacity:resultsVector.size()];
    
    for (typename vector<Interval<RHInterval*> >::iterator i = resultsVector.begin(); i != resultsVector.end(); ++i) {
        Interval<RHInterval*> interval = *i;
        [mutableResults addObject:interval.value];
    }
    
    return [NSArray arrayWithArray:mutableResults];
}


#pragma mark - interval overlapping objects

-(NSArray*)overlappingObjectsInRange:(NSRange)range{
    return [self overlappingObjectsBetweenStart:range.location andStop:range.location + range.length];
}

-(NSArray*)overlappingObjectsBetweenStart:(NSInteger)start andStop:(NSInteger)stop{
    vector<Interval<RHInterval*> > resultsVector;
    _intervalTree->findOverlapping(start, stop, resultsVector);
    
    NSMutableArray *mutableResults = [NSMutableArray arrayWithCapacity:resultsVector.size()];
    
    for (typename vector<Interval<RHInterval*> >::iterator i = resultsVector.begin(); i != resultsVector.end(); ++i) {
        Interval<RHInterval*> interval = *i;
        [mutableResults addObject:interval.value];
    }
    
    return [NSArray arrayWithArray:mutableResults];
}

@end

@implementation RHInterval{
    NSInteger _start;
    NSInteger _stop;
    id<NSObject> _object;
}

+(id)intervalWithRange:(NSRange)range object:(id<NSObject>)object{
    if (range.location == NSNotFound) [NSException raise:NSInvalidArgumentException format:@"range.location must not be NSNotFound"];
    if (range.length == 0) [NSException raise:NSInvalidArgumentException format:@"range.length must not be 0"];
    
    return [self intervalWithStart:range.location stop:range.location + range.length - 1 object:object];
}

+(id)intervalWithStart:(NSInteger)start stop:(NSInteger)stop object:(id)object{
    return  [[[RHInterval alloc] initWithStart:start stop:stop object:object] autorelease];
}

-(id)initWithStart:(NSInteger)start stop:(NSInteger)stop object:(id)object{
    if (start > stop) [NSException raise:NSInvalidArgumentException format:@"start must be greater than stop"];
    if (!object) [NSException raise:NSInvalidArgumentException format:@"object can not be nil"];
    
    self = [super init];
    if (self){
        _start = start;
        _stop = stop;
        _object = [object retain];
    }
    return self;
}

-(NSInteger)start{
    return _start;
}

-(NSInteger)stop{
    return _stop;
}

-(id<NSObject>)object{
    return _object;
}

-(NSRange)range{
    //5, 10 should be (5, 6)
    NSRange range = NSMakeRange(_start, (_stop - _start) + 1);
    return range;
}

-(NSString*)description{
    return [NSString stringWithFormat:@"%@ (%li->%li) %@", [super description], (long)_start, (long)_stop, _object];
}

-(void)dealloc{
    [_object release]; _object = nil;
    [super dealloc];
}

@end


/*
Copyright 2021 happn

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

@import XCTest;
@import CoreData;

#import "HPNCoreDataUpdatesAggregator.h"



@interface HPNCoreDataUpdatesAggregator_Tests : XCTestCase {
	NSMutableArray *modifiedArray;
	void (^aggregatorHandler)(HPNCoreDataUpdate *update);
}

@end

@implementation HPNCoreDataUpdatesAggregator (Conveniences)

- (void)addDeleteAtIndex:(NSInteger)idx
{
	[self addChangeForObject:nil atIndexPath:[NSIndexPath indexPathForItem:idx inSection:0] changeType:NSFetchedResultsChangeDelete newIndexPath:nil];
}

- (void)addInsertAtIndex:(NSInteger)idx withObject:(id)object
{
	[self addChangeForObject:object atIndexPath:nil changeType:NSFetchedResultsChangeInsert newIndexPath:[NSIndexPath indexPathForItem:idx inSection:0]];
}

- (void)addMoveFromIndex:(NSInteger)sourceIdx toIndex:(NSInteger)destIdx
{
	[self addChangeForObject:nil atIndexPath:[NSIndexPath indexPathForItem:sourceIdx inSection:0] changeType:NSFetchedResultsChangeMove newIndexPath:[NSIndexPath indexPathForItem:destIdx inSection:0]];
}

@end

@implementation HPNCoreDataUpdatesAggregator_Tests

- (void)setUp
{
	[super setUp];
	
	__weak HPNCoreDataUpdatesAggregator_Tests *weakSelf = self;
	aggregatorHandler = ^(HPNCoreDataUpdate *update) {
		HPNCoreDataUpdatesAggregator_Tests *strongSelf = weakSelf;
		if (strongSelf == nil) return;
		switch (update.type) {
			case HPNAggregatedChangeTypeInsert: [strongSelf->modifiedArray insertObject:update.object atIndex:update.destIdx]; break;
			case HPNAggregatedChangeTypeDelete: [strongSelf->modifiedArray removeObjectAtIndex:update.sourceIdx]; break;
			case HPNAggregatedChangeTypeMove: {
				NSUInteger sourceIdx = update.sourceIdx;
				NSUInteger destinationIdx = update.destIdx;
				id obj = strongSelf->modifiedArray[sourceIdx];
				[strongSelf->modifiedArray removeObjectAtIndex:sourceIdx];
				[strongSelf->modifiedArray insertObject:obj atIndex:destinationIdx];
				break;
			}
			case HPNAggregatedChangeTypeUpdate: /* nop */ break;
		}
	};
}

- (void)tearDown
{
	[super tearDown];
}

- (NSMutableArray *)inputArrayFromString:(NSString *)str
{
	NSMutableArray *res = [NSMutableArray arrayWithCapacity:str.length];
	for (NSUInteger i = 0; i < str.length; ++i)
		[res addObject:[str substringWithRange:NSMakeRange(i, 1)]];
	
	return res;
}

- (void)testBasicInsert
{
	HPNCoreDataUpdatesAggregator *aggregator = [HPNCoreDataUpdatesAggregator new];
	
	modifiedArray        = [self inputArrayFromString:@"abc"];
	NSArray *destination = [self inputArrayFromString:@"a1bc"];
	[aggregator addInsertAtIndex:1 withObject:@"1"];
	
	[aggregator iterateAggregatedChangesWithHandler:aggregatorHandler];
	XCTAssertEqualObjects(modifiedArray, destination);
}

- (void)testBasicDelete
{
	HPNCoreDataUpdatesAggregator *aggregator = [HPNCoreDataUpdatesAggregator new];
	
	modifiedArray        = [self inputArrayFromString:@"abc"];
	NSArray *destination = [self inputArrayFromString:@"ac"];
	[aggregator addDeleteAtIndex:1];
	
	[aggregator iterateAggregatedChangesWithHandler:aggregatorHandler];
	XCTAssertEqualObjects(modifiedArray, destination);
}

- (void)testTwoInserts
{
	HPNCoreDataUpdatesAggregator *aggregator = [HPNCoreDataUpdatesAggregator new];
	
	modifiedArray        = [self inputArrayFromString:@"abc"];
	NSArray *destination = [self inputArrayFromString:@"a1b3c"];
	[aggregator addInsertAtIndex:1 withObject:@"1"];
	[aggregator addInsertAtIndex:3 withObject:@"3"];
	
	[aggregator iterateAggregatedChangesWithHandler:aggregatorHandler];
	XCTAssertEqualObjects(modifiedArray, destination);
}

- (void)testTwoDeletes
{
	HPNCoreDataUpdatesAggregator *aggregator = [HPNCoreDataUpdatesAggregator new];
	
	modifiedArray        = [self inputArrayFromString:@"abc"];
	NSArray *destination = [self inputArrayFromString:@"a"];
	[aggregator addDeleteAtIndex:1];
	[aggregator addDeleteAtIndex:2];
	
	[aggregator iterateAggregatedChangesWithHandler:aggregatorHandler];
	XCTAssertEqualObjects(modifiedArray, destination);
}

- (void)testBasicMove
{
	HPNCoreDataUpdatesAggregator *aggregator = [HPNCoreDataUpdatesAggregator new];
	
	modifiedArray        = [self inputArrayFromString:@"abc"];
	NSArray *destination = [self inputArrayFromString:@"cab"];
	[aggregator addMoveFromIndex:2 toIndex:0];
	
	[aggregator iterateAggregatedChangesWithHandler:aggregatorHandler];
	XCTAssertEqualObjects(modifiedArray, destination);
}

- (void)testBasicTwoInsertsTwoFalseMoves
{
	HPNCoreDataUpdatesAggregator *aggregator = [HPNCoreDataUpdatesAggregator new];
	
	modifiedArray        = [self inputArrayFromString:@"ca"];
	NSArray *destination = [self inputArrayFromString:@"dcba"];
	[aggregator addInsertAtIndex:2 withObject:@"b"];
	[aggregator addInsertAtIndex:0 withObject:@"d"];
	[aggregator addMoveFromIndex:0 toIndex:1];
	[aggregator addMoveFromIndex:1 toIndex:3];
	
	[aggregator iterateAggregatedChangesWithHandler:aggregatorHandler];
	XCTAssertEqualObjects(modifiedArray, destination);
}

- (void)testBasicTwoDeletesTwoFalseMoves
{
	HPNCoreDataUpdatesAggregator *aggregator = [HPNCoreDataUpdatesAggregator new];
	
	modifiedArray        = [self inputArrayFromString:@"dcba"];
	NSArray *destination = [self inputArrayFromString:@"ca"];
	[aggregator addMoveFromIndex:1 toIndex:0];
	[aggregator addMoveFromIndex:3 toIndex:1];
	[aggregator addDeleteAtIndex:2];
	[aggregator addDeleteAtIndex:0];
	
	[aggregator iterateAggregatedChangesWithHandler:aggregatorHandler];
	XCTAssertEqualObjects(modifiedArray, destination);
}

- (void)testInsertAndMoveAfterInsert
{
	HPNCoreDataUpdatesAggregator *aggregator = [HPNCoreDataUpdatesAggregator new];
	
	modifiedArray        = [self inputArrayFromString:@"abc"];
	NSArray *destination = [self inputArrayFromString:@"a1cb"];
	[aggregator addInsertAtIndex:1 withObject:@"1"];
	[aggregator addMoveFromIndex:2 toIndex:2];
	
	[aggregator iterateAggregatedChangesWithHandler:aggregatorHandler];
	XCTAssertEqualObjects(modifiedArray, destination);
}

- (void)testInsertAndMoveFromBeforeToAfterInsert
{
	HPNCoreDataUpdatesAggregator *aggregator = [HPNCoreDataUpdatesAggregator new];
	
	modifiedArray = [self inputArrayFromString:@"abc"];
	NSArray *destination = [self inputArrayFromString:@"b1ac"];
	[aggregator addInsertAtIndex:1 withObject:@"1"];
	[aggregator addMoveFromIndex:0 toIndex:2];
	
	[aggregator iterateAggregatedChangesWithHandler:aggregatorHandler];
	XCTAssertEqualObjects(modifiedArray, destination);
}

- (void)testInsertAndMoveFromAfterToBeforeInsert
{
	HPNCoreDataUpdatesAggregator *aggregator = [HPNCoreDataUpdatesAggregator new];
	
	modifiedArray        = [self inputArrayFromString:@"abc"];
	NSArray *destination = [self inputArrayFromString:@"c1ab"];
	[aggregator addInsertAtIndex:1 withObject:@"1"];
	[aggregator addMoveFromIndex:2 toIndex:0];
	
	[aggregator iterateAggregatedChangesWithHandler:aggregatorHandler];
	XCTAssertEqualObjects(modifiedArray, destination);
}

@end

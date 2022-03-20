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

@import UIKit.UICollectionView;

#import "HPNCoreDataUpdatesAggregator.h"



@interface HPNCoreDataUpdate () /* Private, but adds properties, cannot be a named category. */

+ (NSArray *)coreDataUpdatesWithObject:(id)object type:(NSFetchedResultsChangeType)type sourceIndexPath:(NSIndexPath *)sourceIndexPath destinationIndexPath:(NSIndexPath *)destinationIndexPath;

+ (instancetype)atomicCoreDataUpdateWithObject:(id)object type:(NSFetchedResultsChangeType)type sourceIndex:(NSUInteger)sourceIndex destinationIndex:(NSUInteger)destinationIndex;
+ (instancetype)atomicCoreDataUpdateWithObject:(id)object type:(NSFetchedResultsChangeType)type sourceIndexPath:(NSIndexPath *)sourceIndexPath destinationIndexPath:(NSIndexPath *)destinationIndexPath;

@property(nonatomic, weak) HPNCoreDataUpdate *linkedUpdateForMove;
@property(nonatomic, readonly) BOOL isMove;

/* Only used by the algorithm to aggregate the updates. Defaults to NSNotFound. */
@property(nonatomic, assign) NSUInteger __idx;

/* Requires receiver to be a decomposed moved update. */
- (HPNCoreDataUpdate *)atomicMoveUpdate;

@end



@implementation HPNCoreDataUpdate

+ (NSArray *)coreDataUpdatesWithObject:(id)object type:(NSFetchedResultsChangeType)type sourceIndexPath:(NSIndexPath *)sourceIndexPath destinationIndexPath:(NSIndexPath *)destinationIndexPath
{
	switch (type) {
		case NSFetchedResultsChangeUpdate:
		case NSFetchedResultsChangeInsert:
		case NSFetchedResultsChangeDelete:
			return @[[self atomicCoreDataUpdateWithObject:object type:type sourceIndexPath:sourceIndexPath destinationIndexPath:destinationIndexPath]];
		case NSFetchedResultsChangeMove: {
			HPNCoreDataUpdate *update1 = [HPNCoreDataUpdate atomicCoreDataUpdateWithObject:object type:NSFetchedResultsChangeDelete sourceIndexPath:sourceIndexPath destinationIndexPath:nil];
			HPNCoreDataUpdate *update2 = [HPNCoreDataUpdate atomicCoreDataUpdateWithObject:object type:NSFetchedResultsChangeInsert sourceIndexPath:nil             destinationIndexPath:destinationIndexPath];
			update1.linkedUpdateForMove = update2;
			update2.linkedUpdateForMove = update1;
			return @[update1, update2];
		}
		default: NSAssert(NO, @"***** ERROR: Unexpected type %"NSUINT_FMT, type);
	}
	return nil;
}

+ (instancetype)atomicCoreDataUpdateWithObject:(id)object type:(NSFetchedResultsChangeType)type sourceIndex:(NSUInteger)sourceIndex destinationIndex:(NSUInteger)destinationIndex
{
	HPNCoreDataUpdate *res = [self new];
	res.object = object;
	switch (type) {
		case NSFetchedResultsChangeUpdate: res.type = HPNAggregatedChangeTypeUpdate; break;
		case NSFetchedResultsChangeInsert: res.type = HPNAggregatedChangeTypeInsert; break;
		case NSFetchedResultsChangeDelete: res.type = HPNAggregatedChangeTypeDelete; break;
		case NSFetchedResultsChangeMove: res.type = HPNAggregatedChangeTypeMove; break;
		default: NSAssert(NO, @"***** ERROR: Unexpected type %"NSUINT_FMT, type);
	}
	res.sourceIdx = sourceIndex;
	res.destIdx = destinationIndex;
	res.__idx = NSNotFound;
	return res;
}

+ (instancetype)atomicCoreDataUpdateWithObject:(id)object type:(NSFetchedResultsChangeType)type sourceIndexPath:(NSIndexPath *)sourceIndexPath destinationIndexPath:(NSIndexPath *)destinationIndexPath
{
	NSParameterAssert(sourceIndexPath.section == 0 && destinationIndexPath.section == 0);
	return [self atomicCoreDataUpdateWithObject:object type:type
											  sourceIndex:(sourceIndexPath? sourceIndexPath.item: NSNotFound)
										destinationIndex:(destinationIndexPath? destinationIndexPath.item: NSNotFound)];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"HPNCoreDataUpdate<%p>, %"NSUINT_FMT", from %"NSUINT_FMT" to %"NSUINT_FMT" --> %p",
			  self, self.type, self.sourceIdx, self.destIdx, self.linkedUpdateForMove];
}

- (BOOL)isMove
{
	return (self.linkedUpdateForMove != nil);
}

- (HPNCoreDataUpdate *)atomicMoveUpdate
{
	NSParameterAssert(self.linkedUpdateForMove != nil);
	NSAssert(self.linkedUpdateForMove.linkedUpdateForMove == self, @"***** ERROR: I'm invalid (linked update of linked update is not me)! %@", self);
	NSAssert(self.object == self.linkedUpdateForMove.object, @"***** ERROR: I'm invalid (linked object != my object)! %@ - %@", self, self.linkedUpdateForMove);
	HPNCoreDataUpdate *delete = (self.type == HPNAggregatedChangeTypeDelete? self: self.linkedUpdateForMove);
	HPNCoreDataUpdate *insert = (self.type == HPNAggregatedChangeTypeInsert? self: self.linkedUpdateForMove);
	NSAssert(delete.type == HPNAggregatedChangeTypeDelete, @"***** ERROR: I'm invalid (delete is not delete)! %@ - %@", self, delete);
	NSAssert(insert.type == HPNAggregatedChangeTypeInsert, @"***** ERROR: I'm invalid (insert is not insert)! %@ - %@", self, insert);
	return [self.class atomicCoreDataUpdateWithObject:insert.object type:NSFetchedResultsChangeMove sourceIndex:delete.sourceIdx destinationIndex:insert.destIdx];
}

@end



@implementation HPNCoreDataUpdatesAggregator

- (id)init
{
	if ((self = [super init]) != nil) {
		_keepObject = YES;
		currentStaticUpdates = [NSMutableArray arrayWithCapacity:50];
		currentMovingUpdates = [NSMutableArray arrayWithCapacity:50];
	}
	
	return self;
}

- (void)addChangeForObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath changeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
	NSParameterAssert(indexPath.section == 0 && newIndexPath.section == 0);
	if (!self.keepObject) anObject = nil;
	switch (type) {
		case NSFetchedResultsChangeUpdate: [currentStaticUpdates addObject:[HPNCoreDataUpdate atomicCoreDataUpdateWithObject:anObject type:type sourceIndexPath:indexPath destinationIndexPath:newIndexPath]]; break;
		case NSFetchedResultsChangeInsert: [currentMovingUpdates addObject:[HPNCoreDataUpdate atomicCoreDataUpdateWithObject:anObject type:type sourceIndexPath:indexPath destinationIndexPath:newIndexPath]]; break;
		case NSFetchedResultsChangeDelete: [currentMovingUpdates addObject:[HPNCoreDataUpdate atomicCoreDataUpdateWithObject:anObject type:type sourceIndexPath:indexPath destinationIndexPath:newIndexPath]]; break;
		case NSFetchedResultsChangeMove:   [currentMovingUpdates addObjectsFromArray:[HPNCoreDataUpdate coreDataUpdatesWithObject:anObject type:type sourceIndexPath:indexPath destinationIndexPath:newIndexPath]]; break;
		default:
			/* The NSAssert below is INVALID! Apparently, on iOS 8, when the app is
			 * compiled with Xcode 7, we receive changes of type 0, which is
			 * invalid... */
//			NSAssert(NO, @"***** ERROR: Unknown change type %"NSUINT_FMT, type);
			;
	}
}

- (void)removeAllChanges
{
	[currentStaticUpdates removeAllObjects];
	[currentMovingUpdates removeAllObjects];
}

#define ASSERT_VALID_INDEX(idx)   NSAssert(idx != NSNotFound, @"***** INTERNAL ERROR (invalid index path %"NSUINT_FMT")", idx)
#define ASSERT_INVALID_INDEX(idx) NSAssert(idx == NSNotFound, @"***** INTERNAL ERROR   (valid index path %"NSUINT_FMT")", idx)

- (void)iterateAggregatedChangesWithHandler:(void (^)(HPNCoreDataUpdate *update))handler
{
	/* ********* Let's call the updates. ********* */
	for (HPNCoreDataUpdate *update in currentStaticUpdates) {
		/* The assert below is WRONG!
		 * See: http://stackoverflow.com/a/32213076 */
//		ASSERT_INVALID_INDEX(update.destinationIndex);
		ASSERT_VALID_INDEX(update.sourceIdx);
		
		handler(update);
	}
	
	/* ********* Let's sort/reindex the inserts, deletes and moves. ********* */
	[currentMovingUpdates sortUsingComparator:^NSComparisonResult(HPNCoreDataUpdate *obj1, HPNCoreDataUpdate *obj2) {
		NSParameterAssert([obj1 isKindOfClass:HPNCoreDataUpdate.class]);
		NSParameterAssert([obj2 isKindOfClass:HPNCoreDataUpdate.class]);
		NSParameterAssert(obj1.type == HPNAggregatedChangeTypeDelete || obj1.type == HPNAggregatedChangeTypeInsert);
		NSParameterAssert(obj2.type == HPNAggregatedChangeTypeDelete || obj2.type == HPNAggregatedChangeTypeInsert);
		
		if (obj1.type == HPNAggregatedChangeTypeDelete && obj2.type == HPNAggregatedChangeTypeInsert) return NSOrderedAscending;
		if (obj1.type == HPNAggregatedChangeTypeInsert && obj2.type == HPNAggregatedChangeTypeDelete) return NSOrderedDescending;
		
		if (obj1.type == HPNAggregatedChangeTypeInsert) {
			NSParameterAssert(obj1.destIdx != obj2.destIdx);
			NSParameterAssert(obj2.type == HPNAggregatedChangeTypeInsert);
			if (obj1.destIdx < obj2.destIdx) return NSOrderedAscending;
			return NSOrderedDescending;
		}
		NSParameterAssert(obj1.type == HPNAggregatedChangeTypeDelete && obj2.type == HPNAggregatedChangeTypeDelete);
		NSParameterAssert(obj1.sourceIdx != obj2.sourceIdx);
		if (obj1.sourceIdx < obj2.sourceIdx) return NSOrderedDescending;
		return NSOrderedAscending;
	}];
	NSUInteger i = 0, n = currentMovingUpdates.count;
	while (i < n) {
		HPNCoreDataUpdate *update = currentMovingUpdates[i];
		NSAssert(update.__idx == NSNotFound || update.__idx == i, @"***** INTERNAL ERROR: Invalid idx.");
		update.__idx = i;
		
		if (update.type == HPNAggregatedChangeTypeInsert && update.isMove && update.linkedUpdateForMove.__idx != i-1) {
			NSAssert(i > 0, @"***** INTERNAL LOGIC ERROR");
			NSAssert(update.__idx == i, @"***** INTERNAL LOGIC ERROR");
			NSAssert(update.__idx > update.linkedUpdateForMove.__idx + 1, @"***** INTERNAL ERROR");
			NSUInteger destIdx = update.linkedUpdateForMove.__idx;
			for (NSUInteger j = i; j > destIdx + 1; --j) {
				NSAssert(currentMovingUpdates[j] == update, @"***** INTERNAL LOGIC ERROR");
				HPNCoreDataUpdate *swappedUpdate = currentMovingUpdates[j-1];
				if (swappedUpdate.type == HPNAggregatedChangeTypeInsert && update.type == HPNAggregatedChangeTypeInsert) {
					if (update.destIdx <= swappedUpdate.destIdx) ++swappedUpdate.destIdx;
					else {
						NSAssert(update.destIdx > 0, @"***** INTERNAL LOGIC ERROR");
						--update.destIdx;
					}
				} else if (swappedUpdate.type == HPNAggregatedChangeTypeInsert && update.type == HPNAggregatedChangeTypeDelete) {
					if (update.sourceIdx > swappedUpdate.destIdx) ++update.sourceIdx;
					else {
						NSAssert(update.sourceIdx < swappedUpdate.destIdx, @"***** INTERNAL LOGIC ERROR"); /* Equality case is not possible. */
						NSAssert(swappedUpdate.destIdx > 0, @"***** INTERNAL LOGIC ERROR");
						--swappedUpdate.destIdx;
					}
				} else if (swappedUpdate.type == HPNAggregatedChangeTypeDelete && update.type == HPNAggregatedChangeTypeInsert) {
					if (swappedUpdate.sourceIdx >= update.destIdx) ++swappedUpdate.sourceIdx;
					else                                           ++update.destIdx;
				} else {
					NSAssert(swappedUpdate.type == HPNAggregatedChangeTypeDelete && update.type == HPNAggregatedChangeTypeDelete, @"***** INTERNAL LOGIC ERROR");
					if      (swappedUpdate.sourceIdx < update.sourceIdx) ++update.sourceIdx;
					else if (swappedUpdate.sourceIdx > update.sourceIdx) {
						NSAssert(swappedUpdate.sourceIdx > 0, @"***** INTERNAL LOGIC ERROR");
						--swappedUpdate.sourceIdx;
					}
					/* In case of equality, there's nothing to do. */
				}
				[currentMovingUpdates exchangeObjectAtIndex:j withObjectAtIndex:j-1];
			}
		}
		++i;
	}
	i = 0;
	while (i < n) {
		HPNCoreDataUpdate *update = currentMovingUpdates[i++];
		if (!update.isMove) handler(update);
		else {
			NSAssert(update.linkedUpdateForMove == currentMovingUpdates[i], @"***** INTERNAL LOGIC ERROR");
			handler(update.atomicMoveUpdate);
			++i;
		}
	}
	
	/* ********* Finally, let's remove all the registered changes as they are applied. ********* */
	[self removeAllChanges];
}

@end

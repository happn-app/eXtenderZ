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

@import CoreData;
@import Foundation;



typedef NS_CLOSED_ENUM(NSUInteger, HPNAggregatedChangeType) {
	HPNAggregatedChangeTypeUpdate, /* sourceIdx is set; ignore destIdx. */
	HPNAggregatedChangeTypeInsert, /* destIdx is set;   ignore sourceIdx. */
	HPNAggregatedChangeTypeDelete, /* sourceIdx is set; ignore destIdx. */
	HPNAggregatedChangeTypeMove    /* sourceIdx and destIdx are set. */
};



@interface HPNCoreDataUpdate : NSObject

@property(nonatomic, retain) id object;

@property(nonatomic, assign) HPNAggregatedChangeType type;

@property(nonatomic, assign) NSUInteger sourceIdx;
@property(nonatomic, assign) NSUInteger destIdx;

@end



/* Currently only supports sources with one section only (expects all index
 * paths to have section == 0).
 * Support for more sections or section updates should not be very hard to add
 * but I can't test it. */
@interface HPNCoreDataUpdatesAggregator : NSObject {
	NSMutableArray *currentMovingUpdates;
	NSMutableArray *currentStaticUpdates;
}

/* YES by default. If NO, object will always be nil in the handler. */
@property(nonatomic, assign) BOOL keepObject;

- (void)addChangeForObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath changeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath;
- (void)removeAllChanges;

/* If you have an NSMutableArray, you can simply update, delete, move and insert
 * the elements directly at the indexes given by the handler and you will be
 * good to go!
 * For the moves, delete source, then insert at destination (in this order). Do
 * NOT exchanges source and destination! */
- (void)iterateAggregatedChangesWithHandler:(void (^)(HPNCoreDataUpdate *update))handler;

@end

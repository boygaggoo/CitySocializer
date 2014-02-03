//
//  User.h
//  CitySocializer
//
//  Created by OsamaMac on 2/3/14.
//  Copyright (c) 2014 OsamaMac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Actions, Followed;

@interface User : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *done;
@property (nonatomic, retain) NSSet *followed;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addDoneObject:(Actions *)value;
- (void)removeDoneObject:(Actions *)value;
- (void)addDone:(NSSet *)values;
- (void)removeDone:(NSSet *)values;

- (void)addFollowedObject:(Followed *)value;
- (void)removeFollowedObject:(Followed *)value;
- (void)addFollowed:(NSSet *)values;
- (void)removeFollowed:(NSSet *)values;

@end

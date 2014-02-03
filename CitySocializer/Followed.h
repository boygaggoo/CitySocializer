//
//  Followed.h
//  CitySocializer
//
//  Created by OsamaMac on 2/3/14.
//  Copyright (c) 2014 OsamaMac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Followed : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * pic;
@property (nonatomic, retain) User *followedBy;

@end

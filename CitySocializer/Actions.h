//
//  Actions.h
//  CitySocializer
//
//  Created by OsamaMac on 2/3/14.
//  Copyright (c) 2014 OsamaMac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Actions : NSManagedObject

@property (nonatomic, retain) NSString * actionDesc;
@property (nonatomic, retain) NSDate * actionDate;
@property (nonatomic, retain) User *doneBy;

@end

//
//  MyActionsViewController.h
//  CitySocializer
//
//  Created by OsamaMac on 2/3/14.
//  Copyright (c) 2014 OsamaMac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataTableViewController.h"

@interface MyActionsViewController : UITableViewController

/** The variables used to fetch and manage the core data throught the application **/
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;


@end

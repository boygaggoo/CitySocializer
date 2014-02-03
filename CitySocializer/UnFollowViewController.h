//
//  UnFollowViewController.h
//  CitySocializer
//
//  Created by OsamaMac on 2/3/14.
//  Copyright (c) 2014 OsamaMac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Accounts/Accounts.h>
#import "CoreDataTableViewController.h"
#import "User.h"

@interface UnFollowViewController : UITableViewController<UIActionSheetDelegate>{
    NSArray* accounts;/*This is where i save all the twitter accounts registered*/
    
    ACAccountStore *accountStore;/*This is the accountStore given by the OS to access the different accounts and i specify i need twitter ones*/
    
    int accountIndex; /*This is the index that was passed from the account chooser screen*/
    
    User* currentUser; /** Used to get reference for the current use in the core data so we can store his actions and all users he followed for further notice**/

}


/** The variables used to fetch and manage the core data throught the application **/
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) IBOutlet UIView *waitView;
@property (strong, nonatomic) IBOutlet UILabel *waitLabel;

@end

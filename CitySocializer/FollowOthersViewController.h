//
//  FollowOthersViewController.h
//  CitySocializer
//  This class is responsible for showing the user a new set of another registered accounts, this is used for him so he can follow them (All, or one by one).
//  When the user, follows one he follows him and on the server side the other on follows the user instantly.
//  Created by OsamaMac on 2/3/14.
//  Copyright (c) 2014 OsamaMac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Accounts/Accounts.h>
#import "TWAPIManager.h"
#import "CoreDataTableViewController.h"
#import "User.h"

@interface FollowOthersViewController : UITableViewController<NSURLConnectionDataDelegate>
{
    NSArray* accounts;/*This is where i save all the twitter accounts registered*/
    
    ACAccountStore *accountStore;/*This is the accountStore given by the OS to access the different accounts and i specify i need twitter ones*/
    
    int accountIndex; /*This is the index that was passed from the account chooser screen*/
    
    /*When doing the reverse OAuth process, we get two values, the oauth Token for the selected account and its secret Token*/
    NSString *oauthToken;
    NSString *oauthTokenSecret;
    
    NSURLConnection* loadNewProfilesConnection; /*This is the connection that asks the server for new set of profiles that i can follow*/

    NSArray* newPoriflesArray; /* This array that holds the profiles passed back from the server*/
    
    NSURLConnection* followThemConnection; /*This is the connection that asks the server to make the profiles follow me and i follow them as well*/
    
    TWAPIManager *apiManager; /*This is used to do the reverse OAuth process*/
    
    NSURLConnection* registerMeConnection; /*This is the connection that stores the login in credentionals to the server database */
    
    User* currentUser; /** Used to get reference for the current use in the core data so we can store his actions and all users he followed for further notice**/
}

@property (strong, nonatomic) IBOutlet UIView *waitView;
@property (strong, nonatomic) IBOutlet UIView *theHeaderView;
@property (strong, nonatomic) IBOutlet UIView *theFooterView;
@property (strong, nonatomic) IBOutlet UILabel *waitLabel;
@property (strong, nonatomic) IBOutlet UIView *followingView;
/** The variables used to fetch and manage the core data throught the application **/
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (weak, nonatomic) IBOutlet UIProgressView *followingProgess;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *followThemButton;
- (IBAction)followThemClicked:(id)sender;

@end

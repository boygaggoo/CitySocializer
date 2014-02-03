//
//  UnFollowViewController.m
//  CitySocializer
//
//  Created by OsamaMac on 2/3/14.
//  Copyright (c) 2014 OsamaMac. All rights reserved.
//

#import <Twitter/Twitter.h>
#import "UnFollowViewController.h"
#import "AsyncImageView.h"
#import "Actions.h"
#import "Followed.h"

@interface UnFollowViewController ()

@end

@implementation UnFollowViewController

@synthesize fetchedResultsController = __fetchedResultsController;
@synthesize managedObjectContext = __managedObjectContext;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[self.navigationController view] addSubview:_waitView];
    _waitView.frame = CGRectMake(0, 0, _waitView.frame.size.width, _waitView.frame.size.height);

    
    accountIndex = [[[NSUserDefaults standardUserDefaults]stringForKey:@"accountIndex"]intValue];
    
    accounts = [[NSArray alloc]init];
    accountStore = [[ACAccountStore alloc] init];
    
    NSString *ver = [[UIDevice currentDevice] systemVersion];
    if ([ver floatValue] < 7.0)
    {
        [[UIBarButtonItem appearance] setTintColor:[UIColor colorWithRed:0/255 green:90.0/255 blue:120.0/255 alpha:1]];
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav-bar-img.png"] forBarMetrics:UIBarMetricsDefault];
    }
    
    
    
    
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
        if(granted){
            // Get the list of Twitter accounts.
            accounts = [accountStore accountsWithAccountType:accountType];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self setupFetchedResultsControllerUser:[[accounts objectAtIndex:accountIndex] username]];
                if ([[self.fetchedResultsController fetchedObjects] count] > 0) {
                    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                    currentUser = [self.fetchedResultsController objectAtIndexPath:indexPath];
                    [self setupFetchedResultsController];
                    
                }
                dispatch_async(dispatch_get_main_queue(), ^(void) {});
            });
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.fetchedResultsController)
    {
        return [[self.fetchedResultsController fetchedObjects] count];
    }else
    {
        return 0;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100.0f;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ProfilesCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    CGRect frame;
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        AsyncImageView* oldImage = (AsyncImageView*)[ cell.contentView viewWithTag:1];
        frame = oldImage.frame;
        [oldImage removeFromSuperview];
        
    }else {
        AsyncImageView* oldImage = (AsyncImageView*) [cell.contentView viewWithTag:1];
        frame = oldImage.frame;
        [oldImage removeFromSuperview];
    }
    
    
    Followed* user = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    [(UILabel*)[cell viewWithTag:2]setText:[user name]];
    AsyncImageView* asyncImage = [[AsyncImageView alloc]
                                  initWithFrame:frame];
	asyncImage.tag = 1;
    
	NSURL* url = [[NSURL alloc] initWithString:[user pic]];
	[asyncImage loadImageFromURL:url];
	[cell.contentView addSubview:asyncImage];
    UIImageView *theFrame = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"frame-img.png"]];
    
    theFrame.frame = CGRectMake(0, 0, 64, 64);
    theFrame.center = asyncImage.center;
    [cell.contentView addSubview:asyncImage];
    [cell.contentView addSubview:theFrame];
    
    [_waitView removeFromSuperview];

    return cell;
}

#pragma mark table delegate

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        [[self.navigationController view] addSubview:_waitView];
        _waitView.frame = CGRectMake(0, 0, _waitView.frame.size.width, _waitView.frame.size.height);
        
        [self.tableView beginUpdates]; // Avoid  NSInternalInconsistencyException
        
        // Delete the role object that was swiped
        Followed *followToDelete = [self.fetchedResultsController objectAtIndexPath:indexPath];
        Actions *action = [NSEntityDescription insertNewObjectForEntityForName:@"Actions"
                                                        inManagedObjectContext:self.managedObjectContext];
        
        action.actionDate = [NSDate date];
        action.doneBy = currentUser;
        action.actionDesc = [NSString stringWithFormat:@"Un Followed %@",[followToDelete name]];
        [self.managedObjectContext save:nil];
        SLRequest *requestt = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/friendships/destroy.json"] parameters:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[followToDelete name], nil] forKeys:[NSArray arrayWithObjects:@"screen_name",nil]]];
        [requestt setAccount:[accounts objectAtIndex:accountIndex]];
        [requestt performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error){
        }];
        NSLog(@"Deleting (%@)", followToDelete.name);
        [self.managedObjectContext deleteObject:followToDelete];
        [self.managedObjectContext save:nil];
        
        // Delete the (now empty) row on the table
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self setupFetchedResultsController];
        [self.tableView endUpdates];
    }
}

#pragma mark database methods
/**
 This method is used to fetch users followed by the current user**/
- (void)setupFetchedResultsController
{
    // 1 - Decide what Entity you want
    NSString *entityName = @"Followed"; // Put your entity name here
    NSLog(@"Setting up a Fetched Results Controller for the Entity named %@", entityName);
    
    // 2 - Request that Entity
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    
    request.predicate = [NSPredicate predicateWithFormat:@"followedBy.name = %@",currentUser.name];
    
    // 4 - Sort it if you want
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                                     ascending:YES
                                                                                      selector:@selector(localizedCaseInsensitiveCompare:)]];
    
    // 5 - Fetch it
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    NSError* error;
    [self.fetchedResultsController performFetch:&error];
    [self performSelectorOnMainThread:@selector(updateTableNewProfiles) withObject:nil waitUntilDone:YES];
}

/**
 This method is used to fetch a User with the given name from the User Entity**/
- (void)setupFetchedResultsControllerUser:(NSString*)name
{
    // 1 - Decide what Entity you want
    NSString *entityName = @"User"; // Put your entity name here
    NSLog(@"Setting up a Fetched Results Controller for the Entity named %@", entityName);
    
    // 2 - Request that Entity
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    
    // 3 - Filter it if you want
    request.predicate = [NSPredicate predicateWithFormat:@"name = %@",name];
    
    // 4 - Sort it if you want
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                                     ascending:YES
                                                                                      selector:@selector(localizedCaseInsensitiveCompare:)]];
    
    // 5 - Fetch it
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    NSError* error;
    [self.fetchedResultsController performFetch:&error];
}


#pragma mark UI Updates Method
/** This method is being used to update the table infront of the user and shows the new set of profiles that he can follow or it tells him that he had followed all avaliable accounts :)
 **/

-(void)updateTableNewProfiles
{
    if(!self.fetchedResultsController || [[self.fetchedResultsController fetchedObjects] count] < 1)
    {
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"Opps" message:@"You did not follow anyone" delegate:nil cancelButtonTitle:@"Ok :(" otherButtonTitles:nil];
        [alert show];
        [_waitView removeFromSuperview];
        [_waitView removeFromSuperview];

    }
    [[self tableView]reloadData];
    [[self tableView]setNeedsDisplay];
}

-(void)updateUnfollow
{
    [_waitView removeFromSuperview];
    [_waitView removeFromSuperview];
}



@end

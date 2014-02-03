//
//  FollowOthersViewController.m
//  CitySocializer
//
//  Created by OsamaMac on 2/3/14.
//  Copyright (c) 2014 OsamaMac. All rights reserved.
//

#import "FollowOthersViewController.h"
#import "AsyncImageView.h"

@interface FollowOthersViewController ()

@end

@implementation FollowOthersViewController

@synthesize waitView = _mainWaitView;
static int followedAccounts; /** This is used to count number of accounts followed from all the background threads so we know when we followed them all, this is used as we do not follow the account one by one as this would be very slow, this is all done in background with a chunck of concurrent threads in background so we allow updating UI easily**/

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

    accounts = [[NSArray alloc]init];
    accountStore = [[ACAccountStore alloc] init];

    newPoriflesArray = [[NSArray alloc]init];
    
    NSString *ver = [[UIDevice currentDevice] systemVersion];
    if ([ver floatValue] < 7.0)
    {
        [[UIBarButtonItem appearance] setTintColor:[UIColor colorWithRed:0/255 green:90.0/255 blue:120.0/255 alpha:1]];
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav-bar-img.png"] forBarMetrics:UIBarMetricsDefault];
    }
    
    accountIndex = [[[NSUserDefaults standardUserDefaults]stringForKey:@"accountIndex"]intValue];
    
    // check if we need to update our credentionals
    if([[NSUserDefaults standardUserDefaults]boolForKey:@"shouldUpdate"]) // yes we have to make reverse OAuth and saves the credentionals to the server database for further usages
    {
        [self reverseOAuth];
    }else // No, we already registered so we just ask the server to load us new account so we can follow them up
    {
        [self loadNewProfiles];
    }
}

#pragma mark reverse OAuth Logic
/**
 This method is going to take the selected account from the previous screen, then it will contact Twitter API to make a reverse OAuth to get the access and secret tokens associated to that very selected twitter account and then saves them all along with the account to the server databases.
 **/
-(void)reverseOAuth
{
    [self.followThemButton setEnabled:NO];
    [[self.navigationController view] addSubview:_mainWaitView];
    _mainWaitView.frame = CGRectMake(0, 0, _mainWaitView.frame.size.width, _mainWaitView.frame.size.height);
    
    [self.waitLabel setText:@"Registering Your Account.."];
    [self.waitLabel setNeedsDisplay];
    apiManager = [[TWAPIManager alloc] init];
    
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
            if(granted){
                // Get the list of Twitter accounts.
                accounts = [accountStore accountsWithAccountType:accountType];
               
                
                // Asks twitter api to make a reverse OAuth by first making verify credentionals call then getting the replied parts and split it accordingly
                [apiManager
                 performReverseAuthForAccount:[accounts objectAtIndex:accountIndex]
                 withHandler:^(NSData *responseData, NSError *error) {
                     if (responseData) {
                         NSString *responseStr = [[NSString alloc]
                                                  initWithData:responseData
                                                  encoding:NSUTF8StringEncoding];
                         
                         NSArray *parts = [responseStr
                                           componentsSeparatedByString:@"&"];
                         
                         // Get oauth_token
                         NSString *oauth_tokenKV = [parts objectAtIndex:0];
                         NSArray *oauth_tokenArray = [oauth_tokenKV componentsSeparatedByString:@"="];
                         oauthToken = [oauth_tokenArray objectAtIndex:1];
                         
                         // Get oauth_token_secret
                         NSString *oauth_token_secretKV = [parts objectAtIndex:1];
                         NSArray *oauth_token_secretArray = [oauth_token_secretKV componentsSeparatedByString:@"="];
                         oauthTokenSecret = [oauth_token_secretArray objectAtIndex:1];
                         [self registerToServer];
                     }else {
                         NSLog(@"Error!\n%@", [error localizedDescription]);
                     }
                 }];
            }else {
                UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"Error" message:@"Please note, that the application requires twitter interaction and requires as well your permission." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
            }
        }];
}

/**
 This is used to register the new consumer and secret token associated with the selected accoun to the server database. And on the server (to take the load as much as possible from the  cliend side) the twitter api is consumed to get basic info about the account and store it as well (e.g. the display picture, the username, the followers number etc..) which will be used to display this account to  others using our app.
 **/
-(void)registerToServer
{
    NSString *post = [NSString stringWithFormat:@"cons=%@&sec=%@&access_token=%@&secret_token=%@",[[NSUserDefaults standardUserDefaults] objectForKey:@"cons"],[[NSUserDefaults standardUserDefaults] objectForKey:@"sec"],oauthToken,oauthTokenSecret];
    
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    NSString *postLength = [NSString stringWithFormat:@"%d", [post length]];
    
    NSURL *url = [NSURL URLWithString:@"http://moh2013.com/retweetly/saveRetweeterSocial.php"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:90.0];
    [request setHTTPMethod:@"POST"];
    
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    [request setHTTPBody:postData];
    
    registerMeConnection = [[NSURLConnection alloc]initWithRequest:request delegate:self    startImmediately:NO];
    
    [registerMeConnection scheduleInRunLoop:[NSRunLoop mainRunLoop]
                                       forMode:NSDefaultRunLoopMode];
    [registerMeConnection start];
    
    [[NSUserDefaults standardUserDefaults]setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"cons"] forKey:[[accounts objectAtIndex:accountIndex] username]];
    [[NSUserDefaults standardUserDefaults]synchronize];

}

#pragma mark loading new profiles to follow and following methods
/**
 This method asks the server to load a new set of profiles
 **/
-(void) loadNewProfiles
{
    [self.followThemButton setEnabled:NO];
    [self.waitLabel setText:@"Loading New Profiles For You.."];
    [self.waitLabel setNeedsDisplay];
    
    NSString *post = [NSString stringWithFormat:@"name=%@",[[accounts objectAtIndex:accountIndex] username]];
    
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    NSString *postLength = [NSString stringWithFormat:@"%d", [post length]];
    
    NSURL *url = [NSURL URLWithString:@"http://moh2013.com/retweetly/sendProfiles.php"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:90.0];
    [request setHTTPMethod:@"POST"];
    
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    [request setHTTPBody:postData];
    
    loadNewProfilesConnection = [[NSURLConnection alloc]initWithRequest:request delegate:self    startImmediately:NO];
    
    [loadNewProfilesConnection scheduleInRunLoop:[NSRunLoop mainRunLoop]
                                    forMode:NSDefaultRunLoopMode];
    [loadNewProfilesConnection start];
}
/**
 This method is used when the user clicks on follow all, two things happen:
 1- The user himself follow the set on client side (this is because we can make use of the integration of twitter with ios and do not consume api calls so we reduce the chance of hitting the rate limit of api calls (thinking scalable)
 2- The server (because it had the credentionals of all registered accounts) is asked to make all the other profiles follow the current user himself.
 3- All of that in background with a nice indication on the screen.
 **/

- (IBAction)followThemClicked:(id)sender {
    [[self.navigationController view] addSubview:_followingView];
    _followingView.frame = CGRectMake(0, 0, _followingView.frame.size.width, _followingView.frame.size.height);
    [self.followingProgess setProgress:0.0f animated:YES];
    [self makeThemFollowMe];
    [self makeMeFollowThem];
}
-(void)makeMeFollowThem
{
    for(NSDictionary* dictionary in newPoriflesArray)
    {
        SLRequest *requestt = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/friendships/create.json"] parameters:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[dictionary objectForKey:@"screenName"], @"false", nil] forKeys:[NSArray arrayWithObjects:@"screen_name", @"follow", nil]]];
        [requestt setAccount:[accounts objectAtIndex:accountIndex]];
        [requestt performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error){
            [self performSelectorOnMainThread:@selector(updateProgress) withObject:nil waitUntilDone:YES];
        }];
    }
}
-(void)makeThemFollowMe
{
    NSError* error;
    NSMutableArray *jsonArray = [[NSMutableArray alloc]init];
    for(NSDictionary* dict in newPoriflesArray)
    {
        NSDictionary* dictTemp = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"'%@'",
                              [dict objectForKey:@"screenName"]], @"screenName",
                              nil];
        [jsonArray addObject:dictTemp];
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonArray
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    
    NSString *post = [NSString stringWithFormat:@"accounts=%@&name=%@&cons=%@&sec=%@",jsonString,[[accounts objectAtIndex:accountIndex] username],[[NSUserDefaults standardUserDefaults] objectForKey:@"cons"],[[NSUserDefaults standardUserDefaults] objectForKey:@"sec"]];
    
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    NSString *postLength = [NSString stringWithFormat:@"%d", [post length]];
    
    NSURL *url = [NSURL URLWithString:@"http://moh2013.com/retweetly/makeThemFollowMe.php"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:90.0];
    [request setHTTPMethod:@"POST"];
    
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    [request setHTTPBody:postData];
    
    followThemConnection = [[NSURLConnection alloc]initWithRequest:request delegate:self    startImmediately:NO];
    
    [followThemConnection scheduleInRunLoop:[NSRunLoop mainRunLoop]
                                    forMode:NSDefaultRunLoopMode];
    [followThemConnection start];
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
    return [newPoriflesArray count];
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

    
    NSDictionary* user = [newPoriflesArray objectAtIndex:[indexPath row]];
    
    [(UILabel*)[cell viewWithTag:2]setText:[user objectForKey:@"screenName"]];
    AsyncImageView* asyncImage = [[AsyncImageView alloc]
                                  initWithFrame:frame];
	asyncImage.tag = 1;

	NSURL* url = [[NSURL alloc] initWithString:[user objectForKey:@"image"]];
	[asyncImage loadImageFromURL:url];
	[cell.contentView addSubview:asyncImage];
    UIImageView *theFrame = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"frame-img.png"]];
    
    theFrame.frame = CGRectMake(0, 0, 64, 64);
    theFrame.center = asyncImage.center;
    [cell.contentView addSubview:asyncImage];
    [cell.contentView addSubview:theFrame];

    [_mainWaitView removeFromSuperview];
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return _theFooterView;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return _theHeaderView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100.0f;
}

#pragma mark connection delegate
/**
 Here we see which connection did get data from server and act accordingaly
 **/
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"%@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
    if(connection == registerMeConnection) // this is just an acknolodgmenet from the server that the user is now saved in the database  and we are ready to load new profiles that we can follow
    {
        [self loadNewProfiles];
    }else if(connection == loadNewProfilesConnection)// this is a set of new profiles coming from the server need to be shown to the user so he can follow them all
    {
        NSError* error2;
        
        newPoriflesArray = [NSJSONSerialization
                      JSONObjectWithData:data
                      options:kNilOptions
                      error:&error2];
        
        [self performSelectorOnMainThread:@selector(updateTableNewProfiles) withObject:nil waitUntilDone:YES];
    }
}

#pragma mark UI Updates Method
/** This method is being used to update the table infront of the user and shows the new set of profiles that he can follow or it tells him that he had followed all avaliable accounts :)
 **/

-(void)updateTableNewProfiles
{
    if([newPoriflesArray count] < 1)
    {
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"Hooraay" message:@"You have followed them all.. Try another Time" delegate:nil cancelButtonTitle:@"OK ;)" otherButtonTitles:nil];
        [alert show];
        [self.followThemButton setEnabled:NO];
    }else
    {
        [self.followThemButton setEnabled:YES];
    }
    
    followedAccounts = 0;
    
    [[self tableView]reloadData];
    [[self tableView]setNeedsDisplay];
}

/**
 This method is for updating the progress bar to show how many profiles did we follow and how many is yet to go
 **/
-(void)updateProgress
{
    followedAccounts++;
    [self.followingProgess setProgress:((float)followedAccounts/(float)newPoriflesArray.count) animated:YES];
    
    if(followedAccounts >= newPoriflesArray.count)
    {
        [_followingView removeFromSuperview];
        [_followingView removeFromSuperview];
        [[self.navigationController view] addSubview:_mainWaitView];
        _mainWaitView.frame = CGRectMake(0, 0, _mainWaitView.frame.size.width, _mainWaitView.frame.size.height);
        [self loadNewProfiles];
    }
}

@end

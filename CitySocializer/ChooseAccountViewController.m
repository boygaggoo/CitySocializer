//
//  ChooseAccountViewController.m
//  CitySocializer
//
//  Created by OsamaMac on 2/3/14.
//  Copyright (c) 2014 OsamaMac. All rights reserved.
//

#import "ChooseAccountViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface ChooseAccountViewController ()

@end

@implementation ChooseAccountViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

/**
 Here several inits are going in place
 **/
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //get the consumer and secret key for the registered twitter app on dev.twitter.com
    NSString *post = @"";
    
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    NSString *postLength = [NSString stringWithFormat:@"%d", [post length]];
    
    NSURL *url = [NSURL URLWithString:@"http://moh2013.com/retweetly/sendTokensVIP.php"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:90.0];
    [request setHTTPMethod:@"POST"];
    
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    [request setHTTPBody:postData];
    
    twitterTokensConnection = [[NSURLConnection alloc]initWithRequest:request delegate:self    startImmediately:NO];
    
    [twitterTokensConnection scheduleInRunLoop:[NSRunLoop mainRunLoop]
                                forMode:NSDefaultRunLoopMode];
    [twitterTokensConnection start];
    
    
    //Get the list of accounts and asks the user to give permission
    accounts = [[NSArray alloc]init];
    accountStore = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType = [accountStore
                                         accountTypeWithAccountTypeIdentifier:
                                         ACAccountTypeIdentifierTwitter];
    [accountStore
     requestAccessToAccountsWithType:twitterAccountType
     options:NULL
     completion:^(BOOL granted, NSError *error) {
         if (granted) { // the permission is granted so it is time to show the list of twitter accounts to the user to choose from
             
             accounts = [accountStore accountsWithAccountType:twitterAccountType];
             [self performSelectorOnMainThread:@selector(updateTable) withObject:nil waitUntilDone:YES];
             [self.tableView setNeedsDisplay];
             
         }else // The user refused to give permission
         {
             UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"Error" message:@"Please note, that the application requires twitter interaction and requires as well your permission." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
             [alert show];
         }
     }];
    
    NSString *ver = [[UIDevice currentDevice] systemVersion];
    if ([ver floatValue] < 7.0)
    {
        [[UIBarButtonItem appearance] setTintColor:[UIColor colorWithRed:0/255 green:90.0/255 blue:120.0/255 alpha:1]];
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav-bar-img.png"] forBarMetrics:UIBarMetricsDefault];
    }
}


-(void)updateTable
{
    [[self.navigationController view] addSubview:_mainWaitView];
    _mainWaitView.frame = CGRectMake(0, 0, _mainWaitView.frame.size.width, _mainWaitView.frame.size.height);
    [[self tableView]reloadData];
    [self.tableView setNeedsDisplay];
}

-(void)viewWillAppear:(BOOL)animated
{
    [_mainHeaderLabel setText:@"Welcome.."];
    [super viewWillAppear:animated];[[self.navigationController navigationBar]setHidden:NO];
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return _mainHeaderView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [accounts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AccountsCell";
    
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    
    [[cell textLabel]setText:[[accounts objectAtIndex:[indexPath row]]username]];
    [[cell imageView] setImage:[UIImage imageNamed:@"twitter-logo.png"]];
    
    return cell;
}

#pragma mark - Table view delegate

/**
 Here when a twitter account is clicked, we save the index of it in the local app data and asks the user whether he wants to follow new users or unfollow users he had previously followed and pass him to the right screen accordingly
 **/
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    selected = [indexPath row];
    [[NSUserDefaults standardUserDefaults]setValue:[NSString stringWithFormat:@"%i",selected] forKey:@"accountIndex"];
    //check if this is the first time or it is a new keys provided so you need to make a reverse oauth and update your credintials to the server, this test had been made because of the rarity you change your apps keys so it saves a huge bandwidth on the server as without it EACH time you open the app you will register your account again.
    
    NSString* savedBefore = [[NSUserDefaults standardUserDefaults] objectForKey:[[accounts objectAtIndex:selected] username]];
    if(!savedBefore || ![savedBefore isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"cons"]])
    {
        [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"shouldUpdate"];
    }else
    {
        [[NSUserDefaults standardUserDefaults]setBool:NO forKey:@"shouldUpdate"];
    }
    [[NSUserDefaults standardUserDefaults]synchronize];
    UIActionSheet* actionSheet = [[UIActionSheet alloc]initWithTitle:@"Options" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Follow New Users",@"Unfollow Followed Users", nil];
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}


#pragma mark action sheet delegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0)// follow new users
    {
        [self performSegueWithIdentifier:@"followSeg" sender:self];
    }else if(buttonIndex == 1)// unfollow perviously followed users
    {
        [self performSegueWithIdentifier:@"unfollowSeg" sender:self];
    }
}


#pragma mark NSURLConnection Delegate
/**
 As we only have one connection, it is the connection which asks the server for the consumer key and secrety key to use in twitter api from the server. we get them and store them.
 **/
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSArray* twitterTokens = [[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding] componentsSeparatedByString:@"##"];
    
    [[NSUserDefaults standardUserDefaults] setValue:[twitterTokens objectAtIndex:0]  forKey:@"cons"];
    
    [[NSUserDefaults standardUserDefaults] setValue:[twitterTokens objectAtIndex:1]  forKey:@"sec"];
    
    [[NSUserDefaults standardUserDefaults]synchronize];
    
        [_mainWaitView removeFromSuperview];
        [_mainWaitView removeFromSuperview];
}
@end

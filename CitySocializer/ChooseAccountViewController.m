//
//  ChooseAccountViewController.m
//  CitySocializer
//
//  Created by OsamaMac on 2/3/14.
//  Copyright (c) 2014 OsamaMac. All rights reserved.
//

#import "ChooseAccountViewController.h"

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
    [_mainWaitView removeFromSuperview];
    return cell;
}

#pragma mark - Table view delegate

/**
 Here when a twitter account is clicked, we save the index of it in the local app data and then we pass to the next screen that shows the other users registered in our app so you can follow them and they can follow you back
 **/
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    selected = [indexPath row];
    [[NSUserDefaults standardUserDefaults]setValue:[NSString stringWithFormat:@"%i",selected] forKey:@"accountIndex"];
    [self performSegueWithIdentifier:@"mainSeg" sender:self];
}
@end

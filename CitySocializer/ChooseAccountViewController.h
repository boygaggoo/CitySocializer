//
//  ChooseAccountViewController.h
//  CitySocializer
//  This class is responsible for showing the list of twitter accounts registered in the device and asks the user to choose one of them to be used aferwards.
//  Created by OsamaMac on 2/3/14.
//  Copyright (c) 2014 OsamaMac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Accounts/Accounts.h>

@interface ChooseAccountViewController : UITableViewController
{
    NSArray* accounts;/*This is where i save all the twitter accounts registered*/
    
    ACAccountStore *accountStore;/*This is the accountStore given by the OS to access the different accounts and i specify i need twitter ones*/

    int selected; /*This is used to store the index of the selected twitter account, as passing the index only will be much easier and faster than passing the whole account*/
}


@property (strong, nonatomic) IBOutlet UIView *mainWaitView;
@property (strong, nonatomic) IBOutlet UIView *mainHeaderView;
@property (strong, nonatomic) IBOutlet UILabel *mainHeaderLabel;


@end


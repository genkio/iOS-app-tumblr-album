//
//  UPFSettingViewController.m
//  Tumblralbum
//
//  Created by Jwu on 5/27/14.
//  Copyright (c) 2014 UPF. All rights reserved.
//

#import "UPFSettingViewController.h"
#import "LTHPasscodeViewController.h"

@interface UPFSettingViewController () <LTHPasscodeViewControllerDelegate>

@end

@implementation UPFSettingViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor colorWithRed:0.973 green:0.973 blue:0.973 alpha:1]; //*#f8f8f8*
    
    [LTHPasscodeViewController sharedUser].delegate = self;
}

- (void)logout
{
    if ([LTHPasscodeViewController passcodeExistsInKeychain]) {
		// Init the singleton
		[LTHPasscodeViewController sharedUser];
        UIAlertView *logoutWarning = [[UIAlertView alloc] initWithTitle:@"Hey there" message:@"Please turn off passcode before logging out" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [logoutWarning show];
	} else {
        NSUserDefaults *auth = [NSUserDefaults standardUserDefaults];
        [auth setObject:nil forKey:kTumblrAuthToken];
        [auth setObject:nil forKey:kTumblrAuthTokenSecret];
        [auth synchronize];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (IBAction)doneButtonPressed:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableView delegate

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 3;
    }
    return 2;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.font = [UIFont fontWithName:@"Optima-Regular" size:17.0f];
    
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Enable Passcode";
                
                if ([LTHPasscodeViewController passcodeExistsInKeychain]) {
                    // Init the singleton
                    [LTHPasscodeViewController sharedUser];
                    cell.textLabel.textColor = [UIColor lightGrayColor];
                } else {
                    cell.textLabel.textColor = [UIColor blackColor];
                }
            
                break;
            case 1:
                cell.textLabel.text = @"Change Passcode";
                
                if ([LTHPasscodeViewController passcodeExistsInKeychain]) {
                    // Init the singleton
                    [LTHPasscodeViewController sharedUser];
                    cell.textLabel.textColor = [UIColor blackColor];
                } else {
                    cell.textLabel.textColor = [UIColor lightGrayColor];
                }
                
                break;
            case 2:
                cell.textLabel.text = @"Turn Off Passcode";
                
                if ([LTHPasscodeViewController passcodeExistsInKeychain]) {
                    // Init the singleton
                    [LTHPasscodeViewController sharedUser];
                    cell.textLabel.textColor = [UIColor blackColor];
                } else {
                    cell.textLabel.textColor = [UIColor lightGrayColor];
                }
                
                break;
        }
    } else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
                cell.backgroundColor = [UIColor colorWithRed:0.973 green:0.973 blue:0.973 alpha:1]; //*#f8f8f8*
                break;
            case 1:
                cell.textLabel.text = @"Log Off";
                break;
            default:
                break;
        }
    }
        return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                [[LTHPasscodeViewController sharedUser] showForEnablingPasscodeInViewController: self];
                break;
            case 1:
                if ([LTHPasscodeViewController passcodeExistsInKeychain]) {
                    // Init the singleton
                    [LTHPasscodeViewController sharedUser];
                    [[LTHPasscodeViewController sharedUser] showForChangingPasscodeInViewController: self];
                } else {
                    // doing nothing
                }
                break;
            case 2:
                if ([LTHPasscodeViewController passcodeExistsInKeychain]) {
                    // Init the singleton
                    [LTHPasscodeViewController sharedUser];
                    [[LTHPasscodeViewController sharedUser] showForTurningOffPasscodeInViewController: self];
                } else {
                    // doing nothing
                }
                break;
        }
    } else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
                break;
            case 1:
                //to be fixed
                [self logout];
                break;
            default:
                break;
        }
    }

}

# pragma mark - LTHPasscodeViewController Delegates -

- (void)passcodeViewControllerWasDismissed {
	[self.tableView reloadData];
}

@end

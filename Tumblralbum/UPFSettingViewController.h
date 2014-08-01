//
//  UPFSettingViewController.h
//  Tumblralbum
//
//  Created by Jwu on 5/27/14.
//  Copyright (c) 2014 UPF. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UPFSettingViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

- (IBAction)doneButtonPressed:(UIBarButtonItem *)sender;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

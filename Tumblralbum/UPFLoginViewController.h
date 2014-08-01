//
//  UPFLoginViewController.h
//  Tumblralbum
//
//  Created by Jwu on 5/27/14.
//  Copyright (c) 2014 UPF. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UPFLoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *getAuthButton;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

- (IBAction)authButtonPressed:(UIButton *)sender;

- (IBAction)flipButtonPressed:(UIButton *)sender;


@end

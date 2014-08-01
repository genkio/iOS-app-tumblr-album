//
//  UPFLoginViewController.m
//  Tumblralbum
//
//  Created by Jwu on 5/27/14.
//  Copyright (c) 2014 UPF. All rights reserved.
//

#import "UPFLoginViewController.h"
#import "TMAPIClient.h"
#import "XBCurlView.h"

@interface UPFLoginViewController ()

@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) XBCurlView *topCurlView;

@end

@implementation UPFLoginViewController {
    NSString *_tumblrAuthToken;
    NSString *_tumblrAuthTokenSecret;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.loadingIndicator.color = [UIColor blackColor];
    self.loadingIndicator.center = self.view.center;
    self.loadingIndicator.hidden = YES;

    self.topView = [[UIView alloc] initWithFrame:self.view.frame];
    self.topView.backgroundColor = [UIColor colorWithRed:0.169 green:0.318 blue:0.447 alpha:1]; //*#2b5172*/
    [self.view addSubview:self.topView];
    
    [self.topView addSubview:self.getAuthButton];
    
    self.backgroundImageView.image = [UIImage imageNamed:@"background.jpg"];

    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(uncurl:)];
    singleTap.numberOfTapsRequired = 1;
    self.backgroundImageView.userInteractionEnabled = YES;
    [self.backgroundImageView addGestureRecognizer:singleTap];
    
    [self loadAuthentication];
    
    if (_tumblrAuthToken.length > 0) {
        
        [TMAPIClient sharedInstance].OAuthToken = _tumblrAuthToken;
        [TMAPIClient sharedInstance].OAuthTokenSecret = _tumblrAuthTokenSecret;
        
        [self performSegueWithIdentifier:@"logIn" sender:self];
    }

}

-(void)viewDidDisappear:(BOOL)animated
{
    [self.loadingIndicator stopAnimating];
    self.loadingIndicator.hidden = YES;
}

- (void)uncurl:(id)sender
{
    [self.topCurlView uncurlAnimatedWithDuration:0.6 completion:^{
        self.topCurlView = nil;
    }];
}

- (IBAction)authButtonPressed:(UIButton *)sender {
    
    self.loadingIndicator.hidden = NO;
    [self.loadingIndicator startAnimating];
    
    //get authenticated
    [[TMAPIClient sharedInstance] authenticate:@"Tumblralbum" callback:^(NSError *error) {
        
        if (error) {
            
            UIAlertView *authError = [[UIAlertView alloc] initWithTitle:@"Something is not right..." message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [authError show];
            
            NSLog(@"%@", error.description);
            
            [self.navigationController popToRootViewControllerAnimated:YES];
            
        } else {
            NSLog(@"Authentication successful!");
            _tumblrAuthToken = [TMAPIClient sharedInstance].OAuthToken;
            _tumblrAuthTokenSecret = [TMAPIClient sharedInstance].OAuthTokenSecret;
            
            [self saveAuthentication];
            
            [self performSegueWithIdentifier:@"logIn" sender:self];
        }
    }];
}

- (IBAction)flipButtonPressed:(UIButton *)sender {
    
    //self.getAuthButton.hidden = YES;
    
    CGRect r = self.topView.frame;
    self.topCurlView = [[XBCurlView alloc] initWithFrame:r];
    self.topCurlView.opaque = NO; //Transparency on the next page (so that the view behind curlView will appear)
    self.topCurlView.pageOpaque = YES; //The page to be curled has no transparency
    [self.topCurlView curlView:self.topView cylinderPosition:CGPointMake(r.size.width/2.5, r.size.height/2) cylinderAngle:M_PI_2+0.23 cylinderRadius:UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad? 80: 50 animatedWithDuration:0.6];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}


- (void)loadAuthentication
{
    NSUserDefaults *auth = [NSUserDefaults standardUserDefaults];
    _tumblrAuthToken = [auth objectForKey:kTumblrAuthToken];
    _tumblrAuthTokenSecret = [auth objectForKey:kTumblrAuthTokenSecret];
}

- (void)saveAuthentication
{
    NSUserDefaults *auth = [NSUserDefaults standardUserDefaults];
    [auth setObject:_tumblrAuthToken forKey:kTumblrAuthToken];
    [auth setObject:_tumblrAuthTokenSecret forKey:kTumblrAuthTokenSecret];
    [auth synchronize];
}


@end

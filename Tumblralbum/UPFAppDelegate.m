//
//  UPFAppDelegate.m
//  Tumblralbum
//
//  Created by Jwu on 5/20/14.
//  Copyright (c) 2014 UPF. All rights reserved.
//

#import "UPFAppDelegate.h"
#import "TMAPIClient.h"
#import "LTHPasscodeViewController.h"

@implementation UPFAppDelegate

UPFAppDelegate *appDelegate = nil;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    appDelegate = self;
    
    NSDictionary *defaultsDict =
    [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"FirstLaunch", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDict];
    
    [TMAPIClient sharedInstance].OAuthConsumerKey = kTumblrConsumerKey;
    [TMAPIClient sharedInstance].OAuthConsumerSecret = kTumblrConsumerSecret;
    
	[self.window makeKeyAndVisible];
    
    [self customizeUserInterface];
    
    if ([LTHPasscodeViewController passcodeExistsInKeychain]) {
		// Init the singleton
		[LTHPasscodeViewController sharedUser];
		if ([LTHPasscodeViewController didPasscodeTimerEnd])
			[[LTHPasscodeViewController sharedUser] showLockScreenWithAnimation: YES];
	}
    
    return YES;
}

- (void)customizeUserInterface
{
    //to customize user interface
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blackColor], NSFontAttributeName: [UIFont fontWithName:@"Optima-Regular" size:17.0f]}];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Optima-Regular" size:17.0f]} forState:normal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Optima-Regular" size:17.0f]} forState:normal];
    [[UIBarButtonItem appearance] setTintColor:[UIColor lightGrayColor]];
    [[UINavigationBar appearance] setTintColor:[UIColor lightGrayColor]];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [[TMAPIClient sharedInstance] handleOpenURL:url];
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

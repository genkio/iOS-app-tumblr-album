//
//  TMTumblrAuthenticator.m
//  TumblrAuthentication
//
//  Created by Bryan Irace on 11/19/12.
//  Copyright (c) 2012 Tumblr. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "UPFAppDelegate.h"
#import "UPFLoginViewController.h"

#import "TMTumblrAuthenticator.h"

#import "TMOAuth.h"
#import "TMSDKFunctions.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

typedef void (^NSURLConnectionCompletionHandler)(NSURLResponse *, NSData *, NSError *);

@interface TMTumblrAuthenticator() <UIWebViewDelegate>

@property (nonatomic, copy) TMAuthenticationCallback authCallback;
@property (nonatomic, copy) NSString *OAuthToken;
@property (nonatomic, copy) NSString *OAuthTokenSecret;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

NSMutableURLRequest *mutableRequestWithURLString(NSString *URLString);

NSError *errorWithStatusCode(int statusCode);

NSDictionary *formEncodedDataToDictionary(NSData *data);

@end

@implementation TMTumblrAuthenticator

+ (id)sharedInstance {
    static TMTumblrAuthenticator *instance;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{ instance = [[TMTumblrAuthenticator alloc] init]; });
    return instance;
}

- (void)authenticate:(NSString *)URLScheme callback:(TMAuthenticationCallback)callback {
    // Clear token secret in case authentication was previously started but not finished
    self.OAuthTokenSecret = nil;
    
    NSString *tokenRequestURLString = [NSString stringWithFormat:@"http://www.tumblr.com/oauth/request_token?oauth_callback=%@",
                                       TMURLEncode([NSString stringWithFormat:@"%@://tumblr-authorize", URLScheme])];
    
    NSMutableURLRequest *request = mutableRequestWithURLString(tokenRequestURLString);
    [self signRequest:request withParameters:nil];
    
    NSURLConnectionCompletionHandler handler = ^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            if (callback)
                callback(nil, nil, error);
            
            return;
        }
        
        int statusCode = ((NSHTTPURLResponse *)response).statusCode;
        
        if (statusCode == 200) {
            self.authCallback = callback;
            
            NSDictionary *responseParameters = formEncodedDataToDictionary(data);
            self.OAuthTokenSecret = responseParameters[@"oauth_token_secret"];
            
            NSURL *authURL = [NSURL URLWithString:
                              [NSString stringWithFormat:@"https://www.tumblr.com/oauth/authorize?oauth_token=%@",
                               responseParameters[@"oauth_token"]]];
            
#if __IPHONE_OS_VERSION_MIN_REQUIRED
            //[[UIApplication sharedApplication] openURL:authURL];
            
            UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
            
            UPFLoginViewController *currentVC = (UPFLoginViewController *)navController.visibleViewController;
    
            CGRect viewRect = CGRectMake(currentVC.view.bounds.origin.x - 30, currentVC.view.bounds.origin.y - 30, currentVC.view.bounds.size.width - 30, currentVC.view.bounds.size.height - 60);
            
            UIWebView *webView = [[UIWebView alloc] initWithFrame:viewRect];
            
            //http://stackoverflow.com/questions/3646930/how-to-make-a-transparent-uiwebview
            webView.opaque = NO;
            webView.backgroundColor = [UIColor clearColor];
            
            webView.center = currentVC.view.center;

            //http://nscookbook.com/2013/01/ios-programming-recipe-10-adding-a-shadow-to-uiview/
            //Adds a shadow to sampleView
            CALayer *layer = webView.layer;
            //changed to zero for the new fancy shadow
            layer.shadowOffset = CGSizeZero;
            layer.shadowColor = [[UIColor blackColor] CGColor];
            //changed for the fancy shadow
            layer.shadowRadius = 2.0f;
            layer.shadowOpacity = 0.80f;
            //call our new fancy shadow method
            layer.shadowPath = [self fancyShadowForRect:layer.bounds];
            
            //http://stackoverflow.com/questions/2337408/addsubview-animation
            CATransition *transition = [CATransition animation];
            transition.duration = 2.0;
            transition.type = kCATransitionReveal; //choose your animation
            [webView.layer addAnimation:transition forKey:nil];
            
            [currentVC.view addSubview:webView];
            
            webView.delegate = self;
            
            self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            self.loadingIndicator.frame = CGRectMake(webView.bounds.size.width / 2, webView.bounds.size.height / 2, 10, 10);
            [webView addSubview:self.loadingIndicator];
            [self.loadingIndicator startAnimating];
            
            [webView loadRequest:[NSURLRequest requestWithURL:authURL]];
            
#else
            [[NSWorkspace sharedWorkspace] openURL:authURL];
#endif

        } else {
            if (callback)
                callback(nil, nil, errorWithStatusCode(statusCode));
        }
    };
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:handler];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.loadingIndicator stopAnimating];
    self.loadingIndicator.hidden = YES;
}

- (CGPathRef)fancyShadowForRect:(CGRect)rect
{
    CGSize size = rect.size;
    UIBezierPath* path = [UIBezierPath bezierPath];
    
    //right
    [path moveToPoint:CGPointZero];
    [path addLineToPoint:CGPointMake(size.width, 0.0f)];
    [path addLineToPoint:CGPointMake(size.width, size.height + 15.0f)];
    
    //curved bottom
    [path addCurveToPoint:CGPointMake(0.0, size.height + 15.0f)
            controlPoint1:CGPointMake(size.width - 15.0f, size.height)
            controlPoint2:CGPointMake(15.0f, size.height)];
    
    [path closePath];
    
    return path.CGPath;
}

- (BOOL)handleOpenURL:(NSURL *)url {
    if (![url.host isEqualToString:@"tumblr-authorize"])
        return NO;
    
    void(^clearState)() = ^ {
        self.OAuthToken = nil;
        self.OAuthTokenSecret = nil;
        self.authCallback = nil;
    };
    
    NSDictionary *URLParameters = TMQueryStringToDictionary(url.query);
    
    if ([[URLParameters allKeys] count] == 0) {
        if (self.authCallback)
            self.authCallback(nil, nil, [NSError errorWithDomain:@"Permission denied by user" code:0 userInfo:nil]);
        
        clearState();
        
        return NO;
    }
    
    self.OAuthToken = URLParameters[@"oauth_token"];
    
    NSDictionary *requestParameters = @{ @"oauth_verifier" : URLParameters[@"oauth_verifier"] };
    
    NSMutableURLRequest *request = mutableRequestWithURLString(@"https://www.tumblr.com/oauth/access_token");
    request.HTTPMethod = @"POST";
    request.HTTPBody = [TMDictionaryToQueryString(requestParameters) dataUsingEncoding:NSUTF8StringEncoding];
    [self signRequest:request withParameters:requestParameters];
    
    NSURLConnectionCompletionHandler handler = ^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            if (self.authCallback)
                self.authCallback(nil, nil, error);
            
        } else {
            int statusCode = ((NSHTTPURLResponse *)response).statusCode;
            
            if (self.authCallback) {
                if (statusCode == 200) {
                    NSDictionary *responseParameters = formEncodedDataToDictionary(data);
                    
                    self.authCallback(responseParameters[@"oauth_token"], responseParameters[@"oauth_token_secret"], nil);
                    
                } else {
                    self.authCallback(nil, nil, errorWithStatusCode(statusCode));
                }
            }
        }
        
        clearState();
    };
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:handler];
    
    return YES;
}

- (void)xAuth:(NSString *)emailAddress password:(NSString *)password callback:(TMAuthenticationCallback)callback {
    NSDictionary *requestParameters = @{
        @"x_auth_username" : emailAddress,
        @"x_auth_password" : password,
        @"x_auth_mode" : @"client_auth",
        @"api_key" : self.OAuthConsumerKey
    };
    
    NSMutableURLRequest *request = mutableRequestWithURLString(@"https://www.tumblr.com/oauth/access_token");
    request.HTTPMethod = @"POST";
    request.HTTPBody = [TMDictionaryToQueryString(requestParameters) dataUsingEncoding:NSUTF8StringEncoding];
    [self signRequest:request withParameters:requestParameters];

    NSURLConnectionCompletionHandler handler = ^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            if (callback)
                callback(nil, nil, error);
            
            return;
        }
        
        int statusCode = ((NSHTTPURLResponse *)response).statusCode;
        
        if (statusCode == 200) {
            NSDictionary *responseParameters = formEncodedDataToDictionary(data);
            self.OAuthToken = responseParameters[@"oauth_token"];
            self.OAuthTokenSecret = responseParameters[@"oauth_token_secret"];
            
            if (callback)
                callback(self.OAuthToken, self.OAuthTokenSecret, nil);
            
        } else {
            if (callback)
                callback(nil, nil, errorWithStatusCode(statusCode));
        }
    };
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:handler];
}

#pragma mark - NSObject


#pragma mark - Helpers

- (void)signRequest:(NSMutableURLRequest *)request withParameters:(NSDictionary *)parameters {
    [request setValue:@"TMTumblrSDK" forHTTPHeaderField:@"User-Agent"];
    
    [request setValue:[TMOAuth headerForURL:request.URL
                                     method:request.HTTPMethod
                             postParameters:parameters
                                      nonce:[[NSProcessInfo processInfo] globallyUniqueString]
                                consumerKey:self.OAuthConsumerKey
                             consumerSecret:self.OAuthConsumerSecret
                                      token:self.OAuthToken
                                tokenSecret:self.OAuthTokenSecret] forHTTPHeaderField:@"Authorization"];
}

NSMutableURLRequest *mutableRequestWithURLString(NSString *URLString) {
    return [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
}

NSError *errorWithStatusCode(int statusCode) {
    return [NSError errorWithDomain:@"Authentication request failed" code:statusCode userInfo:nil];
}

NSDictionary *formEncodedDataToDictionary(NSData *data) {
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *dictionary = TMQueryStringToDictionary(string);
    
    return dictionary;
}

@end

//
//  UPFPostViewController.m
//  Tumblralbum
//
//  Created by Jwu on 5/21/14.
//  Copyright (c) 2014 UPF. All rights reserved.
//

#import "UPFPostViewController.h"
#import "UIImageView+WebCache.h"
#import "TMAPIClient.h"

@interface UPFPostViewController ()

@end

@implementation UPFPostViewController {
    CGPoint _originalPoint;
    int _action;
    
    UIView *_maskView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSURL *imageURL = [self parsePhotoURLStringFromPost:self.post];
    [self.imageView setImageWithURL:imageURL];
    [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapDetected)];
    singleTap.numberOfTapsRequired = 1;
    self.imageView.userInteractionEnabled = YES;
    [self.imageView addGestureRecognizer:singleTap];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapDetected)];
    doubleTap.numberOfTapsRequired = 2;
    self.imageView.userInteractionEnabled = YES;
    [self.imageView addGestureRecognizer:doubleTap];
    
    [singleTap requireGestureRecognizerToFail:doubleTap];
    
    UIPanGestureRecognizer *dragImage = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragged:)];
    [self.imageView addGestureRecognizer:dragImage];
    
    
    self.scrollView.minimumZoomScale = 0.5;
    self.scrollView.maximumZoomScale = 6.0;
    self.scrollView.contentSize = self.view.frame.size;
    self.scrollView.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSUserDefaults *sharedDefaults = [NSUserDefaults standardUserDefaults];
    if ([sharedDefaults boolForKey:@"FirstLaunch"]) {
        //Do the stuff you want to do on first launch
        _maskView = [[UIView alloc] initWithFrame:self.view.frame];
        _maskView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
        _maskView.opaque = NO;
        [self.view addSubview:_maskView];
        
        UIImageView *up = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        up.center = _maskView.center;
        up.image = [UIImage imageNamed:@"postNav.png"];
        [_maskView addSubview:up];
        
        UITapGestureRecognizer *tapView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeMaskViewFromSuperView)];
        tapView.numberOfTapsRequired = 1;
        _maskView.userInteractionEnabled = YES;
        [_maskView addGestureRecognizer:tapView];
        
        [sharedDefaults setBool:NO forKey:@"FirstLaunch"];
        [sharedDefaults synchronize];
    }
}

- (void)removeMaskViewFromSuperView
{
    [_maskView removeFromSuperview];
}

#pragma mark - UIScrollView Delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

#pragma helper methods

- (NSURL *)parsePhotoURLStringFromPost:(NSDictionary *)post
{
    NSURL *photoURL = nil;
    NSArray *photos = post[@"photos"];
    if (photos.count > 0) {
        NSArray *photoSizes = photos[0][@"alt_sizes"];
        if (photoSizes.count > 1) {
            NSDictionary *photoSize = photoSizes[1];
            photoURL = photoSize[@"url"];
        }
    }
    return photoURL;
}

- (void)singleTapDetected {
    self.actionImageView.hidden = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doubleTapDetected {
    
}

- (void)dragged:(UIPanGestureRecognizer *)gestureRecognizer
{
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:{
            
            _originalPoint = self.imageView.center;
            
            break;
        };
        case UIGestureRecognizerStateChanged:{
            
            CGFloat xDistance = [gestureRecognizer translationInView:self.imageView].x;
            CGFloat yDistance = [gestureRecognizer translationInView:self.imageView].y;
            
            CGPoint velocity = [gestureRecognizer velocityInView:gestureRecognizer.view];
            
            if (fabs(velocity.x) > fabs(velocity.y)) {
                if (velocity.x > 0) {
                    //swipe right
                    self.imageView.center = CGPointMake(_originalPoint.x + xDistance, _originalPoint.y + yDistance);
                    
                    if (xDistance > 100) {
                        self.actionImageView.image = [UIImage imageNamed:@"heart.png"];
                        self.actionImageView.hidden = NO;
                        
                        _action = 1; //[like post]
                    }
        
                } else {
                    //swipe left
                    self.imageView.center = CGPointMake(_originalPoint.x + xDistance, _originalPoint.y + yDistance);
                    
                    //[self unlikePost];
                    
                    if (fabs(xDistance) > 100) {
                        self.actionImageView.image = [UIImage imageNamed:@"heartbroken.png"];
                        self.actionImageView.hidden = NO;
                        
                        _action = 2; //[unlike post]
                    }
                    
                }
            } else {
                if (velocity.y > 0) {
                    //swipe down
                    self.imageView.center = CGPointMake(_originalPoint.x + xDistance, _originalPoint.y + yDistance);
                    
                    if (yDistance > 100) {
                        self.actionImageView.image = [UIImage imageNamed:@"reblog.png"];
                        self.actionImageView.hidden = NO;
                        
                        _action = 3; //[reblog post]
                    }
                    
                } else {
                    //swipe up
                    self.imageView.center = CGPointMake(_originalPoint.x + xDistance, _originalPoint.y + yDistance);

                    if (fabs(yDistance) > 100) {
                        self.actionImageView.image = [UIImage imageNamed:@"share.png"];
                        self.actionImageView.hidden = NO;
                        
                        _action = 4; //[share post]
                    }
                }
            }
            
            break;
        };
        case UIGestureRecognizerStateEnded: {
            [self resetViewPositionAndTransformations];
            
            switch (_action) {
                case 1:
                    //NSLog(@"like post");
                    [self likePost];
                    break;
                case 2:
                    //NSLog(@"unlike post");
                    [self unlikePost];
                    break;
                case 3:
                    //NSLog(@"reblog post");
                    [self confirmToReblog];
                    break;
                case 4:
                    //NSLog(@"share post");
                    [self sharePost:self.post];
                    
                    //[self savePostToPhotoAlbum];
                    break;
                default:
                    break;
            }
            
            self.actionImageView.image = nil;
            self.actionImageView.hidden = YES;
            
            break;
        };
        case UIGestureRecognizerStatePossible:break;
        case UIGestureRecognizerStateCancelled:break;
        case UIGestureRecognizerStateFailed:break;
    }
}

- (void)resetViewPositionAndTransformations
{
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.imageView.center = _originalPoint;
                         self.imageView.transform = CGAffineTransformMakeRotation(0);
                     }];
}

- (void)likePost
{
    [[TMAPIClient sharedInstance] like:[NSString stringWithFormat:@"%@", self.post[@"id"]]
                             reblogKey:[NSString stringWithFormat:@"%@", self.post[@"reblog_key"]]
                              callback:^(id results, NSError *error) {
                                  if (error) {
                                      NSLog(@"like post error: %@ %@", error, [error description]);
                                  }
        
    }];
}

- (void)unlikePost
{
    [[TMAPIClient sharedInstance] unlike:[NSString stringWithFormat:@"%@", self.post[@"id"]]
                             reblogKey:[NSString stringWithFormat:@"%@", self.post[@"reblog_key"]]
                              callback:^(id results, NSError *error) {
                                  if (error) {
                                      NSLog(@"unlike post error: %@ %@", error, [error description]);
                                  }
                                  
                              }];
}

- (void)reblogPost
{

    [[TMAPIClient sharedInstance] userInfo:^(id result, NSError *error) {
        if (error) {
            NSLog(@"loading error: %@ %@", error, [error description]);
        }
        
        [[TMAPIClient sharedInstance] reblogPost:result[@"user"][@"name"]
                                      parameters:@{@"id" : [NSString stringWithFormat:@"%@", self.post[@"id"]],
                                                   @"reblog_key" : [NSString stringWithFormat:@"%@", self.post[@"reblog_key"]]
                                                   }
                                        callback:^(id resutls, NSError *error) {
                                            if (error) {
                                                NSLog(@"reblog error: %@ %@", error, [error description]);
                                            }
                                        }];
    }];
}

- (void)sharePost:(NSDictionary *)post
{
    
    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[@"Check this out!", post[@"image_permalink"]] applicationActivities:nil];
    
    NSArray *excludedActivities = @[UIActivityTypeAddToReadingList,
                                    UIActivityTypeAssignToContact,
                                    UIActivityTypePostToVimeo,
                                    ];
    
    controller.excludedActivityTypes = excludedActivities;
    
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)confirmToReblog
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Reblog" message:@"Sure about reblog?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"YES!", nil];
    [alert show];
}

#pragma mark - UIAlertView Delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        //cancel button pressed
    } else {
        [self reblogPost];
    }
    
    self.imageView.center = self.view.center;
    self.actionImageView.hidden = YES;
}

@end

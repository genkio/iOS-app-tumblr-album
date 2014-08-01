//
//  UPFPhotoViewController.m
//  Tumblralbum
//
//  Created by Jwu on 5/30/14.
//  Copyright (c) 2014 UPF. All rights reserved.
//

#import "UPFPhotoViewController.h"
#import "UIImageView+WebCache.h"
#import "TMAPIClient.h"

@interface UPFPhotoViewController ()

@end

@implementation UPFPhotoViewController {
    UIToolbar *_toolbar;
    UIImageView *_actionImageView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor blackColor];

    NSURL *imageURL = [self parsePhotoURLStringFromPost:self.post];
    [self.imageView setImageWithURL:imageURL];
    [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:self.imageView];
    
    [self.imageView setImageWithURL:imageURL];
    [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
    
    if ([self.post[@"liked"] integerValue] == 1) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Unlike"
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(unlike:)];
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Like"
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(like:)];
    }
    
    _toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 44, self.view.frame.size.width, 44)];
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithTitle:@"Share" style:UIBarButtonItemStylePlain target:self action:@selector(share:)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *reblogButton = [[UIBarButtonItem alloc] initWithTitle:@"Reblog" style:UIBarButtonItemStylePlain target:self action:@selector(reblog:)];
    
    NSArray *items = [NSArray arrayWithObjects:shareButton, flex, reblogButton, nil];
    _toolbar.items = items;
    
    [self.view addSubview:_toolbar];
    
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapDetected:)];
    singleTap.numberOfTapsRequired = 1;
    self.imageView.userInteractionEnabled = YES;
    [self.imageView addGestureRecognizer:singleTap];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapDetected:)];
    doubleTap.numberOfTapsRequired = 2;
    self.imageView.userInteractionEnabled = YES;
    [self.imageView addGestureRecognizer:doubleTap];
    
    [singleTap requireGestureRecognizerToFail:doubleTap];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    _toolbar.hidden = YES;
}

#pragma helper methods

- (void)singleTapDetected:(id)sender
{
    //NSLog(@"single tap detected");
    if (self.navigationController.navigationBarHidden == YES) {
        self.navigationController.navigationBarHidden = NO;
        _toolbar.hidden = NO;
        self.view.backgroundColor = [UIColor whiteColor];
    } else {
        self.navigationController.navigationBarHidden = YES;
        _toolbar.hidden = YES;
        self.view.backgroundColor = [UIColor blackColor];
    }
}

- (void)doubleTapDetected:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
    self.navigationController.navigationBarHidden = NO;
}

- (void)actionImageAnimation:(NSString *)imageNamed
{
    _actionImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 150, 150)];
    _actionImageView.center = self.view.center;
    _actionImageView.image = [UIImage imageNamed:imageNamed];
    [self.imageView addSubview:_actionImageView];
    
    [UIView animateWithDuration:1.0f animations:^{
        _actionImageView.image = [UIImage imageNamed:imageNamed];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:1.0f animations:^{
            _actionImageView.frame = CGRectMake(self.imageView.center.x, self.imageView.center.y, 0, 0);
        } completion:^(BOOL finished) {
            nil;
        }];
    }];
}

- (void)like:(id)sender
{
    //NSLog(@"like");
    
    [[TMAPIClient sharedInstance] like:[NSString stringWithFormat:@"%@", self.post[@"id"]]
                             reblogKey:[NSString stringWithFormat:@"%@", self.post[@"reblog_key"]]
                              callback:^(id results, NSError *error) {
                                  if (error) {
                                      NSLog(@"like post error: %@ %@", error, [error description]);
                                  } else {
                                      [self actionImageAnimation:@"heart.png"];
                                  }
                                  
                              }];
}

- (void)unlike:(id)sender
{
    //NSLog(@"unlike");
    
    [[TMAPIClient sharedInstance] unlike:[NSString stringWithFormat:@"%@", self.post[@"id"]]
                               reblogKey:[NSString stringWithFormat:@"%@", self.post[@"reblog_key"]]
                                callback:^(id results, NSError *error) {
                                    if (error) {
                                        NSLog(@"unlike post error: %@ %@", error, [error description]);
                                    } else {
                                        [self actionImageAnimation:@"heartbroken.png"];
                                    }
                                    
                                }];
}

- (void)share:(id)sender
{
    //NSLog(@"share");
    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[@"", self.post[@"image_permalink"]] applicationActivities:nil];
    
    NSArray *excludedActivities = @[UIActivityTypeAddToReadingList,
                                    UIActivityTypeAssignToContact,
                                    UIActivityTypePostToVimeo,
                                    ];
    
    controller.excludedActivityTypes = excludedActivities;
    
    [self presentViewController:controller animated:YES completion:nil];

}

- (void)reblog:(id)sender
{
    //NSLog(@"reblog");
    
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
                                            } else {
                                                [self actionImageAnimation:@"reblog.png"];
                                            }
                                        }];
    }];
}

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

@end

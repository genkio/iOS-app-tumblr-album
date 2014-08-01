//
//  UPFPhotoViewController.h
//  Tumblralbum
//
//  Created by Jwu on 5/30/14.
//  Copyright (c) 2014 UPF. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UPFPhotoViewController : UIViewController

@property (strong, nonatomic) NSDictionary *post;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@end

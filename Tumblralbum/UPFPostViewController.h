//
//  UPFPostViewController.h
//  Tumblralbum
//
//  Created by Jwu on 5/21/14.
//  Copyright (c) 2014 UPF. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UPFPostViewController : UIViewController <UIScrollViewDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) NSDictionary *post;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UIImageView *actionImageView;


@end

//
//  UPFCollectionViewController.h
//  Tumblralbum
//
//  Created by Jwu on 5/21/14.
//  Copyright (c) 2014 UPF. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CHTCollectionViewWaterfallLayout.h"

@interface UPFCollectionViewController : UICollectionViewController <CHTCollectionViewDelegateWaterfallLayout>

@property (nonatomic, strong) NSMutableArray *dashboardPosts;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *likesButton;


@end

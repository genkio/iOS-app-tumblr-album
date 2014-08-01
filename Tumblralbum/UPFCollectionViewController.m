//
//  UPFCollectionViewController.m
//  Tumblralbum
//
//  Created by Jwu on 5/21/14.
//  Copyright (c) 2014 UPF. All rights reserved.
//

#import "UPFCollectionViewController.h"
#import "TMAPIClient.h"
#import "UIImageView+WebCache.h"
#import "UPFPostViewController.h"
#import "LTHPasscodeViewController.h"
#import "UPFPhotoViewController.h"


@interface UPFCollectionViewController ()

@end

@implementation UPFCollectionViewController {

    NSString *_tumblrAuthToken;
    NSString *_tumblrAuthTokenSecret;
    
    UIActivityIndicatorView *_initialLoadingIndicator;
    
    BOOL _hasMore;
    BOOL _reRefresh;
    int _offset;
    
    //NSDictionary *_bookmarkedPost;
}

//removed all bookmark features at 2014/5/27

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.hidesBackButton = YES;
    
    if (!self.dashboardPosts) {
        self.dashboardPosts = [[NSMutableArray alloc] init];
    }
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshAction:) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.refreshControl];
    
    //set up layout and style
    CHTCollectionViewWaterfallLayout *layout = [[CHTCollectionViewWaterfallLayout alloc] init];
    layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    layout.minimumColumnSpacing = 10;
    layout.minimumInteritemSpacing = 10;
    layout.columnCount = 2;
    self.collectionView.collectionViewLayout = layout;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    _initialLoadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _initialLoadingIndicator.color = [UIColor blackColor];
    _initialLoadingIndicator.center = self.view.center;
    [self.view addSubview:_initialLoadingIndicator];
    [_initialLoadingIndicator startAnimating];
    
    self.likesButton.title = @"";
    
    [self loadAuthentication];
    
    if (_tumblrAuthToken.length > 0) {
        
        NSLog(@"authentication loaded");
        [TMAPIClient sharedInstance].OAuthToken = _tumblrAuthToken;
        [TMAPIClient sharedInstance].OAuthTokenSecret = _tumblrAuthTokenSecret;
        
        [self requestDashboardPosts];

    }

}


#pragma mark - CHTCollectionViewWaterfallLayout delegate

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSDictionary *post = nil;
    
    if (_hasMore) {
        if (indexPath.row == 0) {
            post = self.dashboardPosts[indexPath.row];
        } else {
            post = self.dashboardPosts[indexPath.row - 1];
        }
    } else {
        post = self.dashboardPosts[indexPath.row];
    }

    float width = 0.0;
    float height = 0.0;
    
    NSArray *photos = post[@"photos"];
    if (photos.count > 0) {
        NSArray *photoSizes = photos[0][@"alt_sizes"];
        if (photoSizes.count > 1) {
            NSDictionary *photoSize = photoSizes[1];
            width = [photoSize[@"width"] floatValue];
            height = [photoSize[@"height"] floatValue];
        }
    }
    
    float cellWidth = (self.view.frame.size.width - 30.0) / 2.0;
    
    float ratio = cellWidth / width;
    return CGSizeMake(cellWidth, height * ratio);
}

#pragma mark - uicollectionview delegate

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (_hasMore) {
        return self.dashboardPosts.count + 1;
    } else {
        return self.dashboardPosts.count;
    }
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *identifier = @"Cell";
    
    UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    if (indexPath.row < self.dashboardPosts.count) {
        
        [_initialLoadingIndicator stopAnimating];
        _initialLoadingIndicator.hidden = YES;
        
        self.likesButton.title = @"Likes";

        UIImageView *imageView = [[UIImageView alloc] initWithFrame:cell.bounds];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        [cell addSubview:imageView];
        
        //create a placeholer image out of color
        CGSize imageSize = CGSizeMake(64, 64);
        UIColor *fillColor = [UIColor colorWithRed:0.973 green:0.973 blue:0.973 alpha:1]; //*#f8f8f8*
        UIGraphicsBeginImageContextWithOptions(imageSize, YES, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        [fillColor setFill];
        CGContextFillRect(context, CGRectMake(0, 0, imageSize.width, imageSize.height));
        UIImage *placeholder = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSDictionary *post = self.dashboardPosts[indexPath.row];
        NSURL *imageURL = [self parsePhotoURLStringFromPost:post];
        [imageView setImageWithURL:imageURL placeholderImage:placeholder];
        
        return cell;
    } else {
        
        if (self.dashboardPosts.count > 0) {
            if (_hasMore) {
                [self requestDashboardPosts];
            }
        }
        
    cell.tag = 2;
    return cell;
        
    }
}

#pragma helper methods

- (void)refreshAction:(id)sender
{
    _reRefresh = YES;
    [self requestDashboardPosts];
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

- (void)requestDashboardPosts
{
    if (self.dashboardPosts.count > 0) {
        _offset = self.dashboardPosts.count;
    }
    
    if (_reRefresh) {
        _offset = 0;
    }
    
    [[TMAPIClient sharedInstance] dashboard:@{@"type" : @"photo",
                                              @"limit" : @"20",
                                              @"offset" : [NSString stringWithFormat:@"%d", _offset]}
                                   callback:^(id results, NSError *error) {
                                       
                                       NSArray *posts = results[@"posts"];
                                       
                                       if (posts.count > 0) {
                                           
                                           _hasMore = YES;
                                           
                                           if (_reRefresh) {
                                               [self.dashboardPosts removeAllObjects];
                                           }
                                           
                                           _reRefresh = NO;
                                           
                                           [self.dashboardPosts addObjectsFromArray:posts];
                                           [self.collectionView reloadData];
                                       } else {
                                           _hasMore = NO;
                                           //NSLog(@"no more posts to load");
                                       }
                                    
                                       [self.refreshControl endRefreshing];
                                       
                                       if (error) {
                                           NSLog(@"request post error: %@ %@", error, [error description]);
                                       }
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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"toPhoto"]) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:sender];
        NSDictionary *selectedPost = self.dashboardPosts[indexPath.row];
        UPFPhotoViewController *photoVC = segue.destinationViewController;
        photoVC.post = selectedPost;
    }
}



@end

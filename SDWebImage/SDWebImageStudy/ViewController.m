//
//  ViewController.m
//  SDWebImageStudy
//
//  Created by 黄成都 on 15/9/27.
//  Copyright (c) 2015年 黄成都. All rights reserved.
//

#import "ViewController.h"
#import "UIImageView+WebCache.h"
#import "UIImage+GIF.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *gifImageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.imageView sd_setImageWithURL:[NSURL URLWithString:@"http://p18.qhimg.com/dr/48_48_/t0108c33d3321352682.png"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        
    }];
    
    [self.imageView sd_setImageWithURL:[NSURL URLWithString:@"http://p18.qhimg.com/dr/48_48_/t0108c33d3321352682.png"] placeholderImage:nil options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        
    }];
    
    /**
     *  加载GIF图片
     */
    UIImage *gifImage = [UIImage sd_animatedGIFNamed:@"123"];
    //[gifImage sd_animatedImageByScalingAndCroppingToSize:CGSizeMake(20, 20)];
    self.gifImageView.image  = gifImage;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

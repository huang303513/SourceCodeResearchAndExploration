//
//  SDWebImageManagerViewController.m
//  SDWebImage4.X源码阅读201704
//
//  Created by huangchengdu on 17/4/29.
//  Copyright © 2017年 huangchengdu. All rights reserved.
//

#import "SDWebImageManagerViewController.h"
#import "SDWebImageManager.h"


@interface SDWebImageManagerViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation SDWebImageManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

/**
 图片加载以后。解压缩与非加压缩。

 @param sender nil
 */
- (IBAction)clickButton1:(id)sender {
    NSString *url = @"http://i1.piimg.com/4851/059582e7cf7a7f43.png";
    SDWebImageOptions type;
    //图片处理以后，再解压缩。然后再缓存
    /*
     通过是否设置SDWebImageScaleDownLargeImages属性。我们发现缓存的图片大小不同。如果设置了，则图片大小有11k。没有设置，则大小只有7k
     */
    if (true) {
        type = SDWebImageScaleDownLargeImages;
    }
    [[SDWebImageManager sharedManager] loadImageWithURL:[NSURL URLWithString:url] options:type progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        NSLog(@"收到：%d---总共：%d",receivedSize,expectedSize);
        
    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        self.imageView.image = image;
    }];

}
- (IBAction)clickButton2:(id)sender {
    
}
- (IBAction)clickButton3:(id)sender {
    
}
- (IBAction)clickButton4:(id)sender {
    
}
- (IBAction)clickButton5:(id)sender {
    
}
- (IBAction)clickButton6:(id)sender {
    
}
- (IBAction)clickButton7:(id)sender {
    
}
- (IBAction)clickButton8:(id)sender {
    
}
- (IBAction)clickButton9:(id)sender {
    
}

@end

//
//  SDImageCacheViewController.m
//  SDWebImage4.X源码阅读201704
//
//  Created by huangchengdu on 17/4/28.
//  Copyright © 2017年 huangchengdu. All rights reserved.
//

#import "SDImageCacheViewController.h"
#import "SDImageCache.h"
#import "Config.h"

NSString *key = @"SDWebImageClassDiagram.png";
@interface SDImageCacheViewController ()
@property(nonatomic,strong)SDImageCache *imageCache;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation SDImageCacheViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!_imageCache) {
        _imageCache = [SDImageCache sharedImageCache];
    }
}

/**
 缓存一张图片的过程

 @param sender nil
 */
- (IBAction)clickButton1:(id)sender {

    [self.imageCache storeImage:[UIImage imageNamed:key] forKey:key toDisk:YES completion:^{
        alert(@"回调");
    }];
}

- (IBAction)clickButton2:(id)sender {
    self.imageView.image = nil;
    [self.imageCache queryCacheOperationForKey:key done:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
        NSString *type;
        if (cacheType == SDImageCacheTypeMemory) {
            type = @"内存缓存";
        }else if (cacheType == SDImageCacheTypeDisk){
            type = @"磁盘缓存";
        }else{
            type = @"没有缓存";
        }
        alert(type);
        self.imageView.image = [UIImage imageWithData:data];
    }];
}
- (IBAction)clickButton3:(id)sender {
    
}
- (IBAction)clickButton4:(id)sender {
    
}
- (IBAction)clickButton5:(id)sender {
    
}


@end

//
//  UIImage+GIF.m
//  LBGIFImage
//
//  Created by Laurin Brandner on 06.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIImage+GIF.h"
#import <ImageIO/ImageIO.h>

@implementation UIImage (GIF)
/**
 *  通过传入一张gif图片的数据，处理返回可以显示动态效果的图片。
 *
 *  @param data gif图片数据
 *
 *  @return 可以动态变化的图片数据
 */
+ (UIImage *)sd_animatedGIFWithData:(NSData *)data {
    if (!data) {
        return nil;
    }
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    //有多少张图片
    size_t count = CGImageSourceGetCount(source);

    UIImage *animatedImage;

    if (count <= 1) {//只有一张图片
        animatedImage = [[UIImage alloc] initWithData:data];
    }
    else {//有多张图片
        NSMutableArray *images = [NSMutableArray array];
        //保存播放一个图片需要的时间
        NSTimeInterval duration = 0.0f;

        for (size_t i = 0; i < count; i++) {
            CGImageRef image = CGImageSourceCreateImageAtIndex(source, i, NULL);
            //计算一次图片的时间
            duration += [self sd_frameDurationAtIndex:i source:source];
            //把图片加入一个数组。
            [images addObject:[UIImage imageWithCGImage:image scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp]];

            CGImageRelease(image);
        }
        //每张图片播放0.1秒。
        if (!duration) {
            duration = (1.0f / 10.0f) * count;
        }
        //把图片数组转换为一个会动的图片
        animatedImage = [UIImage animatedImageWithImages:images duration:duration];
    }

    CFRelease(source);

    return animatedImage;
}
/**
 *  计算播放第index张图片需要的时间。
 *
 *  @param index  第几张
 *  @param source gif图片资源
 *
 *  @return 返回一个时间。
 */
+ (float)sd_frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source {
    float frameDuration = 0.1f;
    //得到第index张图片的属性信息
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
    //得到图片的gif信息
    NSDictionary *gifProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];
    //得到gif信息中的时间
    NSNumber *delayTimeUnclampedProp = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTimeUnclampedProp) {
        frameDuration = [delayTimeUnclampedProp floatValue];
    }
    else {

        NSNumber *delayTimeProp = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTimeProp) {
            frameDuration = [delayTimeProp floatValue];
        }
    }
    //如果gif中一张图片的持续时间小于0.1秒。则设置为0.1秒
    if (frameDuration < 0.011f) {
        frameDuration = 0.100f;
    }
    CFRelease(cfFrameProperties);
    return frameDuration;
}
/**
 *  传入一张gif图片的名字。。返回一张可以动得图片
 *
 *  @param name 图片名字
 *
 *  @return 可以动得图片
 */
+ (UIImage *)sd_animatedGIFNamed:(NSString *)name {
    //是否是视网膜屏幕
    CGFloat scale = [UIScreen mainScreen].scale;

    if (scale > 1.0f) {
        //加载两倍图片
        NSString *retinaPath = [[NSBundle mainBundle] pathForResource:[name stringByAppendingString:@"@2x"] ofType:@"gif"];
        //得到GIF图片的数据
        NSData *data = [NSData dataWithContentsOfFile:retinaPath];

        if (data) {
            return [UIImage sd_animatedGIFWithData:data];
        }
        //如果没有两倍图片
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"gif"];
        //一倍图片的数据
        data = [NSData dataWithContentsOfFile:path];

        if (data) {
            return [UIImage sd_animatedGIFWithData:data];
        }

        return [UIImage imageNamed:name];
    }
    else {//直接加载一倍图片
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"gif"];

        NSData *data = [NSData dataWithContentsOfFile:path];

        if (data) {
            return [UIImage sd_animatedGIFWithData:data];
        }

        return [UIImage imageNamed:name];
    }
}

- (UIImage *)sd_animatedImageByScalingAndCroppingToSize:(CGSize)size {
    if (CGSizeEqualToSize(self.size, size) || CGSizeEqualToSize(size, CGSizeZero)) {
        return self;
    }

    CGSize scaledSize = size;
    CGPoint thumbnailPoint = CGPointZero;

    CGFloat widthFactor = size.width / self.size.width;
    CGFloat heightFactor = size.height / self.size.height;
    CGFloat scaleFactor = (widthFactor > heightFactor) ? widthFactor : heightFactor;
    scaledSize.width = self.size.width * scaleFactor;
    scaledSize.height = self.size.height * scaleFactor;

    if (widthFactor > heightFactor) {
        thumbnailPoint.y = (size.height - scaledSize.height) * 0.5;
    }
    else if (widthFactor < heightFactor) {
        thumbnailPoint.x = (size.width - scaledSize.width) * 0.5;
    }

    NSMutableArray *scaledImages = [NSMutableArray array];

    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);

    for (UIImage *image in self.images) {
        [image drawInRect:CGRectMake(thumbnailPoint.x, thumbnailPoint.y, scaledSize.width, scaledSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();

        [scaledImages addObject:newImage];
    }

    UIGraphicsEndImageContext();

    return [UIImage animatedImageWithImages:scaledImages duration:self.duration];
}

@end

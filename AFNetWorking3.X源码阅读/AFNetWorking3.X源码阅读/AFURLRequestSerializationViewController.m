//
//  AFURLRequestSerializationViewController.m
//  AFNetWorking3.X源码阅读
//
//  Created by huangchengdu on 17/4/22.
//  Copyright © 2017年 huangchengdu. All rights reserved.
//

#import "AFURLRequestSerializationViewController.h"
#import "AFNetworking.h"


@interface AFURLRequestSerializationViewController ()

@end

@implementation AFURLRequestSerializationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)request1:(id)sender {
    //请求头参数
    NSDictionary *dic = @{
                          @"businessType":@"CC_USER_CENTER",
                          @"fileType":@"image",
                          @"file":@"img.jpeg"
                          };
    //请求体图片数据
    NSData *imageData = UIImagePNGRepresentation([UIImage imageNamed:@"1.png"]);
    //创建request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:url]];
    //post方法
    [request setHTTPMethod:@"POST"];
    // 设置请求头格式为Content-Type:multipart/form-data; boundary=xxxxx
    //[request setValue:@"multipart/form-data; boundary=xxxxx" forHTTPHeaderField:@"Content-Type"];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *task = [manager POST:url parameters:dic constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        //请求体里面的参数
        NSDictionary *bodyDic = @{
                                  @"Content-Disposition":@"form-data;name=\"file\";filename=\"img.jpeg\"",
                                  @"Content-Type":@"image/png",
                                  };
        [formData appendPartWithHeaders:bodyDic body:imageData];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        NSLog(@"下载进度");
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"下载成功:%@",responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"下载失败%@",error);
    }];
    [task resume];
}

- (IBAction)request2:(id)sender {
    
}

- (IBAction)request3:(id)sender {
    
}


@end

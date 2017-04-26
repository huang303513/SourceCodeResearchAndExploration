//
//  AFURLRequestSerializationViewController.m
//  AFNetWorking3.X源码阅读
//
//  Created by huangchengdu on 17/4/22.
//  Copyright © 2017年 huangchengdu. All rights reserved.
//

#import "AFURLRequestSerializationViewController.h"
#import "AFNetworking.h"
#import "AFURLRequestSerialization.h"


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
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://jsonplaceholder.typicode.com/posts"]];
    //指请求体的类型。由于我们test.txt里面的文件是json格式的字符串。所以我这里指定为`application/json`
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"POST"];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [request setTimeoutInterval:20];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"txt"];
    NSURL *url = [NSURL URLWithString:[path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *task = [session uploadTaskWithRequest:request fromFile:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString *result = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@",result);
    }];
    [task resume];
    
    
    
//    AFHTTPRequestSerializer  *requestSerialization = [AFHTTPRequestSerializer serializer];
//    NSURLRequest *distionRequest = [requestSerialization requestWithMultipartFormRequest:request writingStreamContentsToFile:[NSURL URLWithString:path] completionHandler:^(NSError * _Nullable error) {
//        NSLog(@"%@",error);
//    }];
//    
//    NSURLSessionDataTask *task1 = [session uploadTaskWithRequest:distionRequest fromFile:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        NSString *result = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
//        NSLog(@"%@",result);
//    }];
//    [task1 resume];
//    
}

- (IBAction)request3:(id)sender {
    
}


@end


/**
 .h文件和.m文件放在同一个文件
 */
@interface mytest:NSObject
@property(nonatomic,copy)NSString *name;
-(void)doTest;
@end


@interface mytest()
@property(nonatomic,strong)NSString *phone;
-(void)updateTest;
@end

@implementation mytest

-(void)doTest{

}

-(void)updateTest{

}

@end

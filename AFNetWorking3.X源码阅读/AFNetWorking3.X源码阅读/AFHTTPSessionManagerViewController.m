//
//  AFSecurityPolicyViewController.m
//  AFNetWorking3.X源码阅读
//
//  Created by huangchengdu on 17/4/19.
//  Copyright © 2017年 huangchengdu. All rights reserved.
//

#import "AFHTTPSessionManagerViewController.h"
#import "AFNetworking.h"

@interface AFHTTPSessionManagerViewController ()

@end

@implementation AFHTTPSessionManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)visitBaidu:(id)sender {
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSDictionary *params = @{
                             @"uuid":@"4e3abc0f-1824-4a5d-982f-7d9dee92d9cd",
                             @"referrer":@"http://www.jianshu.com/p/e15592ce40ae"
                             };
    NSURLSessionDataTask *task = [manager POST:@"http://www.jianshu.com//notes/e15592ce40ae/mark_viewed.json" parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
        NSLog(@"进度更新");
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"返回数据：%@",responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"返回错误：%@",error);
    }];
    [task resume];
}

- (IBAction)updatePic:(id)sender {
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

- (IBAction)multipartformPost3:(id)sender {
    //参数
    NSDictionary *dic = @{
                          @"businessType":@"CC_USER_CENTER",
                          @"fileType":@"image",
                          @"file":@"img.jpeg"
                          };
    NSString *boundaryString = @"xxxxx";
    NSMutableString *str = [NSMutableString string];
    [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [str appendFormat:@"--%@\r\n",boundaryString];
        [str appendFormat:@"%@name=\"%@\"\r\n\r\n",@"Content-Disposition: form-data;",key];
        [str appendFormat:@"%@\r\n",obj];
    }];
    
    NSMutableData *requestMutableData=[NSMutableData data];
    
    [str appendFormat:@"--%@\r\n",boundaryString];
    [str appendFormat:@"%@:%@",@"Content-Disposition",@"form-data;"];
    [str appendFormat:@"%@=\"%@\";",@"name",@"file"];
    [str appendFormat:@"%@=\"%@\"\r\n",@"filename",@"img1.jpeg"];
    [str appendFormat:@"%@:%@\r\n\r\n",@"Content-Type",@"image/png"];
    //转换成为二进制数据
    [requestMutableData appendData:[str dataUsingEncoding:NSUTF8StringEncoding]];
    NSData *imageData = UIImagePNGRepresentation([UIImage imageNamed:@"1.png"]);
    //文件数据部分
    [requestMutableData appendData:imageData];
    //添加结尾boundary
    [requestMutableData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundaryString] dataUsingEncoding:NSUTF8StringEncoding]];

    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:url]];
    //post方法
    [request setHTTPMethod:@"POST"];
    // 设置请求头格式为Content-Type:multipart/form-data; boundary=xxxxx
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundaryString] forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = requestMutableData;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString *result = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@",result);
    }];
    
    [task resume];

}

- (IBAction)multipartformPost2:(id)sender {
    //参数
    NSDictionary *dic = @{
                          @"businessType":@"CC_USER_CENTER",
                          @"fileType":@"image",
                          @"file":@"img.jpeg"
                          };
    NSString *boundaryString = @"xxxxx";
    NSMutableString *str = [NSMutableString string];
    [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [str appendFormat:@"--%@\r\n",boundaryString];
        [str appendFormat:@"%@name=\"%@\"\r\n\r\n",@"Content-Disposition: form-data;",key];
        [str appendFormat:@"%@\r\n",obj];
    }];
    
     NSMutableData *requestMutableData=[NSMutableData data];

    [str appendFormat:@"--%@\r\n",boundaryString];
    [str appendFormat:@"%@:%@",@"Content-Disposition",@"form-data;"];
    [str appendFormat:@"%@=\"%@\";",@"name",@"file"];
    [str appendFormat:@"%@=\"%@\"\r\n",@"filename",@"img1.jpeg"];
    [str appendFormat:@"%@:%@\r\n\r\n",@"Content-Type",@"image/png"];
    //转换成为二进制数据
    [requestMutableData appendData:[str dataUsingEncoding:NSUTF8StringEncoding]];
    NSData *imageData = UIImagePNGRepresentation([UIImage imageNamed:@"1.png"]);
    //文件数据部分
    [requestMutableData appendData:imageData];
    //添加结尾boundary
    [requestMutableData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundaryString] dataUsingEncoding:NSUTF8StringEncoding]];
    //创建一个请求对象
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:url]];
    //post方法
    [request setHTTPMethod:@"POST"];
    // 设置请求头格式为Content-Type:multipart/form-data; boundary=xxxxx
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundaryString] forHTTPHeaderField:@"Content-Type"];
    //session
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *task = [session uploadTaskWithRequest:request fromData:requestMutableData completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString *result = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@",result);
    }];
    [task resume];

}





- (IBAction)applicationjsonPOST1:(id)sender {
    
}

- (IBAction)applicationjsonPOST2:(id)sender {
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
}

@end

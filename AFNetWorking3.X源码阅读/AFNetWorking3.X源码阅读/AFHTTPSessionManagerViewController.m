//
//  AFSecurityPolicyViewController.m
//  AFNetWorking3.X源码阅读
//
//  Created by huangchengdu on 17/4/19.
//  Copyright © 2017年 huangchengdu. All rights reserved.
//

#import "AFHTTPSessionManagerViewController.h"
#import "AFNetworking.h"

static NSString *url = @"http://activity.test.chuangchuang.cn/uploadFile";
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
    [request setValue:@"multipart/form-data; boundary=xxxxx" forHTTPHeaderField:@"Content-Type"];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *task = [manager POST:@"http://activity.test.chuangchuang.cn/uploadFile" parameters:dic constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
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
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:url]];
    //post方法
    [request setHTTPMethod:@"POST"];
    //参数
    NSDictionary *dic = @{
                          @"businessType":@"CC_USER_CENTER",
                          @"fileType":@"image",
                          @"file":@"img.jpeg"
                          };
    NSMutableString *str = [NSMutableString string];
    [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [str appendFormat:@"%@=%@&",key,obj];
    }];
    NSString *jsonString = [str substringToIndex:str.length -1];
    NSLog(@"%@",jsonString);
    //1.拼接--xxxxx。分隔符开始是--
    NSMutableString *myString=[NSMutableString stringWithFormat:@"%@\r\n\r\n--xxxxx\r\n",jsonString];
    
    //2.拼接Content-Disposition:form-data;name="file";filename="img.jpeg"
    [myString appendString:[NSString stringWithFormat:@"Content-Disposition:form-data;name=\"file\";filename=\"img.jpeg\" \r\n"]];
    //png图片
    [myString appendString:[NSString stringWithFormat:@"Content-Type:image/png\r\n"]];
    // 创建可拼接NSMutableData对象
    NSMutableData *requestMutableData=[NSMutableData data];
    //转换成为二进制数据
    [requestMutableData appendData:[myString dataUsingEncoding:NSUTF8StringEncoding]];
    [requestMutableData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    NSData *imageData = UIImagePNGRepresentation([UIImage imageNamed:@"1.png"]);
    //4.文件数据部分
    [requestMutableData appendData:imageData];
    [requestMutableData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    //5. 结尾的时候的分隔符--xxxxx--，左右两边都是--
    [requestMutableData appendData:[[NSString stringWithFormat:@"--xxxxx--"] dataUsingEncoding:NSUTF8StringEncoding]];
    // 设置请求头格式为Content-Type:multipart/form-data; boundary=xxxxx
    [request setValue:@"multipart/form-data; boundary=xxxxx" forHTTPHeaderField:@"Content-Type"];
    
    request.HTTPBody = requestMutableData;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString *result = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@",result);
    }];
    
    [task resume];

}

- (IBAction)multipartformPost2:(id)sender {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:url]];
    //post方法
    [request setHTTPMethod:@"POST"];
    //参数
    NSDictionary *dic = @{
                          @"businessType":@"CC_USER_CENTER",
                          @"fileType":@"image",
                          @"file":@"img.jpeg"
                          };
    NSMutableString *str = [NSMutableString string];
    [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [str appendFormat:@"%@=%@&",key,obj];
    }];
    NSString *jsonString = [str substringToIndex:str.length -1];
    NSLog(@"%@",jsonString);
    //1.拼接--xxxxx。分隔符开始是--
    NSMutableString *myString=[NSMutableString stringWithFormat:@"%@\r\n\r\n--xxxxx\r\n",jsonString];
    
    //2.拼接Content-Disposition:form-data;name="file";filename="img.jpeg"
    [myString appendString:[NSString stringWithFormat:@"Content-Disposition:form-data;name=\"file\";filename=\"img.jpeg\" \r\n"]];
    //png图片
    [myString appendString:[NSString stringWithFormat:@"Content-Type:image/png\r\n"]];
    // 创建可拼接NSMutableData对象
    NSMutableData *requestMutableData=[NSMutableData data];
    //转换成为二进制数据
    [requestMutableData appendData:[myString dataUsingEncoding:NSUTF8StringEncoding]];
    [requestMutableData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    NSData *imageData = UIImagePNGRepresentation([UIImage imageNamed:@"1.png"]);
    //4.文件数据部分
    [requestMutableData appendData:imageData];
    [requestMutableData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    //5. 结尾的时候的分隔符--xxxxx--，左右两边都是--
    [requestMutableData appendData:[[NSString stringWithFormat:@"--xxxxx--"] dataUsingEncoding:NSUTF8StringEncoding]];
    // 设置请求头格式为Content-Type:multipart/form-data; boundary=xxxxx
    [request setValue:@"multipart/form-data; boundary=xxxxx" forHTTPHeaderField:@"Content-Type"];
    
    
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
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"POST"];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [request setTimeoutInterval:20];
    NSURL *url = [NSURL URLWithString:[[NSBundle mainBundle] pathForResource:@"test" ofType:@"txt"]];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *task = [session uploadTaskWithRequest:request fromFile:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString *result = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@",result);
    }];
    [task resume];
}

@end

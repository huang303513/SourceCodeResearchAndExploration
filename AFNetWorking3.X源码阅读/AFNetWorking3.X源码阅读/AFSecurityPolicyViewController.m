//
//  AFSecurityPolicyViewController.m
//  AFNetWorking3.X源码阅读
//
//  Created by huangchengdu on 17/4/25.
//  Copyright © 2017年 huangchengdu. All rights reserved.
//

#import "AFSecurityPolicyViewController.h"
#import "AFNetworking.h"
@interface AFSecurityPolicyViewController ()

@end

@implementation AFSecurityPolicyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}
//自建证书认证
- (IBAction)buttion1:(id)sender {
    NSURL *url = [NSURL URLWithString:@"https://kyfw.12306.cn/otn/leftTicket/init"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
   // [request setValue:@"text/html" forHTTPHeaderField:@"Accept"];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    //指定安全策略
    manager.securityPolicy = [self ticketSecurityPolicy];
    //指定返回数据类型,默认是AFJSONResponseSerializer类型，犹豫这里不是JSON类型的返回数据，所以需要手动指定返回类型
    AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
    responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    manager.responseSerializer = responseSerializer;
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        NSLog(@"%@-----%@",[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding],error);
    }];
    [dataTask resume];

}

/**
 12306的认证证书，他的认证证书是自签名的

 @return 返回指定的认证策略
 */
-(AFSecurityPolicy*)ticketSecurityPolicy {
    // /先导入证书
    NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"12306" ofType:@"cer"];//证书的路径
    NSData *certData = [NSData dataWithContentsOfFile:cerPath];
    NSSet *set = [NSSet setWithObject:certData];
    
    AFSecurityPolicy *securityPolicy;
    if (true) {
        //对于自签名证书，这里只能是
        securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:set];
    }else{
        // AFSSLPinningModeCertificate 使用证书验证模式。下面这个方法会默认使用项目里面的所有证书
        securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    }
    // allowInvalidCertificates 是否允许无效证书（也就是自建的证书），默认为NO
    // 如果是需要验证自建证书，需要设置为YES
    securityPolicy.allowInvalidCertificates = YES;
    
    //validatesDomainName 是否需要验证域名，默认为YES；
    //假如证书的域名与你请求的域名不一致，需把该项设置为NO；如设成NO的话，即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险，建议打开。
    //置为NO，主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册通配符的域名*.google.com，但这个还是比较贵的。
    //如置为NO，建议自己添加对应域名的校验逻辑。
    securityPolicy.validatesDomainName = NO;
    
    return securityPolicy;
}

//认证证书认证
- (IBAction)button2:(id)sender {
    NSURL *url = [NSURL URLWithString:@"https://www.baidu.com"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    //[request setValue:@"text/html" forHTTPHeaderField:@"Accept"];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    //指定安全策略
    manager.securityPolicy = [self baiduSecurityPolicy];
    //指定返回数据类型,默认是AFJSONResponseSerializer类型，犹豫这里不是JSON类型的返回数据，所以需要手动指定返回类型
    AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
    responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    manager.responseSerializer = responseSerializer;
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        NSLog(@"%@-----%@",[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding],error);
    }];
    [dataTask resume];
}

/**
百度的的认证证书，他的认证证书是花钱买的，也就是不是自签名的证书。这种证书，如果我们要手动指定，pinmode只能是`AFSSLPinningModeNone`
 
 @return 返回指定的认证策略
 */
-(AFSecurityPolicy*)baiduSecurityPolicy {
    // /先导入证书
    NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"baidu" ofType:@"cer"];//证书的路径
    NSData *certData = [NSData dataWithContentsOfFile:cerPath];
    NSSet *set = [NSSet setWithObject:certData];
    
    AFSecurityPolicy *securityPolicy;
    if (true) {
        //这里只能用AFSSLPinningModeNone才能成功，而且我系统的证书列表里面已经有百度的证书了
        securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone withPinnedCertificates:set];
    }else{
        // AFSSLPinningModeCertificate 使用证书验证模式。下面这个方法会默认使用项目里面的所有证书
        securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    }
    // allowInvalidCertificates 是否允许无效证书（也就是自建的证书），默认为NO
    // 如果是需要验证自建证书，需要设置为YES
    securityPolicy.allowInvalidCertificates = NO;
    
    //validatesDomainName 是否需要验证域名，默认为YES；
    //假如证书的域名与你请求的域名不一致，需把该项设置为NO；如设成NO的话，即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险，建议打开。
    //置为NO，主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册通配符的域名*.google.com，但这个还是比较贵的。
    //如置为NO，建议自己添加对应域名的校验逻辑。
    securityPolicy.validatesDomainName = YES;
    
    return securityPolicy;
}


//系统证书认证
- (IBAction)button3:(id)sender {
    NSURL *url = [NSURL URLWithString:@"https://www.apple.com/"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    //指定返回数据类型,默认是AFJSONResponseSerializer类型，犹豫这里不是JSON类型的返回数据，所以需要手动指定返回类型
    AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
    responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    manager.responseSerializer = responseSerializer;
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        NSLog(@"%@-----%@",[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding],error);
    }];
    [dataTask resume];
}

@end

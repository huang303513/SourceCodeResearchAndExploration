//
//  AFURLSessionManagerViewController.m
//  AFNetWorking3.X源码阅读
//
//  Created by huangchengdu on 17/4/15.
//  Copyright © 2017年 huangchengdu. All rights reserved.
//

#import "AFURLSessionManagerViewController.h"
#import "AFURLSessionManager.h"

static NSString *const bigPic = @"http://i1.piimg.com/4851/d1498fea89ae3bc1.png";
static NSString *const smallPic = @"http://i1.piimg.com/4851/97aef4680d359905.png";

@interface AFURLSessionManagerViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation AFURLSessionManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)uploadPic:(id)sender {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:@"http://www.freeimagehosting.net//upl.php"]];
    [request setValue:@"image/png" forHTTPHeaderField:@"Content-type"];
     //[request setValue:@"Content-Disposition" forHTTPHeaderField:@"Content-type"];
    [request setValue:@"text/html" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"POST"];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [request setTimeoutInterval:60];
    
    NSData *data = UIImagePNGRepresentation([UIImage imageNamed:@"1.png"]);
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLSessionUploadTask *task = [manager uploadTaskWithRequest:request fromData:data progress:^(NSProgress * _Nonnull uploadProgress) {
        NSLog(@"上传进度:%lld",uploadProgress.completedUnitCount);
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        NSLog(@"%@",responseObject);
    }];
    
    [task resume];
}


//请求数据
- (IBAction)clickButton:(id)sender {
    //通过默认配置初始化Session
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    //设置网络请求序列化对象
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    [requestSerializer setValue:@"test" forHTTPHeaderField:@"requestHeader"];
    requestSerializer.timeoutInterval = 60;
    requestSerializer.stringEncoding = NSUTF8StringEncoding;
    //设置返回数据序列化对象
    AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer = responseSerializer;
    //网络请求安全策略
    if (true) {
        AFSecurityPolicy *securityPolicy;
        securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
        securityPolicy.allowInvalidCertificates = false;
        securityPolicy.validatesDomainName = YES;
        manager.securityPolicy = securityPolicy;
    } else {
        manager.securityPolicy.allowInvalidCertificates = true;
        manager.securityPolicy.validatesDomainName = false;
    }
    //是否允许请求重定向
    if (true) {
        [manager setTaskWillPerformHTTPRedirectionBlock:^NSURLRequest *(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request) {
            if (response) {
                return nil;
            }
            return request;
        }];
    }
    //监听网络状态
    [manager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        NSLog(@"%ld",(long)status);
    }];
    [manager.reachabilityManager startMonitoring];
    
    NSURL *URL = [NSURL URLWithString:bigPic];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress *downloadProgress){
        NSLog(@"下载进度:%lld",downloadProgress.completedUnitCount);
    } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        NSURL *fileURL = [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
        NSLog(@"fileURL:%@",[fileURL absoluteString]);
        return fileURL;
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        self.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:filePath]];
        NSLog(@"File downloaded to: %@", filePath);
    }];
    [downloadTask resume];
}


@end

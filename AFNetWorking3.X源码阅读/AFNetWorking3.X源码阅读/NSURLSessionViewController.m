//
//  ViewController.m
//  AFNetWorking3.X源码阅读
//
//  Created by huangchengdu on 17/4/5.
//  Copyright © 2017年 huangchengdu. All rights reserved.
//

#import "NSURLSessionViewController.h"

static NSString *const bigPic = @"http://i1.piimg.com/4851/d1498fea89ae3bc1.png";
static NSString *const smallPic = @"http://i1.piimg.com/4851/97aef4680d359905.png";

@interface NSURLSessionViewController ()<NSURLSessionDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property(nonatomic,strong)NSMutableData *data;
@end

@implementation NSURLSessionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)dataTaskRequest:(id)sender {
     [self clear];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:[NSURL URLWithString:bigPic]];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request];
    [dataTask resume];
}


- (IBAction)downloadTaskRequest:(id)sender {
     [self clear];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:[NSURL URLWithString:bigPic]];
    NSURLSessionDownloadTask *dataTask = [session downloadTaskWithRequest:request];
    [dataTask resume];
}

-(IBAction)blockDataTaskRequest:(id)sender{
    [self clear];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:[NSURL URLWithString:bigPic]];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        UIImage *image = [[UIImage alloc]initWithData:data];
        self.imageView.image = image;
    }];
    [dataTask resume];
}

-(void)clear{
    self.imageView.image = nil;
}

//==============================NSURLSessionDelegate========================
#pragma NSURLSessionDelegate
//当一个session遇到系统错误或者未检测到的错误的时候，就会调用这个方法。
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error{

}
//当请求需要认证、或者https证书认证的时候，我们就需要在这个方法里面处理。
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler{
    
}
//如果应用进入后台、这个方法会被调用。我们在这里可以对session发起的请求做各种操作比如请求完成的回调等。
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {

}

//==================================NSURLSessionTaskDelegate====================
#pragma NSURLSessionTaskDelegate
/*
 当请求重定向的时候调用这个方法。我们必须设置一个新的`NSURLRequest`对象传入completionHandler来重定向新的请求，但是当`session`是background模式的时候，这个方法不会被调用。
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler{

}
/*
 当请求需要认证的时候调用这个方法。如果没有实现这个代理，那么请求认证这个过程不会被调用。
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler{

}
/*
    如果请求需要一个新的请求体时，这个方法就会被调用。比如认证失败的时候，我们可以通过这个机会从新认证。
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
 needNewBodyStream:(void (^)(NSInputStream * _Nullable bodyStream))completionHandler{

}
/*
 当我们上传数据的时候，我们可以通过这个代理方法获取上传进度。
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
    NSLog(@"");
}
/*
 当task的统计信息收集好了以后，调用这个方法。
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics {

}
/*
 当一个task出错的时候，会调用这个方法。如果error是nil，也会调用这个方法，表示task完成。
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    NSLog(@"数据返回以后，不管有错没错都回调用，如果没错，error及时nil");
    if (self.data) {
        self.imageView.image = [UIImage imageWithData:self.data];
        self.data = nil;
    }
}

//==================================NSURLSessionDataDelegate=====================================
#pragma NSURLSessionDataDelegate
/*
 当一个task接收到返回信息。当所有信息都接收完毕以后，completionHandler会被调用。我们可以在这里取消一个网络请求或者把一个datatask转换为downloadtask。如果没有实现这个代理方法，我们也可以通过task的response属性获取到对应的数据。background模式的uploadtask不会调用这个方法。
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
    self.data = nil;
    self.data = [NSMutableData data];
    // 允许处理服务器的响应，才会继续接收服务器返回的数据
    completionHandler(NSURLSessionResponseAllow);
}
/*
 当一个datatask转换为一个downloadtask以后会调用。
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask{
    
}
/*
 暂时忽略，这个是和数据流相关的。不管了
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didBecomeStreamTask:(NSURLSessionStreamTask *)streamTask{

}
/*
 当data可以使用的时候，调用这个方法。我们可以在这里获取data。
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    [self.data appendData:data];
    NSLog(@"具体数据在URLSession:(NSURLSession *)session task:(NSURLSessionTask *)taskdidCompleteWithError:(nullable NSError *)error处理");
}
/*
 允许我们在这里调用completionHandler缓存data，或者传入nil来禁止缓存
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse * _Nullable cachedResponse))completionHandler{

}
//==================================NSURLSessionDownloadTask=================================
#pragma NSURLSessionDownloadTask
/*
    当一个下载task任务完成以后，这个方法会被调用。我们可以在这里移动或者复制download的数据
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location{
    NSString *path = location.absoluteString;
    UIImage *image = [[UIImage alloc]initWithData:[NSData dataWithContentsOfURL:location]];
    self.imageView.image = image;
    NSLog(@"数据下载完成以后，会保存在一个location的地方。%@",location);
}
/*
 获取下载进度
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    NSLog(@"总得数据大小%lld----",bytesWritten);
}
/*
 重启一个下载任务(比如下载一半后停止然后过一点时间继续)。如果下载出错，`NSURLSessionDownloadTaskResumeData`里面包含重新开始下载的数据。
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes{

}
@end

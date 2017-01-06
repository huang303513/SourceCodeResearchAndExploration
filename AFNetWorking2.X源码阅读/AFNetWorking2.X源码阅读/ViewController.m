//
//  ViewController.m
//  AFNetWorking2.X源码阅读
//
//  Created by huangchengdu on 16/10/31.
//  Copyright © 2016年 huangchengdu. All rights reserved.
//



#import "ViewController.h"
#import "AFHTTPRequestOperation.h"
#import "AFHTTPRequestOperationManager.h"
#import "AFHTTPRequestOperation.h"
static NSString *urlString =  @"http://www.joes-hardware.com/specials/saw-blade.gif";
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    

}


- (IBAction)loadImage:(id)sender {
    
    NSURL *URL = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.imageView.image = [UIImage imageWithData:responseObject];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
    [operation start];
    

}

- (IBAction)loadImageAFURL:(id)sender {
    NSURL *URL = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    AFURLConnectionOperation *operation = [[AFURLConnectionOperation alloc]initWithRequest:request];
    //AFN已经做了处理，不会产生循环引用
    [operation setCompletionBlock:^{
        self.imageView.image = [UIImage imageWithData:operation.responseData];
    }];
    [operation start];
}



- (IBAction)loadData:(id)sender {

    
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:@"http://www.joes-hardware.com/hammers.html" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.textView.text = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}


@end

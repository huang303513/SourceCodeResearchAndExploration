//
//  SecondViewController.m
//  AFNetWorking2.X源码阅读
//
//  Created by huangchengdu on 16/10/31.
//  Copyright © 2016年 huangchengdu. All rights reserved.
//

#import "SecondViewController.h"
#import "AFURLConnectionOperation.h"

static NSString *urlString =  @"http://www.joes-hardware.com/specials/saw-blade.gif";

@interface SecondViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSURL *URL = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    AFURLConnectionOperation *operation = [[AFURLConnectionOperation alloc]initWithRequest:request];
    
    
    
    //AFN已经做了处理，不会产生循环引用
    [operation setCompletionBlock:^{
        self.imageView.image = [UIImage imageWithData:operation.responseData];
    }];
    [operation start];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc{

}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

//
//  AppDelegate.m
//  WebViewJavascriptCore解析
//
//  Created by huangchengdu on 17/3/30.
//  Copyright © 2017年 huangchengdu. All rights reserved.
//

#import "AppDelegate.h"
//#import "ExampleUIWebViewController.h"
#import "ExampleWKWebViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // 1. Create the UIWebView example
//    ExampleUIWebViewController* UIWebViewExampleController = [[ExampleUIWebViewController alloc] init];
   // UIWebViewExampleController.tabBarItem.title             = @"UIWebView";
    
    // 2. Create the tab footer and add the UIWebView example
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    // 3. Create the  WKWebView example for devices >= iOS 8
    if([WKWebView class]) {
        ExampleWKWebViewController* WKWebViewExampleController = [[ExampleWKWebViewController alloc] init];
        WKWebViewExampleController.tabBarItem.title             = @"WKWebView";
        [tabBarController addChildViewController:WKWebViewExampleController];
    }
    //[tabBarController addChildViewController:UIWebViewExampleController];

    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = tabBarController;
    [self.window makeKeyAndVisible];
    
    
    return YES;
}

@end

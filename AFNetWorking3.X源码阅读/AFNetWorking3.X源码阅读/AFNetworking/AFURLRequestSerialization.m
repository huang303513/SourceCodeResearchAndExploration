// AFURLRequestSerialization.m
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AFURLRequestSerialization.h"

#if TARGET_OS_IOS || TARGET_OS_WATCH || TARGET_OS_TV
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <CoreServices/CoreServices.h>
#endif

NSString * const AFURLRequestSerializationErrorDomain = @"com.alamofire.error.serialization.request";
NSString * const AFNetworkingOperationFailingURLRequestErrorKey = @"com.alamofire.serialization.request.error.response";

/**
 把parameters这个字典转换为url的query参数。并且绑定给request对象

 @param request query参数绑定的request对象
 @param parameters 序列化的参数
 @param error 错误
 @return 序列化以后的query参数
 */
typedef NSString * (^AFQueryStringSerializationBlock)(NSURLRequest *request, id parameters, NSError *__autoreleasing *error);

/**
 Returns a percent-escaped string following RFC 3986 for a query string key or value.
 RFC 3986 states that the following characters are "reserved" characters.
    - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
    - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="

 In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
 query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
 should be percent-escaped in the query string.
    - parameter string: The string to be percent-escaped.
    - returns: The percent-escaped string.
 */
#pragma mark  AFPercentEscapedStringFromString方法的作用就是把一个普通字符串转换为百分号编码的字符串
/**
 把一个普通字符串转换为百分号编码的字符串
 http://blog.csdn.net/qq_32010299/article/details/51790407

 @param string 一个字符串
 @return 百分号编码的字符串
 */
NSString * AFPercentEscapedStringFromString(NSString *string) {
    //可能需要做百分号编码处理的字符串
    static NSString * const kAFCharactersGeneralDelimitersToEncode = @":#[]@"; // does not include "?" or "/" due to RFC 3986 - Section 3.4
    static NSString * const kAFCharactersSubDelimitersToEncode = @"!$&'()*+,;=";
    //不需要做百分号编码的字符串集合
    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    //获取目前系统中最终需要做百分号编码转换的字符集合
    [allowedCharacterSet removeCharactersInString:[kAFCharactersGeneralDelimitersToEncode stringByAppendingString:kAFCharactersSubDelimitersToEncode]];

	// FIXME: https://github.com/AFNetworking/AFNetworking/pull/3028
    // return [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];

    static NSUInteger const batchSize = 50;

    NSUInteger index = 0;
    NSMutableString *escaped = @"".mutableCopy;
    //迭代字符串做百分号编码
    while (index < string.length) {
        NSUInteger length = MIN(string.length - index, batchSize);
        NSRange range = NSMakeRange(index, length);
        // To avoid breaking up character sequences such as 👴🏻👮🏽
        //移除字符串中的一些非法字符。
        range = [string rangeOfComposedCharacterSequencesForRange:range];

        NSString *substring = [string substringWithRange:range];
        //指定范围内的字符做百分号编码
        NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
        [escaped appendString:encoded];

        index += range.length;
    }
    //返回处理以后的字符串
	return escaped;
}

#pragma mark - AFQueryStringPair的主要功能就是把一个key和vaue的键值对转换为百分号编码格式的键值对并且用=链接起来

@interface AFQueryStringPair : NSObject
@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (instancetype)initWithField:(id)field value:(id)value;

- (NSString *)URLEncodedStringValue;
@end

@implementation AFQueryStringPair

- (instancetype)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.field = field;
    self.value = value;

    return self;
}

/**
 把key、value键值对转换为百分号编码，并且链接起来

 @return 转换后的字符串
 */
- (NSString *)URLEncodedStringValue {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return AFPercentEscapedStringFromString([self.field description]);
    } else {
        return [NSString stringWithFormat:@"%@=%@", AFPercentEscapedStringFromString([self.field description]), AFPercentEscapedStringFromString([self.value description])];
    }
}

@end

#pragma mark - 分别把一个字典或者key、value键值对转换为url的query参数

FOUNDATION_EXPORT NSArray * AFQueryStringPairsFromDictionary(NSDictionary *dictionary);
FOUNDATION_EXPORT NSArray * AFQueryStringPairsFromKeyAndValue(NSString *key, id value);


/**
 把一个字典转换为百分号编码的query参数
 @param parameters 要转换的字典
 @return query参数
 */
NSString * AFQueryStringFromParameters(NSDictionary *parameters) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (AFQueryStringPair *pair in AFQueryStringPairsFromDictionary(parameters)) {
        //调用`AFQueryStringPair`序列化
        [mutablePairs addObject:[pair URLEncodedStringValue]];
    }
    return [mutablePairs componentsJoinedByString:@"&"];
}

NSArray * AFQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return AFQueryStringPairsFromKeyAndValue(nil, dictionary);
}

/**
 分别把一个字典、数组、集合转换为一个AFQueryStringPair对象的的数组。

 @param key key
 @param value value
 @return AFQueryStringPair类型数组
 */
NSArray * AFQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];
    //使用`description`排序
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        // Sort dictionary keys to ensure consistent ordering in query string, which is important when deserializing potentially ambiguous sequences, such as an array of dictionaries
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            id nestedValue = dictionary[nestedKey];
            if (nestedValue) {
                //如果是字典，就取出每一对key、value处理
                [mutableQueryStringComponents addObjectsFromArray:AFQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        for (id nestedValue in array) {
            //如果是数组，则取出元素，添加一个额外的key处理
            [mutableQueryStringComponents addObjectsFromArray:AFQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }
    } else if ([value isKindOfClass:[NSSet class]]) {
        NSSet *set = value;
        for (id obj in [set sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            //如果是集合，就是用默认key和集合元素处理
            [mutableQueryStringComponents addObjectsFromArray:AFQueryStringPairsFromKeyAndValue(key, obj)];
        }
    } else {
        //添加处理后的key和value
        [mutableQueryStringComponents addObject:[[AFQueryStringPair alloc] initWithField:key value:value]];
    }
    //返回`AFQueryStringPair`对象数组
    return mutableQueryStringComponents;
}

#pragma mark - `AFStreamingMultipartFormData`是一个私有类。继承了`AFMultipartFormData`协议。实现了对multiform请求的请求体拼装的功能。

@interface AFStreamingMultipartFormData : NSObject <AFMultipartFormData>
- (instancetype)initWithURLRequest:(NSMutableURLRequest *)urlRequest
                    stringEncoding:(NSStringEncoding)encoding;

- (NSMutableURLRequest *)requestByFinalizingMultipartFormData;
@end

#pragma mark - request请求序列化要观察的属性列表、是一个数组，里面有对蜂窝数据、缓存策略、cookie、管道、网络状态、超时这几个元素。

static NSArray * AFHTTPRequestSerializerObservedKeyPaths() {
    static NSArray *_AFHTTPRequestSerializerObservedKeyPaths = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _AFHTTPRequestSerializerObservedKeyPaths = @[NSStringFromSelector(@selector(allowsCellularAccess)), NSStringFromSelector(@selector(cachePolicy)), NSStringFromSelector(@selector(HTTPShouldHandleCookies)), NSStringFromSelector(@selector(HTTPShouldUsePipelining)), NSStringFromSelector(@selector(networkServiceType)), NSStringFromSelector(@selector(timeoutInterval))];
    });

    return _AFHTTPRequestSerializerObservedKeyPaths;
}

static void *AFHTTPRequestSerializerObserverContext = &AFHTTPRequestSerializerObserverContext;

#pragma mark `AFHTTPRequestSerializer`主要实现了大部分解析功能。
/**
 参数解析、multiformdata请求体数据拼装
 */
@interface AFHTTPRequestSerializer ()
//某个request需要观察的属性集合
@property (readwrite, nonatomic, strong) NSMutableSet *mutableObservedChangedKeyPaths;
//存储request的请求头域
@property (readwrite, nonatomic, strong) NSMutableDictionary *mutableHTTPRequestHeaders;
//用于修改或者设置请求体域的dispatch_queue_t。
@property (readwrite, nonatomic, strong) dispatch_queue_t requestHeaderModificationQueue;
@property (readwrite, nonatomic, assign) AFHTTPRequestQueryStringSerializationStyle queryStringSerializationStyle;
//手动指定parameters参数序列化的Block
@property (readwrite, nonatomic, copy) AFQueryStringSerializationBlock queryStringSerialization;
@end

@implementation AFHTTPRequestSerializer

+ (instancetype)serializer {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    //指定序列化编码格式
    self.stringEncoding = NSUTF8StringEncoding;
    //请求头保存在一个字典中，方便后面构建request的时候拼装。
    self.mutableHTTPRequestHeaders = [NSMutableDictionary dictionary];
    //初始化一个操作request的header域的dispatch_queue_t
    self.requestHeaderModificationQueue = dispatch_queue_create("requestHeaderModificationQueue", DISPATCH_QUEUE_CONCURRENT);

    // Accept-Language HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
    NSMutableArray *acceptLanguagesComponents = [NSMutableArray array];
    /*
     *枚举系统的language列表。然后设置`Accept-Language`请求头域。优先级逐级降低，最多五个。
     */
    [[NSLocale preferredLanguages] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        float q = 1.0f - (idx * 0.1f);
        [acceptLanguagesComponents addObject:[NSString stringWithFormat:@"%@;q=%0.1g", obj, q]];
        *stop = q <= 0.5f;
    }];
    //数组元素使用`, `分割
    [self setValue:[acceptLanguagesComponents componentsJoinedByString:@", "] forHTTPHeaderField:@"Accept-Language"];

    /*
     *设置User-Agent请求头域的值。
     */
    NSString *userAgent = nil;
#if TARGET_OS_IOS
    // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
    userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale]];
#elif TARGET_OS_WATCH
    // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
    userAgent = [NSString stringWithFormat:@"%@/%@ (%@; watchOS %@; Scale/%0.2f)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[WKInterfaceDevice currentDevice] model], [[WKInterfaceDevice currentDevice] systemVersion], [[WKInterfaceDevice currentDevice] screenScale]];
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
    userAgent = [NSString stringWithFormat:@"%@/%@ (Mac OS X %@)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[NSProcessInfo processInfo] operatingSystemVersionString]];
#endif
    
    if (userAgent) {
        /*
         *如果userAgent里面包含非ASCII码的字符，比如中文，则需要转换。这里是转换为对应的拉丁字母。
         AFNetWorking3.X源码阅读/1.0 (iPhone; iOS 10.2; Scale/2.00)
         AFNetWorking3.X yuan ma yue du/1.0 (iPhone; iOS 10.2; Scale/2.00)
         */
        if (![userAgent canBeConvertedToEncoding:NSASCIIStringEncoding]) {
            NSMutableString *mutableUserAgent = [userAgent mutableCopy];
            //转换为拉丁字母
            if (CFStringTransform((__bridge CFMutableStringRef)(mutableUserAgent), NULL, (__bridge CFStringRef)@"Any-Latin; Latin-ASCII; [:^ASCII:] Remove", false)) {
                userAgent = mutableUserAgent;
            }
        }
        [self setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    }

    // HTTP Method Definitions; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html
    //需要把parameters转换为query参数的方法集合。
    self.HTTPMethodsEncodingParametersInURI = [NSSet setWithObjects:@"GET", @"HEAD", @"DELETE", nil];

    self.mutableObservedChangedKeyPaths = [NSMutableSet set];
    /*
     添加对蜂窝数据、缓存策略、cookie、管道、网络状态、超时这几个属性的观察。
     */
    for (NSString *keyPath in AFHTTPRequestSerializerObservedKeyPaths()) {
        if ([self respondsToSelector:NSSelectorFromString(keyPath)]) {
            [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:AFHTTPRequestSerializerObserverContext];
        }
    }
    return self;
}

/**
 移除对蜂窝数据、缓存策略、cookie、管道、网络状态、超时这几个属性的观察。
 */
- (void)dealloc {
    for (NSString *keyPath in AFHTTPRequestSerializerObservedKeyPaths()) {
        if ([self respondsToSelector:NSSelectorFromString(keyPath)]) {
            [self removeObserver:self forKeyPath:keyPath context:AFHTTPRequestSerializerObserverContext];
        }
    }
}

#pragma mark - 手动触发蜂窝数据、缓存策略、cookie、管道、网络状态、超时的观察。可以用于测试这些属性变化是否崩溃等。
// Workarounds for crashing behavior using Key-Value Observing with XCTest
// See https://github.com/AFNetworking/AFNetworking/issues/2523

- (void)setAllowsCellularAccess:(BOOL)allowsCellularAccess {
    [self willChangeValueForKey:NSStringFromSelector(@selector(allowsCellularAccess))];
    _allowsCellularAccess = allowsCellularAccess;
    [self didChangeValueForKey:NSStringFromSelector(@selector(allowsCellularAccess))];
}

- (void)setCachePolicy:(NSURLRequestCachePolicy)cachePolicy {
    [self willChangeValueForKey:NSStringFromSelector(@selector(cachePolicy))];
    _cachePolicy = cachePolicy;
    [self didChangeValueForKey:NSStringFromSelector(@selector(cachePolicy))];
}

- (void)setHTTPShouldHandleCookies:(BOOL)HTTPShouldHandleCookies {
    [self willChangeValueForKey:NSStringFromSelector(@selector(HTTPShouldHandleCookies))];
    _HTTPShouldHandleCookies = HTTPShouldHandleCookies;
    [self didChangeValueForKey:NSStringFromSelector(@selector(HTTPShouldHandleCookies))];
}

- (void)setHTTPShouldUsePipelining:(BOOL)HTTPShouldUsePipelining {
    [self willChangeValueForKey:NSStringFromSelector(@selector(HTTPShouldUsePipelining))];
    _HTTPShouldUsePipelining = HTTPShouldUsePipelining;
    [self didChangeValueForKey:NSStringFromSelector(@selector(HTTPShouldUsePipelining))];
}

- (void)setNetworkServiceType:(NSURLRequestNetworkServiceType)networkServiceType {
    [self willChangeValueForKey:NSStringFromSelector(@selector(networkServiceType))];
    _networkServiceType = networkServiceType;
    [self didChangeValueForKey:NSStringFromSelector(@selector(networkServiceType))];
}

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval {
    [self willChangeValueForKey:NSStringFromSelector(@selector(timeoutInterval))];
    _timeoutInterval = timeoutInterval;
    [self didChangeValueForKey:NSStringFromSelector(@selector(timeoutInterval))];
}

#pragma mark - 请求头域操作的各种getter和setter。

/**
 返回请求头域key和vaue

 @return 字典
 */
- (NSDictionary *)HTTPRequestHeaders {
    NSDictionary __block *value;
    dispatch_sync(self.requestHeaderModificationQueue, ^{
        value = [NSDictionary dictionaryWithDictionary:self.mutableHTTPRequestHeaders];
    });
    return value;
}

/**
 设置一个请求头域

 @param value vaue
 @param field 域名
 */
- (void)setValue:(NSString *)value
forHTTPHeaderField:(NSString *)field
{
    dispatch_barrier_async(self.requestHeaderModificationQueue, ^{
        [self.mutableHTTPRequestHeaders setValue:value forKey:field];
    });
}
/**
 返回指定请求头域的值

 @param field 域名
 @return 值
 */
- (NSString *)valueForHTTPHeaderField:(NSString *)field {
    NSString __block *value;
    dispatch_sync(self.requestHeaderModificationQueue, ^{
        value = [self.mutableHTTPRequestHeaders valueForKey:field];
    });
    return value;
}

/**
 设置Basic Authorization的用户名和密码。记住需要是base64编码格式的。

 @param username 用户
 @param password 密码
 */
- (void)setAuthorizationHeaderFieldWithUsername:(NSString *)username
                                       password:(NSString *)password
{
    NSData *basicAuthCredentials = [[NSString stringWithFormat:@"%@:%@", username, password] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64AuthCredentials = [basicAuthCredentials base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)0];
    [self setValue:[NSString stringWithFormat:@"Basic %@", base64AuthCredentials] forHTTPHeaderField:@"Authorization"];
}

/**
 移除Basic Authorization的请求头
 */
- (void)clearAuthorizationHeader {
    dispatch_barrier_async(self.requestHeaderModificationQueue, ^{
        [self.mutableHTTPRequestHeaders removeObjectForKey:@"Authorization"];
    });
}

#pragma mark - 把`queryStringSerialization`这个Block置为nil或者初始化

- (void)setQueryStringSerializationWithStyle:(AFHTTPRequestQueryStringSerializationStyle)style {
    self.queryStringSerializationStyle = style;
    self.queryStringSerialization = nil;
}

- (void)setQueryStringSerializationWithBlock:(NSString *(^)(NSURLRequest *, id, NSError *__autoreleasing *))block {
    self.queryStringSerialization = block;
}

#pragma mark - 通过`AFURLRequestSerialization`来创建`NSMutableURLRequest`系列api

/**
 根据给定的url、方法名、参数构建一个request。

 @param method 方法名
 @param URLString url地址
 @param parameters 参数，根据不同的请求方法构建出不同的模式
 @param error 构建出错
 @return 返回一个非multipartForm请求
 */
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(id)parameters
                                     error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(method);
    NSParameterAssert(URLString);
    NSURL *url = [NSURL URLWithString:URLString];
    NSParameterAssert(url);
    NSMutableURLRequest *mutableRequest = [[NSMutableURLRequest alloc] initWithURL:url];
    mutableRequest.HTTPMethod = method;
    /*
     *mutableObservedChangedKeyPaths集合里面的属性都通过`setValue: forKey`手动设置一下。估计目的是触发这几个属性的kvo。
     */
    for (NSString *keyPath in AFHTTPRequestSerializerObservedKeyPaths()) {
        if ([self.mutableObservedChangedKeyPaths containsObject:keyPath]) {
            [mutableRequest setValue:[self valueForKeyPath:keyPath] forKey:keyPath];
        }
    }
    /*
     根据parameters和HTTPRequestHeaders构建一个request
     */
    mutableRequest = [[self requestBySerializingRequest:mutableRequest withParameters:parameters error:error] mutableCopy];
	return mutableRequest;
}

/**
 构建一个multipartForm的request。并且通过`AFMultipartFormData`类型的formData来构建请求体

 @param method 方法名，一般都是POST
 @param URLString 请求地址
 @param parameters 请求头参数
 @param block 用于构建请求体的Block
 @param error 构建请求体出错
 @return 返回一个构建好的request
 */
- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                              URLString:(NSString *)URLString
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                                                  error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(method);
    NSParameterAssert(![method isEqualToString:@"GET"] && ![method isEqualToString:@"HEAD"]);
    /*
     先构建一个普通的request对象，然后在构建出multipartFrom的request
     * 在这一步将会把parameters加入请求头或者请求体。然后把`AFURLRequestSerialization`指定的headers加入request的请求头中。这个request就只差构建multipartFrom部分了
     */
    NSMutableURLRequest *mutableRequest = [self requestWithMethod:method URLString:URLString parameters:nil error:error];
    /*
     *初始化一个`AFStreamingMultipartFormData`对象。用于封装multipartFrom的body部分
     */
    __block AFStreamingMultipartFormData *formData = [[AFStreamingMultipartFormData alloc] initWithURLRequest:mutableRequest stringEncoding:NSUTF8StringEncoding];
    if (parameters) {
        /*
         把parameters拼接成`AFQueryStringPair`对象。然后根据取出的key和value处理。
         */
        for (AFQueryStringPair *pair in AFQueryStringPairsFromDictionary(parameters)) {
            NSData *data = nil;
            //把value处理为NSData类型
            if ([pair.value isKindOfClass:[NSData class]]) {
                data = pair.value;
            } else if ([pair.value isEqual:[NSNull null]]) {
                data = [NSData data];
            } else {
                data = [[pair.value description] dataUsingEncoding:self.stringEncoding];
            }
            if (data) {
                [formData appendPartWithFormData:data name:[pair.field description]];
            }
        }
    }
    if (block) {
        block(formData);
    }
    //body具体序列化操作
    return [formData requestByFinalizingMultipartFormData];
}

/**
 通过一个Multipart-Form的request创建一个request。新request的httpBody是`fileURL`指定的文件。
 并且是通过`HTTPBodyStream`这个属性添加，`HTTPBodyStream`属性的数据会自动添加为httpBody。

 @param request 原request
 @param fileURL 文件的url
 @param handler 错误处理
 @return 处理完成的request
 */
- (NSMutableURLRequest *)requestWithMultipartFormRequest:(NSURLRequest *)request
                             writingStreamContentsToFile:(NSURL *)fileURL
                                       completionHandler:(void (^)(NSError *error))handler
{
    NSParameterAssert(request.HTTPBodyStream);
    NSParameterAssert([fileURL isFileURL]);
    //获取`HTTPBodyStream`属性
    NSInputStream *inputStream = request.HTTPBodyStream;
    //获取文件的数据流
    NSOutputStream *outputStream = [[NSOutputStream alloc] initWithURL:fileURL append:NO];
    __block NSError *error = nil;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //把读和写的操作加入当前线程的runloop
        [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        //打开读和写数据流
        [inputStream open];
        [outputStream open];
        //循环做读和写操作
        while ([inputStream hasBytesAvailable] && [outputStream hasSpaceAvailable]) {
            uint8_t buffer[1024];

            NSInteger bytesRead = [inputStream read:buffer maxLength:1024];
            if (inputStream.streamError || bytesRead < 0) {
                error = inputStream.streamError;
                break;
            }

            NSInteger bytesWritten = [outputStream write:buffer maxLength:(NSUInteger)bytesRead];
            if (outputStream.streamError || bytesWritten < 0) {
                error = outputStream.streamError;
                break;
            }

            if (bytesRead == 0 && bytesWritten == 0) {
                break;
            }
        }
        //读和写完成。关闭读和写数据流
        [outputStream close];
        [inputStream close];
        //如果有handler，调用handler这个Block
        if (handler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(error);
            });
        }
    });
    //获取一个新的request，新的request的httpBody已经通过`HTTPBodyStream`转换成功
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    mutableRequest.HTTPBodyStream = nil;
    //返回一个request对象
    return mutableRequest;
}

#pragma mark - AFURLRequestSerialization的序列化params的方法，负责具体的request拼接

/**
 根据不同类型的request，不parameters添加请求的不同地方。如果是get，则构建成query部分。如果是post，则构建成请求体

 @param request 需要再次处理的request
 @param parameters 要处理的参数
 @param error 错误
 @return 处理成功的request
 */
- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(id)parameters
                                        error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(request);

    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    /*
     把`HTTPRequestHeaders`属性放入request的请求域中
     */
    [self.HTTPRequestHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
        if (![request valueForHTTPHeaderField:field]) {
            [mutableRequest setValue:value forHTTPHeaderField:field];
        }
    }];

    NSString *query = nil;
    /*
     把parameters序列化为url的query部分
     */
    if (parameters) {
        //如果指定了queryStringSerialization，表示用户要自定义序列化操作
        if (self.queryStringSerialization) {
            NSError *serializationError;
            query = self.queryStringSerialization(request, parameters, &serializationError);

            if (serializationError) {
                if (error) {
                    *error = serializationError;
                }

                return nil;
            }
        } else {//使用默认的序列化操作
            switch (self.queryStringSerializationStyle) {
                case AFHTTPRequestQueryStringDefaultStyle:
                    query = AFQueryStringFromParameters(parameters);
                    break;
            }
        }
    }
    /*
    `HTTPMethodsEncodingParametersInURI`包含`GET`,`HEAD`,`DELETE`。如果是这个三种方法，则把query加入url的后面。否则把query加入request的请求体
     */
    if ([self.HTTPMethodsEncodingParametersInURI containsObject:[[request HTTPMethod] uppercaseString]]) {
        if (query && query.length > 0) {
            mutableRequest.URL = [NSURL URLWithString:[[mutableRequest.URL absoluteString] stringByAppendingFormat:mutableRequest.URL.query ? @"&%@" : @"?%@", query]];
        }
    } else {
        // #2864: an empty string is a valid x-www-form-urlencoded payload
        if (!query) {
            query = @"";
        }
        //如果没有请求头。则设置请求头`application/x-www-form-urlencoded`。
        if (![mutableRequest valueForHTTPHeaderField:@"Content-Type"]) {
            [mutableRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        }
        [mutableRequest setHTTPBody:[query dataUsingEncoding:self.stringEncoding]];
    }

    return mutableRequest;
}

#pragma mark - NSKeyValueObserving
/**
 如果kvo的触发机制是默认出发。则返回true，否则返回false。在这里，只要是`AFHTTPRequestSerializerObservedKeyPaths`里面的属性，我们都取消自动出发kvo机制，使用手动触发。

 @param key kvo的key
 @return bool值
 */
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    if ([AFHTTPRequestSerializerObservedKeyPaths() containsObject:key]) {
        return NO;
    }

    return [super automaticallyNotifiesObserversForKey:key];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(__unused id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    //是否是选择要观察的属性
    if (context == AFHTTPRequestSerializerObserverContext) {
        //如果属性值为null，则表示么有这个属性，移除对其的观察
        if ([change[NSKeyValueChangeNewKey] isEqual:[NSNull null]]) {
            [self.mutableObservedChangedKeyPaths removeObject:keyPath];
        } else {
            //添加到要观察的属性的集合
            [self.mutableObservedChangedKeyPaths addObject:keyPath];
        }
    }
}
#pragma mark - NSSecureCoding。归档接档协议实现。有两个属性，一个是`mutableHTTPRequestHeaders`，一个是`queryStringSerializationStyle`。
+ (BOOL)supportsSecureCoding {
    return YES;
}
- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [self init];
    if (!self) {
        return nil;
    }
    self.mutableHTTPRequestHeaders = [[decoder decodeObjectOfClass:[NSDictionary class] forKey:NSStringFromSelector(@selector(mutableHTTPRequestHeaders))] mutableCopy];
    self.queryStringSerializationStyle = (AFHTTPRequestQueryStringSerializationStyle)[[decoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(queryStringSerializationStyle))] unsignedIntegerValue];
    return self;
}
- (void)encodeWithCoder:(NSCoder *)coder {
    dispatch_sync(self.requestHeaderModificationQueue, ^{
        [coder encodeObject:self.mutableHTTPRequestHeaders forKey:NSStringFromSelector(@selector(mutableHTTPRequestHeaders))];
    });
    [coder encodeInteger:self.queryStringSerializationStyle forKey:NSStringFromSelector(@selector(queryStringSerializationStyle))];
}

#pragma mark - NSCopying。复制协议实现。复制了三个属性，分别是`mutableHTTPRequestHeaders`、`queryStringSerializationStyle`、`queryStringSerialization`。
- (instancetype)copyWithZone:(NSZone *)zone {
    AFHTTPRequestSerializer *serializer = [[[self class] allocWithZone:zone] init];
    dispatch_sync(self.requestHeaderModificationQueue, ^{
        serializer.mutableHTTPRequestHeaders = [self.mutableHTTPRequestHeaders mutableCopyWithZone:zone];
    });
    serializer.queryStringSerializationStyle = self.queryStringSerializationStyle;
    serializer.queryStringSerialization = self.queryStringSerialization;

    return serializer;
}

@end

#pragma mark - 用于拼接`MultipartForm`请求的请求体全局方法列表

/*
 生成multipartForm的request的boundary
 */
static NSString * AFCreateMultipartFormBoundary() {
    return [NSString stringWithFormat:@"Boundary+%08X%08X", arc4random(), arc4random()];
}
//回车换行符
static NSString * const kAFMultipartFormCRLF = @"\r\n";
//生成一个request的请求体中的参数的开始符号，第一个
static inline NSString * AFMultipartFormInitialBoundary(NSString *boundary) {
    return [NSString stringWithFormat:@"--%@%@", boundary, kAFMultipartFormCRLF];
}
//生成一个request的请求体中的参数的开始符号，菲第一个。
static inline NSString * AFMultipartFormEncapsulationBoundary(NSString *boundary) {
    return [NSString stringWithFormat:@"%@--%@%@", kAFMultipartFormCRLF, boundary, kAFMultipartFormCRLF];
}
////生成一个request的请求体中的参数的结束符号
static inline NSString * AFMultipartFormFinalBoundary(NSString *boundary) {
    return [NSString stringWithFormat:@"%@--%@--%@", kAFMultipartFormCRLF, boundary, kAFMultipartFormCRLF];
}
/*
根据文件的扩展名获取文件的`MIMEType`
 */
static inline NSString * AFContentTypeForPathExtension(NSString *extension) {
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if (!contentType) {
        return @"application/octet-stream";
    } else {
        return contentType;
    }
}

NSUInteger const kAFUploadStream3GSuggestedPacketSize = 1024 * 16;
NSTimeInterval const kAFUploadStream3GSuggestedDelay = 0.2;

@interface AFHTTPBodyPart : NSObject
@property (nonatomic, assign) NSStringEncoding stringEncoding;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, copy) NSString *boundary;
@property (nonatomic, strong) id body;
@property (nonatomic, assign) unsigned long long bodyContentLength;
@property (nonatomic, strong) NSInputStream *inputStream;

@property (nonatomic, assign) BOOL hasInitialBoundary;
@property (nonatomic, assign) BOOL hasFinalBoundary;

@property (readonly, nonatomic, assign, getter = hasBytesAvailable) BOOL bytesAvailable;
@property (readonly, nonatomic, assign) unsigned long long contentLength;

- (NSInteger)read:(uint8_t *)buffer
        maxLength:(NSUInteger)length;
@end

@interface AFMultipartBodyStream : NSInputStream <NSStreamDelegate>
@property (nonatomic, assign) NSUInteger numberOfBytesInPacket;
@property (nonatomic, assign) NSTimeInterval delay;
@property (nonatomic, strong) NSInputStream *inputStream;
@property (readonly, nonatomic, assign) unsigned long long contentLength;
@property (readonly, nonatomic, assign, getter = isEmpty) BOOL empty;

- (instancetype)initWithStringEncoding:(NSStringEncoding)encoding;
- (void)setInitialAndFinalBoundaries;
- (void)appendHTTPBodyPart:(AFHTTPBodyPart *)bodyPart;
@end

#pragma mark -  负责MultipartFrom的Body的具体构建。比如boundary的指定、请求体数据的拼接等

@interface AFStreamingMultipartFormData ()
@property (readwrite, nonatomic, copy) NSMutableURLRequest *request;
@property (readwrite, nonatomic, assign) NSStringEncoding stringEncoding;
@property (readwrite, nonatomic, copy) NSString *boundary;
@property (readwrite, nonatomic, strong) AFMultipartBodyStream *bodyStream;
@end

@implementation AFStreamingMultipartFormData

- (instancetype)initWithURLRequest:(NSMutableURLRequest *)urlRequest
                    stringEncoding:(NSStringEncoding)encoding
{
    self = [super init];
    if (!self) {
        return nil;
    }
    //需要添加httpbody的request
    self.request = urlRequest;
    //字符编码
    self.stringEncoding = encoding;
    //指定boundary
    self.boundary = AFCreateMultipartFormBoundary();
    //这个属性用于存储httpbody数据
    self.bodyStream = [[AFMultipartBodyStream alloc] initWithStringEncoding:encoding];
    return self;
}
/*
 根据文件的url添加一个`multipart/form-data`请求的请求体域
 */
- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                        error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(fileURL);
    NSParameterAssert(name);
    //文件扩展名
    NSString *fileName = [fileURL lastPathComponent];
    //获取文件的mimetype的类型
    NSString *mimeType = AFContentTypeForPathExtension([fileURL pathExtension]);

    return [self appendPartWithFileURL:fileURL name:name fileName:fileName mimeType:mimeType error:error];
}

/**
 根据指定类型的fileurl，把数据添加进入bodyStream中。以提供给后面构建request的body。

 @param fileURL 文件的url
 @param name 参数名称
 @param fileName 文件名称
 @param mimeType 文件类型
 @param error 错误
 @return 是否成功
 */
- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                     fileName:(NSString *)fileName
                     mimeType:(NSString *)mimeType
                        error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(fileURL);
    NSParameterAssert(name);
    NSParameterAssert(fileName);
    NSParameterAssert(mimeType);
    /*
     各种错误情况判断
     */
    if (![fileURL isFileURL]) {
        NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey: NSLocalizedStringFromTable(@"Expected URL to be a file URL", @"AFNetworking", nil)};
        if (error) {
            *error = [[NSError alloc] initWithDomain:AFURLRequestSerializationErrorDomain code:NSURLErrorBadURL userInfo:userInfo];
        }
        return NO;
    } else if ([fileURL checkResourceIsReachableAndReturnError:error] == NO) {
        NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey: NSLocalizedStringFromTable(@"File URL not reachable.", @"AFNetworking", nil)};
        if (error) {
            *error = [[NSError alloc] initWithDomain:AFURLRequestSerializationErrorDomain code:NSURLErrorBadURL userInfo:userInfo];
        }
        return NO;
    }
    //获取指定路径文件的属性
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[fileURL path] error:error];
    if (!fileAttributes) {
        return NO;
    }
    //添加`Content-Disposition`和`Content-Type`这两个请求体域
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", name, fileName] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:mimeType forKey:@"Content-Type"];
    //把一个完整的请求体域封装进一个`AFHTTPBodyPart`对象中。
    AFHTTPBodyPart *bodyPart = [[AFHTTPBodyPart alloc] init];
    bodyPart.stringEncoding = self.stringEncoding;
    bodyPart.headers = mutableHeaders;
    bodyPart.boundary = self.boundary;
    bodyPart.body = fileURL;
    bodyPart.bodyContentLength = [fileAttributes[NSFileSize] unsignedLongLongValue];
    [self.bodyStream appendHTTPBodyPart:bodyPart];

    return YES;
}
/**
 根据指定类型的数据流，把数据添加进入bodyStream中。以提供给后面构建request的body。
 
 @param inputStream 输入的数据流
 @param name 参数名称
 @param fileName 文件名称
 @param mimeType 文件类型
 */
- (void)appendPartWithInputStream:(NSInputStream *)inputStream
                             name:(NSString *)name
                         fileName:(NSString *)fileName
                           length:(int64_t)length
                         mimeType:(NSString *)mimeType
{
    NSParameterAssert(name);
    NSParameterAssert(fileName);
    NSParameterAssert(mimeType);
    //添加`Content-Disposition`和`Content-Type`这两个请求体域
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", name, fileName] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:mimeType forKey:@"Content-Type"];
    //把一个完整的请求体域封装进一个`AFHTTPBodyPart`对象中
    AFHTTPBodyPart *bodyPart = [[AFHTTPBodyPart alloc] init];
    bodyPart.stringEncoding = self.stringEncoding;
    bodyPart.headers = mutableHeaders;
    bodyPart.boundary = self.boundary;
    bodyPart.body = inputStream;
    bodyPart.bodyContentLength = (unsigned long long)length;
    [self.bodyStream appendHTTPBodyPart:bodyPart];
}

/**
 根据指定的data添加到请求体域中

 @param data 数据
 @param name 名称
 @param fileName 文件名称
 @param mimeType mimeType
 */
- (void)appendPartWithFileData:(NSData *)data
                          name:(NSString *)name
                      fileName:(NSString *)fileName
                      mimeType:(NSString *)mimeType
{
    NSParameterAssert(name);
    NSParameterAssert(fileName);
    NSParameterAssert(mimeType);

    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", name, fileName] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:mimeType forKey:@"Content-Type"];
    
    [self appendPartWithHeaders:mutableHeaders body:data];
}

/**
 根据指定的key和value拼接到`Content-Disposition`属性中

 @param data 参数值
 @param name 参数名
 */
- (void)appendPartWithFormData:(NSData *)data
                          name:(NSString *)name
{
    NSParameterAssert(name);

    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"", name] forKey:@"Content-Disposition"];
    //把处理好的数据加入对应的request的请求体中`Content-Disposition`部分
    [self appendPartWithHeaders:mutableHeaders body:data];
}

/**
 给一个multipartForm的`Content-Disposition`添加boundary

 @param headers 请求头域
 @param body 值
 */
- (void)appendPartWithHeaders:(NSDictionary *)headers
                         body:(NSData *)body
{
    NSParameterAssert(body);

    AFHTTPBodyPart *bodyPart = [[AFHTTPBodyPart alloc] init];
    bodyPart.stringEncoding = self.stringEncoding;
    bodyPart.headers = headers;
    bodyPart.boundary = self.boundary;
    bodyPart.bodyContentLength = [body length];
    bodyPart.body = body;

    [self.bodyStream appendHTTPBodyPart:bodyPart];
}

- (void)throttleBandwidthWithPacketSize:(NSUInteger)numberOfBytes
                                  delay:(NSTimeInterval)delay
{
    self.bodyStream.numberOfBytesInPacket = numberOfBytes;
    self.bodyStream.delay = delay;
}

/**
 根据一个request对应的`AFStreamingMultipartFormData`对象获取封装好的request对象

 @return multipart/form的request对象
 */
- (NSMutableURLRequest *)requestByFinalizingMultipartFormData {
    if ([self.bodyStream isEmpty]) {
        return self.request;
    }
    // Reset the initial and final boundaries to ensure correct Content-Length
    //重置boundary，从而确保`Content-Length`正确
    [self.bodyStream setInitialAndFinalBoundaries];
    //把拼接好的bodyStream添加进入request中
    [self.request setHTTPBodyStream:self.bodyStream];
    //给requst的请求头添加Content-Type属性指定为`multipart/form-data`类型的request。同时设置请求体的长度Content-Length。
    [self.request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", self.boundary] forHTTPHeaderField:@"Content-Type"];
    [self.request setValue:[NSString stringWithFormat:@"%llu", [self.bodyStream contentLength]] forHTTPHeaderField:@"Content-Length"];
    return self.request;
}

@end

#pragma mark -

@interface NSStream ()
@property (readwrite) NSStreamStatus streamStatus;
@property (readwrite, copy) NSError *streamError;
@end

@interface AFMultipartBodyStream () <NSCopying>
@property (readwrite, nonatomic, assign) NSStringEncoding stringEncoding;
@property (readwrite, nonatomic, strong) NSMutableArray *HTTPBodyParts;
@property (readwrite, nonatomic, strong) NSEnumerator *HTTPBodyPartEnumerator;
@property (readwrite, nonatomic, strong) AFHTTPBodyPart *currentHTTPBodyPart;
@property (readwrite, nonatomic, strong) NSOutputStream *outputStream;
@property (readwrite, nonatomic, strong) NSMutableData *buffer;
@end

@implementation AFMultipartBodyStream
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1100)
@synthesize delegate;
#endif
@synthesize streamStatus;
@synthesize streamError;

- (instancetype)initWithStringEncoding:(NSStringEncoding)encoding {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.stringEncoding = encoding;
    self.HTTPBodyParts = [NSMutableArray array];
    self.numberOfBytesInPacket = NSIntegerMax;

    return self;
}

- (void)setInitialAndFinalBoundaries {
    if ([self.HTTPBodyParts count] > 0) {
        for (AFHTTPBodyPart *bodyPart in self.HTTPBodyParts) {
            bodyPart.hasInitialBoundary = NO;
            bodyPart.hasFinalBoundary = NO;
        }

        [[self.HTTPBodyParts firstObject] setHasInitialBoundary:YES];
        [[self.HTTPBodyParts lastObject] setHasFinalBoundary:YES];
    }
}

- (void)appendHTTPBodyPart:(AFHTTPBodyPart *)bodyPart {
    [self.HTTPBodyParts addObject:bodyPart];
}

- (BOOL)isEmpty {
    return [self.HTTPBodyParts count] == 0;
}

#pragma mark - NSInputStream

- (NSInteger)read:(uint8_t *)buffer
        maxLength:(NSUInteger)length
{
    if ([self streamStatus] == NSStreamStatusClosed) {
        return 0;
    }

    NSInteger totalNumberOfBytesRead = 0;

    while ((NSUInteger)totalNumberOfBytesRead < MIN(length, self.numberOfBytesInPacket)) {
        if (!self.currentHTTPBodyPart || ![self.currentHTTPBodyPart hasBytesAvailable]) {
            if (!(self.currentHTTPBodyPart = [self.HTTPBodyPartEnumerator nextObject])) {
                break;
            }
        } else {
            NSUInteger maxLength = MIN(length, self.numberOfBytesInPacket) - (NSUInteger)totalNumberOfBytesRead;
            NSInteger numberOfBytesRead = [self.currentHTTPBodyPart read:&buffer[totalNumberOfBytesRead] maxLength:maxLength];
            if (numberOfBytesRead == -1) {
                self.streamError = self.currentHTTPBodyPart.inputStream.streamError;
                break;
            } else {
                totalNumberOfBytesRead += numberOfBytesRead;

                if (self.delay > 0.0f) {
                    [NSThread sleepForTimeInterval:self.delay];
                }
            }
        }
    }

    return totalNumberOfBytesRead;
}

- (BOOL)getBuffer:(__unused uint8_t **)buffer
           length:(__unused NSUInteger *)len
{
    return NO;
}

- (BOOL)hasBytesAvailable {
    return [self streamStatus] == NSStreamStatusOpen;
}

#pragma mark - NSStream

- (void)open {
    if (self.streamStatus == NSStreamStatusOpen) {
        return;
    }

    self.streamStatus = NSStreamStatusOpen;

    [self setInitialAndFinalBoundaries];
    self.HTTPBodyPartEnumerator = [self.HTTPBodyParts objectEnumerator];
}

- (void)close {
    self.streamStatus = NSStreamStatusClosed;
}

- (id)propertyForKey:(__unused NSString *)key {
    return nil;
}

- (BOOL)setProperty:(__unused id)property
             forKey:(__unused NSString *)key
{
    return NO;
}

- (void)scheduleInRunLoop:(__unused NSRunLoop *)aRunLoop
                  forMode:(__unused NSString *)mode
{}

- (void)removeFromRunLoop:(__unused NSRunLoop *)aRunLoop
                  forMode:(__unused NSString *)mode
{}

- (unsigned long long)contentLength {
    unsigned long long length = 0;
    for (AFHTTPBodyPart *bodyPart in self.HTTPBodyParts) {
        length += [bodyPart contentLength];
    }

    return length;
}

#pragma mark - Undocumented CFReadStream Bridged Methods

- (void)_scheduleInCFRunLoop:(__unused CFRunLoopRef)aRunLoop
                     forMode:(__unused CFStringRef)aMode
{}

- (void)_unscheduleFromCFRunLoop:(__unused CFRunLoopRef)aRunLoop
                         forMode:(__unused CFStringRef)aMode
{}

- (BOOL)_setCFClientFlags:(__unused CFOptionFlags)inFlags
                 callback:(__unused CFReadStreamClientCallBack)inCallback
                  context:(__unused CFStreamClientContext *)inContext {
    return NO;
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    AFMultipartBodyStream *bodyStreamCopy = [[[self class] allocWithZone:zone] initWithStringEncoding:self.stringEncoding];

    for (AFHTTPBodyPart *bodyPart in self.HTTPBodyParts) {
        [bodyStreamCopy appendHTTPBodyPart:[bodyPart copy]];
    }

    [bodyStreamCopy setInitialAndFinalBoundaries];

    return bodyStreamCopy;
}

@end

#pragma mark -

typedef enum {
    AFEncapsulationBoundaryPhase = 1,
    AFHeaderPhase                = 2,
    AFBodyPhase                  = 3,
    AFFinalBoundaryPhase         = 4,
} AFHTTPBodyPartReadPhase;

@interface AFHTTPBodyPart () <NSCopying> {
    AFHTTPBodyPartReadPhase _phase;
    NSInputStream *_inputStream;
    unsigned long long _phaseReadOffset;
}

- (BOOL)transitionToNextPhase;
- (NSInteger)readData:(NSData *)data
           intoBuffer:(uint8_t *)buffer
            maxLength:(NSUInteger)length;
@end

@implementation AFHTTPBodyPart

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    [self transitionToNextPhase];

    return self;
}

- (void)dealloc {
    if (_inputStream) {
        [_inputStream close];
        _inputStream = nil;
    }
}

- (NSInputStream *)inputStream {
    if (!_inputStream) {
        if ([self.body isKindOfClass:[NSData class]]) {
            _inputStream = [NSInputStream inputStreamWithData:self.body];
        } else if ([self.body isKindOfClass:[NSURL class]]) {
            _inputStream = [NSInputStream inputStreamWithURL:self.body];
        } else if ([self.body isKindOfClass:[NSInputStream class]]) {
            _inputStream = self.body;
        } else {
            _inputStream = [NSInputStream inputStreamWithData:[NSData data]];
        }
    }

    return _inputStream;
}

- (NSString *)stringForHeaders {
    NSMutableString *headerString = [NSMutableString string];
    for (NSString *field in [self.headers allKeys]) {
        [headerString appendString:[NSString stringWithFormat:@"%@: %@%@", field, [self.headers valueForKey:field], kAFMultipartFormCRLF]];
    }
    [headerString appendString:kAFMultipartFormCRLF];

    return [NSString stringWithString:headerString];
}

- (unsigned long long)contentLength {
    unsigned long long length = 0;

    NSData *encapsulationBoundaryData = [([self hasInitialBoundary] ? AFMultipartFormInitialBoundary(self.boundary) : AFMultipartFormEncapsulationBoundary(self.boundary)) dataUsingEncoding:self.stringEncoding];
    length += [encapsulationBoundaryData length];

    NSData *headersData = [[self stringForHeaders] dataUsingEncoding:self.stringEncoding];
    length += [headersData length];

    length += _bodyContentLength;

    NSData *closingBoundaryData = ([self hasFinalBoundary] ? [AFMultipartFormFinalBoundary(self.boundary) dataUsingEncoding:self.stringEncoding] : [NSData data]);
    length += [closingBoundaryData length];

    return length;
}

- (BOOL)hasBytesAvailable {
    // Allows `read:maxLength:` to be called again if `AFMultipartFormFinalBoundary` doesn't fit into the available buffer
    if (_phase == AFFinalBoundaryPhase) {
        return YES;
    }

    switch (self.inputStream.streamStatus) {
        case NSStreamStatusNotOpen:
        case NSStreamStatusOpening:
        case NSStreamStatusOpen:
        case NSStreamStatusReading:
        case NSStreamStatusWriting:
            return YES;
        case NSStreamStatusAtEnd:
        case NSStreamStatusClosed:
        case NSStreamStatusError:
        default:
            return NO;
    }
}

- (NSInteger)read:(uint8_t *)buffer
        maxLength:(NSUInteger)length
{
    NSInteger totalNumberOfBytesRead = 0;

    if (_phase == AFEncapsulationBoundaryPhase) {
        NSData *encapsulationBoundaryData = [([self hasInitialBoundary] ? AFMultipartFormInitialBoundary(self.boundary) : AFMultipartFormEncapsulationBoundary(self.boundary)) dataUsingEncoding:self.stringEncoding];
        totalNumberOfBytesRead += [self readData:encapsulationBoundaryData intoBuffer:&buffer[totalNumberOfBytesRead] maxLength:(length - (NSUInteger)totalNumberOfBytesRead)];
    }

    if (_phase == AFHeaderPhase) {
        NSData *headersData = [[self stringForHeaders] dataUsingEncoding:self.stringEncoding];
        totalNumberOfBytesRead += [self readData:headersData intoBuffer:&buffer[totalNumberOfBytesRead] maxLength:(length - (NSUInteger)totalNumberOfBytesRead)];
    }

    if (_phase == AFBodyPhase) {
        NSInteger numberOfBytesRead = 0;

        numberOfBytesRead = [self.inputStream read:&buffer[totalNumberOfBytesRead] maxLength:(length - (NSUInteger)totalNumberOfBytesRead)];
        if (numberOfBytesRead == -1) {
            return -1;
        } else {
            totalNumberOfBytesRead += numberOfBytesRead;

            if ([self.inputStream streamStatus] >= NSStreamStatusAtEnd) {
                [self transitionToNextPhase];
            }
        }
    }

    if (_phase == AFFinalBoundaryPhase) {
        NSData *closingBoundaryData = ([self hasFinalBoundary] ? [AFMultipartFormFinalBoundary(self.boundary) dataUsingEncoding:self.stringEncoding] : [NSData data]);
        totalNumberOfBytesRead += [self readData:closingBoundaryData intoBuffer:&buffer[totalNumberOfBytesRead] maxLength:(length - (NSUInteger)totalNumberOfBytesRead)];
    }

    return totalNumberOfBytesRead;
}

- (NSInteger)readData:(NSData *)data
           intoBuffer:(uint8_t *)buffer
            maxLength:(NSUInteger)length
{
    NSRange range = NSMakeRange((NSUInteger)_phaseReadOffset, MIN([data length] - ((NSUInteger)_phaseReadOffset), length));
    [data getBytes:buffer range:range];

    _phaseReadOffset += range.length;

    if (((NSUInteger)_phaseReadOffset) >= [data length]) {
        [self transitionToNextPhase];
    }

    return (NSInteger)range.length;
}

- (BOOL)transitionToNextPhase {
    if (![[NSThread currentThread] isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self transitionToNextPhase];
        });
        return YES;
    }

    switch (_phase) {
        case AFEncapsulationBoundaryPhase:
            _phase = AFHeaderPhase;
            break;
        case AFHeaderPhase:
            [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
            [self.inputStream open];
            _phase = AFBodyPhase;
            break;
        case AFBodyPhase:
            [self.inputStream close];
            _phase = AFFinalBoundaryPhase;
            break;
        case AFFinalBoundaryPhase:
        default:
            _phase = AFEncapsulationBoundaryPhase;
            break;
    }
    _phaseReadOffset = 0;

    return YES;
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    AFHTTPBodyPart *bodyPart = [[[self class] allocWithZone:zone] init];

    bodyPart.stringEncoding = self.stringEncoding;
    bodyPart.headers = self.headers;
    bodyPart.bodyContentLength = self.bodyContentLength;
    bodyPart.body = self.body;
    bodyPart.boundary = self.boundary;

    return bodyPart;
}

@end

#pragma mark -

@implementation AFJSONRequestSerializer

+ (instancetype)serializer {
    return [self serializerWithWritingOptions:(NSJSONWritingOptions)0];
}

+ (instancetype)serializerWithWritingOptions:(NSJSONWritingOptions)writingOptions
{
    AFJSONRequestSerializer *serializer = [[self alloc] init];
    serializer.writingOptions = writingOptions;

    return serializer;
}

#pragma mark - AFURLRequestSerialization

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(id)parameters
                                        error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(request);
    /*
     对于`GET`,`HEAD`,`DELETE`等方法中。直接使用父类的处理方式
     */
    if ([self.HTTPMethodsEncodingParametersInURI containsObject:[[request HTTPMethod] uppercaseString]]) {
        return [super requestBySerializingRequest:request withParameters:parameters error:error];
    }
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    //把`HTTPRequestHeaders`中的值添加进入请求头中。
    [self.HTTPRequestHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
        if (![request valueForHTTPHeaderField:field]) {
            [mutableRequest setValue:value forHTTPHeaderField:field];
        }
    }];
    if (parameters) {
        //设置请求头的`Content-Type`类型
        if (![mutableRequest valueForHTTPHeaderField:@"Content-Type"]) {
            [mutableRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        }

        if (![NSJSONSerialization isValidJSONObject:parameters]) {
            if (error) {
                NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey: NSLocalizedStringFromTable(@"The `parameters` argument is not valid JSON.", @"AFNetworking", nil)};
                *error = [[NSError alloc] initWithDomain:AFURLRequestSerializationErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:userInfo];
            }
            return nil;
        }
        //把parameters转换为JSON序列化的data
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters options:self.writingOptions error:error];
        if (!jsonData) {
            return nil;
        }
        //JSON序列化的数据设置为httpbody
        [mutableRequest setHTTPBody:jsonData];
    }
    return mutableRequest;
}

#pragma mark - NSSecureCoding

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (!self) {
        return nil;
    }

    self.writingOptions = [[decoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(writingOptions))] unsignedIntegerValue];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];

    [coder encodeInteger:self.writingOptions forKey:NSStringFromSelector(@selector(writingOptions))];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    AFJSONRequestSerializer *serializer = [super copyWithZone:zone];
    serializer.writingOptions = self.writingOptions;

    return serializer;
}

@end

#pragma mark -

@implementation AFPropertyListRequestSerializer

+ (instancetype)serializer {
    return [self serializerWithFormat:NSPropertyListXMLFormat_v1_0 writeOptions:0];
}

+ (instancetype)serializerWithFormat:(NSPropertyListFormat)format
                        writeOptions:(NSPropertyListWriteOptions)writeOptions
{
    AFPropertyListRequestSerializer *serializer = [[self alloc] init];
    serializer.format = format;
    serializer.writeOptions = writeOptions;

    return serializer;
}

#pragma mark - AFURLRequestSerializer

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(id)parameters
                                        error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(request);
    /*
     对于`GET`,`HEAD`,`DELETE`等方法中。直接使用父类的处理方式
     */
    if ([self.HTTPMethodsEncodingParametersInURI containsObject:[[request HTTPMethod] uppercaseString]]) {
        return [super requestBySerializingRequest:request withParameters:parameters error:error];
    }
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    //把`HTTPRequestHeaders`中的值添加进入请求头中。
    [self.HTTPRequestHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
        if (![request valueForHTTPHeaderField:field]) {
            [mutableRequest setValue:value forHTTPHeaderField:field];
        }
    }];
    if (parameters) {
        //设置请求头的`Content-Type`类型
        if (![mutableRequest valueForHTTPHeaderField:@"Content-Type"]) {
            [mutableRequest setValue:@"application/x-plist" forHTTPHeaderField:@"Content-Type"];
        }
        //把parameters转换为Plist序列化的data
        NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:parameters format:self.format options:self.writeOptions error:error];
        if (!plistData) {
            return nil;
        }
        //Plist序列化的数据设置为httpbody
        [mutableRequest setHTTPBody:plistData];
    }
    return mutableRequest;
}

#pragma mark - NSSecureCoding

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (!self) {
        return nil;
    }

    self.format = (NSPropertyListFormat)[[decoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(format))] unsignedIntegerValue];
    self.writeOptions = [[decoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(writeOptions))] unsignedIntegerValue];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];

    [coder encodeInteger:self.format forKey:NSStringFromSelector(@selector(format))];
    [coder encodeObject:@(self.writeOptions) forKey:NSStringFromSelector(@selector(writeOptions))];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    AFPropertyListRequestSerializer *serializer = [super copyWithZone:zone];
    serializer.format = self.format;
    serializer.writeOptions = self.writeOptions;

    return serializer;
}

@end

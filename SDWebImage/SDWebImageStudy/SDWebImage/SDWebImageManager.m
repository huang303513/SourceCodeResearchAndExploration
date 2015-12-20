/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageManager.h"
#import <objc/message.h>
<<<<<<< HEAD

=======
/**
 *  内部类
 */
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
@interface SDWebImageCombinedOperation : NSObject <SDWebImageOperation>

@property (assign, nonatomic, getter = isCancelled) BOOL cancelled;
@property (copy, nonatomic) SDWebImageNoParamsBlock cancelBlock;
@property (strong, nonatomic) NSOperation *cacheOperation;

@end

@interface SDWebImageManager ()

@property (strong, nonatomic, readwrite) SDImageCache *imageCache;
@property (strong, nonatomic, readwrite) SDWebImageDownloader *imageDownloader;
@property (strong, nonatomic) NSMutableSet *failedURLs;
@property (strong, nonatomic) NSMutableArray *runningOperations;

@end

@implementation SDWebImageManager

+ (id)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}
<<<<<<< HEAD

=======
/**
 *  // 初始化方法.
 1.获得一个SDImageCache的单例.
 2.获取一个SDWebImageDownloader的单例.
 3.新建一个MutableSet来存储下载失败的url.
 4.新建一个用来存储下载operation的可变数组.
 // 为什么不用MutableArray储存下载失败的URL?
 // 因为NSSet类有一个特性,就是Hash.实际上NSSet是一个哈希表,哈希表比数组优秀的地方是什么呢?就是查找速度快.查找同样一个元素,哈希表只需要通过key
 // 即可取到,而数组至少需要遍历依次.因为SDWebImage里有关失败URL的业务需求是,一个失败的URL只需要储存一次.这样的话Set自然比Array更合适.
 *
 *  @return
 */
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
- (id)init {
    if ((self = [super init])) {
        _imageCache = [self createCache];
        _imageDownloader = [SDWebImageDownloader sharedDownloader];
        _failedURLs = [NSMutableSet new];
        _runningOperations = [NSMutableArray new];
    }
    return self;
}
<<<<<<< HEAD

- (SDImageCache *)createCache {
    return [SDImageCache sharedImageCache];
}

=======
// 获取一个cache的单例
- (SDImageCache *)createCache {
    return [SDImageCache sharedImageCache];
}
// 利用Image的URL生成一个缓存时需要的key.
// 这里有两种情况,第一种是如果检测到cacheKeyFilter不为空时,利用cacheKeyFilter来处理URL生成一个key.
// 如果为空,那么直接返回URL的string内容,当做key.
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
- (NSString *)cacheKeyForURL:(NSURL *)url {
    if (self.cacheKeyFilter) {
        return self.cacheKeyFilter(url);
    }
    else {
        return [url absoluteString];
    }
}
<<<<<<< HEAD

=======
// 检测一张图片是否已被缓存.
// 首先检测内存缓存是否存在这张图片,如果已有,直接返回yes.
// 如果内存缓存里没有这张图片,那么调用diskImageExistsWithKey这个方法去硬盘缓存里找
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
- (BOOL)cachedImageExistsForURL:(NSURL *)url {
    NSString *key = [self cacheKeyForURL:url];
    if ([self.imageCache imageFromMemoryCacheForKey:key] != nil) return YES;
    return [self.imageCache diskImageExistsWithKey:key];
}
<<<<<<< HEAD

=======
// 检测硬盘里是否缓存了图片
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
- (BOOL)diskImageExistsForURL:(NSURL *)url {
    NSString *key = [self cacheKeyForURL:url];
    return [self.imageCache diskImageExistsWithKey:key];
}
<<<<<<< HEAD

=======
// 首先生成一个用来cache 住Image的key(利用key的url生成)
// 然后检测内存缓存里是否已经有这张图片
// 如果已经被缓存,那么再主线程里回调block
// 如果没有检测到,那么调用diskImageExistsWithKey,这个方法会在异步线程里,将图片存到硬盘,当然在存图之前也会检测是否已在硬盘缓存图片.
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
- (void)cachedImageExistsForURL:(NSURL *)url
                     completion:(SDWebImageCheckCacheCompletionBlock)completionBlock {
    NSString *key = [self cacheKeyForURL:url];
    
    BOOL isInMemoryCache = ([self.imageCache imageFromMemoryCacheForKey:key] != nil);
    
    if (isInMemoryCache) {
        // making sure we call the completion block on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionBlock) {
                completionBlock(YES);
            }
        });
        return;
    }
    
    [self.imageCache diskImageExistsWithKey:key completion:^(BOOL isInDiskCache) {
        // the completion block of checkDiskCacheForImageWithKey:completion: is always called on the main queue, no need to further dispatch
        if (completionBlock) {
            completionBlock(isInDiskCache);
        }
    }];
}
<<<<<<< HEAD

=======
//将图片存入硬盘
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
- (void)diskImageExistsForURL:(NSURL *)url
                   completion:(SDWebImageCheckCacheCompletionBlock)completionBlock {
    NSString *key = [self cacheKeyForURL:url];
    
    [self.imageCache diskImageExistsWithKey:key completion:^(BOOL isInDiskCache) {
        // the completion block of checkDiskCacheForImageWithKey:completion: is always called on the main queue, no need to further dispatch
        if (completionBlock) {
            completionBlock(isInDiskCache);
        }
    }];
}
<<<<<<< HEAD

=======
// 通过url建立一个operation用来下载图片.
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
- (id <SDWebImageOperation>)downloadImageWithURL:(NSURL *)url
                                         options:(SDWebImageOptions)options
                                        progress:(SDWebImageDownloaderProgressBlock)progressBlock
                                       completed:(SDWebImageCompletionWithFinishedBlock)completedBlock {
    // Invoking this method without a completedBlock is pointless
    NSAssert(completedBlock != nil, @"If you mean to prefetch the image, use -[SDWebImagePrefetcher prefetchURLs] instead");

    // Very common mistake is to send the URL using NSString object instead of NSURL. For some strange reason, XCode won't
    // throw any warning for this type mismatch. Here we failsafe this error by allowing URLs to be passed as NSString.
    if ([url isKindOfClass:NSString.class]) {
        url = [NSURL URLWithString:(NSString *)url];
    }

    // Prevents app crashing on argument type error like sending NSNull instead of NSURL
    if (![url isKindOfClass:NSURL.class]) {
        url = nil;
    }

    __block SDWebImageCombinedOperation *operation = [SDWebImageCombinedOperation new];
    __weak SDWebImageCombinedOperation *weakOperation = operation;
<<<<<<< HEAD

=======
    // 创建一个互斥锁防止现在有别的线程修改failedURLs.
    // 判断这个url是否是fail过的.如果url failed过的那么isFailedUrl就是true
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
    BOOL isFailedUrl = NO;
    @synchronized (self.failedURLs) {
        isFailedUrl = [self.failedURLs containsObject:url];
    }
<<<<<<< HEAD

=======
    // 如果url不存在那么直接返回一个block,如果url存在.那么继续进行判断.
    // options与SDWebImageRetryFailed这个option进行按位与操作.判断用户的options里是否有retry这个option.
    // 如果用户的options里没有retry这个选项并且isFaileUrl 是true.那么就回调一个error的block.
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
    if (!url || (!(options & SDWebImageRetryFailed) && isFailedUrl)) {
        dispatch_main_sync_safe(^{
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:nil];
            completedBlock(nil, error, SDImageCacheTypeNone, YES, url);
        });
        return operation;
    }
<<<<<<< HEAD
      
=======
    // 创建一个互斥锁防止现在有别的线程修改runningOperations.
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
    @synchronized (self.runningOperations) {
        [self.runningOperations addObject:operation];
    }
    NSString *key = [self cacheKeyForURL:url];
<<<<<<< HEAD

=======
    // cacheOperation应该是一个用来下载图片并且缓存的operation
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
    operation.cacheOperation = [self.imageCache queryDiskCacheForKey:key done:^(UIImage *image, SDImageCacheType cacheType) {
        if (operation.isCancelled) {
            @synchronized (self.runningOperations) {
                [self.runningOperations removeObject:operation];
            }

            return;
        }
<<<<<<< HEAD

=======
        //如果实现了SDWebImageManagerDelegate的代理方法、则返回缓存图片。
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
        if ((!image || options & SDWebImageRefreshCached) && (![self.delegate respondsToSelector:@selector(imageManager:shouldDownloadImageForURL:)] || [self.delegate imageManager:self shouldDownloadImageForURL:url])) {
            if (image && options & SDWebImageRefreshCached) {
                dispatch_main_sync_safe(^{
                    // If image was found in the cache bug SDWebImageRefreshCached is provided, notify about the cached image
                    // AND try to re-download it in order to let a chance to NSURLCache to refresh it from server.
                    completedBlock(image, nil, cacheType, YES, url);
                });
            }

            // download if no image or requested to refresh anyway, and download allowed by delegate
<<<<<<< HEAD
=======
            //根据参数、配置下载选项。
            //下面都是判断我们的options里包含哪些SDWebImageOptions,然后给我们的downloaderOptions相应的添加对应的SDWebImageDownloaderOptions. downloaderOptions |= SDWebImageDownloaderLowPriority这种表达式的意思等同于
            // downloaderOptions = downloaderOptions | SDWebImageDownloaderLowPriority
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
            SDWebImageDownloaderOptions downloaderOptions = 0;
            if (options & SDWebImageLowPriority) downloaderOptions |= SDWebImageDownloaderLowPriority;
            if (options & SDWebImageProgressiveDownload) downloaderOptions |= SDWebImageDownloaderProgressiveDownload;
            if (options & SDWebImageRefreshCached) downloaderOptions |= SDWebImageDownloaderUseNSURLCache;
            if (options & SDWebImageContinueInBackground) downloaderOptions |= SDWebImageDownloaderContinueInBackground;
            if (options & SDWebImageHandleCookies) downloaderOptions |= SDWebImageDownloaderHandleCookies;
            if (options & SDWebImageAllowInvalidSSLCertificates) downloaderOptions |= SDWebImageDownloaderAllowInvalidSSLCertificates;
            if (options & SDWebImageHighPriority) downloaderOptions |= SDWebImageDownloaderHighPriority;
            if (image && options & SDWebImageRefreshCached) {
                // force progressive off if image already cached but forced refreshing
                downloaderOptions &= ~SDWebImageDownloaderProgressiveDownload;
                // ignore image read from NSURLCache if image if cached but force refreshing
                downloaderOptions |= SDWebImageDownloaderIgnoreCachedResponse;
            }
<<<<<<< HEAD
            id <SDWebImageOperation> subOperation = [self.imageDownloader downloadImageWithURL:url options:downloaderOptions progress:progressBlock completed:^(UIImage *downloadedImage, NSData *data, NSError *error, BOOL finished) {
                if (weakOperation.isCancelled) {
=======
            //通过下载器imageDownloader来下载图片。
            //// 调用imageDownloader去下载image并且返回执行这个request的download的operation
            id <SDWebImageOperation> subOperation = [self.imageDownloader downloadImageWithURL:url options:downloaderOptions progress:progressBlock completed:^(UIImage *downloadedImage, NSData *data, NSError *error, BOOL finished) {
                if (weakOperation.isCancelled) {//如果下载操作已经被取消了，则什么也不做。
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
                    // Do nothing if the operation was cancelled
                    // See #699 for more details
                    // if we would call the completedBlock, there could be a race condition between this block and another completedBlock for the same object, so if this one is called second, we will overwrite the new data
                }
<<<<<<< HEAD
                else if (error) {
=======
                else if (error) {//如果下载图片出错
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
                    dispatch_main_sync_safe(^{
                        if (!weakOperation.isCancelled) {
                            completedBlock(nil, error, SDImageCacheTypeNone, finished, url);
                        }
                    });

                    BOOL shouldBeFailedURLAlliOSVersion = (error.code != NSURLErrorNotConnectedToInternet && error.code != NSURLErrorCancelled && error.code != NSURLErrorTimedOut);
                    BOOL shouldBeFailedURLiOS7 = (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1 && error.code != NSURLErrorInternationalRoamingOff && error.code != NSURLErrorCallIsActive && error.code != NSURLErrorDataNotAllowed);
                    if (shouldBeFailedURLAlliOSVersion || shouldBeFailedURLiOS7) {
                        @synchronized (self.failedURLs) {
                            [self.failedURLs addObject:url];
                        }
                    }
                }
<<<<<<< HEAD
                else {
=======
                else {//如果要尝试下载下载失败的链接，则把对应的链接从failedURLs重移除。
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
                    if ((options & SDWebImageRetryFailed)) {
                        @synchronized (self.failedURLs) {
                            [self.failedURLs removeObject:url];
                        }
                    }
                    
                    BOOL cacheOnDisk = !(options & SDWebImageCacheMemoryOnly);

                    if (options & SDWebImageRefreshCached && image && !downloadedImage) {
                        // Image refresh hit the NSURLCache cache, do not call the completion block
                    }
<<<<<<< HEAD
                    else if (downloadedImage && (!downloadedImage.images || (options & SDWebImageTransformAnimatedImage)) && [self.delegate respondsToSelector:@selector(imageManager:transformDownloadedImage:withURL:)]) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
=======
                    else if (downloadedImage && (!downloadedImage.images || (options & SDWebImageTransformAnimatedImage)) && [self.delegate respondsToSelector:@selector(imageManager:transformDownloadedImage:withURL:)]) {//如果下载成功了，代理对象实现了SDWebImageManagerDelegate协议方法，并且设置了SDWebImageTransformAnimatedImage选项，则转换图片的方向。
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                            //返回转换方向以后的图片
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
                            UIImage *transformedImage = [self.delegate imageManager:self transformDownloadedImage:downloadedImage withURL:url];

                            if (transformedImage && finished) {
                                BOOL imageWasTransformed = ![transformedImage isEqual:downloadedImage];
<<<<<<< HEAD
=======
                                //把图片加入缓存起来。
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
                                [self.imageCache storeImage:transformedImage recalculateFromImage:imageWasTransformed imageData:(imageWasTransformed ? nil : data) forKey:key toDisk:cacheOnDisk];
                            }

                            dispatch_main_sync_safe(^{
                                if (!weakOperation.isCancelled) {
                                    completedBlock(transformedImage, nil, SDImageCacheTypeNone, finished, url);
                                }
                            });
                        });
                    }
                    else {
                        if (downloadedImage && finished) {
                            [self.imageCache storeImage:downloadedImage recalculateFromImage:NO imageData:data forKey:key toDisk:cacheOnDisk];
                        }

                        dispatch_main_sync_safe(^{
                            if (!weakOperation.isCancelled) {
                                completedBlock(downloadedImage, nil, SDImageCacheTypeNone, finished, url);
                            }
                        });
                    }
                }

                if (finished) {
                    @synchronized (self.runningOperations) {
                        [self.runningOperations removeObject:operation];
                    }
                }
            }];
            operation.cancelBlock = ^{
                [subOperation cancel];
                
                @synchronized (self.runningOperations) {
                    [self.runningOperations removeObject:weakOperation];
                }
            };
        }
        else if (image) {
            dispatch_main_sync_safe(^{
                if (!weakOperation.isCancelled) {
                    completedBlock(image, nil, cacheType, YES, url);
                }
            });
            @synchronized (self.runningOperations) {
                [self.runningOperations removeObject:operation];
            }
        }
        else {
            // Image not in cache and download disallowed by delegate
            dispatch_main_sync_safe(^{
                if (!weakOperation.isCancelled) {
                    completedBlock(nil, nil, SDImageCacheTypeNone, YES, url);
                }
            });
            @synchronized (self.runningOperations) {
                [self.runningOperations removeObject:operation];
            }
        }
    }];

    return operation;
}

- (void)saveImageToCache:(UIImage *)image forURL:(NSURL *)url {
    if (image && url) {
        NSString *key = [self cacheKeyForURL:url];
        [self.imageCache storeImage:image forKey:key toDisk:YES];
    }
}
<<<<<<< HEAD

=======
// cancel掉所有正在执行的operation
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
- (void)cancelAll {
    @synchronized (self.runningOperations) {
        NSArray *copiedOperations = [self.runningOperations copy];
        [copiedOperations makeObjectsPerformSelector:@selector(cancel)];
        [self.runningOperations removeObjectsInArray:copiedOperations];
    }
}

- (BOOL)isRunning {
    return self.runningOperations.count > 0;
}

@end


@implementation SDWebImageCombinedOperation

- (void)setCancelBlock:(SDWebImageNoParamsBlock)cancelBlock {
    // check if the operation is already cancelled, then we just call the cancelBlock
    if (self.isCancelled) {
        if (cancelBlock) {
            cancelBlock();
        }
        _cancelBlock = nil; // don't forget to nil the cancelBlock, otherwise we will get crashes
    } else {
        _cancelBlock = [cancelBlock copy];
    }
}

- (void)cancel {
    self.cancelled = YES;
    if (self.cacheOperation) {
        [self.cacheOperation cancel];
        self.cacheOperation = nil;
    }
    if (self.cancelBlock) {
        self.cancelBlock();
        
        // TODO: this is a temporary fix to #809.
        // Until we can figure the exact cause of the crash, going with the ivar instead of the setter
//        self.cancelBlock = nil;
        _cancelBlock = nil;
    }
}

@end

<<<<<<< HEAD

=======
/**
 *  被废弃的接口。
 */
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
@implementation SDWebImageManager (Deprecated)

// deprecated method, uses the non deprecated method
// adapter for the completion block
- (id <SDWebImageOperation>)downloadWithURL:(NSURL *)url options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletedWithFinishedBlock)completedBlock {
    return [self downloadImageWithURL:url
                              options:options
                             progress:progressBlock
                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                if (completedBlock) {
                                    completedBlock(image, error, cacheType, finished);
                                }
                            }];
}

@end

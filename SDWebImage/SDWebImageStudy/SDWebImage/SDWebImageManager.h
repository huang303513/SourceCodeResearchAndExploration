/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"
#import "SDWebImageOperation.h"
#import "SDWebImageDownloader.h"
#import "SDImageCache.h"

typedef NS_OPTIONS(NSUInteger, SDWebImageOptions) {
<<<<<<< HEAD
    /**
     * By default, when a URL fail to be downloaded, the URL is blacklisted so the library won't keep trying.
     * This flag disable this blacklisting.
     */
    SDWebImageRetryFailed = 1 << 0,

    /**
     * By default, image downloads are started during UI interactions, this flags disable this feature,
     * leading to delayed download on UIScrollView deceleration for instance.
     */
    SDWebImageLowPriority = 1 << 1,

    /**
     * This flag disables on-disk caching
=======
    /// *默认情况下,如果一个url在下载的时候失败了,那么这个url会被加入黑名单并且library不会尝试再次下载,这个flag会阻止library把失败的url加入黑名单(简单来说如果选择了这个flag,那么即使某个url下载失败了,sdwebimage还是会尝试再次下载他.)
    SDWebImageRetryFailed = 1 << 0,

    ///  *默认情况下,图片会在交互发生的时候下载(例如你滑动tableview的时候),这个flag会禁止这个特性,导致的结果就是在scrollview减速的时候
    //*才会开始下载(也就是你滑动的时候scrollview不下载,你手从屏幕上移走,scrollview开始减速的时候才会开始下载图片)
    SDWebImageLowPriority = 1 << 1,

    /**
     * 禁止磁盘缓存，只做内存缓存
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
     */
    SDWebImageCacheMemoryOnly = 1 << 2,

    /**
<<<<<<< HEAD
     * This flag enables progressive download, the image is displayed progressively during download as a browser would do.
     * By default, the image is only displayed once completely downloaded.
=======
     * 这个flag会在图片下载的时候就显示(就像你用浏览器浏览网页的时候那种图片下载,一截一截的显示(待确认))
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
     */
    SDWebImageProgressiveDownload = 1 << 3,

    /**
<<<<<<< HEAD
     * Even if the image is cached, respect the HTTP response cache control, and refresh the image from remote location if needed.
     * The disk caching will be handled by NSURLCache instead of SDWebImage leading to slight performance degradation.
     * This option helps deal with images changing behind the same request URL, e.g. Facebook graph api profile pics.
     * If a cached image is refreshed, the completion block is called once with the cached image and again with the final image.
     *
     * Use this flag only if you can't make your URLs static with embedded cache busting parameter.
=======
     **这个选项的意思是正常情况下 只会根据url做key去判断图片是否加载过 但是 有些网页是动态网站 图片的url就会变 但是文件的签名 如
     e-tag （http header里面）是用来判断图片是否是同一个 默认sd 没有看http header 如果加上这个标记 就会访问http header .
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
     */
    SDWebImageRefreshCached = 1 << 4,

    /**
<<<<<<< HEAD
     * In iOS 4+, continue the download of the image if the app goes to background. This is achieved by asking the system for
     * extra time in background to let the request finish. If the background task expires the operation will be cancelled.
=======
     * 启动后台下载,加入你进入一个页面,有一张图片正在下载这时候你让app进入后台,图片还是会继续下载(这个估计要开backgroundfetch才有用)
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
     */
    SDWebImageContinueInBackground = 1 << 5,

    /**
<<<<<<< HEAD
     * Handles cookies stored in NSHTTPCookieStore by setting
     * NSMutableURLRequest.HTTPShouldHandleCookies = YES;
=======
     * 可以控制存在NSHTTPCookieStore的cookies.(我没用过,等用过的人过来解释一下)
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
     */
    SDWebImageHandleCookies = 1 << 6,

    /**
<<<<<<< HEAD
     * Enable to allow untrusted SSL certificates.
     * Useful for testing purposes. Use with caution in production.
=======
     * 允许不安全的SSL证书,在正式环境中慎用
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
     */
    SDWebImageAllowInvalidSSLCertificates = 1 << 7,

    /**
<<<<<<< HEAD
     * By default, image are loaded in the order they were queued. This flag move them to
     * the front of the queue and is loaded immediately instead of waiting for the current queue to be loaded (which 
     * could take a while).
=======
     * 默认情况下,image在装载的时候是按照他们在队列中的顺序装载的(就是先进先出).这个flag会把他们移动到队列的前端,并且立刻装载
     *而不是等到当前队列装载的时候再装载.
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
     */
    SDWebImageHighPriority = 1 << 8,
    
    /**
<<<<<<< HEAD
     * By default, placeholder images are loaded while the image is loading. This flag will delay the loading
     * of the placeholder image until after the image has finished loading.
=======
     * 默认情况下,占位图会在图片下载的时候显示.这个flag开启会延迟占位图显示的时间,等到图片下载完成之后才会显示占位图.(等图片显示完了我干嘛还显示占位图?或许是我理解错了?)
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
     */
    SDWebImageDelayPlaceholder = 1 << 9,

    /**
<<<<<<< HEAD
     * We usually don't call transformDownloadedImage delegate method on animated images,
     * as most transformation code would mangle it.
     * Use this flag to transform them anyway.
=======
     * 是否transform图片(没用过,还要再看,但是据我估计,是否是图片有可能方向不对需要调整方向,例如采用iPhone拍摄的照片如果不纠正方向,那么图片是向左旋转90度的.可能很多人不知道iPhone的摄像头并不是竖直的,而是向左偏了90度.具体请google.)
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
     */
    SDWebImageTransformAnimatedImage = 1 << 10,
    
    /**
<<<<<<< HEAD
     * By default, image is added to the imageView after download. But in some cases, we want to
     * have the hand before setting the image (apply a filter or add it with cross-fade animation for instance)
     * Use this flag if you want to manually set the image in the completion when success
=======
     默认情况下、图片下载好了以后会理解添加到imageView。但是有时我们想要先对图片做一些处理以后在添加到imageView上。设置这个标记就可以在图片下载成功以后手动设置图片。
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
     */
    SDWebImageAvoidAutoSetImage = 1 << 11
};

typedef void(^SDWebImageCompletionBlock)(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL);

typedef void(^SDWebImageCompletionWithFinishedBlock)(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL);

typedef NSString *(^SDWebImageCacheKeyFilterBlock)(NSURL *url);


@class SDWebImageManager;

<<<<<<< HEAD
@protocol SDWebImageManagerDelegate <NSObject>

@optional

/**
 * Controls which image should be downloaded when the image is not found in the cache.
 *
 * @param imageManager The current `SDWebImageManager`
 * @param imageURL     The url of the image to be downloaded
 *
 * @return Return NO to prevent the downloading of the image on cache misses. If not implemented, YES is implied.
=======

/**
 *  SDWebImageManagerDelegate协议
 */
@protocol SDWebImageManagerDelegate <NSObject>
@optional
/**
 主要作用是当缓存里没有发现某张图片的缓存时,是否选择下载这张图片(默认是yes),可以选择no,那么sdwebimage在缓存中没有找到这张图片的时候不会选择下载
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
 */
- (BOOL)imageManager:(SDWebImageManager *)imageManager shouldDownloadImageForURL:(NSURL *)imageURL;

/**
<<<<<<< HEAD
 * Allows to transform the image immediately after it has been downloaded and just before to cache it on disk and memory.
 * NOTE: This method is called from a global queue in order to not to block the main thread.
 *
 * @param imageManager The current `SDWebImageManager`
 * @param image        The image to transform
 * @param imageURL     The url of the image to transform
=======
 * *在图片下载完成并且还没有加入磁盘缓存或者内存缓存的时候就transform这个图片.这个方法是在异步线程执行的,防治阻塞主线程.
 *至于为什么在异步执行很简单,对一张图片纠正方向(也就是transform)是很耗资源的,一张2M大小的图片纠正方向你可以用instrument测试一下耗时.
 *很恐怖
 * @param imageManager 当前`SDWebImageManager`
 * @param image        需要转变方向的图片
 * @param imageURL     需要转变方向的图片的URL
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
 *
 * @return The transformed image object.
 */
- (UIImage *)imageManager:(SDWebImageManager *)imageManager transformDownloadedImage:(UIImage *)image withURL:(NSURL *)imageURL;

@end

/**
<<<<<<< HEAD
 * The SDWebImageManager is the class behind the UIImageView+WebCache category and likes.
 * It ties the asynchronous downloader (SDWebImageDownloader) with the image cache store (SDImageCache).
 * You can use this class directly to benefit from web image downloading with caching in another context than
 * a UIView.
 *
 * Here is a simple example of how to use SDWebImageManager:
 *
 * @code

=======
 *SDWebImageManager是用在UIImageView+WebCache分类里面或者相似的地方。
 *它连接一步下载器(SDWebImageDownloader)和图片缓冲器(SDImageCache)。
 * 你可以直接使用一个其他上下文环境的SDWebImageManager,而不是仅仅限于一个UIView.
 *
 * 下面是一个SDWebImageManager的基本用法
 *
 * @code
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
SDWebImageManager *manager = [SDWebImageManager sharedManager];
[manager downloadImageWithURL:imageURL
                      options:0
                     progress:nil
                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                        if (image) {
                            // do something with image
                        }
                    }];

 * @endcode
 */
<<<<<<< HEAD
@interface SDWebImageManager : NSObject

@property (weak, nonatomic) id <SDWebImageManagerDelegate> delegate;

=======

/**
 *  SDWebImageManager代码
 */
@interface SDWebImageManager : NSObject
//代理对象
@property (weak, nonatomic) id <SDWebImageManagerDelegate> delegate;
//如同上文所说,一个SDWebImageManager会绑定一个imageCache和一个下载器.
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
@property (strong, nonatomic, readonly) SDImageCache *imageCache;
@property (strong, nonatomic, readonly) SDWebImageDownloader *imageDownloader;

/**
<<<<<<< HEAD
 * The cache filter is a block used each time SDWebImageManager need to convert an URL into a cache key. This can
 * be used to remove dynamic part of an image URL.
 *
 * The following example sets a filter in the application delegate that will remove any query-string from the
 * URL before to use it as a cache key:
 *
=======
 *当每次SDWebImageManager需要转换一个URL到一个缓存key时，我们都需要用到缓存过滤器。这个方法可以用于移除图片URL的动态部分。
 
 *下面的代码是在应用代理类里面设置，他会移除RUL的所有查询字符串在作为缓存key之前。
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
 * @code

[[SDWebImageManager sharedManager] setCacheKeyFilter:^(NSURL *url) {
    url = [[NSURL alloc] initWithScheme:url.scheme host:url.host path:url.path];
    return [url absoluteString];
}];
<<<<<<< HEAD

 * @endcode
 */
@property (nonatomic, copy) SDWebImageCacheKeyFilterBlock cacheKeyFilter;

/**
 * Returns global SDWebImageManager instance.
 *
 * @return SDWebImageManager shared instance
=======
 * @endcode
 */
/**
 *  1他是一个block.2.这个block的作用就是生成一个image的key.因为sdwebimage的缓存原理你可以当成是一个字典,每一个字典的value就是一张image,那么这个value对应的key是什么呢?就是cacheKeyFilter根据某个规则对这个图片的url做一些操作生成的.上面的示例就显示了怎么利用这个block把image的url重新组合生成一个key.以后当sdwebimage检测到你
 */
@property (nonatomic, copy) SDWebImageCacheKeyFilterBlock cacheKeyFilter;

/**
生成一个SDWebImagemanager的单例.
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
 */
+ (SDWebImageManager *)sharedManager;

/**
<<<<<<< HEAD
 * Downloads the image at the given URL if not present in cache or return the cached version otherwise.
 *
 * @param url            The URL to the image
 * @param options        A mask to specify options to use for this request
 * @param progressBlock  A block called while image is downloading
 * @param completedBlock A block called when operation has been completed.
 *
 *   This parameter is required.
 * 
 *   This block has no return value and takes the requested UIImage as first parameter.
 *   In case of error the image parameter is nil and the second parameter may contain an NSError.
 *
 *   The third parameter is an `SDImageCacheType` enum indicating if the image was retrieved from the local cache
 *   or from the memory cache or from the network.
 *
 *   The last parameter is set to NO when the SDWebImageProgressiveDownload option is used and the image is 
 *   downloading. This block is thus called repeatedly with a partial image. When image is fully downloaded, the
 *   block is called a last time with the full image and the last parameter set to YES.
 *
 * @return Returns an NSObject conforming to SDWebImageOperation. Should be an instance of SDWebImageDownloaderOperation
=======
 * 从给定的URL中下载一个之前没有被缓存的Image.
 * 这个方法主要就是SDWebImage下载图片的方法了.
 * 第一个参数是必须要的,就是image的url
 * 第二个参数就是我们上面的Options,你可以定制化各种各样的操作.详情参上.
 * 第三个参数是一个回调block,用于图片在下载过程中的回调.(英文注释应该是有问题的.)
 * 第四个参数是一个下载完成的回调.会在图片下载完成后回调.
 * 返回值是一个NSObject类,并且这个NSObject类是conforming一个协议这个协议叫做SDWebImageOperation,这个协议很简单,就是一个cancel掉operation的协议.
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
 */
- (id <SDWebImageOperation>)downloadImageWithURL:(NSURL *)url
                                         options:(SDWebImageOptions)options
                                        progress:(SDWebImageDownloaderProgressBlock)progressBlock
                                       completed:(SDWebImageCompletionWithFinishedBlock)completedBlock;

/**
<<<<<<< HEAD
 * Saves image to cache for given URL
 *
 * @param image The image to cache
 * @param url   The URL to the image
 *
 */

- (void)saveImageToCache:(UIImage *)image forURL:(NSURL *)url;

/**
 * Cancel all current operations
=======
 将图片存入cache的方法,类似于字典的setValue: forKey:
 *
 */
- (void)saveImageToCache:(UIImage *)image forURL:(NSURL *)url;

/**
 *取消掉当前所有的下载图片的operation
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
 */
- (void)cancelAll;

/**
<<<<<<< HEAD
 * Check one or more operations running
=======
 check一下是否有一个或者多个operation正在执行(简单来说就是check是否有图片在下载)
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
 */
- (BOOL)isRunning;

/**
<<<<<<< HEAD
 *  Check if image has already been cached
 *
 *  @param url image url
 *
 *  @return if the image was already cached
=======
 * 检测一个image是否已经被缓存到磁盘(是否存且仅存在disk里).
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
 */
- (BOOL)cachedImageExistsForURL:(NSURL *)url;

/**
<<<<<<< HEAD
 *  Check if image has already been cached on disk only
 *
 *  @param url image url
 *
 *  @return if the image was already cached (disk only)
=======
 * 检测一个image是否已经被缓存到磁盘(是否存且仅存在disk里).
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
 */
- (BOOL)diskImageExistsForURL:(NSURL *)url;

/**
<<<<<<< HEAD
 *  Async check if image has already been cached
 *
 *  @param url              image url
 *  @param completionBlock  the block to be executed when the check is finished
 *  
 *  @note the completion block is always executed on the main queue
=======
 如果检测到图片已经被缓存,那么执行回调block.这个block会永远执行在主线程.也就是你可以在这个回调block里更新ui.
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
 */
- (void)cachedImageExistsForURL:(NSURL *)url
                     completion:(SDWebImageCheckCacheCompletionBlock)completionBlock;

/**
<<<<<<< HEAD
 *  Async check if image has already been cached on disk only
 *
 *  @param url              image url
 *  @param completionBlock  the block to be executed when the check is finished
 *
 *  @note the completion block is always executed on the main queue
=======
 如果检测到图片已经被缓存在磁盘(存且仅存在disk),那么执行回调block.这个block会永远执行在主线程.也就是你可以在这个回调block里更新ui.
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
 */
- (void)diskImageExistsForURL:(NSURL *)url
                   completion:(SDWebImageCheckCacheCompletionBlock)completionBlock;


/**
<<<<<<< HEAD
 *Return the cache key for a given URL
=======
通过image的url返回image存在缓存里的key.有人会问了,为什么不直接把图片的url当做image的key来使用呢?而是非要对url做一些处理才能当做key.我的解释是,我也不太清楚.可能为了防止重复吧.
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
 */
- (NSString *)cacheKeyForURL:(NSURL *)url;

@end

<<<<<<< HEAD

#pragma mark - Deprecated

=======
/**
 *  下面是已经被废弃的接口和代码块
 */
#pragma mark - Deprecated
>>>>>>> afd7a2b3cfc8fdee25a4a4b6f849871289a844c8
typedef void(^SDWebImageCompletedBlock)(UIImage *image, NSError *error, SDImageCacheType cacheType) __deprecated_msg("Block type deprecated. Use `SDWebImageCompletionBlock`");
typedef void(^SDWebImageCompletedWithFinishedBlock)(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) __deprecated_msg("Block type deprecated. Use `SDWebImageCompletionWithFinishedBlock`");


@interface SDWebImageManager (Deprecated)

/**
 *  Downloads the image at the given URL if not present in cache or return the cached version otherwise.
 *
 *  @deprecated This method has been deprecated. Use `downloadImageWithURL:options:progress:completed:`
 */
- (id <SDWebImageOperation>)downloadWithURL:(NSURL *)url
                                    options:(SDWebImageOptions)options
                                   progress:(SDWebImageDownloaderProgressBlock)progressBlock
                                  completed:(SDWebImageCompletedWithFinishedBlock)completedBlock __deprecated_msg("Method deprecated. Use `downloadImageWithURL:options:progress:completed:`");

@end

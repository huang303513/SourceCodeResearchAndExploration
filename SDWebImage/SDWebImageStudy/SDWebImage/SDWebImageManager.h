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
    /// *默认情况下,如果一个url在下载的时候失败了,那么这个url会被加入黑名单并且library不会尝试再次下载,这个flag会阻止library把失败的url加入黑名单(简单来说如果选择了这个flag,那么即使某个url下载失败了,sdwebimage还是会尝试再次下载他.)
    SDWebImageRetryFailed = 1 << 0,

    ///  *默认情况下,图片会在交互发生的时候下载(例如你滑动tableview的时候),这个flag会禁止这个特性,导致的结果就是在scrollview减速的时候
    //*才会开始下载(也就是你滑动的时候scrollview不下载,你手从屏幕上移走,scrollview开始减速的时候才会开始下载图片)
    SDWebImageLowPriority = 1 << 1,

    /**
     * 禁止磁盘缓存，只做内存缓存
     */
    SDWebImageCacheMemoryOnly = 1 << 2,

    /**
     * 这个flag会在图片下载的时候就显示(就像你用浏览器浏览网页的时候那种图片下载,一截一截的显示(待确认))
     */
    SDWebImageProgressiveDownload = 1 << 3,

    /**
     **这个选项的意思是正常情况下 只会根据url做key去判断图片是否加载过 但是 有些网页是动态网站 图片的url就会变 但是文件的签名 如
     e-tag （http header里面）是用来判断图片是否是同一个 默认sd 没有看http header 如果加上这个标记 就会访问http header .
     */
    SDWebImageRefreshCached = 1 << 4,

    /**
     * 启动后台下载,加入你进入一个页面,有一张图片正在下载这时候你让app进入后台,图片还是会继续下载(这个估计要开backgroundfetch才有用)
     */
    SDWebImageContinueInBackground = 1 << 5,

    /**
     * 可以控制存在NSHTTPCookieStore的cookies.(我没用过,等用过的人过来解释一下)
     */
    SDWebImageHandleCookies = 1 << 6,

    /**
     * 允许不安全的SSL证书,在正式环境中慎用
     */
    SDWebImageAllowInvalidSSLCertificates = 1 << 7,

    /**
     * 默认情况下,image在装载的时候是按照他们在队列中的顺序装载的(就是先进先出).这个flag会把他们移动到队列的前端,并且立刻装载
     *而不是等到当前队列装载的时候再装载.
     */
    SDWebImageHighPriority = 1 << 8,
    
    /**
     * 默认情况下,占位图会在图片下载的时候显示.这个flag开启会延迟占位图显示的时间,等到图片下载完成之后才会显示占位图.(等图片显示完了我干嘛还显示占位图?或许是我理解错了?)
     */
    SDWebImageDelayPlaceholder = 1 << 9,

    /**
     * 是否transform图片(没用过,还要再看,但是据我估计,是否是图片有可能方向不对需要调整方向,例如采用iPhone拍摄的照片如果不纠正方向,那么图片是向左旋转90度的.可能很多人不知道iPhone的摄像头并不是竖直的,而是向左偏了90度.具体请google.)
     */
    SDWebImageTransformAnimatedImage = 1 << 10,
    
    /**
     默认情况下、图片下载好了以后会理解添加到imageView。但是有时我们想要先对图片做一些处理以后在添加到imageView上。设置这个标记就可以在图片下载成功以后手动设置图片。
     */
    SDWebImageAvoidAutoSetImage = 1 << 11
};

typedef void(^SDWebImageCompletionBlock)(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL);

typedef void(^SDWebImageCompletionWithFinishedBlock)(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL);

typedef NSString *(^SDWebImageCacheKeyFilterBlock)(NSURL *url);


@class SDWebImageManager;


/**
 *  SDWebImageManagerDelegate协议
 */
@protocol SDWebImageManagerDelegate <NSObject>
@optional
/**
 主要作用是当缓存里没有发现某张图片的缓存时,是否选择下载这张图片(默认是yes),可以选择no,那么sdwebimage在缓存中没有找到这张图片的时候不会选择下载
 */
- (BOOL)imageManager:(SDWebImageManager *)imageManager shouldDownloadImageForURL:(NSURL *)imageURL;

/**
 * *在图片下载完成并且还没有加入磁盘缓存或者内存缓存的时候就transform这个图片.这个方法是在异步线程执行的,防治阻塞主线程.
 *至于为什么在异步执行很简单,对一张图片纠正方向(也就是transform)是很耗资源的,一张2M大小的图片纠正方向你可以用instrument测试一下耗时.
 *很恐怖
 * @param imageManager 当前`SDWebImageManager`
 * @param image        需要转变方向的图片
 * @param imageURL     需要转变方向的图片的URL
 *
 * @return The transformed image object.
 */
- (UIImage *)imageManager:(SDWebImageManager *)imageManager transformDownloadedImage:(UIImage *)image withURL:(NSURL *)imageURL;

@end

/**
 *SDWebImageManager是用在UIImageView+WebCache分类里面或者相似的地方。
 *它连接一步下载器(SDWebImageDownloader)和图片缓冲器(SDImageCache)。
 * 你可以直接使用一个其他上下文环境的SDWebImageManager,而不是仅仅限于一个UIView.
 *
 * 下面是一个SDWebImageManager的基本用法
 *
 * @code
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

/**
 *  SDWebImageManager代码
 */
@interface SDWebImageManager : NSObject
//代理对象
@property (weak, nonatomic) id <SDWebImageManagerDelegate> delegate;
//如同上文所说,一个SDWebImageManager会绑定一个imageCache和一个下载器.
@property (strong, nonatomic, readonly) SDImageCache *imageCache;
@property (strong, nonatomic, readonly) SDWebImageDownloader *imageDownloader;

/**
 *当每次SDWebImageManager需要转换一个URL到一个缓存key时，我们都需要用到缓存过滤器。这个方法可以用于移除图片URL的动态部分。
 
 *下面的代码是在应用代理类里面设置，他会移除RUL的所有查询字符串在作为缓存key之前。
 * @code

[[SDWebImageManager sharedManager] setCacheKeyFilter:^(NSURL *url) {
    url = [[NSURL alloc] initWithScheme:url.scheme host:url.host path:url.path];
    return [url absoluteString];
}];
 * @endcode
 */
/**
 *  1他是一个block.2.这个block的作用就是生成一个image的key.因为sdwebimage的缓存原理你可以当成是一个字典,每一个字典的value就是一张image,那么这个value对应的key是什么呢?就是cacheKeyFilter根据某个规则对这个图片的url做一些操作生成的.上面的示例就显示了怎么利用这个block把image的url重新组合生成一个key.以后当sdwebimage检测到你
 */
@property (nonatomic, copy) SDWebImageCacheKeyFilterBlock cacheKeyFilter;

/**
生成一个SDWebImagemanager的单例.
 */
+ (SDWebImageManager *)sharedManager;

/**
 * 从给定的URL中下载一个之前没有被缓存的Image.
 * 这个方法主要就是SDWebImage下载图片的方法了.
 * 第一个参数是必须要的,就是image的url
 * 第二个参数就是我们上面的Options,你可以定制化各种各样的操作.详情参上.
 * 第三个参数是一个回调block,用于图片在下载过程中的回调.(英文注释应该是有问题的.)
 * 第四个参数是一个下载完成的回调.会在图片下载完成后回调.
 * 返回值是一个NSObject类,并且这个NSObject类是conforming一个协议这个协议叫做SDWebImageOperation,这个协议很简单,就是一个cancel掉operation的协议.
 */
- (id <SDWebImageOperation>)downloadImageWithURL:(NSURL *)url
                                         options:(SDWebImageOptions)options
                                        progress:(SDWebImageDownloaderProgressBlock)progressBlock
                                       completed:(SDWebImageCompletionWithFinishedBlock)completedBlock;

/**
 将图片存入cache的方法,类似于字典的setValue: forKey:
 *
 */
- (void)saveImageToCache:(UIImage *)image forURL:(NSURL *)url;

/**
 *取消掉当前所有的下载图片的operation
 */
- (void)cancelAll;

/**
 check一下是否有一个或者多个operation正在执行(简单来说就是check是否有图片在下载)
 */
- (BOOL)isRunning;

/**
 * 检测一个image是否已经被缓存到磁盘(是否存且仅存在disk里).
 */
- (BOOL)cachedImageExistsForURL:(NSURL *)url;

/**
 * 检测一个image是否已经被缓存到磁盘(是否存且仅存在disk里).
 */
- (BOOL)diskImageExistsForURL:(NSURL *)url;

/**
 如果检测到图片已经被缓存,那么执行回调block.这个block会永远执行在主线程.也就是你可以在这个回调block里更新ui.
 */
- (void)cachedImageExistsForURL:(NSURL *)url
                     completion:(SDWebImageCheckCacheCompletionBlock)completionBlock;

/**
 如果检测到图片已经被缓存在磁盘(存且仅存在disk),那么执行回调block.这个block会永远执行在主线程.也就是你可以在这个回调block里更新ui.
 */
- (void)diskImageExistsForURL:(NSURL *)url
                   completion:(SDWebImageCheckCacheCompletionBlock)completionBlock;


/**
通过image的url返回image存在缓存里的key.有人会问了,为什么不直接把图片的url当做image的key来使用呢?而是非要对url做一些处理才能当做key.我的解释是,我也不太清楚.可能为了防止重复吧.
 */
- (NSString *)cacheKeyForURL:(NSURL *)url;

@end

/**
 *  下面是已经被废弃的接口和代码块
 */
#pragma mark - Deprecated
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

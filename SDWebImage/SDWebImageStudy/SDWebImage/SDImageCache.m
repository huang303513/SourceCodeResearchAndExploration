/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDImageCache.h"
#import "SDWebImageDecoder.h"
#import "UIImage+MultiFormat.h"
#import <CommonCrypto/CommonDigest.h>

// See https://github.com/rs/SDWebImage/pull/1141 for discussion
@interface AutoPurgeCache : NSCache
@end

@implementation AutoPurgeCache

- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];

}

@end

static const NSInteger kDefaultCacheMaxCacheAge = 60 * 60 * 24 * 7; // 1 week
// PNG signature bytes and data (below)
static unsigned char kPNGSignatureBytes[8] = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
static NSData *kPNGSignatureData = nil;

BOOL ImageDataHasPNGPreffix(NSData *data);
//判断图片是否是PNG图片
BOOL ImageDataHasPNGPreffix(NSData *data) {
    NSUInteger pngSignatureLength = [kPNGSignatureData length];
    if ([data length] >= pngSignatureLength) {
        if ([[data subdataWithRange:NSMakeRange(0, pngSignatureLength)] isEqualToData:kPNGSignatureData]) {
            return YES;
        }
    }

    return NO;
}
//获取图片占用内存大小
FOUNDATION_STATIC_INLINE NSUInteger SDCacheCostForImage(UIImage *image) {
    return image.size.height * image.size.width * image.scale * image.scale;
}

@interface SDImageCache ()

@property (strong, nonatomic) NSCache *memCache;
@property (strong, nonatomic) NSString *diskCachePath;
@property (strong, nonatomic) NSMutableArray *customPaths;
@property (SDDispatchQueueSetterSementics, nonatomic) dispatch_queue_t ioQueue;

@end


@implementation SDImageCache {
    NSFileManager *_fileManager;
}

+ (SDImageCache *)sharedImageCache {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (id)init {
    return [self initWithNamespace:@"default"];
}

- (id)initWithNamespace:(NSString *)ns {
    //磁盘缓存地址
    NSString *path = [self makeDiskCachePath:ns];
    return [self initWithNamespace:ns diskCacheDirectory:path];
}
/**
 *  初始化操作
 *
 *  @param ns        内存缓存的名字
 *  @param directory 磁盘缓存的目录
 *
 *  @return 返回对象
 */
- (id)initWithNamespace:(NSString *)ns diskCacheDirectory:(NSString *)directory {
    if ((self = [super init])) {
        NSString *fullNamespace = [@"com.hackemist.SDWebImageCache." stringByAppendingString:ns];

        // initialise PNG signature data
        /**
         *  PNG的标记Data，有8比特长
         */
        kPNGSignatureData = [NSData dataWithBytes:kPNGSignatureBytes length:8];

        // Create IO serial queue
        //一个线性的GCD队列
        _ioQueue = dispatch_queue_create("com.hackemist.SDWebImageCache", DISPATCH_QUEUE_SERIAL);

        // Init default values
        //最长缓存时间为1周
        _maxCacheAge = kDefaultCacheMaxCacheAge;

        // Init the memory cache
        //内存管理的类。当接收到内存警告时，对内存缓存的图片处理
        _memCache = [[AutoPurgeCache alloc] init];
        _memCache.name = fullNamespace;

        // Init the disk cache
        //磁盘缓存地址
        if (directory != nil) {
            _diskCachePath = [directory stringByAppendingPathComponent:fullNamespace];
        } else {
            NSString *path = [self makeDiskCachePath:ns];
            _diskCachePath = path;
        }

        // Set decompression to YES
        _shouldDecompressImages = YES;

        // memory cache enabled
        _shouldCacheImagesInMemory = YES;

        // Disable iCloud
        _shouldDisableiCloud = YES;

        dispatch_sync(_ioQueue, ^{
            _fileManager = [NSFileManager new];
        });

#if TARGET_OS_IPHONE
        //接收内存警告通知
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearMemory)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        //接收应用终止通知
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cleanDisk)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        //进入后台通知
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(backgroundCleanDisk)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
#endif
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SDDispatchQueueRelease(_ioQueue);
}

- (void)addReadOnlyCachePath:(NSString *)path {
    if (!self.customPaths) {
        self.customPaths = [NSMutableArray new];
    }

    if (![self.customPaths containsObject:path]) {
        [self.customPaths addObject:path];
    }
}

- (NSString *)cachePathForKey:(NSString *)key inPath:(NSString *)path {
    NSString *filename = [self cachedFileNameForKey:key];
    return [path stringByAppendingPathComponent:filename];
}

- (NSString *)defaultCachePathForKey:(NSString *)key {
    return [self cachePathForKey:key inPath:self.diskCachePath];
}

#pragma mark SDImageCache (private)
/**
 *  对文件名MD5加密
 *
 *  @param key 文件名
 *
 *  @return 返回加密以后的字符串
 */
- (NSString *)cachedFileNameForKey:(NSString *)key {
    const char *str = [key UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                                                    r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];

    return filename;
}

#pragma mark ImageCache

// 初始化磁盘缓存的地址。
-(NSString *)makeDiskCachePath:(NSString*)fullNamespace{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths[0] stringByAppendingPathComponent:fullNamespace];
}

- (void)storeImage:(UIImage *)image recalculateFromImage:(BOOL)recalculate imageData:(NSData *)imageData forKey:(NSString *)key toDisk:(BOOL)toDisk {
    if (!image || !key) {
        return;
    }
    // if memory cache is enabled
    //存入内存缓存
    if (self.shouldCacheImagesInMemory) {
        NSUInteger cost = SDCacheCostForImage(image);
        [self.memCache setObject:image forKey:key cost:cost];
    }

    if (toDisk) {
        dispatch_async(self.ioQueue, ^{
            NSData *data = imageData;

            if (image && (recalculate || !data)) {
#if TARGET_OS_IPHONE
                // We need to determine if the image is a PNG or a JPEG
                // PNGs are easier to detect because they have a unique signature (http://www.w3.org/TR/PNG-Structure.html)
                // The first eight bytes of a PNG file always contain the following (decimal) values:
                // 137 80 78 71 13 10 26 10

                // If the imageData is nil (i.e. if trying to save a UIImage directly or the image was transformed on download)
                // and the image has an alpha channel, we will consider it PNG to avoid losing the transparency
                //如果图片有透明度信息，我们需要处理以保存图片的透明信息
                int alphaInfo = CGImageGetAlphaInfo(image.CGImage);
                BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                                  alphaInfo == kCGImageAlphaNoneSkipFirst ||
                                  alphaInfo == kCGImageAlphaNoneSkipLast);
                BOOL imageIsPng = hasAlpha;

                // But if we have an image data, we will look at the preffix
                //判断图片是否是PNG
                if ([imageData length] >= [kPNGSignatureData length]) {
                    imageIsPng = ImageDataHasPNGPreffix(imageData);
                }
                //是否是PNG或者JPG
                if (imageIsPng) {
                    data = UIImagePNGRepresentation(image);
                }
                else {
                    data = UIImageJPEGRepresentation(image, (CGFloat)1.0);
                }
#else
                data = [NSBitmapImageRep representationOfImageRepsInArray:image.representations usingType: NSJPEGFileType properties:nil];
#endif
            }

            if (data) {
                //创建一个图片缓存的路径
                if (![_fileManager fileExistsAtPath:_diskCachePath]) {
                    [_fileManager createDirectoryAtPath:_diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
                }

                // get cache Path for image key
                NSString *cachePathForKey = [self defaultCachePathForKey:key];
                // transform to NSUrl
                NSURL *fileURL = [NSURL fileURLWithPath:cachePathForKey];

                [_fileManager createFileAtPath:cachePathForKey contents:data attributes:nil];

                // disable iCloud backup
                //把图片存入iCloud
                if (self.shouldDisableiCloud) {
                    [fileURL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
                }
            }
        });
    }
}
/**
 *  把图片存入磁盘
 *
 *  @param image 图片
 *  @param key   key
 */
- (void)storeImage:(UIImage *)image forKey:(NSString *)key {
    [self storeImage:image recalculateFromImage:YES imageData:nil forKey:key toDisk:YES];
}
/**
 *  把图片存入磁盘
 *
 *  @param image 图片
 *  @param key   key
 */
- (void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk {
    [self storeImage:image recalculateFromImage:YES imageData:nil forKey:key toDisk:toDisk];
}

- (BOOL)diskImageExistsWithKey:(NSString *)key {
    BOOL exists = NO;
    
    // this is an exception to access the filemanager on another queue than ioQueue, but we are using the shared instance
    // from apple docs on NSFileManager: The methods of the shared NSFileManager object can be called from multiple threads safely.
    exists = [[NSFileManager defaultManager] fileExistsAtPath:[self defaultCachePathForKey:key]];
    
    return exists;
}

- (void)diskImageExistsWithKey:(NSString *)key completion:(SDWebImageCheckCacheCompletionBlock)completionBlock {
    dispatch_async(_ioQueue, ^{
        BOOL exists = [_fileManager fileExistsAtPath:[self defaultCachePathForKey:key]];
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(exists);
            });
        }
    });
}
/**
 *  从内存缓存中读取图片
 *
 *  @param key key
 *
 *  @return 返回图片
 */
- (UIImage *)imageFromMemoryCacheForKey:(NSString *)key {
    return [self.memCache objectForKey:key];
}

- (UIImage *)imageFromDiskCacheForKey:(NSString *)key {

    // First check the in-memory cache...
    UIImage *image = [self imageFromMemoryCacheForKey:key];
    if (image) {
        return image;
    }

    // Second check the disk cache...
    UIImage *diskImage = [self diskImageForKey:key];
    if (diskImage && self.shouldCacheImagesInMemory) {
        NSUInteger cost = SDCacheCostForImage(diskImage);
        [self.memCache setObject:diskImage forKey:key cost:cost];
    }

    return diskImage;
}
/**
 *  从硬盘查找图片
 *
 *  @param key key
 *
 *  @return 返回图片的数据
 */
- (NSData *)diskImageDataBySearchingAllPathsForKey:(NSString *)key {
    NSString *defaultPath = [self defaultCachePathForKey:key];
    NSData *data = [NSData dataWithContentsOfFile:defaultPath];
    if (data) {
        return data;
    }
    //从自定义路径取图片
    NSArray *customPaths = [self.customPaths copy];
    for (NSString *path in customPaths) {
        NSString *filePath = [self cachePathForKey:key inPath:path];
        NSData *imageData = [NSData dataWithContentsOfFile:filePath];
        if (imageData) {
            return imageData;
        }
    }

    return nil;
}
/**
 *  通过key在磁盘上查找图片并返回图片
 *
 *  @param key key
 *
 *  @return 返回图片
 */
- (UIImage *)diskImageForKey:(NSString *)key {
    NSData *data = [self diskImageDataBySearchingAllPathsForKey:key];
    if (data) {
        UIImage *image = [UIImage sd_imageWithData:data];
        image = [self scaledImageForKey:key image:image];
        if (self.shouldDecompressImages) {
            image = [UIImage decodedImageWithImage:image];
        }
        return image;
    }
    else {
        return nil;
    }
}

- (UIImage *)scaledImageForKey:(NSString *)key image:(UIImage *)image {
    return SDScaledImageForKey(key, image);
}
/**
 *  查询磁盘缓存获取图片。返回一个操作来完成
 *
 *  @param key       key
 *  @param doneBlock 回调block
 *
 *  @return 返回一个操作。这个操作完成对图片的具体获取
 */
- (NSOperation *)queryDiskCacheForKey:(NSString *)key done:(SDWebImageQueryCompletedBlock)doneBlock {
    if (!doneBlock) {
        return nil;
    }

    if (!key) {
        doneBlock(nil, SDImageCacheTypeNone);
        return nil;
    }

    // First check the in-memory cache...
    //内存缓存查询
    UIImage *image = [self imageFromMemoryCacheForKey:key];
    if (image) {
        doneBlock(image, SDImageCacheTypeMemory);
        return nil;
    }
    //新建一个操作
    NSOperation *operation = [NSOperation new];
    dispatch_async(self.ioQueue, ^{
        if (operation.isCancelled) {
            return;
        }

        @autoreleasepool {
            UIImage *diskImage = [self diskImageForKey:key];
            if (diskImage && self.shouldCacheImagesInMemory) {
                NSUInteger cost = SDCacheCostForImage(diskImage);
                //把图片数据存入内存缓存中
                [self.memCache setObject:diskImage forKey:key cost:cost];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                doneBlock(diskImage, SDImageCacheTypeDisk);
            });
        }
    });

    return operation;
}

- (void)removeImageForKey:(NSString *)key {
    [self removeImageForKey:key withCompletion:nil];
}

- (void)removeImageForKey:(NSString *)key withCompletion:(SDWebImageNoParamsBlock)completion {
    [self removeImageForKey:key fromDisk:YES withCompletion:completion];
}

- (void)removeImageForKey:(NSString *)key fromDisk:(BOOL)fromDisk {
    [self removeImageForKey:key fromDisk:fromDisk withCompletion:nil];
}

- (void)removeImageForKey:(NSString *)key fromDisk:(BOOL)fromDisk withCompletion:(SDWebImageNoParamsBlock)completion {
    
    if (key == nil) {
        return;
    }

    if (self.shouldCacheImagesInMemory) {
        [self.memCache removeObjectForKey:key];
    }

    if (fromDisk) {
        dispatch_async(self.ioQueue, ^{
            [_fileManager removeItemAtPath:[self defaultCachePathForKey:key] error:nil];
            
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion();
                });
            }
        });
    } else if (completion){
        completion();
    }
    
}

- (void)setMaxMemoryCost:(NSUInteger)maxMemoryCost {
    self.memCache.totalCostLimit = maxMemoryCost;
}

- (NSUInteger)maxMemoryCost {
    return self.memCache.totalCostLimit;
}

- (NSUInteger)maxMemoryCountLimit {
    return self.memCache.countLimit;
}

- (void)setMaxMemoryCountLimit:(NSUInteger)maxCountLimit {
    self.memCache.countLimit = maxCountLimit;
}

- (void)clearMemory {
    [self.memCache removeAllObjects];
}

- (void)clearDisk {
    [self clearDiskOnCompletion:nil];
}

- (void)clearDiskOnCompletion:(SDWebImageNoParamsBlock)completion
{
    dispatch_async(self.ioQueue, ^{
        [_fileManager removeItemAtPath:self.diskCachePath error:nil];
        [_fileManager createDirectoryAtPath:self.diskCachePath
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:NULL];

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    });
}

- (void)cleanDisk {
    [self cleanDiskWithCompletionBlock:nil];
}
/**
 *  清楚图片缓存
 *在程序退出或者进入后台时，会出图片文件进行管理，具体的策略：
 
 清除过期的文件，默认一星期
 如果设置了最大缓存，并且当前缓存的文件超过了这个限制，则删除最旧的文件，直到当前缓存文件的大小为最大缓存大小的一半

 *  @param completionBlock 清理完成以后的回调
 */
- (void)cleanDiskWithCompletionBlock:(SDWebImageNoParamsBlock)completionBlock {
    dispatch_async(self.ioQueue, ^{
        NSURL *diskCacheURL = [NSURL fileURLWithPath:self.diskCachePath isDirectory:YES];
        NSArray *resourceKeys = @[NSURLIsDirectoryKey, NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey];

        // This enumerator prefetches useful properties for our cache files.
        NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtURL:diskCacheURL
                                                   includingPropertiesForKeys:resourceKeys
                                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                 errorHandler:NULL];

        NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-self.maxCacheAge];
        NSMutableDictionary *cacheFiles = [NSMutableDictionary dictionary];
        NSUInteger currentCacheSize = 0;

        // Enumerate all of the files in the cache directory.  This loop has two purposes:
        //
        //  1. Removing files that are older than the expiration date.
        //  2. Storing file attributes for the size-based cleanup pass.
        NSMutableArray *urlsToDelete = [[NSMutableArray alloc] init];
        for (NSURL *fileURL in fileEnumerator) {
            NSDictionary *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:NULL];

            // Skip directories.
            if ([resourceValues[NSURLIsDirectoryKey] boolValue]) {
                continue;
            }

            // Remove files that are older than the expiration date;
            NSDate *modificationDate = resourceValues[NSURLContentModificationDateKey];
            if ([[modificationDate laterDate:expirationDate] isEqualToDate:expirationDate]) {
                [urlsToDelete addObject:fileURL];
                continue;
            }

            // Store a reference to this file and account for its total size.
            NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
            currentCacheSize += [totalAllocatedSize unsignedIntegerValue];
            [cacheFiles setObject:resourceValues forKey:fileURL];
        }
        
        for (NSURL *fileURL in urlsToDelete) {
            [_fileManager removeItemAtURL:fileURL error:nil];
        }

        // If our remaining disk cache exceeds a configured maximum size, perform a second
        // size-based cleanup pass.  We delete the oldest files first.
        if (self.maxCacheSize > 0 && currentCacheSize > self.maxCacheSize) {
            // Target half of our maximum cache size for this cleanup pass.
            const NSUInteger desiredCacheSize = self.maxCacheSize / 2;

            // Sort the remaining cache files by their last modification time (oldest first).
            NSArray *sortedFiles = [cacheFiles keysSortedByValueWithOptions:NSSortConcurrent
                                                            usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                                return [obj1[NSURLContentModificationDateKey] compare:obj2[NSURLContentModificationDateKey]];
                                                            }];

            // Delete files until we fall below our desired cache size.
            for (NSURL *fileURL in sortedFiles) {
                if ([_fileManager removeItemAtURL:fileURL error:nil]) {
                    NSDictionary *resourceValues = cacheFiles[fileURL];
                    NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
                    currentCacheSize -= [totalAllocatedSize unsignedIntegerValue];

                    if (currentCacheSize < desiredCacheSize) {
                        break;
                    }
                }
            }
        }
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock();
            });
        }
    });
}
/**
 *  后台清理磁盘操作
 */
- (void)backgroundCleanDisk {
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    if(!UIApplicationClass || ![UIApplicationClass respondsToSelector:@selector(sharedApplication)]) {
        return;
    }
    UIApplication *application = [UIApplication performSelector:@selector(sharedApplication)];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        // Clean up any unfinished task business by marking where you
        // stopped or ending the task outright.
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];

    // Start the long-running task and return immediately.
    [self cleanDiskWithCompletionBlock:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}

- (NSUInteger)getSize {
    __block NSUInteger size = 0;
    dispatch_sync(self.ioQueue, ^{
        NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtPath:self.diskCachePath];
        for (NSString *fileName in fileEnumerator) {
            NSString *filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
            NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
            size += [attrs fileSize];
        }
    });
    return size;
}

- (NSUInteger)getDiskCount {
    __block NSUInteger count = 0;
    dispatch_sync(self.ioQueue, ^{
        NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtPath:self.diskCachePath];
        count = [[fileEnumerator allObjects] count];
    });
    return count;
}
/**
 *  计算目录的大小
 *
 *  @param completionBlock 回调
 */
- (void)calculateSizeWithCompletionBlock:(SDWebImageCalculateSizeBlock)completionBlock {
    NSURL *diskCacheURL = [NSURL fileURLWithPath:self.diskCachePath isDirectory:YES];

    dispatch_async(self.ioQueue, ^{
        NSUInteger fileCount = 0;
        NSUInteger totalSize = 0;

        NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtURL:diskCacheURL
                                                   includingPropertiesForKeys:@[NSFileSize]
                                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                 errorHandler:NULL];

        for (NSURL *fileURL in fileEnumerator) {
            NSNumber *fileSize;
            [fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
            totalSize += [fileSize unsignedIntegerValue];
            fileCount += 1;
        }

        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(fileCount, totalSize);
            });
        }
    });
}

@end

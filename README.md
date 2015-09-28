
##学习博客地址列表：

[我自己实现SDWebImage基本功能的demo](https://github.com/huang303513/GCD-OperationQueue-Exploration/tree/master/HCDWebImage)

[SDWebImage源码分析--加载gif图片](http://www.bubuko.com/infodetail-633704.html)

[SDWebImage源码解析之SDWebImageManager的注解](http://www.jianshu.com/p/6ae6f99b6c4c)


[SDWebImage源码解析之SDWebImageManager的注解(2)](http://www.jianshu.com/p/0f9a7296f4c0)

##结构说明：
`UIImageView+WebCache.h`通过`SDWebImageManager`单列来管理图片的加载和回调。

`SDWebImageManager`通过拥有一个`SDImageCache`和`SDWebImageDownloader`来实现图片的缓存和下载器功能。`SDImageCache`主要实现缓存功能。`SDWebImageDownloader`主要实现下载功能和下载回调。




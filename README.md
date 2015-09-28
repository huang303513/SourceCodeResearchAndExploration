
##学习博客地址列表,仓库中的部分代码带中文注释持续学习中，待会儿活干完了继续学习：

[我自己实现SDWebImage基本功能的demo](https://github.com/huang303513/GCD-OperationQueue-Exploration/tree/master/HCDWebImage)

[SDWebImage源码分析--加载gif图片](http://www.bubuko.com/infodetail-633704.html)

[图片处理：Image I/O 学习笔记](http://www.jianshu.com/p/4dcd6e4bdbf0)

[SDWebImage源码解析之SDWebImageManager的注解](http://www.jianshu.com/p/6ae6f99b6c4c)


[SDWebImage源码解析之SDWebImageManager的注解(2)](http://www.jianshu.com/p/0f9a7296f4c0)

[SDWebImage源码学习-One](http://www.jianshu.com/p/b18de01e0cc8)

[SDWebImage源码剖析（－)](http://www.jianshu.com/p/c07df06c60be)

[SDWebImage源码剖析（二)](http://www.jianshu.com/p/d401ec7626eb)


##结构说明：
`UIImageView+WebCache.h`通过`SDWebImageManager`单列来管理图片的加载、缓存和回调。主要的入口类。

`SDWebImageManager`通过拥有一个`SDImageCache`和`SDWebImageDownloader`来实现图片的缓存和下载器功能。这个类应该是框架的核心和枢纽功能的类。`SDWebImageManager`是一个单列

`UIImage+GIF`主要实现了对gif图片的加载功能。

`SDWebImageDecoder`主要实现图片的解压缩功能，从网络上下载的图片首先需要解压缩以后才能正常显示。这个类专门处理这个工作。

`SDImageCache`管理着SDWebImage的缓存，其中内存缓存采用NSCache，同时会创建一个ioQueue负责对硬盘的读写，并且会添加观察者，在收到内存警告、关闭或进入后台时完成对应的处理。同时在后台完成磁盘文件的清理、创建等工作。

`SDWebImageDownloader`主要实现下载功能和下载回调。他通过自定义的操作`SDWebImageDownloaderOperation`来处理具体的下载。并且管理操作之间的依赖关系为LIFO(后进先出)。这个类是单列。

`SDWebImageDownloaderOperation`是自定义的并发队列，最直接的负责图片的下载。通过NSURLConnection接口来实现。实现`SDWebImageOperation`来处理取消下载操作。在下载过程中会发送四个通知用于表示开始下载、停止下载、接收到数据、下载完成。

`NSData+ImageContentType`用于得到图片数据的具体类型。

##总结

###接口设计简单

通常我们使用较多的UIImageView分类：

[self.imageView sd_setImageWithURL:[NSURL URLWithString:@"url"]
placeholderImage:[UIImage imageNamed:@"placeholder"]];

一个简单的接口将其中复杂的实现细节全部隐藏：简单就是美。
采用NSCache作为内存缓

耗时较长的请求，都采用异步形式，在回调函数块中处理请求结果

NSOperation和NSOperationQueue：可以取消任务处理队列中的任务，设置最大并发数，设置operation之间的依赖关系。

图片缓存清理的策略

dispatch_barrier_sync：前面的任务执行结束后它才执行，而且它后面的任务要等它执行完成之后才会执行。

使用weak self strong self 防止retain circle

如果子线程进需要不断处理一些事件，那么设置一个Run Loop是最好的处理方式



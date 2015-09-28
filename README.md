
##学习博客地址列表,仓库中的部分代码带中文注释持续学习中，待会儿活干完了继续学习：

[我自己实现SDWebImage基本功能的demo](https://github.com/huang303513/GCD-OperationQueue-Exploration/tree/master/HCDWebImage)

[SDWebImage源码分析--加载gif图片](http://www.bubuko.com/infodetail-633704.html)

[图片处理：Image I/O 学习笔记](http://www.jianshu.com/p/4dcd6e4bdbf0)

[SDWebImage源码解析之SDWebImageManager的注解](http://www.jianshu.com/p/6ae6f99b6c4c)


[SDWebImage源码解析之SDWebImageManager的注解(2)](http://www.jianshu.com/p/0f9a7296f4c0)

[SDWebImage源码学习-One](http://www.jianshu.com/p/b18de01e0cc8)

##结构说明：
`UIImageView+WebCache.h`通过`SDWebImageManager`单列来管理图片的加载、缓存和回调。主要的入口类。

`SDWebImageManager`通过拥有一个`SDImageCache`和`SDWebImageDownloader`来实现图片的缓存和下载器功能。这个类应该是框架的核心和枢纽功能的类。

//=================其他一些文件的职责==================

`UIImage+GIF`主要实现了对gif图片的加载功能。


`SDWebImageDecoder`主要实现图片的解压缩功能，从网络上下载的图片首先需要解压缩以后才能正常显示。这个类专门处理这个工作。

`SDImageCache`主要实现缓存功能。

`SDWebImageDownloader`主要实现下载功能和下载回调。




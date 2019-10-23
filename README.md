# iOS中的各种锁
多线程编程中，应该尽量避免资源在线程之间共享，以减少线程间的相互作用。
## 锁是线程编程同步工具的基础。iOS开发中常用的锁有如下几种：
 1. @synchronized
 2. NSLock 对象锁
 3. NSRecursiveLock 递归锁
 4. NSConditionLock 条件锁
 5. pthread_mutex 互斥锁（C语言）
 6. dispatch_semaphore 信号量实现加锁（GCD）
 7. OSSpinLock （暂不建议使用，原因参见[这里](https://blog.ibireme.com/2016/01/16/spinlock_is_unsafe_in_ios/)）

## 性能对比:
 
![](https://upload-images.jianshu.io/upload_images/1457495-4151d1dc7f68827e.jpg?imageMogr2/auto-orient/strip|imageView2/2/format/webp)
 

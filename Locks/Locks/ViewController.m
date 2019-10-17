//
//  ViewController.m
//  ThreadTest
//
//  Created by fangyp on 2019/10/17.
//  Copyright © 2019 fangyp. All rights reserved.
//

#import "ViewController.h"
#include <pthread.h>
@interface ViewController ()

@property (nonatomic,assign) NSInteger tickets; // 飘的数量

@property (nonatomic,strong) dispatch_queue_t concurrentQueue; // 队列

@property (nonatomic,strong) NSLock *mutexLock; //互斥锁

@property (nonatomic,strong) NSRecursiveLock * rsLock; //递归锁

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    /*
     * 自定义队列(并行):
     * 并行队列 + 异步任务 = 多条新线程
     */
    self.concurrentQueue = dispatch_queue_create("test.q", DISPATCH_QUEUE_CONCURRENT);
}
/*
 * @synchronized 关键字加锁 互斥锁，性能较差不推荐使用
 */
- (IBAction)synchronizedAction:(UIButton *)sender {
    
    _tickets = 5;
    dispatch_async(self.concurrentQueue, ^{
        [self saleTicketsUseSynchronized];
    });
    
    dispatch_async(self.concurrentQueue, ^{
        [self saleTicketsUseSynchronized];
    });
}


/*
 * @synchronized(这里添加一个OC对象，一般使用self) {
 * 这里写要加锁的代码
 * }
 * 1.加锁的代码尽量少
 * 2.添加的OC对象必须在多个线程中都是同一对象
 * 3.优点是不需要显式的创建锁对象，便可以实现锁的机制。
 * 4@synchronized块会隐式的添加一个异常处理例程来保护代码，该处理例程会在异常抛出的时候自动的释放互斥锁。所以如果不想让隐式的异常处理例程带来额外的开销，你可以考虑使用锁对象。
 */

- (void) saleTicketsUseSynchronized {
    
    while (1) {
        [NSThread sleepForTimeInterval:1];
        @synchronized(self) {
            if (_tickets > 0) {
                _tickets--;
                NSLog(@"剩余票数= %ld, Thread:%@",_tickets,[NSThread currentThread]);
            } else {
                NSLog(@"票卖完了  Thread:%@",[NSThread currentThread]);
                break;
            }
        }
    }
}
/*
 * NSLock 互斥锁 不能多次调用 lock方法,会造成死锁
 */
- (IBAction)lockAction:(UIButton *)sender {
    
    _tickets = 5;
    
    _mutexLock = [[NSLock alloc] init];
    
    dispatch_async(self.concurrentQueue, ^{
        [self saleTicketsUseNSLock];
    });
    
    dispatch_async(self.concurrentQueue, ^{
        [self saleTicketsUseNSLock];
    });
}
/*
 * 在Cocoa程序中NSLock中实现了一个简单的互斥锁。
 * 所有锁（包括NSLock）的接口实际上都是通过NSLocking协议定义的，它定义了lock和unlock方法。你使用这些方法来获取和释放该锁。
 * NSLock类还增加了tryLock和lockBeforeDate:方法。
 * tryLock试图获取一个锁，但是如果锁不可用的时候，它不会阻塞线程，相反，它只是返回NO。
 * lockBeforeDate:方法试图获取一个锁，但是如果锁没有在规定的时间内被获得，它会让线程从阻塞状态变为非阻塞状态（或者返回NO）
 */
- (void) saleTicketsUseNSLock {
    
    while (1) {
        [NSThread sleepForTimeInterval:1];
        
        [_mutexLock lock];
        if (_tickets > 0) {
            _tickets--;
            NSLog(@"剩余票数= %ld, Thread:%@",_tickets,[NSThread currentThread]);
        } else {
            NSLog(@"票卖完了  Thread:%@",[NSThread currentThread]);
            break;
        }
        
        [_mutexLock unlock];
    }
}
/*
 * NSRecursiveLock 递归锁
 */
- (IBAction)recursiveLockAction:(UIButton *)sender {
    
    /*
     * NSLock 递归或循环中造成死锁
     * 递归block中，锁会被多次的lock，所以自己也被阻塞
     */
    //    _mutexLock = [[NSLock alloc]init];
    
    /*
     * 此处将NSLock换成NSRecursiveLock，便可解决问题。
     * NSRecursiveLock类定义的锁可以在同一线程多次lock，而不会造成死锁。
     * 递归锁会跟踪它被多少次lock。每次成功的lock都必须平衡调用unlock操作。
     * 只有所有的锁住和解锁操作都平衡的时候，锁才真正被释放给其他线程获得。
     */
    _rsLock = [[NSRecursiveLock alloc] init];
    
    // 线程1
    dispatch_async(self.concurrentQueue, ^{
        static void(^TestMethod)(int);
        TestMethod = ^(int value)
        {
            NSLog(@"加锁 value = %d",value);
            //            [self->_mutexLock lock];
            [self->_rsLock lock];
            if (value > 0)
            {
                [NSThread sleepForTimeInterval:1];
                TestMethod(--value);
            }
            NSLog(@"解锁");
            //            [self->_mutexLock unlock];
            [self->_rsLock unlock];
        };
        
        TestMethod(5);
    });
}

/*
 * NSConditionLock 条件锁
 * 在线程1中的加锁使用了lock，是不需要条件的，所以顺利的就锁住了。
 * unlockWithCondition:在开锁的同时设置了一个整型的条件 2 。
 * 线程2则需要一把被标识为2的钥匙，所以当线程1循环到 i = 2 时，线程2的任务才执行。
 * NSConditionLock也跟其它的锁一样，是需要lock与unlock对应的，只是lock,lockWhenCondition:与unlock，unlockWithCondition:是可以随意组合的，当然这是与你的需求相关的。
 */
- (IBAction)conditionLockAction:(UIButton *)sender {
    
    NSConditionLock *conditionLock = [[NSConditionLock alloc] init];
    
    //线程1
    dispatch_async(self.concurrentQueue, ^{
        for (int i=0;i<=3;i++) {
            [conditionLock lock];
            NSLog(@"thread1:%d",i);
            sleep(1);
            [conditionLock unlockWithCondition:2];
        }
    });
    
    //线程2
    dispatch_async(self.concurrentQueue, ^{
        [conditionLock lockWhenCondition:2];
        NSLog(@"thread2");
        [conditionLock unlock];
    });
}

/*
 * pthread_mutex 互斥锁
 */
- (IBAction)pthread_mutextAction:(id)sender {
    
    __block pthread_mutex_t mutex;
    pthread_mutex_init(&mutex, NULL);
    
    dispatch_async(self.concurrentQueue, ^{
        pthread_mutex_lock(&mutex);
        NSLog(@"任务1");
        sleep(2);
        pthread_mutex_unlock(&mutex);
    });
    
    dispatch_async(self.concurrentQueue, ^{
        sleep(1);
        pthread_mutex_lock(&mutex);
        NSLog(@"任务2");
        pthread_mutex_unlock(&mutex);
    });
}
/*
 * dispatch_semaphore 信号量
 */
- (IBAction)dispatch_semaphoreAction:(id)sender {
    
    // 信号量
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"任务1");
        sleep(10);
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"任务2");
        dispatch_semaphore_signal(semaphore);
    });
}
/*
 * OSSpinLock
 */
- (IBAction)OSSpinLockAction:(id)sender {
    NSLog(@"dispatch_semaphore or pthread_mutex 替代");
}
@end

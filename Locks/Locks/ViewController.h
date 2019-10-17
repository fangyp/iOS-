//
//  ViewController.h
//  ThreadTest
//
//  Created by fangyp on 2019/10/17.
//  Copyright © 2019 fangyp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

/*
 * synchronized 关键字加锁 互斥锁
 */
- (IBAction)synchronizedAction:(UIButton *)sender;
/*
 * NSLock 互斥锁
 */
- (IBAction)lockAction:(UIButton *)sender;
/*
 * NSRecursiveLock 递归锁
 */
- (IBAction)recursiveLockAction:(UIButton *)sender;
/*
 * NSConditionLock 条件锁
 */
- (IBAction)conditionLockAction:(UIButton *)sender;

/*
 * pthread_mutex 互斥锁
 */
- (IBAction)pthread_mutextAction:(id)sender;
/*
 * dispatch_semaphore 信号量
 */
- (IBAction)dispatch_semaphoreAction:(id)sender;
/*
 * OSSpinLock
 */
- (IBAction)OSSpinLockAction:(id)sender;

@end


//
//  LGExceptionHandle.m
//  Crash分析
//
//  Created by cooci on 2019/5/31.
//  Copyright © 2019 lgcooci. All rights reserved.
//

#import "LGUncaughtExceptionHandle.h"
#import <SCLAlertView.h>
#import <UIKit/UIKit.h>
#include <libkern/OSAtomic.h>
#include <execinfo.h>
#include <stdatomic.h>


NSString * const LGUncaughtExceptionHandlerSignalExceptionName = @"LGUncaughtExceptionHandlerSignalExceptionName";
NSString * const LGUncaughtExceptionHandlerSignalExceptionReason = @"LGUncaughtExceptionHandlerSignalExceptionReason";
NSString * const LGUncaughtExceptionHandlerSignalKey = @"LGUncaughtExceptionHandlerSignalKey";
NSString * const LGUncaughtExceptionHandlerAddressesKey = @"LGUncaughtExceptionHandlerAddressesKey";
NSString * const LGUncaughtExceptionHandlerFileKey = @"LGUncaughtExceptionHandlerFileKey";
NSString * const LGUncaughtExceptionHandlerCallStackSymbolsKey = @"LGUncaughtExceptionHandlerCallStackSymbolsKey";


atomic_int      LGUncaughtExceptionCount = 0;
const int32_t   LGUncaughtExceptionMaximum = 8;
const NSInteger LGUncaughtExceptionHandlerSkipAddressCount = 4;
const NSInteger LGUncaughtExceptionHandlerReportAddressCount = 5;


@implementation LGUncaughtExceptionHandle

// 注册
+ (void)installUncaughtSignalExceptionHandler{

    NSSetUncaughtExceptionHandler(&LGExceptionHandlers);
}

/// Exception
void LGExceptionHandlers(NSException *exception) {
    NSLog(@"%s",__func__);
    
    int32_t exceptionCount = atomic_fetch_add_explicit(&LGUncaughtExceptionCount,1,memory_order_relaxed);
    if (exceptionCount > LGUncaughtExceptionMaximum) {
        return;
    }
    // 获取堆栈信息 - model 编程思想
    NSArray *callStack = [LGUncaughtExceptionHandle lg_backtrace];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
    [userInfo setObject:exception.name forKey:LGUncaughtExceptionHandlerSignalExceptionName];
    [userInfo setObject:exception.reason forKey:LGUncaughtExceptionHandlerSignalExceptionReason];
    [userInfo setObject:callStack forKey:LGUncaughtExceptionHandlerAddressesKey];
    [userInfo setObject:exception.callStackSymbols forKey:LGUncaughtExceptionHandlerCallStackSymbolsKey];
    [userInfo setObject:@"LGException" forKey:LGUncaughtExceptionHandlerFileKey];
    
    
    // 抛出异常 执行函数
    [[[LGUncaughtExceptionHandle alloc] init]
     performSelectorOnMainThread:@selector(lg_handleException:)
     withObject:
     [NSException
      exceptionWithName:[exception name]
      reason:[exception reason]
      userInfo:userInfo]
     waitUntilDone:YES];
}


- (void)lg_handleException:(NSException *)exception{
    //保存上传服务器 - crash -- > 后台
    // 不想 崩溃   -- runloop
    // items --> model --- > runloop
    //runloop ： 检测卡顿 --- 切换 mode
    //GCD -- runloop --- 超时
//    timer 不如 gcd
//    切换mode 会卡顿，导致计时不准确
//    GCD 和 runloop 属于平级 ，不会直接依耐于整个runloop
   
    CFRunLoopRef runloop = CFRunLoopGetCurrent();
    // 获取事务(item) - runloop 转圈 - mode
    CFArrayRef allmodes  = CFRunLoopCopyAllModes(runloop);

    NSDictionary *userinfo = [exception userInfo];
    NSLog(@">>>>> %@", userinfo);
    [self saveCrash:exception file:[userinfo objectForKey:LGUncaughtExceptionHandlerFileKey]];
    
    SCLAlertView *alert = [[SCLAlertView alloc] initWithNewWindowWidth:300.f];
    [alert addButton:@"奔溃" actionBlock:^{
        self.dismissed = YES;
    }];
    
    [alert showSuccess:exception.name subTitle:exception.reason closeButtonTitle:nil duration:0.0f];
    
    // 保证长须不崩溃
    while (!self.dismissed) {
        for (NSString *mode in (__bridge NSArray *)allmodes) {
            CFRunLoopRunInMode((CFStringRef)mode, 0.001, false);
        }
    }
    CFRelease(allmodes);
    
}

/// 保存奔溃信息或者上传
- (void)saveCrash:(NSException *)exception file:(NSString *)file{
    
    NSArray *stackArray = [[exception userInfo] objectForKey:LGUncaughtExceptionHandlerCallStackSymbolsKey];// 异常的堆栈信息
    NSString *reason = [exception reason];// 出现异常的原因
    NSString *name = [exception name];// 异常名称
    
    // 或者直接用代码，输入这个崩溃信息，以便在console中进一步分析错误原因
    // NSLog(@"crash: %@", exception);
    
    NSString * _libPath  = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:file];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:_libPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:_libPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSDate *dat = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval a=[dat timeIntervalSince1970];
    NSString *timeString = [NSString stringWithFormat:@"%f", a];
    
    NSString * savePath = [_libPath stringByAppendingFormat:@"/error%@.log",timeString];
    
    NSString *exceptionInfo = [NSString stringWithFormat:@"Exception reason：%@\nException name：%@\nException stack：%@",name, reason, stackArray];
    
    BOOL sucess = [exceptionInfo writeToFile:savePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    NSLog(@"保存崩溃日志 sucess:%d,%@",sucess,savePath);
    
}

/// 获取函数堆栈信息
+ (NSArray *)lg_backtrace{
    
    void* callstack[128];
    int frames = backtrace(callstack, 128);//用于获取当前线程的函数调用堆栈，返回实际获取的指针个数
    char **strs = backtrace_symbols(callstack, frames);//从backtrace函数获取的信息转化为一个字符串数组
    int i;
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (i = LGUncaughtExceptionHandlerSkipAddressCount;
         i < LGUncaughtExceptionHandlerSkipAddressCount+LGUncaughtExceptionHandlerReportAddressCount;
         i++)
    {
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
    return backtrace;
}



@end

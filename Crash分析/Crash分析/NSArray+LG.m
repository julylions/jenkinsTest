//
//  NSArray+LG.m
//  Crash分析
//
//  Created by Cooci on 2020/3/17.
//  Copyright © 2020 lgcooci. All rights reserved.
//

#import "NSArray+LG.h"
#import <objc/message.h>
@implementation NSArray (LG)

//+ (void)load{
//    // 性能
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        
//        Method m1 = class_getInstanceMethod(objc_getClass("__NSArrayI"), @selector(objectAtIndex:));
//        Method m2 = class_getInstanceMethod(objc_getClass("__NSArrayI"), @selector(lg_objectAtIndex:));
//        method_exchangeImplementations(m1, m2);
//    });
//}
//
//- (id)lg_objectAtIndex:(NSUInteger)index{
//    if (index > self.count-1) {
//        NSLog(@"老弟 越界");
//        return nil;
//    }
//    return [self lg_objectAtIndex:index];
//}

@end

//
//  LGUncaughtExceptionHandle.h
//  Crash分析
//
//  Created by cooci on 2019/5/31.
//  Copyright © 2019 lgcooci. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LGUncaughtExceptionHandle : NSObject

@property (nonatomic) BOOL dismissed;

+ (void)installUncaughtSignalExceptionHandler;

@end

NS_ASSUME_NONNULL_END

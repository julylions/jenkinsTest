//
//  ViewController.m
//  Crash分析
//
//  Created by cooci on 2019/5/31.
//  Copyright © 2019 lgcooci. All rights reserved.
//

#import "ViewController.h"
#import "LGUncaughtExceptionHandle.h"
#import <UIImage+ImageEffects.h>

@interface ViewController ()
@property (nonatomic, strong) NSArray *dataArray;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataArray = @[@"逻辑教育-iOS底层大师班",@"Swift底层进阶",@"Flutter高级",@"视觉全训班"];
    
    
    UIImageView *IV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 250, self.view.frame.size.width, 500)];
    
    UIImage *image = [UIImage imageNamed:@"iPhone8"];
    
    
    IV.image = [image applyTintEffectWithColor:[UIColor cyanColor]];;
    
//    - (UIImage *)applyLightEffect;
//    - (UIImage *)applyExtraLightEffect;
//    - (UIImage *)applyDarkEffect;
    
    
    [self.view addSubview:IV];
    
}

// 容错 - 自己的方法 - 切片 (自由)
// 想到其他东西 - 3-5-6
// aop
// 收集

// 强制更新 - 热更新
// runloop -
// 平行空间
// 卡顿 - 小事务 -
// 异步渲染
// 666
// 牛逼 - 6-7K

- (IBAction)exceptionAction:(id)sender {
    NSLog(@"%@",[self.dataArray objectAtIndex:5]);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (int i = 0; i<1000; i++) {
            NSString *str = [NSString stringWithFormat:@"cooci_和谐学习不急不躁"];
        }
    });
}
@end

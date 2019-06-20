//
//  ViewController.h
//  cymscanning
//
//  Created by 常永梅 on 2019/3/27.
//  Copyright © 2019 常永梅. All rights reserved.
//
/* 关于二维码扫描功能的相关配置：
 * plist文件里面添加 “Privacy - Camera Usage Description” 格式是string，后面填写 “扫描获取二维码信息，需要使用摄像头”
 *
 */

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
{
    NSString *stringValue; // 扫描结果信息
}

@end


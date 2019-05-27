//
//  ViewController.m
//  cymscanning
//
//  Created by 常永梅 on 2019/3/27.
//  Copyright © 2019 常永梅. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
///
#define kScreenWidth ([UIScreen mainScreen].bounds.size.width) // 当前视图的宽度
#define kScreenHeight ([UIScreen mainScreen].bounds.size.height) // 当前视图的高度
#define kNavigationHeight ([[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height) // 状态栏+导航栏
#define kStatusBarHeight ([[UIApplication sharedApplication] statusBarFrame].size.height) //状态栏高度
#define kNavBarHight (self.navigationController.navigationBar.frame.size.height) //导航栏高度
///
#define kScreenScale ([UIScreen mainScreen].scale)
#define kScaleWidth (kScreenScale*kScreenWidth) // 分辨率  W
#define kScaleHeight (kScreenScale*kScreenHeight) // 分辨率 H
///
#define SWidth kScreenWidth - 113
#define Sx 56.5
#define Sy 140

@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate>
{
    int num;
    BOOL upOrdown;
    NSTimer * timer;
     UIImageView * imageView;
}
@property (strong,nonatomic)AVCaptureDevice * device; //获取设备
@property (strong,nonatomic)AVCaptureDeviceInput * input; // 输入流
@property (strong,nonatomic)AVCaptureMetadataOutput * output; // 输出流
@property (strong,nonatomic)AVCaptureSession * session; // 扫描标记
@property (strong,nonatomic)AVCaptureVideoPreviewLayer * preview; // 可识别绘制
@property (nonatomic, retain) UIImageView * line; // 横线

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
-(void)viewWillAppear:(BOOL)animated{
    [self initUIScanLine]; // 页面UI绘制
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [timer setFireDate:[NSDate distantFuture]]; // 关闭定时器
    [_session stopRunning];  // 扫描识别停止
    [self removeSuperLayer]; // 删除
}
#pragma mark -
-(void)initUIScanLine{
    imageView = [[UIImageView alloc]initWithFrame:CGRectMake(Sx,kNavigationHeight+Sy,SWidth,SWidth)];
    imageView.image = [UIImage imageNamed:@"scanscanBg.png"];
    [self.view addSubview:imageView];
    
    upOrdown = NO;
    num =0;
    _line = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMinX(imageView.frame)+5, CGRectGetMinY(imageView.frame)+5, SWidth-10,1)];
    _line.image = [UIImage imageNamed:@"scanLine"];
    [self.view addSubview:_line];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:.02 target:self selector:@selector(timerAnimation) userInfo:nil repeats:YES];
    
    [self setupCamera];
    
    UIView *navview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kNavigationHeight)];
    [self.view addSubview:navview];
    
    UILabel *labTitle= [[UILabel alloc] initWithFrame:CGRectMake((kScreenWidth-100)/2, kStatusBarHeight, 100, 44)];
    labTitle.textAlignment = NSTextAlignmentCenter;
    labTitle.font = [UIFont systemFontOfSize:18];
    labTitle.textColor = [UIColor blackColor];
    labTitle.text  = @"扫一扫";
    [navview addSubview:labTitle];
    
    UILabel * labIntroudction= [[UILabel alloc] initWithFrame:CGRectMake(0,navview.frame.origin.y+navview.frame.size.height+20, kScreenWidth, 50)];
    labIntroudction.backgroundColor = [UIColor clearColor];
    labIntroudction.numberOfLines=2;
    labIntroudction.textColor=[UIColor whiteColor];
    labIntroudction.text=@"将取景框对准二维码\n即可自动扫描";
    labIntroudction.font = [UIFont systemFontOfSize:14];
    labIntroudction.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:labIntroudction];
}

-(void)setupCamera{
    // Input 创建输入流
    _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    
    // Output 创建输出流
    _output = [[AVCaptureMetadataOutput alloc]init];
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    _output.rectOfInterest =[self rectOfInterestByScanViewRect:imageView.frame];//CGRectMake(0.1, 0, 0.9, 1);// 识别区域 这个值是按比例0~1设置，而且X、Y要调换位置，width、height调换位置
    
    // Session 初始化链接对象
    _session = [[AVCaptureSession alloc]init];
    [_session setSessionPreset:AVCaptureSessionPresetHigh]; // 高质量采集率
    if ([_session canAddInput:self.input])
    {
        [_session addInput:self.input];
    }
    
    if ([_session canAddOutput:self.output])
    {
        [_session addOutput:self.output];
    }
    
    // 支持 二维码 和 条码类型 AVMetadataObjectTypeQRCode
    _output.metadataObjectTypes =@[AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeQRCode];
    
    // Preview
    _preview =[AVCaptureVideoPreviewLayer layerWithSession:self.session];
    _preview.videoGravity = AVLayerVideoGravityResize;
    _preview.frame =self.view.bounds;
    [self.view.layer insertSublayer:self.preview atIndex:0];
    [self.view bringSubviewToFront:imageView];
    
    [self setOverView];
    
    // Start
    [_session startRunning];
}
-(void)timerAnimation{
    if (upOrdown == NO) {
        num ++;
        _line.frame = CGRectMake(CGRectGetMinX(imageView.frame)+5, CGRectGetMinY(imageView.frame)+5+2*num, SWidth-10,1);
        
        if (num ==(int)(( SWidth-10)/2)) {
            upOrdown = YES;
        }
    }
    else {
        num --;
        _line.frame =CGRectMake(CGRectGetMinX(imageView.frame)+5, CGRectGetMinY(imageView.frame)+5+2*num, SWidth-10,1);
        
        if (num == 0) {
            upOrdown = NO;
        }
    }
}
#pragma mark - self
- (CGRect)rectOfInterestByScanViewRect:(CGRect)rect {
    CGFloat width = CGRectGetWidth(self.view.frame);
    CGFloat height = CGRectGetHeight(self.view.frame);
    
    CGFloat x = (height - CGRectGetHeight(rect)) / 2 / height;
    CGFloat y = (width - CGRectGetWidth(rect)) / 2 / width;
    
    return CGRectMake(x, y, (CGRectGetHeight(rect))/height, (CGRectGetWidth(rect))/width);
}

#pragma mark - 添加模糊效果
- (void)setOverView {
    CGFloat width = CGRectGetWidth(self.view.frame);
    CGFloat height = CGRectGetHeight(self.view.frame);
    
    CGFloat x = CGRectGetMinX(imageView.frame);
    CGFloat y = CGRectGetMinY(imageView.frame);
    CGFloat w = CGRectGetWidth(imageView.frame);
    CGFloat h = CGRectGetHeight(imageView.frame);
    
    [self creatView:CGRectMake(0, 0, width, y)]; // 上
    [self creatView:CGRectMake(0, y, x, h)];     // 左
    [self creatView:CGRectMake(0, y + h, width, height - y - h)]; // 下
    [self creatView:CGRectMake(x + w, y, width - x - w, h)];  // 右
}

- (void)creatView:(CGRect)rect {
    CGFloat alpha = 0.48;
    UIView *view = [[UIView alloc] initWithFrame:rect];
    view.backgroundColor = [UIColor blackColor];
    view.alpha = alpha;
    [self.view addSubview:view];
}
#pragma mark - 删除
-(void)removeSuperLayer{
    for (UIView *view in [self.view subviews]) {
        [view removeFromSuperview];
    }
    
    [_preview removeAllAnimations];
    [_preview removeFromSuperlayer];
}

@end

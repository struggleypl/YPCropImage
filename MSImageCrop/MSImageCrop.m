//
//  MSImageCrop.m
//  TipsView
//
//  Created by ypl on 2019/1/11.
//  Copyright © 2019年 ypl. All rights reserved.
//

#import "MSImageCrop.h"
#import "UIImageView+AFNetworking.h"
#import "UIView+frameByPoint.h"
#import "UIImage+MSImageCropExtension.h"

#define kDefualRatioOfWidthAndHeight 1.0f
#define kButtonWidth 50
#define kButtonViewHeight 50

@interface MSImageCrop ()<UIScrollViewDelegate>

@property(nonatomic,strong) UIScrollView *scrollView;
@property(nonatomic,strong) UIView *overlayView; //中心截取区域的View
@property(nonatomic,strong) UIImageView *imageView;
@property(nonatomic,strong) UIWindow *actionWindow;

@property(nonatomic,strong) UIView *topBlackView;//顶部黑色
@property(nonatomic,strong) UIView *bottomBlackView;//底部黑色
@property(nonatomic,strong) UIView *buttonBackgroundView;//按钮背景
@property(nonatomic,strong) UIButton *cancelButton;
@property(nonatomic,strong) UIButton *confirmButton;

@end

@implementation MSImageCrop

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.ratioOfWidthAndHeight = kDefualRatioOfWidthAndHeight;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
    self.scrollView.frame = self.view.bounds;
    self.overlayView.layer.borderColor = [UIColor colorWithWhite:0.966 alpha:1.000].CGColor;
    
    //绘制上下两块灰色区域
    [self.view addSubview:self.topBlackView = [self createBlackTransparentOverlayView]];
    [self.view addSubview:self.bottomBlackView = [self createBlackTransparentOverlayView]];
    
    //绘制底部按钮的背景View
    UIView *buttonBackgroundView = [[UIView alloc]init];
    buttonBackgroundView.userInteractionEnabled = NO;
    buttonBackgroundView.backgroundColor = [UIColor blackColor];
    buttonBackgroundView.layer.opacity = 0.0f;
    [self.view addSubview:self.buttonBackgroundView = buttonBackgroundView];
    
    //绘制俩button
    [self.view addSubview:self.cancelButton = [self createButtonWithTitle:@"取消" andAction:@selector(onCancel:)]];
    [self.view addSubview:self.confirmButton = [self createButtonWithTitle:@"完成" andAction:@selector(onConfirm:)]];
    [self.confirmButton setTitleColor:[UIColor colorWithRed:255/255.0 green:221/255.0 blue:0/255.0 alpha:1/1.0] forState:UIControlStateNormal];
    
    //双击事件
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.scrollView addGestureRecognizer:doubleTap];
    
}

#pragma mark create view helper
- (UIView*)createBlackTransparentOverlayView {
    UIView *view = [[UIView alloc]init];
    view.userInteractionEnabled = NO;
    view.backgroundColor = [UIColor blackColor];
    view.layer.opacity = 0.25f;
    return view;
}

- (UIButton *)createButtonWithTitle:(NSString*)title andAction:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont systemFontOfSize:16.0f]];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    button.exclusiveTouch = YES;
    return button;
}

#pragma mark - show
- (void)showInViewWithAnimation:(BOOL)animation {
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    window.opaque = YES;
    window.windowLevel = UIWindowLevelStatusBar+1.0f;
    window.rootViewController = self;
    [window makeKeyAndVisible];
    self.actionWindow = window;
    
    if (animation) {
        self.actionWindow.layer.opacity = .01f;
        [UIView animateWithDuration:0.35f animations:^{
            self.actionWindow.layer.opacity = 1.0f;
        }];
    }
}

#pragma mark - event
- (void)disappear {
    //退出
    [UIView animateWithDuration:0.35f animations:^{
        self.actionWindow.layer.opacity = 0.01f;
    } completion:^(BOOL finished) {
        [self.actionWindow removeFromSuperview];
        [self.actionWindow resignKeyWindow];
        self.actionWindow = nil;
    }];
}

- (void)onCancel:(id)sender {
    [self disappear];
}

- (void)onConfirm:(id)sender {
    if (!self.imageView.image) {
        return;
    }
    //稳定再截图
    if (self.scrollView.tracking||self.scrollView.dragging||self.scrollView.decelerating||self.scrollView.zoomBouncing||self.scrollView.zooming){
        return;
    }
    //根据区域来截图
    CGPoint startPoint = [self.overlayView convertPoint:CGPointZero toView:self.imageView];
    CGPoint endPoint = [self.overlayView convertPoint:CGPointMake(CGRectGetMaxX(self.overlayView.bounds), CGRectGetMaxY(self.overlayView.bounds)) toView:self.imageView];
    //这里获取的是实际宽度和zoomScale为1的frame宽度的比例
    CGFloat wRatio = self.imageView.image.size.width/(self.imageView.frame.size.width/self.scrollView.zoomScale);
    CGFloat hRatio = self.imageView.image.size.height/(self.imageView.frame.size.height/self.scrollView.zoomScale);
    CGRect cropRect = CGRectMake(startPoint.x*wRatio, startPoint.y*hRatio, (endPoint.x-startPoint.x)*wRatio, (endPoint.y-startPoint.y)*hRatio);
    
    [self disappear];
    
    UIImage *cropImage = [self.imageView.image MSImageCrop_imageByCropForRect:cropRect];
    if (self.delegate && [self.delegate respondsToSelector:@selector(cropImage:originalImage:)]){
        [self.delegate cropImage:cropImage originalImage:self.image];
    }
}

#pragma mark - tap
- (void)handleDoubleTap:(UITapGestureRecognizer *)tap {
    CGPoint touchPoint = [tap locationInView:self.scrollView];
    if (self.scrollView.zoomScale == self.scrollView.minimumZoomScale) {
        [self.scrollView zoomToRect:CGRectMake(touchPoint.x, touchPoint.y, 1, 1) animated:YES];
    } else {
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES]; //还原
    }
}

#pragma mark - getter or setter

- (void)setImage:(UIImage *)image {
    if ([image isEqual:_image]) {
        return;
    }
    _image = image;
    
    [self.imageView cancelImageDownloadTask];
    self.imageView.image = [image MSImageCrop_fixOrientation];
    if (self.isViewLoaded) {
        [self.view setNeedsLayout];
    }
}

- (void)setImageURL:(NSURL *)imageURL {
    if ([imageURL isEqual:_imageURL]) {
        return;
    }
    _imageURL = imageURL;
    _image = nil;
    
    self.imageView.image = nil;
    //加载图像
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:imageURL];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    indicator.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
    [self.view addSubview:indicator];
    [indicator startAnimating];
    
    NSURL *recordURL = imageURL;
    __weak __typeof(self)weakSelf = self;
    [self.imageView setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        [indicator stopAnimating];
        [indicator removeFromSuperview];
        
        if (!weakSelf.imageURL||![recordURL isEqual:weakSelf.imageURL]) {
            return;
        }
        
        weakSelf.image = image;
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        [indicator stopAnimating];
        [indicator removeFromSuperview];
        
        if (!weakSelf.imageURL||![recordURL isEqual:weakSelf.imageURL]) {
            return;
        }
        UILabel *tipsLabel = [[UILabel alloc]initWithFrame:CGRectMake((weakSelf.view.bounds.size.width-120)/2, (weakSelf.view.bounds.size.height-30)/2, 120, 30)];
        tipsLabel.text = @"图片加载失败";
        tipsLabel.layer.opacity = .4f;
        tipsLabel.layer.cornerRadius = 3.0f;
        tipsLabel.font = [UIFont systemFontOfSize:13.0f];
        tipsLabel.textColor = [UIColor whiteColor];
        tipsLabel.backgroundColor = [UIColor darkGrayColor];
        tipsLabel.textAlignment = NSTextAlignmentCenter;
        [weakSelf.view addSubview:tipsLabel];
        
        [UIView animateWithDuration:2.0f delay:.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            tipsLabel.layer.opacity = .8f;
        } completion:^(BOOL finished) {
            [weakSelf disappear];
        }];
    }];
}

- (void)setRatioOfWidthAndHeight:(CGFloat)ratioOfWidthAndHeight {
    if (ratioOfWidthAndHeight<=0) {
        ratioOfWidthAndHeight = kDefualRatioOfWidthAndHeight;
    }
    if (ratioOfWidthAndHeight==_ratioOfWidthAndHeight) {
        return;
    }
    _ratioOfWidthAndHeight = ratioOfWidthAndHeight;
    //重绘
    if (self.isViewLoaded) {
        [self.view setNeedsLayout];
    }
}

- (UIView*)overlayView {
    if (!_overlayView) {
        _overlayView = [[UIView alloc]init];
        _overlayView.layer.borderColor = [UIColor whiteColor].CGColor;
        _overlayView.layer.borderWidth = 1.0f;
        _overlayView.userInteractionEnabled = NO;
        [self.view addSubview:_overlayView];
    }
    return _overlayView;
}

- (UIScrollView*)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc]init];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.exclusiveTouch = YES;
        _scrollView.delegate = self;
        if (@available(iOS 11.0, *)) {
            _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            self.automaticallyAdjustsScrollViewInsets = false;
        }
        [self.view addSubview:_scrollView];
    }
    return _scrollView;
}

- (UIImageView*)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
//        _imageView.backgroundColor = [UIColor yellowColor];
        [self.scrollView addSubview:_imageView];
    }
    return _imageView;
}

#pragma mark - 截取基准
/**
 判断是否是以宽度为基准来截取
 */
- (BOOL)isBaseOnWidthOfOverlayView {
    if (self.overlayView.frame.size.width < self.view.bounds.size.width) {
        return NO;
    }
    return YES;
}

#pragma mark - layout
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.view sendSubviewToBack:self.scrollView];
    CGFloat statusHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    //底部按钮背景View
    self.buttonBackgroundView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds),kButtonViewHeight+statusHeight);
    //底部俩按钮
    self.cancelButton.frame = CGRectMake(15, statusHeight, kButtonWidth, kButtonViewHeight);
    self.confirmButton.frame = CGRectMake(CGRectGetWidth(self.buttonBackgroundView.frame)-kButtonWidth-15, statusHeight, kButtonWidth, kButtonViewHeight);
    
    //scrollView
    //重置下
    self.scrollView.minimumZoomScale = 1.0f;
    self.scrollView.maximumZoomScale = self.scrollView.minimumZoomScale;
    self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
    self.scrollView.frame = self.view.bounds;
    
    //overlayView
    //根据宽度找高度
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = width/self.ratioOfWidthAndHeight;
    BOOL isBaseOnWidth = YES;
    if (height>self.view.bounds.size.height) {
        //超过屏幕了那就只能是，高度定死，宽度修正
        height = self.view.bounds.size.height;
        width = height*self.ratioOfWidthAndHeight;
        isBaseOnWidth = NO;
    }
    self.overlayView.frame = CGRectMake(0, 0, width, height);
    self.overlayView.center = self.view.center;
    
    //上下黑色覆盖View
    if (isBaseOnWidth) {
        //上和下
        self.topBlackView.frame = CGRectMake(0, 0, width, CGRectGetMinY(self.overlayView.frame));
        self.bottomBlackView.frame = CGRectMake(0, CGRectGetMaxY(self.overlayView.frame), width, CGRectGetHeight(self.view.bounds)-CGRectGetMaxY(self.overlayView.frame));
    }else{
        //左和右
        self.topBlackView.frame = CGRectMake(0, 0, CGRectGetMinX(self.overlayView.frame), height);
        self.bottomBlackView.frame = CGRectMake(CGRectGetMaxX(self.overlayView.frame),0, CGRectGetWidth(self.view.bounds)-CGRectGetMaxX(self.overlayView.frame), height);
    }
    //imageView的frame和scrollView的内容
    [self adjustImageViewFrameAndScrollViewContent];
    
    [self setupCropCorners:self.overlayView];
}

- (void)setupCropCorners:(UIView*)bg {
    UIImage *img = [UIImage imageNamed:@"crop_corner"];
    CGSize sz = img.size;
    UIImageView *imgView1 = [[UIImageView alloc] initWithImage:img];imgView1.size = img.size;
    imgView1.transform = CGAffineTransformMakeRotation(-M_PI_2);
    imgView1.x = 0; imgView1.y = 0;
    [bg addSubview:imgView1];
    
    NSData *data2 = [NSKeyedArchiver archivedDataWithRootObject:imgView1];
    UIImageView *imgView2 = [NSKeyedUnarchiver unarchiveObjectWithData:data2];
    imgView2.transform = CGAffineTransformMakeRotation(-M_PI);
    imgView2.x = 0; imgView2.y =  CGRectGetHeight(bg.frame) - sz.width;
    [bg addSubview:imgView2];
    
    NSData *data3 = [NSKeyedArchiver archivedDataWithRootObject:imgView1];
    UIImageView *imgView3 = [NSKeyedUnarchiver unarchiveObjectWithData:data3];
    imgView3.transform = CGAffineTransformMakeRotation(-3*M_PI/2);
    imgView3.x =  CGRectGetWidth(bg.frame) - sz.width; imgView3.y = CGRectGetHeight(bg.frame) - sz.width;
    [bg addSubview:imgView3];
    
    NSData *data4 = [NSKeyedArchiver archivedDataWithRootObject:imgView1];
    UIImageView *imgView4 = [NSKeyedUnarchiver unarchiveObjectWithData:data4];
    imgView4.transform = CGAffineTransformMakeRotation(-2*M_PI);
    imgView4.x =  CGRectGetWidth(bg.frame) - sz.width; imgView4.y = 0;
    [bg addSubview:imgView4];
}

#pragma mark - 调整图片content
- (void)adjustImageViewFrameAndScrollViewContent {
    CGRect frame = self.scrollView.frame;
    if (self.imageView.image) {
        CGSize imageSize = self.imageView.image.size;
        CGRect imageFrame = CGRectMake(0, 0, imageSize.width, imageSize.height);
        
        CGFloat ratio = frame.size.width/imageFrame.size.width;
        imageFrame.size.height = imageFrame.size.height*ratio;
        imageFrame.size.width = frame.size.width;
        
        self.scrollView.contentSize = frame.size;
        
        BOOL isBaseOnWidth = [self isBaseOnWidthOfOverlayView];
        if (isBaseOnWidth) {
            self.scrollView.contentInset = UIEdgeInsetsMake(CGRectGetMinY(self.overlayView.frame), 0, CGRectGetHeight([UIScreen mainScreen].bounds)-CGRectGetMaxY(self.overlayView.frame), 0);
        }else{
            self.scrollView.contentInset = UIEdgeInsetsMake(0, CGRectGetMinX(self.overlayView.frame), 0, CGRectGetWidth(self.view.bounds)-CGRectGetMaxX(self.overlayView.frame));
        }
        
        self.imageView.frame = imageFrame;
        
        //初始化,让其不会有黑框出现
        CGFloat minScale = self.overlayView.frame.size.height/imageFrame.size.height;
        CGFloat minScale2 = self.overlayView.frame.size.width/imageFrame.size.width;
        minScale = minScale>minScale2?minScale:minScale2;
        
        self.scrollView.minimumZoomScale = minScale;
        self.scrollView.maximumZoomScale = self.scrollView.minimumZoomScale*3<2.0f?2.0f:self.scrollView.minimumZoomScale*3;
        self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
        
        //调整下让其居中
        if (isBaseOnWidth) {
            CGFloat offsetY = (self.scrollView.bounds.size.height > self.scrollView.contentSize.height)?
            (self.scrollView.bounds.size.height - self.scrollView.contentSize.height) * 0.5 : 0.0;
            self.scrollView.contentOffset = CGPointMake(0, -offsetY);
        }else{
            CGFloat offsetX = (self.scrollView.bounds.size.width > self.scrollView.contentSize.width)?
            (self.scrollView.bounds.size.width - self.scrollView.contentSize.width) * 0.5 : 0.0;
            self.scrollView.contentOffset = CGPointMake(-offsetX,0);
        }
    }else{
        frame.origin = CGPointZero;
        self.imageView.frame = frame;
        //重置内容大小
        self.scrollView.contentSize = self.imageView.frame.size;
        
        self.scrollView.minimumZoomScale = 1.0f;
        self.scrollView.maximumZoomScale = self.scrollView.minimumZoomScale; //取消缩放功能
        self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
    }
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

//
//  MSImageCrop.h
//  TipsView
//
//  Created by ypl on 2019/1/11.
//  Copyright © 2019年 ypl. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MSImageCropDelegate <NSObject>
@optional
- (void)cropImage:(UIImage*)cropImage originalImage:(UIImage*)originalImage;

@end

@interface MSImageCrop : UIViewController

@property(nonatomic,strong) UIImage *image;
@property(nonatomic,strong) NSURL *imageURL;
@property(nonatomic,weak) id<MSImageCropDelegate> delegate;
@property(nonatomic,assign) CGFloat ratioOfWidthAndHeight; //截取比例，宽高比

- (void)showInViewWithAnimation:(BOOL)animation;

@end

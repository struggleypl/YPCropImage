//
//  UIImage+MSImageCropExtension.h
//  TipsView
//
//  Created by ypl on 2019/1/12.
//  Copyright © 2019年 ypl. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (MSImageCropExtension)
//将根据所定frame来截取图片
- (UIImage*)MSImageCrop_imageByCropForRect:(CGRect)targetRect;
- (UIImage *)MSImageCrop_fixOrientation;
@end

//
//  SliderControl.m
//  CustomControl
//
//  Created by bjovov on 2017/8/9.
//  Copyright © 2017年 ovov.cn. All rights reserved.
//

#import "SliderControl.h"

@interface SliderControl()
@property (nonatomic,assign) int radius;
@property (nonatomic,strong) UITextField *textField;
@end

@implementation SliderControl
#pragma mark - Init Menthod
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        _radius = self.frame.size.width/2 - TB_SAFEAREA_PADDING;
        _angle = 360;
       
        UIFont *font = [UIFont fontWithName:TB_FONTFAMILY size:TB_FONTSIZE];
        NSString *str = @"000";
        CGSize fontSize = [str sizeWithFont:font];
        _textField = [[UITextField alloc]initWithFrame:CGRectMake((frame.size.width  - fontSize.width) /2,
                                                                  (frame.size.height - fontSize.height) /2,
                                                                  fontSize.width,
                                                                  fontSize.height)];
        _textField.backgroundColor = [UIColor clearColor];
        _textField.textColor = [UIColor blackColor];
        _textField.textAlignment = NSTextAlignmentCenter;
        _textField.font = font;
        _textField.text = [NSString stringWithFormat:@"%d",self.angle];
        _textField.enabled = NO;
        [self addSubview:_textField];
    }
    return self;
}

#pragma mark - UIControl Override
/*当在控件的bound内发生了一个触摸事件会调用该方法
 当触摸事件是dragged时，是否需要响应。在我们这里的自定义控件中，是需要跟踪用户的dragging，所以返回YES。
 */
-(BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event{
    [super beginTrackingWithTouch:touch withEvent:event];
    return YES;
}

/*当用户进行drag时,会调用这个方法
 该方法返回的BOOL值标示是否继续跟踪touch事件
 通过该方法我们可以根据touch位置对用户的操作进行过滤
 */
-(BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event{
    [super continueTrackingWithTouch:touch withEvent:event];
    
    //获取触摸的点
    CGPoint lastPoint = [touch locationInView:self];
    
    //改变手柄的位置(仅当touch位置与手柄位置相交的时候才激活控件(activate control))
    CGMutablePathRef pathRef = CGPathCreateMutable();
    CGPoint handleCenter =  [self pointFromAngle: self.angle];
    CGPathAddArc(pathRef, NULL, handleCenter.x, handleCenter.y, TB_LINE_WIDTH/2, 0, M_PI*2, 0);
    if (CGPathContainsPoint(pathRef, NULL, lastPoint, NO)) {
        [self movehandle:lastPoint];
    }else{
        return NO;
    }
    
    //如果希望自己定制的控件与UIControl行为保持一致，那么当控件的值发生变化时，需要进行通知处理
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    return YES;
}

/*当跟踪结束的时候，会调用下面这个方法*/
-(void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event{
    [super endTrackingWithTouch:touch withEvent:event];
}


#pragma mark - DrawRect Menthod
- (void)drawRect:(CGRect)rect{
    [super drawRect:rect];

//1.*****绘制背景*******/
    //创建路径
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextAddArc(ctx, self.frame.size.width/2, self.frame.size.height/2, _radius, 0, M_PI*2, 0);
    
    //设置笔画颜色
    [[UIColor blackColor]setStroke];
    
    //设置线条宽度和类型
    CGContextSetLineWidth(ctx, TB_BACKGROUND_WIDTH);
    CGContextSetLineCap(ctx, kCGLineCapButt);
    
    //绘制
    CGContextDrawPath(ctx, kCGPathStroke);
    
    
//2.*****绘制用户的可操作区域*******/
    //创建遮罩图片
    UIGraphicsBeginImageContext(CGSizeMake(320, 320));
    CGContextRef imageCtx = UIGraphicsGetCurrentContext();
    CGContextAddArc(imageCtx, self.frame.size.width/2, self.frame.size.height/2, _radius, 0, ToRad(_angle), 0);
    [[UIColor redColor]set];
    
    //使用阴影创建模糊效果
    CGContextSetShadowWithColor(imageCtx, CGSizeMake(0, 0), 10, [UIColor blackColor].CGColor);
    
    //设置线条宽度
    CGContextSetLineWidth(imageCtx, TB_LINE_WIDTH);
    CGContextDrawPath(imageCtx, kCGPathStroke);
    
    //保存上下文内容到图片遮罩
    CGImageRef mask = CGBitmapContextCreateImage(UIGraphicsGetCurrentContext());
    UIGraphicsEndImageContext();

    
//3.*****裁剪上下文*******/
    CGContextSaveGState(ctx);
    CGContextClipToMask(ctx, self.bounds, mask);
    CGImageRelease(mask);
    
    //绘制渐变效果
    //定义颜色变化范围
    CGFloat components[8] = {
        0.0, 0.0, 1.0, 1.0,
        1.0, 0.0, 1.0, 1.0 };
    CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(baseSpace, components, NULL, 2);
    CGColorSpaceRelease(baseSpace),baseSpace = NULL;
    
    //定义渐变的方向
    CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
    CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    
    //创建并设置渐变
    CGContextDrawLinearGradient(ctx, gradient, startPoint, endPoint, 0);
    CGGradientRelease(gradient),gradient = NULL;
    CGContextRestoreGState(ctx);
    
    

    /** 绘制手柄 **/
    [self drawTheHandle:ctx];
    
}

-(void) drawTheHandle:(CGContextRef)ctx{
    CGContextSaveGState(ctx);
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, 0), 3, [UIColor blackColor].CGColor);
    CGPoint handleCenter =  [self pointFromAngle: self.angle];
    [[UIColor colorWithWhite:1.0 alpha:0.7]set];
    CGContextAddArc(ctx, handleCenter.x, handleCenter.y, TB_LINE_WIDTH/2, 0, M_PI*2, 1);
    CGContextDrawPath(ctx, kCGPathFill);
    CGContextRestoreGState(ctx);
}

#pragma mark - Math
/*移动手柄*/
-(void)movehandle:(CGPoint)lastPoint{
    CGPoint centerPoint = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    
    //根据两个point，就会返回一个连接这两点对应的一个角度关系
    float currentAngle = AngleFromNorth(centerPoint, lastPoint, NO);
    int angleInt = floor(currentAngle);
    
    //保存当前的弧度
    self.angle = 360 - angleInt;
    _textField.text =  [NSString stringWithFormat:@"%d", self.angle];
    
    //重新绘制
    [self setNeedsDisplay];
}

/*获取当前手柄的中心点*/
-(CGPoint)pointFromAngle:(int)angleInt{
    CGPoint centerPoint = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    CGPoint result;
    result.y = round(centerPoint.y + _radius * sin(ToRad(-angleInt))) ;
    result.x = round(centerPoint.x + _radius * cos(ToRad(-angleInt)));
    return result;
}

//Sourcecode from Apple example clockControl
//Calculate the direction in degrees from a center point to an arbitrary position.
static inline float AngleFromNorth(CGPoint p1, CGPoint p2, BOOL flipped) {
    CGPoint v = CGPointMake(p2.x-p1.x,p2.y-p1.y);
    float vmag = sqrt(SQR(v.x) + SQR(v.y)), result = 0;
    v.x /= vmag;  /*x /= y. 等效于 x = x / y*/
    v.y /= vmag;
    double radians = atan2(v.y,v.x);
    result = ToDeg(radians);
    NSLog(@"移动的角度:%f----弧度:%f 点:%@",result,radians,NSStringFromCGPoint(v));
    return (result >=0  ? result : result + 360.0);
}

/*
 在三角函数中，两个参数的函数atan2是正切函数tan的一个变种。对于任意不同时等于0的实参数x和y，atan2(y,x)所表达的意思是坐标原点为起点，指向(x,y)的射线在坐标平面上与x轴正方向之间的角的角度。当y>0时，射线与x轴正方向的所得的角的角度指的是x轴正方向绕逆时针方向到达射线旋转的角的角度；而当y<0时，射线与x轴正方向所得的角的角度指的是x轴正方向绕顺时针方向达到射线旋转的角的角度。
 在几何意义上，atan2(y, x) 等价于 atan(y/x)，但 atan2 的最大优势是可以正确处理 x=0 而 y≠0 的情况，而不必进行会引发除零异常的 y/x 操作。
 https://zh.wikipedia.org/wiki/Atan2
 */

@end

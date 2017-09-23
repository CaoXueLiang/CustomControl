# CustomControl
自定义iOS的控件

我们需要创建一个这样的控件能支持用户方便的选择0-360°之间的一个角度值，这就需要我们自定义控件了，如下图所示。实现方法是创建一个圆形的滑块，用户通过拖动手柄操作就能选择角度值。

![screen shot](http://upload-images.jianshu.io/upload_images/979175-635ef22f2d2394d4.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

##绘制用户界面
1.首先，是用一个`黑色的圆环`当做滑块的背景。 

![](http://upload-images.jianshu.io/upload_images/979175-ba21dcf197239a14.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
```
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
```
2.弧形`图片遮罩`绘制。

 根据当前的角度绘制弧度。最后，利用`CGBitmapContextCreateImage`方法获取一张图片（刚刚绘制的弧）。这个图片就是我们所需要的掩码图了。
     
![](http://upload-images.jianshu.io/upload_images/979175-ecffecd8dc776988.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
```
   /****绘制用户的可操作区域*******/
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
```
3.裁剪上下文。

现在我们已经有一个的掩码图了。接着利用函数`CGContextClipToMask`对上下文进行裁剪——给该函数传入上面刚刚创建好的掩码图。代码如下所示：
```
    /**裁剪上下文**/
    CGContextSaveGState(ctx);
    CGContextClipToMask(ctx, self.bounds, mask);
    CGImageRelease(mask);
```
4.绘制渐变效果
```
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
```
5.绘制手柄

根据当前的角度值，在的正确位置绘制出手柄，这里我们需要使用三角函数将一个标量值(scalar number)转换为`CGPoint`。然后根据中心点和半径绘制圆环手柄。
     
![](http://upload-images.jianshu.io/upload_images/979175-604d4819c8bb1b99.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
```
/*获取当前手柄的中心点*/
-(CGPoint)pointFromAngle:(int)angleInt{
    CGPoint centerPoint = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    CGPoint result;
    result.y = round(centerPoint.y + _radius * sin(ToRad(-angleInt))) ;
    result.x = round(centerPoint.x + _radius * cos(ToRad(-angleInt)));
    return result;
}
```
```
/*
1.保存当前的上下文(当在一个单独的函数中进行绘制任务时，将上下文的状2.态进行保存是编程的一个好习惯)。
3.给手柄设置一些阴影效果
4.定义手柄的颜色，然后利用CGContextAddArc将其绘制出来。
*/
-(void) drawTheHandle:(CGContextRef)ctx{
    CGContextSaveGState(ctx);
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, 0), 3, [UIColor blackColor].CGColor);
    CGPoint handleCenter =  [self pointFromAngle: self.angle];
    [[UIColor colorWithWhite:1.0 alpha:0.7]set];
    CGContextAddArc(ctx, handleCenter.x, handleCenter.y, TB_LINE_WIDTH/2, 0, M_PI*2, 1);
    CGContextDrawPath(ctx, kCGPathFill);
    CGContextRestoreGState(ctx);
}
```
至此，已经完成了全部的绘制任务。

##跟踪用户的操作

1.开始跟踪

当在控件的bound内发生了一个触摸事件，首先会调用控件的`beginTrackingWithTouch`方法，该函数返回的BOOl值决定着：当触摸事件是`dragged`时，是否需要响应。
```
-(BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event{
    [super beginTrackingWithTouch:touch withEvent:event];
    return YES;
}
```
2.持续跟踪

当用户进行drag时，会调`continueTrackingWithTouch`，通过该方法我们可以根据touch位置对用户的操作进行过滤。
```
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

    //如果希望自己定制的控件与UIControl行为保持一致,那么当控件的值发生变化时,需要进行通知处理
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    return YES;
}
```

3.结束跟踪
```
-(void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event{
    [super endTrackingWithTouch:touch withEvent:event];
}
```
##自定义控件的使用

1.通过调用initWithFrame方法实例化了一个圆形滑块(自定义的控件)。
```
SliderControl *slider = [[SliderControl alloc]initWithFrame:CGRectMake(0, 60, TB_SLIDER_SIZE, TB_SLIDER_SIZE)];
 [self.view addSubview:slider];
```
2.接着定义了如何与该控件进行交互
使用`addTarget:action:forControlEvent:`方法，每当用户移动手柄时，圆形滑块都会发送一个`UIControlEventValueChanged`事件
```
[slider addTarget:self action:@selector(newValue:) forControlEvents:UIControlEventValueChanged];
```
##参考资料

[如何自定义iOS中的控件](http://beyondvincent.com/2014/01/20/2014-01-20-how-to-build-a-custom-control-in-ios/)

[How to build a custom control in iOS](http://www.thinkandbuild.it/how-to-build-a-custom-control-in-ios/)

[Demo下载地址](https://github.com/CaoXueLiang/CustomControl)

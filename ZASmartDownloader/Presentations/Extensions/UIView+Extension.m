/* Copyright (c) 2015-present, Zalo Group.
 * Forked from Three20, ©2011-2014 Jverkoey
 * All rights reserved.
 */

#import "UIView+Extension.h"

@implementation UIView (Extension)

- (CGFloat)left {
    return self.frame.origin.x;
}

- (void)setLeft:(CGFloat)x {
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (CGFloat)top {
    return self.frame.origin.y;
}

- (void)setTop:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGFloat)right {
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setRight:(CGFloat)right {
    CGRect frame = self.frame;
    frame.origin.x = right - frame.size.width;
    self.frame = frame;
}

- (CGFloat)bottom {
    return self.frame.origin.y + self.frame.size.height;
}

- (void)setBottom:(CGFloat)bottom {
    CGRect frame = self.frame;
    frame.origin.y = bottom - frame.size.height;
    self.frame = frame;
}

- (CGFloat)centerX {
    return self.center.x;
}

- (void)setCenterX:(CGFloat)centerX {
    self.center = CGPointMake(centerX, self.center.y);
}

- (CGFloat)centerY {
    return self.center.y;
}

- (void)setCenterY:(CGFloat)centerY {
    self.center = CGPointMake(self.center.x, centerY);
}

- (CGFloat)width {
    return self.frame.size.width;
}

- (void)setWidth:(CGFloat)width {
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (CGFloat)height {
    return self.frame.size.height;
}

- (void)setHeight:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGFloat)ttScreenX {
    CGFloat x = 0;
    for (UIView* view = self; view; view = view.superview) {
        x += view.left;
    }
    return x;
}

- (CGFloat)ttScreenY {
    CGFloat y = 0;
    for (UIView* view = self; view; view = view.superview) {
        y += view.top;
    }
    return y;
}

- (CGFloat)screenViewX {
    CGFloat x = 0;
    for (UIView* view = self; view; view = view.superview) {
        x += view.left;
        
        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView* scrollView = (UIScrollView*)view;
            x -= scrollView.contentOffset.x;
        }
    }
    
    return x;
}

- (CGFloat)screenViewY {
    CGFloat y = 0;
    for (UIView* view = self; view; view = view.superview) {
        y += view.top;
        
        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView* scrollView = (UIScrollView*)view;
            y -= scrollView.contentOffset.y;
        }
    }
    return y;
}

- (CGRect)screenFrame {
    return CGRectMake(self.screenViewX, self.screenViewY, self.width, self.height);
}

- (CGPoint)origin {
    return self.frame.origin;
}

- (void)setOrigin:(CGPoint)origin {
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (CGSize)size {
    return self.frame.size;
}

- (void)setSize:(CGSize)size {
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

//- (CGFloat)orientationWidth {
//    return UIInterfaceOrientationIsLandscape(UXInterfaceOrientation())
//    ? self.height : self.width;
//}
//
//- (CGFloat)orientationHeight {
//    return UIInterfaceOrientationIsLandscape(UXInterfaceOrientation())
//    ? self.width : self.height;
//}

- (UIView*)descendantOrSelfWithClass:(Class)theClass {
    if ([self isKindOfClass:theClass])
        return self;
    
    for (UIView* child in self.subviews) {
        UIView* it = [child descendantOrSelfWithClass:theClass];
        if (it)
            return it;
    }
    
    return nil;
}

- (UIView*)ancestorOrSelfWithClass:(Class)theClass {
    if ([self isKindOfClass:theClass]) {
        return self;
    } else if (self.superview) {
        return [self.superview ancestorOrSelfWithClass:theClass];
    } else {
        return nil;
    }
}

- (void)removeAllSubviews {
    while (self.subviews.count) {
        UIView* child = self.subviews.lastObject;
        [child removeFromSuperview];
    }
}

- (CGPoint)offsetFromView:(UIView*)otherView {
    CGFloat x = 0, y = 0;
    for (UIView* view = self; view && view != otherView; view = view.superview) {
        x += view.left;
        y += view.top;
    }
    return CGPointMake(x, y);
}

- (UIViewController*)viewController {
    for (UIView* next = [self superview]; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController*)nextResponder;
        }
    }
    return nil;
}

//- (CGRect)frameWithKeyboardSubtracted:(CGFloat)plusHeight {
//    CGRect frame = self.frame;
//    if ([self isKeyboardVisible]) {
//        CGRect screenFrame = [UIScreen mainScreen].bounds;
//        CGFloat keyboardTop = (screenFrame.size.height - (kDefaultPortraitKeyboardHeight + plusHeight));
//        CGFloat screenBottom = self.ttScreenY + frame.size.height;
//        CGFloat diff = screenBottom - keyboardTop;
//        if (diff > 0) {
//            frame.size.height -= diff;
//        }
//    }
//    return frame;
//}
//
//- (BOOL)isKeyboardVisible {
//    // Operates on the assumption that the keyboard is visible if
//    // and only if there is a first responder; i.e. a control responding to key events
//    UIWindow* window = [UIApplication sharedApplication].keyWindow;
//    return !![window findFirstResponder];
//}

- (UIImage *)takeSnapshot {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 0);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)setGradientBackgroundWithStartColor:(UIColor *)startColor
                                 startPoint:(CGPoint)startPoint
                                   endColor:(UIColor *)endColor
                                   endPoint:(CGPoint)endPoint {
    
    CAGradientLayer *layer = [CAGradientLayer layer];
    layer.frame = self.bounds;
    layer.colors = @[(id)startColor.CGColor, (id)endColor.CGColor];
    layer.startPoint = CGPointMake(startPoint.x/self.width, startPoint.y/self.height);
    layer.endPoint = CGPointMake(endPoint.x/self.width, endPoint.y/self.height);
    
    [self.layer insertSublayer:layer atIndex:0];
}

//+ (void)setMaskTo:(UIView*)view
//byRoundingCorners:(UIRectCorner)corners
//           radius:(CGSize)radius
//      az_borderColor:(AZColor*)az_color
//      borderWidth:(CGFloat)borderWidth
//        fillColor:(UIColor*)fillColor
//{
//    CGRect bounds = CGRectInset(view.bounds, 0, 0);
//    CGFloat scale = [UIScreen mainScreen].scale;
//
//    CGFloat delta = 0;
//    if (borderWidth < 1) {
//        // Extend corner of mask shape to display full border at the corners
//        delta = sqrt(borderWidth);
//    }
//
//    UIBezierPath* rounded = [UIBezierPath bezierPathWithRoundedRect:bounds
//                                                  byRoundingCorners:corners
//                                                        cornerRadii:CGSizeMake(radius.width - delta, radius.height - delta)];
//
//    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
//    maskLayer.frame = bounds;
//    maskLayer.path = rounded.CGPath;
//    view.layer.mask = maskLayer;
//
//    if (delta > 0) {
//        rounded = [UIBezierPath bezierPathWithRoundedRect:bounds
//                                        byRoundingCorners:corners
//                                              cornerRadii:CGSizeMake(radius.width, radius.height)];
//    }
//
//    CornerCALayer* shape = [[CornerCALayer alloc] init];
//    [shape setFrame:bounds];
//    [shape setPath:rounded.CGPath];
//    shape.lineWidth = borderWidth;
//    shape.az_strokeColor = az_color;
//    shape.fillColor = fillColor.CGColor;
//
//    BOOL isExits = NO;
//    for (CALayer *layer in view.layer.sublayers) {
//        if ([layer isKindOfClass:[CornerCALayer class]]) {
//
//            [view.layer replaceSublayer:layer with:shape];
//            isExits = YES;
//            break;
//        }
//    }
//    if (isExits == NO) {
//        [view.layer addSublayer:shape];
//    }
//
//    [view.layer setShouldRasterize:YES];
//    view.layer.rasterizationScale = scale;
//
//}

+ (void)removeMaskCornerLayerOfView:(UIView*)view {
    if (view) {
        view.layer.mask = nil;
        for (CALayer *layer in view.layer.sublayers) {
            if ([layer isKindOfClass:[CornerCALayer class]]) {
                [layer removeFromSuperlayer];
                break;
            }
        }
    }
}

- (void)updateAppearanceChangesIfNeeded {
    UIView *superview = self.superview;
    if (superview) {
        NSUInteger index = [[superview subviews] indexOfObject:self];
        [self removeFromSuperview];
        [superview insertSubview:self atIndex:index];
    }
}

@end

@implementation CornerCALayer

@end

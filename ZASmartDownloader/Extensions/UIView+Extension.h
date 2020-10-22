/* Copyright (c) 2015-present, Zalo Group.
 * Forked from Three20, ©2011-2014 Jverkoey
 * All rights reserved.
 */

#import <UIKit/UIKit.h>

@interface UIView (Extension)

@property (nonatomic) CGFloat left;
@property (nonatomic) CGFloat top;
@property (nonatomic) CGFloat right;
@property (nonatomic) CGFloat bottom;

@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;

@property (nonatomic) CGFloat centerX;
@property (nonatomic) CGFloat centerY;

@property (nonatomic, readonly) CGFloat ttScreenX;
@property (nonatomic, readonly) CGFloat ttScreenY;
@property (nonatomic, readonly) CGFloat screenViewX;
@property (nonatomic, readonly) CGFloat screenViewY;
@property (nonatomic, readonly) CGRect screenFrame;

@property (nonatomic) CGPoint origin;
@property (nonatomic) CGSize size;

@property (nonatomic, readonly) CGFloat orientationWidth;
@property (nonatomic, readonly) CGFloat orientationHeight;

/**
 * Finds the first descendant view (including this view) that is a member of a particular class.
 */
- (UIView*)descendantOrSelfWithClass:(Class)theClass;

/**
 * Finds the first ancestor view (including this view) that is a member of a particular class.
 */
- (UIView*)ancestorOrSelfWithClass:(Class)theClass;

/**
 * Removes all subviews.
 */
- (void)removeAllSubviews;

/**
 * Calculates the offset of this view from another view in screen coordinates.
 *
 * otherView should be a parent view of this view.
 */
- (CGPoint)offsetFromView:(UIView*)otherView;

/**
 * Calculates the frame of this view with parts that intersect with the keyboard subtracted.
 *
 * If the keyboard is not showing, this will simply return the normal frame.
 */
- (CGRect)frameWithKeyboardSubtracted:(CGFloat)plusHeight;

/**
 * The view controller whose view contains this view.
 */
- (UIViewController*)viewController;

/**
 *  Take the view snapshot and return an image.
 */
- (UIImage *)takeSnapshot;

/**
 Set gradient background for the view.
 */
- (void)setGradientBackgroundWithStartColor:(UIColor *)startColor
                                 startPoint:(CGPoint)startPoint
                                   endColor:(UIColor *)endColor
                                   endPoint:(CGPoint)endPoint;

//+ (void)setMaskTo:(UIView*)view
//byRoundingCorners:(UIRectCorner)corners
//           radius:(CGSize)radius
//   az_borderColor:(AZColor*)az_color
//      borderWidth:(CGFloat)borderWidth
//        fillColor:(UIColor*)fillColor;


+ (void)removeMaskCornerLayerOfView:(UIView*)view;

/**
 Used to update after change @c UIAppearance.
 @Discussion iOS applies appearance changes when a view enters a window, it doesn’t change the appearance of a view that’s already in a window. To change the appearance of a view that’s currently in a window, remove the view from the view hierarchy and then put it back.
 */
- (void)updateAppearanceChangesIfNeeded;
    
@end

@interface CornerCALayer: CAShapeLayer

@property (nonatomic, assign) UIRectCorner savedCorners;
@property (nonatomic, assign) CGSize savedRadius;

@end

/* Copyright (c) 2015-present, Zalo Group.
 * Forked from Three20, ©2011-2014 Jverkoey
 * All rights reserved.
 */

#import <UIKit/UIKit.h>

@interface UIView (Extension)

/**
 * Shortcut for frame.origin.x.
 *
 * Sets frame.origin.x = left
 */
@property (nonatomic) CGFloat left;

/**
 * Shortcut for frame.origin.y
 *
 * Sets frame.origin.y = top
 */
@property (nonatomic) CGFloat top;

/**
 * Shortcut for frame.origin.x + frame.size.width
 *
 * Sets frame.origin.x = right - frame.size.width
 */
@property (nonatomic) CGFloat right;

/**
 * Shortcut for frame.origin.y + frame.size.height
 *
 * Sets frame.origin.y = bottom - frame.size.height
 */
@property (nonatomic) CGFloat bottom;

/**
 * Shortcut for frame.size.width
 *
 * Sets frame.size.width = width
 */
@property (nonatomic) CGFloat width;

/**
 * Shortcut for frame.size.height
 *
 * Sets frame.size.height = height
 */
@property (nonatomic) CGFloat height;

/**
 * Shortcut for center.x
 *
 * Sets center.x = centerX
 */
@property (nonatomic) CGFloat centerX;

/**
 * Shortcut for center.y
 *
 * Sets center.y = centerY
 */
@property (nonatomic) CGFloat centerY;

/**
 * Return the x coordinate on the screen.
 */
@property (nonatomic, readonly) CGFloat ttScreenX;

/**
 * Return the y coordinate on the screen.
 */
@property (nonatomic, readonly) CGFloat ttScreenY;

/**
 * Return the x coordinate on the screen, taking into account scroll views.
 */
@property (nonatomic, readonly) CGFloat screenViewX;

/**
 * Return the y coordinate on the screen, taking into account scroll views.
 */
@property (nonatomic, readonly) CGFloat screenViewY;

/**
 * Return the view frame on the screen, taking into account scroll views.
 */
@property (nonatomic, readonly) CGRect screenFrame;

/**
 * Shortcut for frame.origin
 */
@property (nonatomic) CGPoint origin;

/**
 * Shortcut for frame.size
 */
@property (nonatomic) CGSize size;

/**
 * Return the width in portrait or the height in landscape.
 */
@property (nonatomic, readonly) CGFloat orientationWidth;

/**
 * Return the height in portrait or the width in landscape.
 */
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

//
//  DZKeyboardManager.m
//  ChengYi
//
//  Created by stonedong on 16/2/18.
//  Copyright © 2016年 stonedong. All rights reserved.
//

#import "DZKeyboardManager.h"
#import <UIKit/UIKit.h>
@interface __DZKeyboardWeakContainer : NSObject
@property (nonatomic, weak) id<DZKeyboardChangedProtocol> observer;
@end
@implementation __DZKeyboardWeakContainer

@end

@implementation DZKeyboardManager
{
    NSMutableArray* _observers;
}
- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


+ (instancetype) shareManager
{
    static DZKeyboardManager* manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [DZKeyboardManager new];
    });
    return manager;
}
- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    _observers = [NSMutableArray new];
    [self registerNotification];
    return self;
}


- (void) registerNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHiden:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHiden:) name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
}

- (void) unregisterNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
}

- (void) keyboardWillHiden:(NSNotification*)nc
{
    [self decodeUserInfoAndNotify:nc.userInfo show:NO];
}

- (void) decodeUserInfoAndNotify:(NSDictionary*)userInfo show:(BOOL)isShow
{
    
    DZKeyboardTransition t;
    t.type = isShow ? DZKeyboardTransitionShow : DZKeyboardTransitionHidden;
    t.startFrame = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    t.endFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    t.animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue];
    t.animationDuration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [self notifyObserverWithTransition:t];
}

- (void) notifyObserverWithTransition:(DZKeyboardTransition)transition
{
    for (__DZKeyboardWeakContainer* c in _observers) {
        if ([c.observer respondsToSelector:@selector(keyboardChanged:)]) {
            [c.observer keyboardChanged:transition];
        }

    }
}

- (void) keyboardWillShow:(NSNotification*)nc
{
       [self decodeUserInfoAndNotify:nc.userInfo show:YES];
}

- (void) keyboardDidHiden:(NSNotification*)nc
{
       [self decodeUserInfoAndNotify:nc.userInfo show:NO];
}

- (void) keyboardDidShow:(NSNotification*) nc
{
       [self decodeUserInfoAndNotify:nc.userInfo show:YES];
}

- (void) addObserver:(id<DZKeyboardChangedProtocol>)observer
{
    if (!observer) {
        return;
    }
    for (__DZKeyboardWeakContainer* c  in _observers) {
        if (c.observer == observer) {
            return;
        }
    }
    __DZKeyboardWeakContainer* c = [__DZKeyboardWeakContainer new];
    c.observer = observer;
    [_observers addObject:c];
    
}

- (void) removeObserver:(id<DZKeyboardChangedProtocol>)observer
{
    NSArray* obs = [_observers copy];
    for (__DZKeyboardWeakContainer* c  in obs) {
        if (c.observer == observer) {
            [_observers removeObject:c];
        }
    }
}
- (CGFloat)_systemVersion {
    static CGFloat v;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        v = [UIDevice currentDevice].systemVersion.floatValue;
    });
    return v;
}
- (UIView *)_getKeyboardViewFromWindow:(UIWindow *)window {
    /*
     iOS 6/7:
     UITextEffectsWindow
     UIPeripheralHostView << keyboard
     
     iOS 8:
     UITextEffectsWindow
     UIInputSetContainerView
     UIInputSetHostView << keyboard
     
     iOS 9:
     UIRemoteKeyboardWindow
     UIInputSetContainerView
     UIInputSetHostView << keyboard
     */
    if (!window) return nil;
    
    // Get the window
    NSString *windowName = NSStringFromClass(window.class);
    if ([self _systemVersion] < 9) {
        // UITextEffectsWindow
        if (windowName.length != 19) return nil;
        if (![windowName hasPrefix:@"UI"]) return nil;
        if (![windowName hasSuffix:@"TextEffectsWindow"]) return nil;
    } else {
        // UIRemoteKeyboardWindow
        if (windowName.length != 22) return nil;
        if (![windowName hasPrefix:@"UI"]) return nil;
        if (![windowName hasSuffix:@"RemoteKeyboardWindow"]) return nil;
    }
    
    // Get the view
    if ([self _systemVersion] < 8) {
        // UIPeripheralHostView
        for (UIView *view in window.subviews) {
            NSString *viewName = NSStringFromClass(view.class);
            if (viewName.length != 20) continue;
            if (![viewName hasPrefix:@"UI"]) continue;
            if (![viewName hasSuffix:@"PeripheralHostView"]) continue;
            return view;
        }
    } else {
        // UIInputSetContainerView
        for (UIView *view in window.subviews) {
            NSString *viewName = NSStringFromClass(view.class);
            if (viewName.length != 23) continue;
            if (![viewName hasPrefix:@"UI"]) continue;
            if (![viewName hasSuffix:@"InputSetContainerView"]) continue;
            // UIInputSetHostView
            for (UIView *subView in view.subviews) {
                NSString *subViewName = NSStringFromClass(subView.class);
                if (subViewName.length != 18) continue;
                if (![subViewName hasPrefix:@"UI"]) continue;
                if (![subViewName hasSuffix:@"InputSetHostView"]) continue;
                return subView;
            }
        }
    }
    
    return nil;
}

- (UIWindow *)keyboardWindow {
    UIWindow *window = nil;
    for (window in [UIApplication sharedApplication].windows) {
        if ([self _getKeyboardViewFromWindow:window]) return window;
    }
    window = [UIApplication sharedApplication].keyWindow;
    if ([self _getKeyboardViewFromWindow:window]) return window;
    
    NSMutableArray *kbWindows = nil;
    for (window in [UIApplication sharedApplication].windows) {
        NSString *windowName = NSStringFromClass(window.class);
        if ([self _systemVersion] < 9) {
            // UITextEffectsWindow
            if (windowName.length == 19 &&
                [windowName hasPrefix:@"UI"] &&
                [windowName hasSuffix:@"TextEffectsWindow"]) {
                if (!kbWindows) kbWindows = [NSMutableArray new];
                [kbWindows addObject:window];
            }
        } else {
            // UIRemoteKeyboardWindow
            if (windowName.length == 22 &&
                [windowName hasPrefix:@"UI"] &&
                [windowName hasSuffix:@"RemoteKeyboardWindow"]) {
                if (!kbWindows) kbWindows = [NSMutableArray new];
                [kbWindows addObject:window];
            }
        }
    }
    
    if (kbWindows.count == 1) {
        return kbWindows.firstObject;
    }
    
    return nil;
}

- (BOOL)isKeyboardVisible {
    UIWindow *window = self.keyboardWindow;
    if (!window) return NO;
    UIView *view = self.keyboardView;
    if (!view) return NO;
    CGRect rect = CGRectIntersection(window.bounds, view.frame);
    if (CGRectIsNull(rect)) return NO;
    if (CGRectIsInfinite(rect)) return NO;
    return rect.size.width > 0 && rect.size.height > 0;
}

- (CGRect)keyboardFrame {
    UIView *keyboard = [self keyboardView];
    if (!keyboard) return CGRectNull;
    
    CGRect frame = CGRectNull;
    UIWindow *window = keyboard.window;
    if (window) {
        frame = [window convertRect:keyboard.frame toWindow:nil];
    } else {
        frame = keyboard.frame;
    }
    return frame;
}

- (UIView *)keyboardView {
    UIWindow *window = nil;
    UIView *view = nil;
    for (window in [UIApplication sharedApplication].windows) {
        view = [self _getKeyboardViewFromWindow:window];
        if (view) return view;
    }
    window = [UIApplication sharedApplication].keyWindow;
    view = [self _getKeyboardViewFromWindow:window];
    if (view) return view;
    return nil;
}



- (CGRect)convertRect:(CGRect)rect toView:(UIView *)view {
    if (CGRectIsNull(rect)) return rect;
    if (CGRectIsInfinite(rect)) return rect;
    
    UIWindow *mainWindow = [UIApplication sharedApplication].keyWindow;
    if (!mainWindow) mainWindow = [UIApplication sharedApplication].windows.firstObject;
    if (!mainWindow) { // no window ?!
        if (view) {
            [view convertRect:rect fromView:nil];
        } else {
            return rect;
        }
    }
    
    rect = [mainWindow convertRect:rect fromWindow:nil];
    if (!view) return [mainWindow convertRect:rect toWindow:nil];
    if (view == mainWindow) return rect;
    
    UIWindow *toWindow = [view isKindOfClass:[UIWindow class]] ? (id)view : view.window;
    if (!mainWindow || !toWindow) return [mainWindow convertRect:rect toView:view];
    if (mainWindow == toWindow) return [mainWindow convertRect:rect toView:view];
    
    // in different window
    rect = [mainWindow convertRect:rect toView:mainWindow];
    rect = [toWindow convertRect:rect fromWindow:mainWindow];
    rect = [view convertRect:rect fromView:toWindow];
    return rect;
}


@end

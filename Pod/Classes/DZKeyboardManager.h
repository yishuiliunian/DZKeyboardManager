//
//  DZKeyboardManager.h
//  ChengYi
//
//  Created by stonedong on 16/2/18.
//  Copyright © 2016年 stonedong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

OBJC_ENUM(NSUInteger, DZKeyboardTransitionType) {
    DZKeyboardTransitionShow,
    DZKeyboardTransitionHidden
};

typedef struct  {
    CGRect startFrame;
    CGRect endFrame;
    UIViewAnimationCurve animationCurve;
    NSTimeInterval animationDuration;
    enum DZKeyboardTransitionType type;
} DZKeyboardTransition ;


@protocol DZKeyboardChangedProtocol <NSObject>

- (void) keyboardChanged:(DZKeyboardTransition)transition;

@end

#define DZKeyboardShareManager [DZKeyboardManager shareManager]

@interface DZKeyboardManager : NSObject
+ (instancetype) shareManager;
- (void) addObserver:(id<DZKeyboardChangedProtocol>)observer;
- (void) removeObserver:(id<DZKeyboardChangedProtocol>)observer;

- (CGRect)convertRect:(CGRect)rect toView:(UIView *)view;
@end

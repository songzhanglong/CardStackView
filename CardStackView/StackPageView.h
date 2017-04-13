//
//  StackPageView.h
//  CardStackView
//
//  Created by nanmi on 2017/4/11.
//  Copyright © 2017年 nanmi. All rights reserved.
//

#import <UIKit/UIKit.h>
@class StackPageView;

@protocol StackPageViewDelegate <NSObject>

- (UIView *)stackView:(StackPageView *)stackView pageForIndex:(NSInteger)index;
- (NSInteger)numberOfPagesForStackView:(StackPageView *)stackView;
- (void)stackView:(StackPageView *)stackView selectedPageAtIndex:(NSInteger)index;

@optional
- (CGFloat)heightForBigRow;
- (CGFloat)heightForSmallRow;

@end

@interface StackPageView : UIView

@property (nonatomic,assign)id<StackPageViewDelegate> delegate;

- (UIView *)dequeueReusablePage;

@end

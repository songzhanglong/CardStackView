//
//  StackPageView2.m
//  CardStackView
//
//  Created by nanmi on 2017/4/12.
//  Copyright © 2017年 nanmi. All rights reserved.
//

#import "StackPageView2.h"
#import "UIColor+CatColors.h"

#define SMALL_HEIGHT    80.0
#define BIG_HEIGHT      ([UIScreen mainScreen].bounds.size.height - 2 * SMALL_HEIGHT)
#define TOP_MARGIN      20.0


@interface StackPageView2()

@property (nonatomic,assign)NSInteger selectedPageIndex;
@property (nonatomic,strong)NSMutableArray *pages;
@property (nonatomic,assign)CGPoint beginPoint;
@property (nonatomic,assign)CGFloat bigHeight;
@property (nonatomic,assign)CGFloat smallHeight;
@property (nonatomic,assign)BOOL isUp;

@end

@implementation StackPageView2

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.selectedPageIndex = 0;
        self.pages = [NSMutableArray array];
        self.smallHeight = SMALL_HEIGHT;
        self.bigHeight = BIG_HEIGHT;
        CGFloat yOri = 0;
        for (NSInteger i = 0; i < 8; i++) {
            UIImageView *view = [[UIImageView alloc] initWithFrame:CGRectMake(0, yOri, frame.size.width, (i == 0) ? _bigHeight : _smallHeight)];
            [view setImage:[UIImage imageNamed:[NSString stringWithFormat:@"demo%ld.jpg",(long)i + 1]]];
            [view setUserInteractionEnabled:YES];
            [view setContentMode:UIViewContentModeScaleAspectFill];
            [view setClipsToBounds:YES];
            [self addSubview:view];
            
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
            [view addGestureRecognizer:tap];
            
            [self.pages addObject:view];
            
            yOri += view.frame.size.height;
        }
        
        for (NSInteger i = 0; i < 2; i++) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, yOri, frame.size.width, SMALL_HEIGHT)];
            [label setText:(i == 0) ? @"愿望清单" : @"寻找销售店铺"];
            [label setBackgroundColor:[UIColor blackColor]];
            [label setTextAlignment:NSTextAlignmentCenter];
            [label setTextColor:[UIColor whiteColor]];
            [self.pages addObject:label];
            [self addSubview:label];
            
            yOri += label.frame.size.height;
        }
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)];
        [self addGestureRecognizer:pan];
    }
    return self;
}

- (void)tapped:(UIGestureRecognizer*)sender
{
    UIView *page = [sender view];
    NSInteger index = [self.pages indexOfObject:page];
    if (self.selectedPageIndex != index) {
        self.selectedPageIndex = index;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        
        NSInteger start = self.selectedPageIndex;
        UIView *page = [self.pages objectAtIndex:start];
        CGRect pageRect = page.frame;
        pageRect.origin.y = 0;
        pageRect.size.height = self.bigHeight;
        page.frame = pageRect;
        
        CGFloat yOri = pageRect.origin.y + pageRect.size.height;
        for (NSInteger i = start + 1; i < [self.pages count]; i++) {
            UIView *nextPage = [self.pages objectAtIndex:i];
            CGRect tmpRc = nextPage.frame;
            tmpRc.origin.y = yOri;
            tmpRc.size.height = _smallHeight;
            [nextPage setFrame:tmpRc];
            
            yOri += tmpRc.size.height;
        }
        
        yOri = pageRect.origin.y;
        for (NSInteger i = start - 1; i >= 0; i--) {
            UIView *prePage = [self.pages objectAtIndex:i];
            CGRect tmpRc = prePage.frame;
            tmpRc.origin.y = yOri - _bigHeight;
            tmpRc.size.height = _bigHeight;
            [prePage setFrame:tmpRc];
            
            yOri -= tmpRc.size.height;
        }
    } completion:^(BOOL finished) {
        
    }];
}

- (void)panned:(UIPanGestureRecognizer*)recognizer
{
    UIView *page = [recognizer view];
    CGPoint translation = [recognizer locationInView:page];
    [self bringSubviewToFront:page];
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.beginPoint = translation;
        self.isUp = NO;
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged){
        UIView *curView = [self.pages objectAtIndex:_selectedPageIndex];
        CGRect pageFrame = curView.frame;
        pageFrame.origin.y += translation.y - _beginPoint.y;
        if (pageFrame.origin.y <= -_bigHeight){
            if (self.selectedPageIndex < [self.pages count] - 1) {
                self.selectedPageIndex++;
            }
        }
        else if (pageFrame.origin.y < 0) {
            pageFrame.size.height = _bigHeight;
            if (self.selectedPageIndex == [self.pages count] - 3) {
                pageFrame.origin.y = 0;
            }
            else{
                CGFloat tmpPreY = pageFrame.origin.y + pageFrame.size.height;
                CGFloat changeHei = _bigHeight - tmpPreY * (_bigHeight - _smallHeight) / _bigHeight;
                for (NSInteger i = _selectedPageIndex + 1; i < [self.pages count]; i++) {
                    UIView *nextPage = self.pages[i];
                    CGRect tmpRect = nextPage.frame;
                    tmpRect.origin.y = tmpPreY;
                    if (i == _selectedPageIndex + 1) {
                        tmpRect.size.height = changeHei;
                    }
                    
                    nextPage.frame = tmpRect;
                    tmpPreY += tmpRect.size.height;
                }
                
                CGFloat yOri = pageFrame.origin.y;
                for (NSInteger i = _selectedPageIndex - 1; i >= 0; i--) {
                    UIView *prePage = [self.pages objectAtIndex:i];
                    CGRect tmpRc = prePage.frame;
                    tmpRc.origin.y = yOri - _bigHeight;
                    tmpRc.size.height = _bigHeight;
                    [prePage setFrame:tmpRc];
                    
                    yOri -= tmpRc.size.height;
                }
            }
            
        }
        else if (pageFrame.origin.y >= _bigHeight){
            pageFrame.size.height = _smallHeight;
            //往前第2个视图
            if (self.selectedPageIndex > 0) {
                self.selectedPageIndex--;
            }
        }
        else{
            if (self.selectedPageIndex == 0) {
                //限制上边空白
                if (pageFrame.origin.y > TOP_MARGIN) {
                    pageFrame.origin.y = TOP_MARGIN;
                }
            }
            
            CGFloat changeHei = pageFrame.origin.y * (_bigHeight - _smallHeight) / _bigHeight;
            pageFrame.size.height = _bigHeight - changeHei;
            
            CGFloat tmpPreY = pageFrame.origin.y + pageFrame.size.height;
            for (NSInteger i = _selectedPageIndex + 1; i < [self.pages count]; i++) {
                UIView *nextPage = self.pages[i];
                CGRect tmpRect = nextPage.frame;
                tmpRect.origin.y = tmpPreY;
                
                nextPage.frame = tmpRect;
                tmpPreY += tmpRect.size.height;
            }
            
            CGFloat yOri = pageFrame.origin.y;
            for (NSInteger i = _selectedPageIndex - 1; i >= 0; i--) {
                UIView *prePage = [self.pages objectAtIndex:i];
                CGRect tmpRc = prePage.frame;
                tmpRc.origin.y = yOri - _bigHeight;
                tmpRc.size.height = _bigHeight;
                [prePage setFrame:tmpRc];
                
                yOri -= tmpRc.size.height;
            }

        }
        
        //尾部视图判断是否添加
        
        if ([curView isDescendantOfView:self]) {
            curView.frame = pageFrame;
        }
        
        self.isUp = (translation.y < self.beginPoint.y);
        self.beginPoint = translation;
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (_isUp) {
            self.selectedPageIndex = MIN(_selectedPageIndex + 1, [self.pages count] - 1 - 2);
        }
        else{
            UIView *page = [self.pages objectAtIndex:self.selectedPageIndex];
            if (!CGRectContainsPoint(page.frame, CGPointZero)) {
                self.selectedPageIndex = MAX(_selectedPageIndex - 1, 0);
            }
            
        }
        [UIView animateWithDuration:0.3 animations:^{
            
            NSInteger start = self.selectedPageIndex;
            UIView *page = [self.pages objectAtIndex:start];
            CGRect pageRect = page.frame;
            pageRect.origin.y = 0;
            pageRect.size.height = self.bigHeight;
            page.frame = pageRect;
            
            CGFloat yOri = pageRect.origin.y + pageRect.size.height;
            for (NSInteger i = start + 1; i < [self.pages count]; i++) {
                UIView *nextPage = [self.pages objectAtIndex:i];
                CGRect tmpRc = nextPage.frame;
                tmpRc.origin.y = yOri;
                tmpRc.size.height = _smallHeight;
                [nextPage setFrame:tmpRc];
                
                yOri += tmpRc.size.height;
            }
            
            yOri = pageRect.origin.y;
            for (NSInteger i = start - 1; i >= 0; i--) {
                UIView *prePage = [self.pages objectAtIndex:i];
                CGRect tmpRc = prePage.frame;
                tmpRc.origin.y = yOri - _bigHeight;
                tmpRc.size.height = _bigHeight;
                [prePage setFrame:tmpRc];
                
                yOri -= tmpRc.size.height;
            }
        } completion:^(BOOL finished) {
            
        }];
    }
}

@end

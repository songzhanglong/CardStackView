//
//  StackPageView.m
//  CardStackView
//
//  Created by nanmi on 2017/4/11.
//  Copyright © 2017年 nanmi. All rights reserved.
//

#import "StackPageView.h"

#define SMALL_HEIGHT    80
#define BIG_HEIGHT      200
#define TOP_MARGIN      20.0

@interface StackPageView ()

@property (nonatomic,strong)NSMutableArray *reusablePages;
@property (nonatomic,assign)NSInteger selectedPageIndex;
@property (nonatomic,assign)NSInteger pageCount;
@property (nonatomic,strong)NSMutableArray *pages;
@property (nonatomic,assign)NSRange visiblePages;
@property (nonatomic,assign)CGFloat bigHeight;
@property (nonatomic,assign)CGFloat smallHeight;
@property (nonatomic,assign)CGPoint beginPoint;
@property (nonatomic,assign)BOOL isUpDirect;

@end


@implementation StackPageView

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.pageCount > 0) {
        return;
    }
    
    if (self.delegate) {
        self.pageCount = [self.delegate numberOfPagesForStackView:self];
        
        if ([self.delegate respondsToSelector:@selector(heightForBigRow)]) {
            self.bigHeight = [self.delegate heightForBigRow];
        }
        
        if ([self.delegate respondsToSelector:@selector(heightForSmallRow)]) {
            self.smallHeight = [self.delegate heightForSmallRow];
        }
    }
    
    [self.reusablePages removeAllObjects];
    self.visiblePages = NSMakeRange(0, 0);
    
    for (NSInteger i = 0; i < [self.pages count]; i++) {
        [self removePageAtIndex:i];
    }
    
    [self.pages removeAllObjects];
    
    for (NSInteger i = 0; i < self.pageCount; i++) {
        [self.pages addObject:[NSNull null]];
    }
    
    if (self.selectedPageIndex == -1) {
        self.selectedPageIndex = 0;
    }
    
    
    [self calculateVisibleRowsByStop];
    [self reloadVisiblePagesAtInit];
}

#pragma mark - setup
- (void)setup
{
    self.bigHeight = BIG_HEIGHT;
    self.smallHeight = SMALL_HEIGHT;
    
    self.pageCount = 0;
    self.selectedPageIndex = -1;
    
    self.pages = [NSMutableArray array];
    self.reusablePages = [NSMutableArray array];
    self.visiblePages = NSMakeRange(0, 0);
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)];
    [self addGestureRecognizer:pan];
}

#pragma mark - reload
//初始化时的页面加载
- (void)reloadVisiblePagesAtInit
{
    NSInteger start = self.selectedPageIndex;
    NSInteger endIndex = start + _visiblePages.length - 1;
    for (NSInteger i = start; i <= endIndex; i++) {
        [self setPageAtIndex:i frame:CGRectNull];
    }
    
    for (NSInteger i = 0; i < start; i++) {
        [self removePageAtIndex:i];
    }
    
    for (NSInteger i = endIndex + 1; i < [self.pages count]; i++) {
        [self removePageAtIndex:i];
    }
}

//动画停止时的页面加载
- (void)reloadVisiblePagesAtAnimationStop
{
    UIView *firstPage = self.pages[self.selectedPageIndex],*lastPage = nil;
    NSInteger firIdx = 0,lastIdx = 0;
    for (NSInteger i = _selectedPageIndex - 1; i >= 0; i--) {
        UIView *subPage = self.pages[i];
        if ((NSObject *)subPage == [NSNull null]) {
            break;
        }
        firstPage = subPage;
        firIdx = i;
    }
    for (NSInteger i = _selectedPageIndex; i < [self.pages count]; i++) {
        UIView *subPage = self.pages[i];
        if ((NSObject *)subPage == [NSNull null]) {
            break;
        }
        lastPage = subPage;
        lastIdx = i;
    }
    
    for (NSInteger i = firIdx - 1; i >= (NSInteger)_visiblePages.location; i--) {
        [self setPageAtIndex:i frame:CGRectMake(0, firstPage.frame.origin.y - _bigHeight, CGRectGetWidth(self.frame), _bigHeight)];
        firstPage = self.pages[i];
    }
    
    for (NSInteger i = lastIdx + 1; i <= MIN(_visiblePages.length + _visiblePages.location - 1, self.pageCount - 1); i++) {
        [self setPageAtIndex:i frame:CGRectMake(0, lastPage.frame.origin.y + lastPage.frame.size.height, CGRectGetWidth(self.frame), _smallHeight)];
        lastPage = self.pages[i];
    }
}

#pragma mark - range
//停止时的可见区域计算
- (void)calculateVisibleRowsByStop
{
    if (self.pages == 0) {
        return;
    }
    //初始为0
    NSInteger start = self.selectedPageIndex;
    //除去第一行，剩下的可见行数
    CGFloat residueHei = CGRectGetHeight(self.frame) - self.bigHeight;
    NSInteger number = ceilf(residueHei / self.smallHeight) + 1 + 1;
    if (start > 0) {
        start--;
        number++;
    }
    
    //多加一行，避免突兀
    self.visiblePages = NSMakeRange(start, MIN(self.pageCount - start, number));
}

//移动时的可见区域计算
- (void)calculateVisibleByMoving:(CGFloat)offsetY
{
    if (self.pages == 0) {
        return;
    }
    
    //计算原则：让上下显示行之外再加一行
    NSInteger start = self.selectedPageIndex;
    UIView *page = [self.pages objectAtIndex:start];
    CGFloat residueHei = CGRectGetHeight(self.frame) - page.frame.origin.y - page.frame.size.height;
    //后面多加一行，滑动到最后一行时，让客户无感知
    NSInteger number = ceilf(residueHei / self.smallHeight) + 1 + 1;
    if (start > 0) {
        start--;
        number++;
        if (offsetY > 0) {
            //此时上面应该多加一行，因为当前行上一行已出现，故再上一行可以加载了
            if (start > 0) {
                start--;
                number++;
            }
        }
    }
    
    //多加一行，避免突兀
    self.visiblePages = NSMakeRange(start, MIN(self.pageCount - start, number));
}

- (void)relayoutSubViews:(CGRect)curRect Hei:(CGFloat)newHei
{
    //newHei，紧邻当前页下一个页面的高度，如当前页y坐标<0，则为重新计算的高度，如>0，则为最低高度
    CGFloat tmpPreY = curRect.origin.y + curRect.size.height;
    for (NSInteger i = _selectedPageIndex + 1; i <= _visiblePages.location + _visiblePages.length - 1; i++) {
        UIView *nextPage = self.pages[i];
        CGRect tmpRect = CGRectZero;
        if ((NSObject *)nextPage == [NSNull null]) {
            //新增的可见区域
            [self setPageAtIndex:i frame:CGRectMake(0, tmpPreY, CGRectGetWidth(self.frame), _smallHeight)];
            nextPage = self.pages[i];
            tmpRect = nextPage.frame;
        }
        else{
            tmpRect = nextPage.frame;
            tmpRect.origin.y = tmpPreY;
            if (i == _selectedPageIndex + 1) {
                tmpRect.size.height = newHei;
            }
            nextPage.frame = tmpRect;
        }
        tmpPreY += tmpRect.size.height;
    }
    
    tmpPreY = curRect.origin.y;
    for (NSInteger i = _selectedPageIndex - 1; i >= (NSInteger)_visiblePages.location; i--) {
        UIView *prePage = [self.pages objectAtIndex:i];
        if ((NSObject *)prePage == [NSNull null]) {
            [self setPageAtIndex:i frame:CGRectMake(0, tmpPreY - _bigHeight, CGRectGetWidth(self.frame), _bigHeight)];
            prePage = self.pages[i];
        }
        CGRect tmpRc = prePage.frame;
        tmpRc.origin.y = tmpPreY - _bigHeight;
        tmpRc.size.height = _bigHeight;
        [prePage setFrame:tmpRc];
        
        tmpPreY -= tmpRc.size.height;
    }
}

- (void)setPageAtIndex:(NSInteger)index frame:(CGRect)frame
{
    if (index >= 0 && index < [self.pages count]) {
        UIView *page = [self.pages objectAtIndex:index];
        if ((!page || (NSObject*)page == [NSNull null]) && self.delegate) {
            page = [self.delegate stackView:self pageForIndex:index];
            [self.pages replaceObjectAtIndex:index withObject:page];
            if (CGRectIsNull(frame)) {
                CGFloat yOri = (index == _selectedPageIndex) ? 0 : (_bigHeight + (index - _selectedPageIndex - 1) * _smallHeight);
                CGFloat tmpHei = (index == _selectedPageIndex) ? _bigHeight : _smallHeight;
                page.frame = CGRectMake(0.f, yOri, CGRectGetWidth(self.bounds), tmpHei);
            }
            else{
                page.frame = frame;
            }
            //page.layer.zPosition = index;
        }
        
        if (![page superview]) {
            if ((index == 0 || [self.pages objectAtIndex:index - 1] == [NSNull null]) && index + 1 < [self.pages count]) {
                UIView *topPage = [self.pages objectAtIndex:index + 1];
                [self insertSubview:page belowSubview:topPage];
            } else {
                [self addSubview:page];
            }
        }
        
        if ([page.gestureRecognizers count] < 1) {
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
            [page addGestureRecognizer:tap];
        }
    }
}

#pragma mark - reuse methods
- (void)enqueueReusablePage:(UIView *)page
{
    if ([self.reusablePages count] > 2) {
        [self.reusablePages replaceObjectAtIndex:1 withObject:page];
    }
    else{
        [self.reusablePages addObject:page];
    }
}

- (UIView *)dequeueReusablePage
{
    UIView *page = [self.reusablePages lastObject];
    if (page && (NSObject *)page != [NSNull null]) {
        [self.reusablePages removeObject:page];
        return page;
    }
    return nil;
}

- (void)removePageAtIndex:(NSInteger)index
{
    if (index < 0 || index >= self.pageCount) {
        return;
    }
    
    UIView *page = [self.pages objectAtIndex:index];
    if (page && (NSObject *)page != [NSNull null]) {
        [page removeFromSuperview];
        [self enqueueReusablePage:page];
        [self.pages replaceObjectAtIndex:index withObject:[NSNull null]];
    }
}

#pragma mark - gesture recognizer
- (void)tapped:(UIGestureRecognizer*)sender
{
    UIView *page = [sender view];
    NSInteger index = [self.pages indexOfObject:page];
    if (self.selectedPageIndex == index) {
        return;
    }
    
    self.selectedPageIndex = index;
    [self playEndAnimation];
}

- (void)panned:(UIPanGestureRecognizer*)recognizer
{
    UIView *page = [recognizer view];
    CGPoint curPoint = [recognizer locationInView:page];
    [self bringSubviewToFront:page];
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.beginPoint = curPoint;
        self.isUpDirect = NO;
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged){
        UIView *curView = [self.pages objectAtIndex:_selectedPageIndex];
        CGRect pageFrame = curView.frame;
        pageFrame.origin.y += curPoint.y - _beginPoint.y;
        if (pageFrame.origin.y <= -_bigHeight){
            //上滑过最上面一页高度，当前页往下加1
            if (self.selectedPageIndex < self.pageCount - 1) {
                self.selectedPageIndex++;
            }
        }
        else if (pageFrame.origin.y < 0) {
            //上滑不超过一个视图，此时往下一个视图高度渐变
            pageFrame.size.height = _bigHeight;
            
            CGFloat tmpPreY = pageFrame.origin.y + pageFrame.size.height;
            CGFloat changeHei = _bigHeight - tmpPreY * (_bigHeight - _smallHeight) / _bigHeight;
            [self relayoutSubViews:pageFrame Hei:changeHei];
        }
        else if (pageFrame.origin.y >= _bigHeight){
            //下滑超过最上面一页高度，当前页往上移动一位
            pageFrame.size.height = _smallHeight;
            if (self.selectedPageIndex > 0) {
                self.selectedPageIndex--;
            }
        }
        else{
            //下滑不超过最上面一页高度，调整当前页高度
            if (self.selectedPageIndex == 0) {
                //限制上边空白
                if (pageFrame.origin.y > TOP_MARGIN) {
                    pageFrame.origin.y = TOP_MARGIN;
                }
            }
            
            CGFloat changeHei = pageFrame.origin.y * (_bigHeight - _smallHeight) / _bigHeight;
            pageFrame.size.height = _bigHeight - changeHei;
            [self relayoutSubViews:pageFrame Hei:_smallHeight];
        }
        
        //尾部视图判断是否添加
        
        if ([curView isDescendantOfView:self]) {
            curView.frame = pageFrame;
        }
        
        //重新计算可视区域数据
        [self calculateVisibleByMoving:pageFrame.origin.y];
        
        self.isUpDirect = (curPoint.y < self.beginPoint.y);
        self.beginPoint = curPoint;
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        if (_isUpDirect) {
            self.selectedPageIndex = MIN(_selectedPageIndex + 1, [self.pages count] - 1);
        }
        else{
            UIView *page = [self.pages objectAtIndex:self.selectedPageIndex];
            if (!CGRectContainsPoint(page.frame, CGPointZero)) {
                self.selectedPageIndex = MAX(_selectedPageIndex - 1, 0);
            }
        }
        
        [self playEndAnimation];
    }
}

#pragma mark - end animation
- (void)playEndAnimation
{
    [self calculateVisibleRowsByStop];
    [self reloadVisiblePagesAtAnimationStop];
    
    self.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.3 animations:^{
        [self resetVisiblePagesLocation];
    } completion:^(BOOL finished) {
        NSInteger endIndex = _visiblePages.location + _visiblePages.length - 1;
        for (NSInteger i = 0; i < _visiblePages.location; i++) {
            [self removePageAtIndex:i];
        }
        
        for (NSInteger i = endIndex + 1; i < [self.pages count]; i++) {
            [self removePageAtIndex:i];
        }
        
        self.userInteractionEnabled = YES;
    }];
}

- (void)resetVisiblePagesLocation
{
    NSInteger start = self.selectedPageIndex;
    UIView *page = [self.pages objectAtIndex:start];
    CGRect pageRect = page.frame;
    pageRect.origin.y = 0;
    pageRect.size.height = self.bigHeight;
    page.frame = pageRect;
    
    CGFloat yOri = pageRect.origin.y + pageRect.size.height;
    for (NSInteger i = start + 1; i < _visiblePages.location + _visiblePages.length; i++) {
        UIView *nextPage = [self.pages objectAtIndex:i];
        CGRect tmpRc = nextPage.frame;
        tmpRc.origin.y = yOri;
        tmpRc.size.height = _smallHeight;
        [nextPage setFrame:tmpRc];
        
        yOri += tmpRc.size.height;
    }
    
    yOri = pageRect.origin.y;
    for (NSInteger i = start - 1; i >= (NSInteger)_visiblePages.location; i--) {
        UIView *prePage = [self.pages objectAtIndex:i];
        CGRect tmpRc = prePage.frame;
        tmpRc.origin.y = yOri - _bigHeight;
        tmpRc.size.height = _bigHeight;
        [prePage setFrame:tmpRc];
        
        yOri -= tmpRc.size.height;
    }
}

@end

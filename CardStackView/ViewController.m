//
//  ViewController.m
//  CardStackView
//
//  Created by nanmi on 2017/4/11.
//  Copyright © 2017年 nanmi. All rights reserved.
//

#import "ViewController.h"
#import "StackPageView.h"
#import "StackPageView2.h"
#import "UIColor+CatColors.h"
#import "CustomLayout.h"

#define COLLECTIONCELLID @"customCellId"

@interface ViewController ()<StackPageViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic,strong)StackPageView *pageView;
@property (nonatomic,strong)StackPageView2 *pageView2;
@property (nonatomic,strong)UICollectionView *collectionView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.view addSubview:self.collectionView];
}

#pragma mark - StackPageViewDelegate
- (UIView *)stackView:(StackPageView *)stackView pageForIndex:(NSInteger)index
{
    UIView *thisView = [stackView dequeueReusablePage];
    if (!thisView) {
        thisView = [UIView new];
        thisView.backgroundColor = [UIColor getRandomColor];
    }
    return thisView;
}

- (NSInteger)numberOfPagesForStackView:(StackPageView *)stackView
{
    return 25;
}

- (void)stackView:(StackPageView *)stackView selectedPageAtIndex:(NSInteger)index
{
    
}

#pragma mark - UICollectionView Delegate / DataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return 25;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:COLLECTIONCELLID forIndexPath:indexPath];
    UIView *subView = [cell.contentView viewWithTag:1];
    if (!subView) {
        subView = [[UIView alloc] initWithFrame:cell.bounds];
        [subView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [subView setTag:1];
        [cell.contentView addSubview:subView];
    }
    [subView setBackgroundColor:[UIColor getRandomColor]];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"%ld",(long)indexPath.item);
}

#pragma mark - lazy load
- (StackPageView *)pageView
{
    if (!_pageView) {
        _pageView = [[StackPageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _pageView.delegate = self;
    }
    return _pageView;
}

- (StackPageView2 *)pageView2
{
    if (!_pageView2) {
        _pageView2 = [[StackPageView2 alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
    return _pageView2;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        CustomLayout *layout                = [[CustomLayout alloc] init];
        _collectionView                 = [[UICollectionView alloc] initWithFrame:[UIScreen mainScreen].bounds collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor yellowColor];
        _collectionView.dataSource      = self;
        _collectionView.delegate        = self;
        [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:COLLECTIONCELLID];
    }
    return _collectionView;
}

@end

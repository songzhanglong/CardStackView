//
//  CustomLayout.m
//  CardStackView
//
//  Created by nanmi on 2017/4/12.
//  Copyright © 2017年 nanmi. All rights reserved.
//

#import "CustomLayout.h"

#define SMALL_HEIGHT    80.0
#define BIG_HEIGHT      320.0
#define TOP_MARGIN      20.0

@interface CustomLayout ()

@property (nonatomic,strong)NSMutableArray *allItemAttributes;

@end

@implementation CustomLayout

- (id)init
{
    self = [super init];
    if (self) {
        self.allItemAttributes = [NSMutableArray array];
    }
    
    return self;
}

- (void)prepareLayout
{
    [super prepareLayout];
    
    if (_largeSize.height == 0) {
        _largeSize = CGSizeMake(CGRectGetWidth(self.collectionView.frame), BIG_HEIGHT);
    }
    
    if (_smallSize.height == 0) {
        _smallSize = CGSizeMake(CGRectGetWidth(self.collectionView.frame), SMALL_HEIGHT);
    }
    
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, CGRectGetHeight(self.collectionView.frame) - _largeSize.height - 2 * _smallSize.height, 0);
    
    NSInteger count = [self.collectionView numberOfItemsInSection:0];
    for (NSInteger idx = 0; idx < count; idx++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:0];
        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        attributes.size = (indexPath.item == 0) ? _largeSize : _smallSize;
        CGFloat centerY = (indexPath.item == 0) ? (_largeSize.height / 2) : (_largeSize.height + (indexPath.item - 1) * _smallSize.height + _smallSize.height / 2);
        attributes.center = CGPointMake(CGRectGetMidX(self.collectionView.frame), centerY);
        attributes.zIndex = count - idx;
        [_allItemAttributes addObject:attributes];
    }
}

- (CGSize)collectionViewContentSize
{
    NSInteger cellCount = [self.collectionView numberOfItemsInSection:0];
    return CGSizeMake(CGRectGetWidth(self.collectionView.frame), MAX((cellCount - 2), 0) * _largeSize.height + _smallSize.height * 2);
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [_allItemAttributes objectAtIndex:indexPath.item];
}

- (BOOL)shouldInvalidateLayoutForPreferredLayoutAttributes:(UICollectionViewLayoutAttributes *)preferredAttributes withOriginalAttributes:(UICollectionViewLayoutAttributes *)originalAttributes
{
    
    return YES;
}
- (nullable NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSInteger index = self.collectionView.contentOffset.y / _largeSize.height;
    CGFloat leaveY = self.collectionView.contentOffset.y - _largeSize.height * index;
    NSInteger minIndex = index;
    NSInteger maxIndex = (CGRectGetHeight(self.collectionView.frame) - _largeSize.height + leaveY) / _smallSize.height + 2;
    NSMutableArray *array = [NSMutableArray array];
    
    for (NSInteger i = minIndex; i <= maxIndex; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        UICollectionViewLayoutAttributes *attributes = [_allItemAttributes objectAtIndex:indexPath.item];
        if (i == index) {
            attributes.frame = CGRectMake(0, _largeSize.height * index, _largeSize.width, _largeSize.height);
        }
        else if (i == index + 1){
            CGFloat changeHei = leaveY * (_largeSize.height - _smallSize.height) / _largeSize.height + _smallSize.height;
            UICollectionViewLayoutAttributes *preArr = [array lastObject];
            attributes.frame = CGRectMake(0, preArr.frame.origin.y + preArr.frame.size.height, _largeSize.width, changeHei);
        }
        else{
            UICollectionViewLayoutAttributes *preArr = [array lastObject];
            attributes.frame = CGRectMake(0, preArr.frame.origin.y + preArr.frame.size.height, _smallSize.width, _smallSize.height);
        }
        
        [array addObject:attributes];
    }
    
//    NSInteger cellCount = [self.collectionView numberOfItemsInSection:0];
//    UICollectionViewLayoutAttributes *lastAttribute = [array lastObject];
//    CGFloat yOri = lastAttribute ? (lastAttribute.frame.origin.y + lastAttribute.frame.size.height) : 0;
//    for (NSInteger i = maxIndex + 1; i < cellCount; i++) {
//        UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
//        attributes.frame = CGRectMake(0, yOri, CGRectGetWidth(self.collectionView.frame), _smallSize.height);
//        yOri += _smallSize.height;
//        [array addObject:attributes];
//    }
    
    return array;
}

//- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
//                                 withScrollingVelocity:(CGPoint)velocity {
//    
//    CGFloat index = roundf((( proposedContentOffset.x) + _viewHeight / 2 - _itemHeight / 2) / _itemHeight);
//    
//    proposedContentOffset.x = _itemHeight * index + _itemHeight / 2 - _viewHeight / 2;
//    
//    if (self.carouselSlideIndexBlock) {
//        self.carouselSlideIndexBlock((NSInteger)index);
//    }
//    
//    return proposedContentOffset;
//}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return !CGRectEqualToRect(newBounds, self.collectionView.bounds);
}

@end

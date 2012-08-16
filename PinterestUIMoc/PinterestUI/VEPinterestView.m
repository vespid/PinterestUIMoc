//
//  VEPinterestUIView.m
//  PinterestUIMoc
//
//  Created by Mitsuyoshi Yamazaki on 8/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VEPinterestView.h"
#import <QuartzCore/QuartzCore.h>

static CGFloat const _pinterestViewCellMarginRatio = 0.03f; // ratio of line width to margin
static CGFloat const _pinterestViewCellMinimumHeightRatio = 0.8f; // ratio of line width to minimum cell height
static CGFloat const _pinterestViewCellCornerRadius = 5.0f;
static NSUInteger const _pinterestViewLineCount = 3;
static NSInteger const _pinterestViewTagHeaderView = -1;

@interface VEPinterestView ()
- (void)_initialize;
- (UIView *)_sectionHeaderViewAtSection:(NSUInteger)section;
- (void)_configureCell:(UIView *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)_didSelectCell:(UITapGestureRecognizer *)tapGestureRecognizer;
- (void)_didLongPressCell:(UILongPressGestureRecognizer *)longPressGestureRecognizer;

NSUInteger _shortestLine(CGFloat lineHeight[], NSUInteger lineCount);
NSUInteger _longestLine(CGFloat lineHeight[], NSUInteger lineCount);
CGSize _fitCellSizeToLineWidth(CGSize size, CGFloat lineWidth);
@end

@implementation VEPinterestView

@synthesize delegate;
@synthesize datasource;
@synthesize selectedIndexPath = _selectedIndexPath;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _initialize];
    }
    return self;
}

- (void)_initialize {
	
	_selectedIndexPath = nil;
}

- (void)dealloc
{
    [_selectedIndexPath release], _selectedIndexPath = nil;
	
    [super dealloc];
}

#pragma mark - Reloading
- (void)reloadData {
	
	if (![self.datasource conformsToProtocol:@protocol(VEPinterestViewDatasource)]) {
		[NSException raise:@"もんだいがおきましたほげ" format:@"でーたそーすがないよ"];
	}
	
	NSUInteger sectionCount = [self.datasource numberOfSectionsInPinterestView:self];
	CGFloat sectionHeight = 0.0f;
	CGFloat lineWidth = self.bounds.size.width / 3.0f;
	CGFloat cellMargin = lineWidth * _pinterestViewCellMarginRatio;

	for (NSUInteger section = 0; section < sectionCount; section++) {
	
		UIView *sectionHeaderView = [self _sectionHeaderViewAtSection:section];
		
		CGRect headerViewRect = sectionHeaderView.frame;
		headerViewRect.origin.y += sectionHeight;
		[sectionHeaderView setFrame:headerViewRect];
		
		[self addSubview:sectionHeaderView];
		
		sectionHeight += headerViewRect.size.height + cellMargin * 2.0f;
		
		NSUInteger cellCount = [self.datasource numberOfCellsInPinterestView:self section:section];
		CGFloat lineHeight[_pinterestViewLineCount];
		
		for (NSUInteger lineIndex = 0; lineIndex < _pinterestViewLineCount; lineIndex++) {
			lineHeight[lineIndex] = sectionHeight;
		}

		for (NSUInteger cellIndex = 0; cellIndex < cellCount; cellIndex++) {
			
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:cellIndex inSection:section];
			CGSize cellSize = [self.datasource sizeOfCellInPinterestView:self atIndexPath:indexPath];
			cellSize = _fitCellSizeToLineWidth(cellSize, lineWidth);
			
			NSUInteger shortestLineIndex = _shortestLine(lineHeight, _pinterestViewLineCount);
				
			CGRect cellBackgroundRect;
			cellBackgroundRect.origin.x = shortestLineIndex * lineWidth + cellMargin - 1.0f;
			cellBackgroundRect.origin.y = lineHeight[shortestLineIndex] + cellMargin - 1.0f;
			cellBackgroundRect.size.width = cellSize.width - cellMargin * 2 + 2.0f;
			cellBackgroundRect.size.height = cellSize.height - cellMargin * 2 + 2.0f;
			
			CGRect cellRect = cellBackgroundRect;
			cellRect.origin = CGPointMake(1.0f, 1.0f);
			cellRect.size.width -= 2.0f;
			cellRect.size.height -= 2.0f;
			
			UIView *cellBackgroundView = [[UIView alloc] initWithFrame:cellBackgroundRect];
			cellBackgroundView.backgroundColor = [UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:0.2f];
			cellBackgroundView.clipsToBounds = YES;
			cellBackgroundView.layer.cornerRadius = _pinterestViewCellCornerRadius + 1.0f;
			cellBackgroundView.tag = indexPath.section;
			
			UIView *cell = [[UIView alloc] initWithFrame:cellRect];
			cell.tag = indexPath.row;
			
			[self _configureCell:cell atIndexPath:indexPath];
			
			[cellBackgroundView addSubview:cell];
			[cell release];
			
			[self addSubview:cellBackgroundView];
			[cellBackgroundView release];
						
			lineHeight[shortestLineIndex] += cellSize.height;
		}
		
		NSUInteger longestLineIndex = _longestLine(lineHeight, _pinterestViewLineCount);
		sectionHeight = lineHeight[longestLineIndex];		
	}	
	
	CGSize contentSize = self.contentSize;
	contentSize.height = sectionHeight;
	self.contentSize = contentSize;
}

- (void)_configureCell:(UIView *)cell atIndexPath:(NSIndexPath *)indexPath {
		
	cell.backgroundColor = [UIColor clearColor];
	cell.clipsToBounds = YES;
	cell.layer.cornerRadius = _pinterestViewCellCornerRadius;
	
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_didSelectCell:)];
	[cell addGestureRecognizer:tapGestureRecognizer];
	[tapGestureRecognizer release];
	
	UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_didLongPressCell:)];
	[cell addGestureRecognizer:longPressGestureRecognizer];
	[longPressGestureRecognizer release];
	
	[self.datasource pinterestView:self configureCell:cell atIndexPath:indexPath];
}

- (UIView *)_sectionHeaderViewAtSection:(NSUInteger)section {
	
	CGFloat lineWidth = self.bounds.size.width / 3.0f;
	CGFloat cellMargin = lineWidth * _pinterestViewCellMarginRatio;
	
	CGRect headerRect;
	headerRect.origin = CGPointMake(cellMargin, cellMargin);
	headerRect.size.width = self.frame.size.width - (cellMargin * 2.0f);
	headerRect.size.height = 30.0f;
	
	UIView *headerView = [[[UIView alloc] initWithFrame:headerRect] autorelease];
	headerView.backgroundColor = [UIColor darkGrayColor];
	headerView.tag = _pinterestViewTagHeaderView;
	headerView.clipsToBounds = YES;
	
	CGRect titleRect = headerRect;
	titleRect.origin = CGPointMake(5.0f, 5.0f);
	titleRect.size.width -= 10.0f;
	titleRect.size.height -= 10.0f;
	
	UILabel *titleLabel = [[UILabel alloc] initWithFrame:titleRect];
	titleLabel.backgroundColor = [UIColor clearColor];
	titleLabel.textAlignment = UITextAlignmentCenter;
	titleLabel.textColor = [UIColor whiteColor];
	
	[headerView addSubview:titleLabel];
	[titleLabel release];
	
	if ([self.datasource respondsToSelector:@selector(pinterestView:titleForHeaderInSection:)]) {
		titleLabel.text = [self.datasource pinterestView:self titleForHeaderInSection:section];
	}
	
	if (titleLabel.text.length) {
		headerView.layer.cornerRadius = 10.0f;
		headerRect.size.height = 30.0f;
		titleLabel.hidden = NO;
	}
	else {
		headerView.layer.cornerRadius = 5.0f;
		headerRect.size.height = 10.0f;
		titleLabel.hidden = YES;
	}
	
	[headerView setFrame:headerRect];
	
	return headerView;
}

#pragma mark - Selection Handler
- (void)_didSelectCell:(UITapGestureRecognizer *)tapGestureRecognizer {
	
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:tapGestureRecognizer.view.tag inSection:tapGestureRecognizer.view.superview.tag];
	
	if ([self.delegate respondsToSelector:@selector(pinterestView:didSelectCellAtIndexPath:)]) {
		[self.delegate pinterestView:self didSelectCellAtIndexPath:indexPath];
	}
}

- (void)_didLongPressCell:(UILongPressGestureRecognizer *)longPressGestureRecognizer {

	if (longPressGestureRecognizer.state == UIGestureRecognizerStateBegan) {
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:longPressGestureRecognizer.view.tag inSection:longPressGestureRecognizer.view.superview.tag];
		
		if ([self.delegate respondsToSelector:@selector(pinterestView:didLongPressCellAtIndexPath:)]) {
			[self.delegate pinterestView:self didLongPressCellAtIndexPath:indexPath];
		}
	}
}


#pragma mark - 
NSUInteger _shortestLine(CGFloat lineHeight[], NSUInteger lineCount) {
	
	NSUInteger index = 0;
	
	for (NSUInteger i = 1; i < lineCount; i++) {
		if (lineHeight[i] < lineHeight[index]) {
			index = i;
		}
	}
	return index;
}

NSUInteger _longestLine(CGFloat lineHeight[], NSUInteger lineCount) {
	
	NSUInteger index = 0;
	
	for (NSUInteger i = 1; i < lineCount; i++) {
		if (lineHeight[i] > lineHeight[index]) {
			index = i;
		}
	}
	return index;
}

CGSize _fitCellSizeToLineWidth(CGSize size, CGFloat lineWidth) {
	
	CGSize fitSize;
	fitSize.width = lineWidth;
	fitSize.height = lineWidth * (size.height / size.width);
	
	CGFloat minimumHeight = lineWidth * _pinterestViewCellMinimumHeightRatio;
	fitSize.height = (fitSize.height < minimumHeight) ? minimumHeight : fitSize.height;
	
	return fitSize;
}

@end

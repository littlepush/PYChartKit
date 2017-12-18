//
//  PYPieChart.h
//  PYChartKit
//
//  Created by Push Chen on 18/12/2017.
//  Copyright © 2017 Push Lab. All rights reserved.
//

#import <PYControllers/PYControllers.h>

@protocol PYPieChartDataSource;

@interface PYPieChart : PYView

// Scale rate when touch on, default is 0.95
@property (nonatomic, assign)   CGFloat         magnification;

// The padding to of the max size to the side, default is 10
@property (nonatomic, assign)   CGFloat         padding;

// If show animation when touch the pie
//@property (nonatomic, assign)   BOOL            allowAnimation;

// DataSource
@property (nonatomic, assign)   id<PYPieChartDataSource>    datasource;

// Reload chart
- (void)reloadChart;

@end

@protocol PYPieChartDataSource <NSObject>

@required
// Each point
- (float)pie:(PYPieChart *)pie valueAtIndex:(NSInteger)index;
// count of the points
- (NSUInteger)partCountOfPie:(PYPieChart *)chart;

@optional
// Default is Random
- (UIColor *)pie:(PYPieChart *)pie colorOfPartAtIndex:(NSInteger)index;

@end


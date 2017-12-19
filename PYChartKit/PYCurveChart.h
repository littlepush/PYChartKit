//
//  PYCurveChart.h
//  PYChart
//
//  Created by Push Chen on 9/15/14.
//  Copyright (c) 2014 PushLab. All rights reserved.
//

/*
 LGPL V3 Lisence
 This file is part of cleandns.
 
 PYChartKit is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 PYData is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with cleandns.  If not, see <http://www.gnu.org/licenses/>.
 */

/*
 LISENCE FOR IPY
 COPYRIGHT (c) 2013, Push Chen.
 ALL RIGHTS RESERVED.
 
 REDISTRIBUTION AND USE IN SOURCE AND BINARY
 FORMS, WITH OR WITHOUT MODIFICATION, ARE
 PERMITTED PROVIDED THAT THE FOLLOWING CONDITIONS
 ARE MET:
 
 YOU USE IT, AND YOU JUST USE IT!.
 WHY NOT USE THIS LIBRARY IN YOUR CODE TO MAKE
 THE DEVELOPMENT HAPPIER!
 ENJOY YOUR LIFE AND BE FAR AWAY FROM BUGS.
 */

#import <UIKit/UIKit.h>
#import <PYUIKit/PYUIKit.h>
#import <PYControllers/PYControllers.h>
//#import "PYCurveChartLayer.h"

// Inhiert from the layer's data source.
@protocol PYCurveChartDataSource;

@interface PYCurveChart : PYView

// Padding for the background and the curve context
// Default left/right padding is 15px, bottom padding is 20px
// top padding is 30px
@property (nonatomic, assign)   UIEdgeInsets    edgeInsets;

// The background image view
@property (nonatomic, readonly) UIImageView *backgroundView;
- (void)setBackgroundImage:(UIImage *)image;

// Round corner rate for each knot.
// should between [0, 1], but can be any value.
@property (nonatomic, assign)   float       tension;

// Coordinate, default is 100, 100
@property (nonatomic, assign)   float       maxXCoordinate;
@property (nonatomic, assign)   float       maxYCoordinate;

// If show the point, default is NO
@property (nonatomic, assign)   BOOL        showPoint;
// Point radius, default is 3
@property (nonatomic, assign)   float       pointRaidus;

// If show the shadow
@property (nonatomic, assign)   BOOL        showShadow;

// The data source
@property (nonatomic, assign)   id<PYCurveChartDataSource>      dataSource;

// Reload the chart
- (void)reloadChart;

// Change to bar mode, will cause reload chart to be invoked.
- (void)changeChartToBarMode;

// Change to curve mode(defualt mode)
- (void)changeChartToCurveMode;

@end

@protocol PYCurveChartDataSource <NSObject>

@required
// Each point
- (CGPoint)pointForChart:(PYCurveChart *)chart atIndexPath:(NSIndexPath *)indexPath;
// count of the points
- (NSUInteger)pointCountOfChart:(PYCurveChart *)chart forCurveAtIndex:(NSUInteger)index;

@optional
// Default is 1
- (NSUInteger)chartCurveCount:(PYCurveChart *)chart;
// Default is 2.f
- (CGFloat)chartLineWidth:(PYCurveChart *)chart forCurveAtIndex:(NSUInteger)index;
// Default is Random
- (UIColor *)chartLineColor:(PYCurveChart *)chart forCurveAtIndex:(NSUInteger)index;
// Default is Random
- (UIColor *)chartPointColor:(PYCurveChart *)chart forCurveAtIndex:(NSUInteger)index;

@end

// @littlepush
// littlepush@gmail.com
// PYLab


//
//  PYCurveChartLayer.h
//  PYChart
//
//  Created by Push Chen on 9/13/14.
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

#import <PYUIKit/PYUIKit.h>
#import <PYControllers/PYControllers.h>

typedef NS_ENUM(NSInteger, PYCurveChartMode)
{
    PYCurveChartModeCurve,
    PYCurveChartModeBar,
};

@protocol PYCurveChartLayerDataSource;

@interface PYCurveChartLayer : PYLayer

// Round corner rate for each knot.
// should between [0, 1], but can be any value.
@property (nonatomic, assign)   float       tension;

// Coordinate
@property (nonatomic, assign)   float       maxXCoordinate;
@property (nonatomic, assign)   float       maxYCoordinate;

@property (nonatomic, assign)   id<PYCurveChartLayerDataSource>      dataSource;

- (void)reloadChart:(BOOL)showPoints;

@property (nonatomic, assign)   BOOL        showPoints;

// If show the shadow
@property (nonatomic, assign)   BOOL        showShadow;

// Point radius, default is 3
@property (nonatomic, assign)   float       pointRaidus;

// Default is PYCurveChartModeCurve
@property (nonatomic, assign)   PYCurveChartMode    chartMode;

@end

@protocol PYCurveChartLayerDataSource <NSObject>

@required
// Each point
- (CGPoint)pointForChart:(PYCurveChartLayer *)chart atIndexPath:(NSIndexPath *)indexPath;
// count of the points
- (NSUInteger)pointCountOfChart:(PYCurveChartLayer *)chart forCurveAtIndex:(NSUInteger)index;

@optional
// Default is 1
- (NSUInteger)chartCurveCount:(PYCurveChartLayer *)chart;
// Default is 2.f
- (CGFloat)chartLineWidth:(PYCurveChartLayer *)chart forCurveAtIndex:(NSUInteger)index;
// Default is Random
- (UIColor *)chartLineColor:(PYCurveChartLayer *)chart forCurveAtIndex:(NSUInteger)index;
// Default is the same to the line color
- (UIColor *)chartPointColor:(PYCurveChartLayer *)chart forCurveAtIndex:(NSUInteger)index;

@end

// @littlepush
// littlepush@gmail.com
// PYLab


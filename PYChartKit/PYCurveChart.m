//
//  PYCurveChart.m
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

#import "PYCurveChart.h"
#import "PYCurveChartLayer.h"

@interface PYCurveChart () < PYCurveChartLayerDataSource >
{
    UIImageView                 *_backgroundImgView;
    // The internal layer
    PYCurveChartLayer           *_chartLayer;
    BOOL                        _showPoint;
    UIEdgeInsets                _edgeInsets;
}
@end

@implementation PYCurveChart

// Padding for the background and the curve context
// Default left/right padding is 15px, bottom padding is 20px
// top padding is 30px
@synthesize edgeInsets = _edgeInsets;
- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets
{
    _edgeInsets = edgeInsets;
    [_chartLayer setFrame:CGRectMake(self.edgeInsets.left, self.edgeInsets.top,
                                     self.frame.size.width - (self.edgeInsets.left + self.edgeInsets.right),
                                     self.frame.size.height - (self.edgeInsets.top + self.edgeInsets.bottom))];
    [_chartLayer reloadChart:_showPoint];
}

// The background image view
@synthesize backgroundView = _backgroundImgView;
- (void)setBackgroundImage:(UIImage *)image
{
    [_backgroundImgView setImage:image];
}

// Round corner rate for each knot.
// should between [0, 1], but can be any value.
@dynamic tension;
- (float)tension
{
    return _chartLayer.tension;
}
- (void)setTension:(float)tension
{
    _chartLayer.tension = tension;
    [_chartLayer reloadChart:self.showPoint];
}

// Coordinate, default is 100, 100
@dynamic maxXCoordinate, maxYCoordinate;
- (float)maxXCoordinate { return _chartLayer.maxXCoordinate; }
- (float)maxYCoordinate { return _chartLayer.maxYCoordinate; }
- (void)setMaxXCoordinate:(float)maxXCoordinate
{
    _chartLayer.maxXCoordinate = maxXCoordinate;
    [_chartLayer reloadChart:self.showPoint];
}
- (void)setMaxYCoordinate:(float)maxYCoordinate
{
    _chartLayer.maxYCoordinate = maxYCoordinate;
    [_chartLayer reloadChart:self.showPoint];
}

// If show the point, default is NO
@dynamic showPoint;
- (BOOL)showPoint { return _showPoint; }
- (void)setShowPoint:(BOOL)showPoint
{
    _showPoint = showPoint;
    [_chartLayer setShowPoints:_showPoint];
    [_chartLayer setNeedsDisplay];
}
// Point radius, default is 3
@dynamic pointRaidus;
- (float)pointRaidus { return _chartLayer.pointRaidus; }
- (void)setPointRaidus:(float)pointRaidus
{
    [_chartLayer setPointRaidus:pointRaidus];
    if ( _showPoint == NO ) return;
    [_chartLayer reloadChart:self.showPoint];
}

// If show the shadow
@dynamic showShadow;
- (BOOL)showShadow { return _chartLayer.showShadow; }
- (void)setShowShadow:(BOOL)showShadow
{
    [_chartLayer setShowShadow:showShadow];
    [_chartLayer setNeedsDisplay];
}

// The data source
@synthesize dataSource;

// Reload the chart
- (void)reloadChart
{
    [_chartLayer reloadChart:self.showPoint];
}

- (void)viewJustBeenCreated
{
    [super viewJustBeenCreated];
    _showPoint = NO;
    self.edgeInsets = UIEdgeInsetsMake(30, 15, 20, 15);
    
    // Background view
    _backgroundImgView = [UIImageView object];
    [_backgroundImgView setFrame:self.bounds];
    [self addChild:_backgroundImgView];
    
    // Chart layer
    _chartLayer = [PYCurveChartLayer layer];
    [_chartLayer setBackgroundColor:[UIColor clearColor].CGColor];
    [_chartLayer setFrame:CGRectMake(self.edgeInsets.left, self.edgeInsets.top,
                                     self.frame.size.width - (self.edgeInsets.left + self.edgeInsets.right),
                                     self.frame.size.height - (self.edgeInsets.top + self.edgeInsets.bottom))];
    _chartLayer.dataSource = self;
    [self addChild:_chartLayer];
    [_chartLayer reloadChart:_showPoint];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [_backgroundImgView setFrame:self.bounds];
    [_chartLayer setFrame:CGRectMake(self.edgeInsets.left, self.edgeInsets.top,
                                     self.frame.size.width - (self.edgeInsets.left + self.edgeInsets.right),
                                     self.frame.size.height - (self.edgeInsets.top + self.edgeInsets.bottom))];
    [_chartLayer reloadChart:_showPoint];
}

// Redirect Data Source for the layer
// Each point
- (CGPoint)pointForChart:(PYCurveChartLayer *)chart atIndexPath:(NSIndexPath *)indexPath
{
    if ( [self.dataSource respondsToSelector:@selector(pointForChart:atIndexPath:)] ) {
        return [self.dataSource pointForChart:self atIndexPath:indexPath];
    }
    return CGPointMake(0, 0);
}
// count of the points
- (NSUInteger)pointCountOfChart:(PYCurveChartLayer *)chart forCurveAtIndex:(NSUInteger)index
{
    if ( [self.dataSource respondsToSelector:@selector(pointCountOfChart:forCurveAtIndex:)] ) {
        return [self.dataSource pointCountOfChart:self forCurveAtIndex:index];
    }
    return 0;
}

// Default is 1
- (NSUInteger)chartCurveCount:(PYCurveChartLayer *)chart
{
    if ( [self.dataSource respondsToSelector:@selector(chartCurveCount:)] ) {
        return [self.dataSource chartCurveCount:self];
    }
    return 1;
}
// Default is 2.f
- (CGFloat)chartLineWidth:(PYCurveChartLayer *)chart forCurveAtIndex:(NSUInteger)index
{
    if ( [self.dataSource respondsToSelector:@selector(chartLineWidth:forCurveAtIndex:)] ) {
        return [self.dataSource chartLineWidth:self forCurveAtIndex:index];
    }
    return 2.f;
}
// Default is Random
- (UIColor *)chartLineColor:(PYCurveChartLayer *)chart forCurveAtIndex:(NSUInteger)index
{
    if ( [self.dataSource respondsToSelector:@selector(chartLineColor:forCurveAtIndex:)] ) {
        return [self.dataSource chartLineColor:self forCurveAtIndex:index];
    }
    return [UIColor randomColor];
}
- (UIColor *)chartPointColor:(PYCurveChartLayer *)chart forCurveAtIndex:(NSUInteger)index
{
    if ( [self.dataSource respondsToSelector:@selector(chartPointColor:forCurveAtIndex:)] ) {
        return [self.dataSource chartPointColor:self forCurveAtIndex:index];
    }
    return [UIColor randomColor];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end

// @littlepush
// littlepush@gmail.com
// PYLab

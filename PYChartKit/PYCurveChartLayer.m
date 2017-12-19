//
//  PYCurveChartLayer.m
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

#import "PYCurveChartLayer.h"

void getBezierCurveControlPoint(CGPoint p0, CGPoint p1, CGPoint p2, CGFloat t, CGPoint *c1, CGPoint *c2)
{
    float _d01 = sqrtf(powf(p1.x - p0.x, 2) + powf(p1.y - p0.y, 2));
    float _d12 = sqrtf(powf(p2.x - p1.x, 2) + powf(p2.y - p1.y, 2));
    float _fa = t * _d01 / ( _d01 + _d12 );
    float _fb = t * _d12 / ( _d01 + _d12 );
    
    (*c1).x = p1.x - _fa * (p2.x - p0.x);
    (*c1).y = p1.y - _fa * (p2.y - p0.y);
    (*c2).x = p1.x + _fb * (p2.x - p0.x);
    (*c2).y = p1.y + _fb * (p2.y - p0.y);
}

@interface PYCurveChartLayer ()
{
    NSMutableArray                  *_pathArray;
    NSMutableArray                  *_colorArray;
    NSMutableArray                  *_pointColorArray;
    NSMutableArray                  *_pointsPathSource;
    BOOL                            _showPoints;
}
@end

@implementation PYCurveChartLayer

@synthesize showPoints = _showPoints;

- (void)layerJustBeenCreated
{
    [super layerJustBeenCreated];
    self.tension = 0.5;
    _showPoints = NO;
    self.showShadow = YES;
    self.pointRaidus = 3.f;
    self.maxXCoordinate = 100;
    self.maxYCoordinate = 100;
    self.chartMode = PYCurveChartModeCurve;
}

- (void)layerJustBeenCopyed
{
    [super layerJustBeenCopyed];
    self.tension = 0.5;
    _showPoints = NO;
    self.showShadow = YES;
    self.pointRaidus = 3.f;
    self.maxXCoordinate = 100;
    self.maxYCoordinate = 100;
    self.chartMode = PYCurveChartModeCurve;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self reloadChart:_showPoints];
}

- (void)reloadChart:(BOOL)showPoints
{
    if ( self.dataSource == nil ) return;
    if ( self.superlayer == nil ) return;
    NSUInteger _chartCount = 1;
    if ( [self.dataSource respondsToSelector:@selector(chartCurveCount:)] ) {
        _chartCount = [self.dataSource chartCurveCount:self];
    }
    if ( _pathArray != nil ) {
        [_pathArray removeAllObjects];
        [_colorArray removeAllObjects];
        [_pointsPathSource removeAllObjects];
        [_pointColorArray removeAllObjects];
    } else {
        _pathArray = [NSMutableArray array];
        _colorArray = [NSMutableArray array];
        _pointsPathSource = [NSMutableArray array];
        _pointColorArray = [NSMutableArray array];
    }
    
    // Record the flag;
    _showPoints = showPoints;
    
    for ( NSUInteger _cc = 0; _cc < _chartCount; ++_cc ) {
        NSUInteger _pointCount = [self.dataSource pointCountOfChart:self forCurveAtIndex:_cc];
        if ( _pointCount == 0 ) continue;
        
        if ( self.chartMode == PYCurveChartModeCurve ) {
            UIBezierPath *_curvePath = [UIBezierPath bezierPath];
            CGPoint *_points = (CGPoint *)malloc(sizeof(CGPoint) * (_pointCount + 2));
            
            // Record the point source path array
            NSMutableArray *_sourceArray = [NSMutableArray array];
            CGFloat _pointRadius = self.pointRaidus;
            for ( NSUInteger _pi = 1; _pi <= _pointCount; ++_pi ) {
                _points[_pi] = [self.dataSource
                                pointForChart:self
                                atIndexPath:[NSIndexPath
                                             indexPathForRow:_pi - 1
                                             inSection:_cc]];
                // Transform
                _points[_pi].x = self.frame.size.width * (_points[_pi].x / self.maxXCoordinate);
                _points[_pi].y = self.frame.size.height * (1 - _points[_pi].y / self.maxYCoordinate);
                
                CGRect _pointRect = CGRectMake(_points[_pi].x - _pointRadius, _points[_pi].y - _pointRadius,
                                               _pointRadius * 2, _pointRadius * 2);
                UIBezierPath *_ptPath = [UIBezierPath bezierPathWithRoundedRect:_pointRect cornerRadius:_pointRadius];
                [_sourceArray addObject:_ptPath];
            }
            [_pointsPathSource addObject:_sourceArray];
            
            // Fill the head and tail
            _points[0].x = 0;
            _points[0].y = _points[1].y;
            _points[_pointCount + 1].x = self.frame.size.width;
            _points[_pointCount + 1].y = _points[_pointCount].y;
            
            CGPoint *_controlPoints = (CGPoint *)malloc(sizeof(CGPoint) * (_pointCount * 2));
            for ( int i = 0; i < _pointCount; ++i ) {
                getBezierCurveControlPoint(_points[i], _points[i + 1], _points[i + 2], self.tension,
                                           _controlPoints + i * 2, _controlPoints + (i * 2 + 1));
            }
            
            [_curvePath moveToPoint:_points[1]];    // Start point
            for ( int i = 2; i <= _pointCount; ++i ) {
                [_curvePath addCurveToPoint:_points[i]
                              controlPoint1:_controlPoints[(i - 2) * 2 + 1]
                              controlPoint2:_controlPoints[(i - 2) * 2 + 2]];
            }
            
            free(_controlPoints);
            free(_points);
            
            if ( [self.dataSource respondsToSelector:@selector(chartLineWidth:forCurveAtIndex:)] ) {
                [_curvePath setLineWidth:[self.dataSource chartLineWidth:self forCurveAtIndex:_cc]];
            } else {
                [_curvePath setLineWidth:2.f];
            }
            [_pathArray addObject:_curvePath];
        } else {
            NSMutableArray *_barGroupPath = [NSMutableArray array];
            float _barMaxWidth = self.frame.size.width / (_pointCount * 2 + 1);
            float _barWidth = _barMaxWidth / _chartCount;
            for ( NSUInteger _pi = 0; _pi < _pointCount; ++_pi ) {
                CGPoint _value = [self.dataSource
                                  pointForChart:self
                                  atIndexPath:[NSIndexPath
                                               indexPathForRow:_pi
                                               inSection:_cc]];
                // Transform
                if ( isnan(_value.x) == false ) {
                    _value.x = self.frame.size.width * (_value.x / self.maxXCoordinate);
                }
                _value.y = self.frame.size.height * (1 - _value.y / self.maxYCoordinate);
                UIBezierPath *_barPath = [UIBezierPath
                                          bezierPathWithRect:
                                          CGRectMake((_barMaxWidth * 2) * _pi + _barMaxWidth + _barWidth * _cc,
                                                     _value.y,
                                                     _barWidth,
                                                     self.frame.size.height - _value.y)];
                [_barGroupPath addObject:_barPath];
            }
            [_pathArray addObject:_barGroupPath];
        }
        
        if ( [self.dataSource respondsToSelector:@selector(chartLineColor:forCurveAtIndex:)] ) {
            [_colorArray addObject:[self.dataSource chartLineColor:self forCurveAtIndex:_cc]];
        } else {
            [_colorArray addObject:[UIColor randomColor]];
        }
        
        if ( self.chartMode == PYCurveChartModeCurve ) {
            if ( [self.dataSource respondsToSelector:@selector(chartPointColor:forCurveAtIndex:)] ) {
                [_pointColorArray addObject:[self.dataSource chartPointColor:self forCurveAtIndex:_cc]];
            } else {
                [_pointColorArray addObject:[_colorArray lastObject]];
            }
        }
    }
    
    [self setNeedsDisplay];
}

- (void)drawInContext:(CGContextRef)ctx
{
    self.contentsScale = [UIScreen mainScreen].scale;
    NSUInteger _c = _pathArray.count;
    UIColor *_wcolor = [UIColor whiteColor];
    
    if ( self.chartMode == PYCurveChartModeCurve ) {
        for ( NSUInteger i = 0; i < _c; ++i ) {
            UIBezierPath *_bPath = [_pathArray objectAtIndex:i];
            UIColor *_lColor = [_colorArray objectAtIndex:i];
            UIColor *_pColor = [_pointColorArray objectAtIndex:i];
            
            // Shadow
            if ( self.showShadow ) {
                PYColorInfo _colorInfo = [_lColor colorInfo];
                // Shadow
                UIColor *_startColor = [UIColor colorWithRed:_colorInfo.red
                                                       green:_colorInfo.green
                                                        blue:_colorInfo.blue
                                                       alpha:.5f];
                UIColor *_shadowColor = [UIColor colorWithGradientColors:@[_startColor,
                                                                           [UIColor
                                                                            colorWithWhite:1.f
                                                                            alpha:0.f]]
                                                              fillHeight:self.frame.size.height];
                CGContextSetFillColorWithColor(ctx, _shadowColor.CGColor);
                CGRect _box = _bPath.bounds;
                CGPoint _lastPoint = _bPath.currentPoint;
                UIBezierPath *_shadowPath = [UIBezierPath bezierPathWithCGPath:_bPath.CGPath];
                [_shadowPath addLineToPoint:CGPointMake(_lastPoint.x, self.frame.size.height)];
                [_shadowPath addLineToPoint:CGPointMake(_box.origin.x, self.frame.size.height)];
                [_shadowPath closePath];
                CGContextAddPath(ctx, _shadowPath.CGPath);
                CGContextFillPath(ctx);
            }
            
            // Line
            CGContextSetStrokeColorWithColor(ctx, _lColor.CGColor);
            CGContextAddPath(ctx, _bPath.CGPath);
            CGContextSetLineWidth(ctx, _bPath.lineWidth);
            CGContextStrokePath(ctx);
            
            if ( _showPoints ) {
                CGContextSetFillColorWithColor(ctx, _wcolor.CGColor);
                CGContextSetStrokeColorWithColor(ctx, _pColor.CGColor);
                CGContextSetLineWidth(ctx, _bPath.lineWidth);
                NSMutableArray *_sourcePoints = [_pointsPathSource objectAtIndex:i];
                for ( UIBezierPath *_ptPath in _sourcePoints ) {
                    CGContextAddPath(ctx, _ptPath.CGPath);
                    //                CGContextFillPath(ctx);
                    CGContextDrawPath(ctx, kCGPathFillStroke);
                }
            }
        }
    } else {
        for ( NSUInteger i = 0; i < _c; ++i ) {
            NSArray *_barGroup = [_pathArray objectAtIndex:i];
            UIColor *_barColor = [_colorArray objectAtIndex:i];
            // [_barColor setFill];
            CGContextSetFillColorWithColor(ctx, _barColor.CGColor);
            for ( UIBezierPath *_barPath in _barGroup ) {
                CGContextAddPath(ctx, _barPath.CGPath);
                CGContextFillPath(ctx);
            }
        }
    }
}

@end

// @littlepush
// littlepush@gmail.com
// PYLab


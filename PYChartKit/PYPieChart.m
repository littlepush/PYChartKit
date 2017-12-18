//
//  PYPieChart.m
//  PYChartKit
//
//  Created by Push Chen on 18/12/2017.
//  Copyright © 2017 Push Lab. All rights reserved.
//

#import "PYPieChart.h"

@interface PYPieChart()
{
    NSMutableArray          *_pieOriginalPath;
    NSMutableArray          *_pieMagificentPath;
    NSInteger               _highlightIndex;
}
@end

@implementation PYPieChart

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

- (void)viewJustBeenCreated
{
    [super viewJustBeenCreated];
    [self setUserInteractionEnabled:YES];
    UIPanGestureRecognizer *_pgr = [[UIPanGestureRecognizer alloc]
                                    initWithTarget:self
                                    action:@selector(__gestureLocationCheck:)];
    [self addGestureRecognizer:_pgr];
    
    _pieOriginalPath = [NSMutableArray array];
    _pieMagificentPath = [NSMutableArray array];
    _highlightIndex = -1;
    
    self.magnification = 0.95;
    self.padding = 10.f;
}

- (void)__generatePath
{
    if ( self.datasource == nil ) return;
    NSInteger _pCount = [self.datasource partCountOfPie:self];
    if ( _pCount == 0 ) return;
    
    CGPoint _center = self.center;
    CGFloat _largeRadius = MIN(_center.x, _center.y) - self.padding * 2;
    CGFloat _radius = _largeRadius * self.magnification;
    
    CGPoint _lastLargeCorner = CGPointMake(_center.x, _center.y - _largeRadius);
    CGPoint _lastCorner = CGPointMake(_center.x, _center.y - _radius);
    CGFloat _lastAngle = -M_PI_2;
    
    float _sum = 0;
    float *_values = calloc(_pCount, sizeof(float));
    for ( int i = 0; i < _pCount; ++i ) {
        _values[i] = [self.datasource pie:self valueAtIndex:i];
        _sum += _values[i];
    }
    
    for ( int i = 0; i < _pCount; ++i ) {
        UIBezierPath *_path = [UIBezierPath bezierPath];
        UIBezierPath *_largePath = [UIBezierPath bezierPath];
        CGFloat _angle = (_values[i] / _sum) * M_PI * 2 + _lastAngle;
        [_path moveToPoint:_lastCorner];
        [_path addArcWithCenter:_center
                         radius:_radius
                     startAngle:_lastAngle
                       endAngle:_angle
                      clockwise:YES];
        _lastCorner = _path.currentPoint;
        [_path addLineToPoint:_center];
        [_path closePath];
        
        [_largePath moveToPoint:_lastLargeCorner];
        [_largePath addArcWithCenter:_center
                              radius:_largeRadius
                          startAngle:_lastAngle
                            endAngle:_angle
                           clockwise:YES];
        _lastLargeCorner = _largePath.currentPoint;
        [_largePath addLineToPoint:_center];
        [_largePath closePath];
        
        _lastAngle = _angle;
        
        [_pieOriginalPath addObject:_path];
        [_pieMagificentPath addObject:_largePath];
    }
    free(_values);
}

- (void)reloadChart
{
    [self __generatePath];
}

- (void)__gestureLocationCheck:(UIGestureRecognizer *)gesture
{
    CGPoint _nowPoint = [gesture locationInView:self];
    NSInteger _newHighlight = -1;
    for ( NSInteger i = 0; i < _pieOriginalPath.count; ++i ) {
        UIBezierPath *_path = [_pieOriginalPath objectAtIndex:i];
        if ( [_path containsPoint:_nowPoint] ) {
            _newHighlight = i;
            break;
        }
    }
    if ( _newHighlight != _highlightIndex ) {
        _highlightIndex = _newHighlight;
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{
    CGContextSetShadowWithColor(UIGraphicsGetCurrentContext(),
                                CGSizeMake(1.0, 1.0), 4.f,
                                [UIColor lightGrayColor].CGColor);
    BOOL _useRandomColor = YES;
    if ( [self.datasource respondsToSelector:@selector(pie:colorOfPartAtIndex:)]) {
        _useRandomColor = NO;
    }
    for ( NSInteger i = 0; i < _pieOriginalPath.count; ++i ) {
        UIColor *_partColor = (_useRandomColor ?
                               [UIColor randomColor] :
                               ([self.datasource pie:self colorOfPartAtIndex:i]));
        [_partColor setFill];
        if ( _highlightIndex == i ) {
            [(UIBezierPath *)_pieMagificentPath[i] fill];
        } else {
            [(UIBezierPath *)_pieOriginalPath[i] fill];
        }
    }
}

@end


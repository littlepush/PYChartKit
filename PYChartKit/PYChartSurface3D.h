//
//  PYChartSurface3D.h
//  OpenGLTest
//
//  Created by Push Chen on 25/05/2017.
//  Copyright © 2017 PushLab. All rights reserved.
//

/*
 LGPL V3 Lisence
 This file is part of cleandns.
 
 PYControllers is free software: you can redistribute it and/or modify
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

#import <PYControllers/PYControllers.h>
#import "PYChartSurface3DUtility.h"

typedef struct {
    uint32_t        row;
    uint32_t        column;
} PYChartSurface3DVertexTable;

typedef NS_ENUM(NSInteger, PYChartSurface3DDisplayMode) {
    PYChartSurface3DDisplayModeSquare,
    PYChartSurface3DDisplayModeRelated
};

typedef NS_ENUM(NSInteger, PYChartSurface3DZoom) {
    PYChartSurface3DZoomSmall,
    PYChartSurface3DZoomNormal,
    PYChartSurface3DZoomBig
};

// The Delegate
@protocol PYChartSurface3DDelegate;

@interface PYChartSurface3D : PYView

// The delegate
@property (nonatomic, assign)   id<PYChartSurface3DDelegate>        delegate;

// If to show the grid
@property (nonatomic, assign)   BOOL        displayGrid;

// Color of the grid lines
@property (nonatomic, strong)   UIColor     *gridColor;

// Grid Line Width
@property (nonatomic, assign)   CGFloat     gridLineWidth;

// Show Axes
@property (nonatomic, assign)   BOOL        displayAxes;

// Axes Line Width
@property (nonatomic, assign)   CGFloat     axesLineWidth;

// Axes Line Color
@property (nonatomic, strong)   UIColor     *axesColor;

// Show Grid Rules
@property (nonatomic, assign)   BOOL        displayRules;

// Rules Line Width
@property (nonatomic, assign)   CGFloat     rulesLineWidth;

// Rules Line Color
@property (nonatomic, strong)   UIColor     *rulesColor;

// Display mode, default is square mode
@property (nonatomic, assign)   PYChartSurface3DDisplayMode displayMode;

// Zoom mode, default is normal
@property (nonatomic, assign)   PYChartSurface3DZoom        zoomMode;

// Allow Rotate Around X or Z Axes
// Default is NO
@property (nonatomic, assign)   BOOL        allowRotateAroundX;
// Default is YES
@property (nonatomic, assign)   BOOL        allowRotateAroundZ;

// Initialize the surface with specified vertices.
- (void)prepareSurfaceWithVertexTable:(PYChartSurface3DVertexTable)table expandTimes:(NSUInteger)expand;

// Update the surface with vertex's value in Z, the values should contains table.row * table.column data
- (void)updateVertexValues:(float *)values;

- (void)addRenderGroupObject:(PYChart3DRenderGroup)renderGroup forKey:(NSString *)key;

- (void)removeRenderGroupForKey:(NSString *)key;

- (void)setTransform:(CATransform3D)transform ofRenderGroupForKey:(NSString *)key;

- (PYChart3DRenderGroup *)renderGroupForKey:(NSString *)key;

@end

@protocol PYChartSurface3DDelegate <NSObject>

@optional
// Return the vertix color for specifial value
- (UIColor *)surface3DChart:(PYChartSurface3D *)chart colorForValue:(float)value;

@end

// @littlepush
// littlepush@gmail.com
// PYLab

//
//  PYChartSurface3DUtility.h
//  OpenGLTest
//
//  Created by Push Chen on 03/06/2017.
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


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

typedef struct {
    float position[3];
    float color[4];
} PYChart3DVertex;

typedef struct {
    uint32_t        row;
    uint32_t        column;
} PYChartSurface3DPoint;

typedef struct {
    PYChartSurface3DPoint   point;
    float                   value;
} PYChartSurface3DValue;

// Make the point and value
PYChartSurface3DPoint PYChartSurface3DPointMake(uint32_t r, uint32_t c);
PYChartSurface3DValue PYChartSurface3DValueMake(uint32_t r, uint32_t c, float v);

typedef struct {
    GLuint              verticesBuffer;
    GLuint              indicesBuffer;
    uint32_t            vertexCount;
    uint32_t            indexCount;
    PYChart3DVertex     *vertices;
    GLuint              *indices;
} PYChart3DRenderGroup;

void PYChart3DRenderGroupGenBuffer(PYChart3DRenderGroup *renderGroup);
void PYChart3DRenderGroupRelease(PYChart3DRenderGroup *renderGroup);

typedef struct {
    // Matrix data order in:
    float m11, m12, m13, m14;
    float m21, m22, m23, m24;
    float m31, m32, m33, m34;
    float m41, m42, m43, m44;
} PYChartMatrix;

// Create a project matrix
PYChartMatrix PYChartMatrixFrustum(float left, float right, float bottom, float top, float near, float far);

// Convert a CATransform3D to normal Chart Martix
// CATransfrom3D use CGFloat(aka double), we need to convert the data type
PYChartMatrix PYChartMartixFromCATransform3D(const CATransform3D* transform);

#define PYCHART_AXES_DIRECTION_COUNT            4   // X, Y+, Y-, Z
#define PYCHART_AXES_ARROW_LINES                3   // for each direction, need 3 lines to draw the arrow

// Create the axes vectices and indicies
PYChart3DVertex* PYChartCreateXAxesVerticesWithColor
(
 float xfrom,
 float xto,
 float static_y,
 float static_z,
 UIColor *color,
 uint32_t *count
 );
GLuint* PYChartCreateXAxesIndicies(uint32_t *count);
PYChart3DVertex* PYChartCreateYAxesVerticesWithColor
(
 float yfrom,
 float yto,
 float static_x,
 float static_z,
 UIColor *color,
 uint32_t *count
 );
GLuint* PYChartCreateYAxesIndicies(uint32_t *count);
PYChart3DVertex* PYChartCreateZAxesVerticesWithColor
(
 float zfrom,
 float zto,
 float static_x,
 float static_y,
 UIColor *color,
 uint32_t *count
 );
GLuint* PYChartCreateZAxesIndicies(uint32_t *count);

// Create Ruler
PYChart3DVertex* PYChartCreateXYRulerVerticesWithColor
(
 float xfrom, float xto,
 float yfrom, float yto,
 float static_z,
 float interval, UIColor *color,
 uint32_t *count
 );
GLuint* PYChartCreateXYRulerIndicies
(
 float xfrom, float xto,
 float yfrom, float yto,
 float interval,
 uint32_t *count
 );
PYChart3DVertex* PYChartCreateXZRulerVerticesWithColor
(
 float xfrom, float xto,
 float zfrom, float zto,
 float static_y,
 float interval, UIColor *color,
 uint32_t *count
 );
GLuint* PYChartCreateXZRulerIndicies
(
 float xfrom, float xto,
 float zfrom, float zto,
 float interval,
 uint32_t *count
 );
PYChart3DVertex* PYChartCreateYZRulerVerticesWithColor
(
 float yfrom, float yto,
 float zfrom, float zto,
 float static_x,
 float interval, UIColor *color,
 uint32_t *count
 );
GLuint* PYChartCreateYZRulerIndicies
(
 float yfrom, float yto,
 float zfrom, float zto,
 float interval,
 uint32_t *count
 );

// Release the resources
void PYChartDeleteVertices(PYChart3DVertex* vectices);
void PYChartDeleteIndicies(GLuint* indicies);

#define PYCHART_SET_VERTEX_COLOR(v, colorinfo)  \
    (v).color[0] = (colorinfo).red;             \
    (v).color[1] = (colorinfo).green;           \
    (v).color[2] = (colorinfo).blue;            \
    (v).color[3] = (colorinfo).alpha
#define PYCHART_SET_VERTEX_POSITION(v, x, y, z) \
    (v).position[0] = (x);                      \
    (v).position[1] = (y);                      \
    (v).position[2] = (z)
#define PYCHART_SET_VERTEX(v, x, y, z, c)       \
    PYCHART_SET_VERTEX_POSITION(v, x, y, z);    \
    PYCHART_SET_VERTEX_COLOR(v, c)
#define PYCHART_SET_INDEX_GROUP(i, idx, start, end) \
    (i)[(idx) * 2 + 0] = (start);                   \
    (i)[(idx) * 2 + 1] = (end)

// Inverse Distance Weighted
float PYChartInterpolationIDW
(
 const PYChartSurface3DValue * static_points,
 uint32_t static_count,
 PYChartSurface3DPoint point,
 float *distance_buffer
 );

// @littlepush
// littlepush@gmail.com
// PYLab

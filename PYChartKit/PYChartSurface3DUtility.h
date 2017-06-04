//
//  PYChartSurface3DUtility.h
//  OpenGLTest
//
//  Created by Push Chen on 03/06/2017.
//  Copyright © 2017 PushLab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

typedef struct {
    float x, y, z;
} PYChart3DVertex3;

PYChart3DVertex3 PYChart3DVertex3Make(float x, float y, float z);

typedef struct {
    float r, g, b, a;
} PYChart3DVertex4;

PYChart3DVertex4 PYChart3DVertex4Make(float r, float g, float b, float a);

typedef struct {
    PYChart3DVertex3 position;
    PYChart3DVertex4 color;
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
} PYChartMatrix4;

typedef struct {
    float m11, m12, m13;
    float m21, m22, m23;
    float m31, m32, m33;
} PYChartMatrix3;

extern const PYChartMatrix4 PYChartMartixIdentity;

// Create a project matrix
PYChartMatrix4 PYChartMatrixFrustum(float left, float right, float bottom, float top, float near, float far);

// Convert a CATransform3D to normal Chart Martix
// CATransfrom3D use CGFloat(aka double), we need to convert the data type
PYChartMatrix4 PYChartMartixFromCATransform3D(const CATransform3D transform);

// Multiply two matrix
PYChartMatrix4 PYChartMartixMultiply(PYChartMatrix4 m1, PYChartMatrix4 m2);

// Convert Matrix4 to Matrix3
PYChartMatrix3 PYChartMatrix4ToMatrix3(PYChartMatrix4 m);

// Rotate
PYChart3DVertex3 PYChartRotatePointWithMatrix4(PYChart3DVertex3 v, PYChartMatrix4 m);

// Transform
PYChart3DVertex3 PYChartTransformPointWithMatrix4(PYChart3DVertex3 v, PYChartMatrix4 m);

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

// Create objects
PYChart3DVertex* PYChartCreateCycleVerticesWithColor
(
 PYChart3DVertex3 center,
 uint32_t pieces,
 float radius,
 float thickness,
 float height,
 uint32_t *count,
 PYChartMatrix4 transform,
 UIColor *color
);
GLuint* PYChartCreateCycleIndicies
(
 uint32_t pieces,
 uint32_t *count
 );

// Release the resources
void PYChartDeleteVertices(PYChart3DVertex* vectices);
void PYChartDeleteIndicies(GLuint* indicies);

#define PYCHART_SET_VERTEX_COLOR(v, colorinfo)  \
    (v).color.r = (colorinfo).red;              \
    (v).color.g = (colorinfo).green;            \
    (v).color.b = (colorinfo).blue;             \
    (v).color.a = (colorinfo).alpha
#define PYCHART_SET_VERTEX_POSITION(v, _x, _y, _z)      \
    (v).position.x = (_x);                              \
    (v).position.y = (_y);                              \
    (v).position.z = (_z)
#define PYCHART_SET_VERTEX(v, _x, _y, _z, _c)           \
    PYCHART_SET_VERTEX_POSITION(v, (_x), (_y), (_z));   \
    PYCHART_SET_VERTEX_COLOR(v, (_c))
#define PYCHART_SET_INDEX_GROUP(i, idx, start, end) \
    (i)[(idx) * 2 + 0] = (start);                   \
    (i)[(idx) * 2 + 1] = (end)
#define PYCHART_SET_TRIANGLE_INDEX_GROUP(i, index, p0, p1, p2)  \
    (i)[(index) * 3 + 0] = (p0);                                \
    (i)[(index) * 3 + 1] = (p1);                                \
    (i)[(index) * 3 + 2] = (p2)

// Inverse Distance Weighted
float PYChartInterpolationIDW
(
 const PYChartSurface3DValue * static_points,
 uint32_t static_count,
 PYChartSurface3DPoint point,
 float *distance_buffer
 );

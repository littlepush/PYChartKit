//
//  PYChartSurface3DUtility.m
//  OpenGLTest
//
//  Created by Push Chen on 03/06/2017.
//  Copyright © 2017 PushLab. All rights reserved.
//

#import "PYChartSurface3DUtility.h"
#import <PYUIKit/PYUIKit.h>

const PYChartMatrix4 PYChartMartixIdentity = {
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
};

PYChart3DVertex3 PYChart3DVertex3Make(float x, float y, float z)
{
    PYChart3DVertex3 _v;
    _v.x = x; _v.y = y; _v.z = z;
    return _v;
}

PYChart3DVertex4 PYChart3DVertex4Make(float r, float g, float b, float a)
{
    PYChart3DVertex4 _v;
    _v.r = r; _v.g = g; _v.b = b; _v.a = a;
    return _v;
}

// Make the point and value
PYChartSurface3DPoint PYChartSurface3DPointMake(uint32_t r, uint32_t c)
{
    return (PYChartSurface3DPoint){r, c};
}
PYChartSurface3DValue PYChartSurface3DValueMake(uint32_t r, uint32_t c, float v)
{
    PYChartSurface3DValue _v = {{r, c}, v};
    return _v;
}
void PYChart3DRenderGroupGenBuffer(PYChart3DRenderGroup *renderGroup)
{
    glGenBuffers(1, &renderGroup->verticesBuffer);
    glGenBuffers(1, &renderGroup->indicesBuffer);
    renderGroup->vertices = NULL;
    renderGroup->indices = NULL;
    renderGroup->vertexCount = 0;
    renderGroup->indexCount = 0;
}
void PYChart3DRenderGroupRelease(PYChart3DRenderGroup *renderGroup)
{
    glDeleteBuffers(1, &renderGroup->verticesBuffer);
    glDeleteBuffers(1, &renderGroup->indicesBuffer);
    if ( renderGroup->vertices != NULL ) {
        PYChartDeleteVertices(renderGroup->vertices);
    }
    if ( renderGroup->indices != NULL ) {
        PYChartDeleteIndicies(renderGroup->indices);
    }
}

// Create a project matrix
PYChartMatrix4 PYChartMatrixFrustum(float left, float right, float bottom, float top, float near, float far)
{
    PYChartMatrix4 _m;
    PYChartMatrix4 *m = &_m;
    m->m11 = 2 * near / (right - left);
    m->m12 = 0;
    m->m13 = 0;
    m->m14 = 0;
    
    m->m21 = 0;
    m->m22 = 2 * near / (top - bottom);
    m->m23 = 0;
    m->m24 = 0;
    
    m->m31 = (right + left) / (right - left);
    m->m32 = (top + bottom) / (top - bottom);
    m->m33 = -(far + near) / (far - near);
    m->m34 = -1;
    
    m->m41 = 0;
    m->m42 = 0;
    m->m43 = -2 * far * near / (far - near);
    m->m44 = 0;
    return _m;
}
// Convert a CATransform3D to normal Chart Martix
// CATransfrom3D use CGFloat(aka double), we need to convert the data type
PYChartMatrix4 PYChartMartixFromCATransform3D(const CATransform3D transform)
{
    PYChartMatrix4 _m;
    float *_pm = &_m.m11;
    const CGFloat *_cm = &transform.m11;
    for ( uint8_t i = 0; i < 16; ++i ) {
        _pm[i] = _cm[i];
    }
    return _m;
}
// Multiply two matrix
PYChartMatrix4 PYChartMartixMultiply(PYChartMatrix4 m1, PYChartMatrix4 m2)
{
    PYChartMatrix4 _result;
    memset(&_result, 0, sizeof(PYChartMatrix4));
    float *_presult[4], *_pm1[4], *_pm2[4];
    for ( int i = 0; i < 4; ++i ) {
        _presult[i] = ((float *)&_result.m11) + i * 4;
        _pm1[i] = ((float *)&m1.m11) + i * 4;
        _pm2[i] = ((float *)&m2.m11) + i * 4;
    }
    int i, j, k;
    for ( i = 0; i < 4; ++i ) {
        for ( j = 0; j < 4; ++j ) {
            for ( k = 0; k < 4; ++k ) {
                _presult[i][j] += (_pm1[i][k] * _pm2[k][j]);
            }
        }
    }
    return _result;
}
// Convert Matrix4 to Matrix3
PYChartMatrix3 PYChartMatrix4ToMatrix3(PYChartMatrix4 m)
{
    PYChartMatrix3 _r;
    _r.m11 = m.m11;
    _r.m12 = m.m12;
    _r.m13 = m.m13;
    _r.m21 = m.m21;
    _r.m22 = m.m22;
    _r.m23 = m.m23;
    _r.m31 = m.m31;
    _r.m32 = m.m32;
    _r.m33 = m.m33;
    return _r;
}
//--remember w = 1 for move in space; w = 0 rotate in space;
//local res = [0, 0, 0];
//res.x = mat.row1.x*x + mat.row2.x*y + mat.row3.x*z + mat.row4.x*w;
//res.y = mat.row1.y*x + mat.row2.y*y + mat.row3.y*z + mat.row4.y*w;
//res.z = mat.row1.z*x + mat.row2.z*y + mat.row3.z*z + mat.row4.z*w;
//return res;


// Rotate
PYChart3DVertex3 PYChartRotatePointWithMatrix4(PYChart3DVertex3 v, PYChartMatrix4 m)
{
    return PYChart3DVertex3Make
    (m.m11 * v.x + m.m21 * v.y + m.m31 * v.z + m.m41 * 0,
     m.m12 * v.x + m.m22 * v.y + m.m32 * v.z + m.m42 * 0,
     m.m13 * v.x + m.m23 * v.y + m.m33 * v.z + m.m43 * 0);
}

// Transform
PYChart3DVertex3 PYChartTransformPointWithMatrix4(PYChart3DVertex3 v, PYChartMatrix4 m)
{
    return PYChart3DVertex3Make
    (m.m11 * v.x + m.m21 * v.y + m.m31 * v.z + m.m41 * 1,
     m.m12 * v.x + m.m22 * v.y + m.m32 * v.z + m.m42 * 1,
     m.m13 * v.x + m.m23 * v.y + m.m33 * v.z + m.m43 * 1);
}

// Create the axes vectices and indicies
PYChart3DVertex* PYChartCreateXAxesVerticesWithColor
(
 float xfrom,
 float xto,
 float static_y,
 float static_z,
 UIColor *color,
 uint32_t *count
 )
{
    PYChart3DVertex *_v = (PYChart3DVertex *)malloc(sizeof(PYChart3DVertex) * 4);
    if ( count != NULL ) {
        *count = 4;
    }
    PYColorInfo _ci = color.colorInfo;
    float _delta = (xto < 0 ? -0.15 : 0.15);
    PYCHART_SET_VERTEX(_v[0], xfrom, static_y, static_z, _ci);
    PYCHART_SET_VERTEX(_v[1], xto, static_y, static_z, _ci);
    PYCHART_SET_VERTEX(_v[2], xto - _delta, static_y + 0.15, static_z, _ci);
    PYCHART_SET_VERTEX(_v[3], xto - _delta, static_y - 0.15, static_z, _ci);
    return _v;
}
GLuint* PYChartCreateXAxesIndicies(uint32_t *count)
{
    GLuint* _i = (GLuint *)malloc(sizeof(GLuint) * 3 * 2);
    if ( count != NULL ) {
        *count = 3 * 2;
    }
    PYCHART_SET_INDEX_GROUP(_i, 0, 0, 1);
    PYCHART_SET_INDEX_GROUP(_i, 1, 1, 2);
    PYCHART_SET_INDEX_GROUP(_i, 2, 1, 3);
    return _i;
}
PYChart3DVertex* PYChartCreateYAxesVerticesWithColor
(
 float yfrom,
 float yto,
 float static_x,
 float static_z,
 UIColor *color,
 uint32_t *count
 )
{
    PYChart3DVertex *_v = (PYChart3DVertex *)malloc(sizeof(PYChart3DVertex) * 4);
    if ( count != NULL ) {
        *count = 4;
    }
    PYColorInfo _ci = color.colorInfo;
    float _delta = (yto < 0 ? -0.15 : 0.15);
    PYCHART_SET_VERTEX(_v[0], static_x, yfrom, static_z, _ci);
    PYCHART_SET_VERTEX(_v[1], static_x, yto, static_z, _ci);
    PYCHART_SET_VERTEX(_v[2], static_x - 0.15, yto - _delta, static_z, _ci);
    PYCHART_SET_VERTEX(_v[3], static_x + 0.15, yto - _delta, static_z, _ci);
    return _v;
}
GLuint* PYChartCreateYAxesIndicies(uint32_t *count)
{
    return PYChartCreateXAxesIndicies(count);
}
PYChart3DVertex* PYChartCreateZAxesVerticesWithColor
(
 float zfrom,
 float zto,
 float static_x,
 float static_y,
 UIColor *color,
 uint32_t *count
 )
{
    PYChart3DVertex *_v = (PYChart3DVertex *)malloc(sizeof(PYChart3DVertex) * 4);
    if ( count != NULL ) {
        *count = 4;
    }
    PYColorInfo _ci = color.colorInfo;
    float _delta = (zto < 0 ? -0.15 : 0.15);
    PYCHART_SET_VERTEX(_v[0], static_x, static_y, zfrom, _ci);
    PYCHART_SET_VERTEX(_v[1], static_x, static_y, zto, _ci);
    PYCHART_SET_VERTEX(_v[2], static_x, static_y - 0.15, zto - _delta, _ci);
    PYCHART_SET_VERTEX(_v[3], static_x, static_y + 0.15, zto - _delta, _ci);
    return _v;
}
GLuint* PYChartCreateZAxesIndicies(uint32_t *count)
{
    return PYChartCreateXAxesIndicies(count);
}

// Create Ruler
PYChart3DVertex* PYChartCreateXYRulerVerticesWithColor
(
 float xfrom, float xto,
 float yfrom, float yto,
 float static_z,
 float interval, UIColor *color,
 uint32_t *count
 )
{
    /* 
     Example:
     xfrom: -3, xto: 3, yfrom 3, yto: -3, interval: 0.5
     _xCount: abs((3 - -3) / 0.5) + 1 = 13
     _yCount: abs((-3 - 3) / 0.5) + 1 = 13
     _xDelta = 0.5
     _yDelta = -0.5
     first loop, from 0 to 12 (13 points), create vertex(-3, 3), (-2.5, 3) ... to (3, 3)
     second loop, from 12 to 24 (13 points), create vertex(3, 3), (3, 2.5) ... to (3, -3)
    */
    uint32_t _xCount = fabsf((xto - xfrom) / interval) + 1;
    uint32_t _yCount = fabsf((yto - yfrom) / interval) + 1;
    float _xDelta = (xto > xfrom ? fabsf(interval) : -1 * fabsf(interval));
    float _yDelta = (yto > yfrom ? fabsf(interval) : -1 * fabsf(interval));
    PYColorInfo _ci = color.colorInfo;
    
    uint32_t _all = ((_xCount + _yCount) * 2 - 4);
    PYChart3DVertex *_v = (PYChart3DVertex *)malloc(sizeof(PYChart3DVertex) * ((_xCount + _yCount) * 2 - 4));
    if ( count != NULL ) {
        *count = _all;
    }
    uint32_t _begin = 0;
    uint32_t _end = _begin + _xCount;
    // xfrom -> xto
    for ( uint32_t x = _begin; x < _end; ++x ) {
        PYCHART_SET_VERTEX(_v[x % _all], (xfrom + _xDelta * (x - _begin)), yfrom, static_z, _ci);
    }
    _begin = _end - 1;
    _end = (_begin + _yCount);
    // yfrom -> yto
    for ( uint32_t y = _begin; y < _end; ++y ) {
        PYCHART_SET_VERTEX(_v[y % _all], xto, (yfrom + _yDelta * (y - _begin)), static_z, _ci);
    }
    _begin = _end - 1;
    _end = _begin + _xCount;
    // xto -> xform
    for ( uint32_t x = _begin; x < _end; ++x ) {
        PYCHART_SET_VERTEX(_v[x % _all], (xto - _xDelta * (x - _begin)), yto, static_z, _ci);
    }
    _begin = _end - 1;
    _end = _begin + _yCount;
    // yto -> yfrom
    for ( uint32_t y = _begin; y < _end; ++y ) {
        PYCHART_SET_VERTEX(_v[y % _all], xfrom, (yto - _yDelta * (y - _begin)), static_z, _ci);
    }
    
    return _v;
}
GLuint* PYChartCreateXYRulerIndicies
(
 float xfrom, float xto,
 float yfrom, float yto,
 float interval,
 uint32_t *count
 )
{
    uint32_t _xCount = fabsf((xto - xfrom) / interval) + 1;
    uint32_t _yCount = fabsf((yto - yfrom) / interval) + 1;
    GLuint *_i = (GLuint *)malloc(sizeof(GLuint) * (_xCount + _yCount) * 2);
    if ( count != NULL ) {
        *count = (_xCount + _yCount) * 2;
    }
    uint32_t i = 0;
    uint32_t _all = ((_xCount + _yCount) * 2 - 4);
    uint32_t _begin = 0;
    uint32_t _end = _begin + _xCount;
    uint32_t _last = _all - (_yCount - 1);
    for ( uint32_t x = _begin; x < _end; ++x ) {
        PYCHART_SET_INDEX_GROUP(_i, i, x, (_last - x));
        ++i;
    }
    _begin = _end - 1;
    _end = _begin + _yCount;
    _last = ((_xCount + _yCount) * 2 - 4); // _xCount - 1 + _yCount - 1 + _xCount - 1 + _yCount
    for ( uint32_t y = _begin; y < _end; ++y ) {
        PYCHART_SET_INDEX_GROUP(_i, i, y, (_last - (y - _begin)) % _all);
        ++i;
    }
    return _i;
}
PYChart3DVertex* PYChartCreateXZRulerVerticesWithColor
(
 float xfrom, float xto,
 float zfrom, float zto,
 float static_y,
 float interval, UIColor *color,
 uint32_t *count
 )
{
    uint32_t _xCount = fabsf((xto - xfrom) / interval) + 1;
    uint32_t _zCount = fabsf((zto - zfrom) / interval) + 1;
    float _xDelta = (xto > xfrom ? fabsf(interval) : -1 * fabsf(interval));
    float _zDelta = (zto > zfrom ? fabsf(interval) : -1 * fabsf(interval));
    PYColorInfo _ci = color.colorInfo;
    
    uint32_t _all = ((_xCount + _zCount) * 2 - 4);
    PYChart3DVertex *_v = (PYChart3DVertex *)malloc(sizeof(PYChart3DVertex) * ((_xCount + _zCount) * 2 - 4));
    if ( count != NULL ) {
        *count = _all;
    }
    uint32_t _begin = 0;
    uint32_t _end = _begin + _xCount;
    // xfrom -> xto
    for ( uint32_t x = _begin; x < _end; ++x ) {
        PYCHART_SET_VERTEX(_v[x % _all], (xfrom + _xDelta * (x - _begin)), static_y, zfrom, _ci);
    }
    _begin = _end - 1;
    _end = (_begin + _zCount);
    // yfrom -> yto
    for ( uint32_t z = _begin; z < _end; ++z ) {
        PYCHART_SET_VERTEX(_v[z % _all], xto, static_y, (zfrom + _zDelta * (z - _begin)), _ci);
    }
    _begin = _end - 1;
    _end = _begin + _xCount;
    // xto -> xform
    for ( uint32_t x = _begin; x < _end; ++x ) {
        PYCHART_SET_VERTEX(_v[x % _all], (xto - _xDelta * (x - _begin)), static_y, zto, _ci);
    }
    _begin = _end - 1;
    _end = _begin + _zCount;
    // yto -> yfrom
    for ( uint32_t z = _begin; z < _end; ++z ) {
        PYCHART_SET_VERTEX(_v[z % _all], xfrom, static_y, (zto - _zDelta * (z - _begin)), _ci);
    }
    
    return _v;
}
GLuint* PYChartCreateXZRulerIndicies
(
 float xfrom, float xto,
 float zfrom, float zto,
 float interval,
 uint32_t *count
 )
{
    return PYChartCreateXYRulerIndicies(xfrom, xto, zfrom, zto, interval, count);
}
PYChart3DVertex* PYChartCreateYZRulerVerticesWithColor
(
 float yfrom, float yto,
 float zfrom, float zto,
 float static_x,
 float interval, UIColor *color,
 uint32_t *count
 )
{
    uint32_t _yCount = fabsf((yto - yfrom) / interval) + 1;
    uint32_t _zCount = fabsf((zto - zfrom) / interval) + 1;
    float _yDelta = (yto > yfrom ? fabsf(interval) : -1 * fabsf(interval));
    float _zDelta = (zto > zfrom ? fabsf(interval) : -1 * fabsf(interval));
    PYColorInfo _ci = color.colorInfo;
    
    uint32_t _all = ((_yCount + _zCount) * 2 - 4);
    PYChart3DVertex *_v = (PYChart3DVertex *)malloc(sizeof(PYChart3DVertex) * ((_yCount + _zCount) * 2 - 4));
    if ( count != NULL ) {
        *count = _all;
    }
    uint32_t _begin = 0;
    uint32_t _end = _begin + _yCount;
    // xfrom -> xto
    for ( uint32_t y = _begin; y < _end; ++y ) {
        PYCHART_SET_VERTEX(_v[y % _all], static_x, (yfrom + _yDelta * (y - _begin)), zfrom, _ci);
    }
    _begin = _end - 1;
    _end = (_begin + _zCount);
    // yfrom -> yto
    for ( uint32_t z = _begin; z < _end; ++z ) {
        PYCHART_SET_VERTEX(_v[z % _all], static_x, yto, (zfrom + _zDelta * (z - _begin)), _ci);
    }
    _begin = _end - 1;
    _end = _begin + _yCount;
    // xto -> xform
    for ( uint32_t y = _begin; y < _end; ++y ) {
        PYCHART_SET_VERTEX(_v[y % _all], static_x, (yto - _yDelta * (y - _begin)), zto, _ci);
    }
    _begin = _end - 1;
    _end = _begin + _zCount;
    // yto -> yfrom
    for ( uint32_t z = _begin; z < _end; ++z ) {
        PYCHART_SET_VERTEX(_v[z % _all], static_x, yfrom, (zto - _zDelta * (z - _begin)), _ci);
    }
    
    return _v;
}
GLuint* PYChartCreateYZRulerIndicies
(
 float yfrom, float yto,
 float zfrom, float zto,
 float interval,
 uint32_t *count
 )
{
    return PYChartCreateXYRulerIndicies(yfrom, yto, zfrom, zto, interval, count);
}

PYChart3DVertex* PYChartCreateCycleVerticesWithColor
(
 PYChart3DVertex3 center,
 uint32_t pieces,
 float raidus,
 float thickness,
 float height,
 uint32_t *count,
 PYChartMatrix4 transform,
 UIColor *color
)
{
    PYChart3DVertex* _v = (PYChart3DVertex *)malloc(sizeof(PYChart3DVertex) * pieces * 4);
    if ( count != NULL ) {
        *count = (pieces * 4);
    }
    float _uplayerZ = center.z + height / 2;
    float _downlayerZ = center.z - height / 2;
    float _innerRadius = raidus - thickness;
    if ( _innerRadius < 0 ) _innerRadius = 0.f;
    
    PYColorInfo _ci = color.colorInfo;
    PYChart3DVertex4 _color = PYChart3DVertex4Make(_ci.red, _ci.green, _ci.blue, _ci.alpha);
    float _corner = M_PI * 2 / pieces;
    PYChartMatrix4 _toZero = PYChartMartixFromCATransform3D(CATransform3DMakeTranslation(-center.x, -center.y, -center.z));
    PYChartMatrix4 _comeBack = PYChartMartixFromCATransform3D(CATransform3DMakeTranslation(center.x, center.y, center.z));
    for ( uint32_t i = 0; i < pieces; ++i ) {
        float _c = i * _corner;
        float _cos = cosf(_c);
        float _sin = sinf(_c);
        float _cos_inner = _cos * _innerRadius + center.x;
        float _sin_inner = _sin * _innerRadius + center.y;
        float _cos_outer = _cos * raidus + center.x;
        float _sin_outer = _sin * raidus + center.y;
        PYChart3DVertex3 _piu = PYChart3DVertex3Make(_cos_inner, _sin_inner, _uplayerZ);
        _piu = PYChartTransformPointWithMatrix4(_piu, _toZero);
        _piu = PYChartRotatePointWithMatrix4(_piu, transform);
        _piu = PYChartTransformPointWithMatrix4(_piu, _comeBack);
        PYChart3DVertex3 _pou = PYChart3DVertex3Make(_cos_outer, _sin_outer, _uplayerZ);
        _pou = PYChartTransformPointWithMatrix4(_pou, _toZero);
        _pou = PYChartRotatePointWithMatrix4(_pou, transform);
        _pou = PYChartTransformPointWithMatrix4(_pou, _comeBack);
        PYChart3DVertex3 _pid = PYChart3DVertex3Make(_cos_inner, _sin_inner, _downlayerZ);
        _pid = PYChartTransformPointWithMatrix4(_pid, _toZero);
        _pid = PYChartRotatePointWithMatrix4(_pid, transform);
        _pid = PYChartTransformPointWithMatrix4(_pid, _comeBack);
        PYChart3DVertex3 _pod = PYChart3DVertex3Make(_cos_outer, _sin_outer, _downlayerZ);
        _pod = PYChartTransformPointWithMatrix4(_pod, _toZero);
        _pod = PYChartRotatePointWithMatrix4(_pod, transform);
        _pod = PYChartTransformPointWithMatrix4(_pod, _comeBack);
        _v[i + (pieces * 0)].position = _piu;
        _v[i + (pieces * 1)].position = _pou;
        _v[i + (pieces * 2)].position = _pid;
        _v[i + (pieces * 3)].position = _pod;
        _v[i + (pieces * 0)].color = _color;
        _v[i + (pieces * 1)].color = _color;
        _v[i + (pieces * 2)].color = _color;
        _v[i + (pieces * 3)].color = _color;
    }
    return _v;
}
GLuint* PYChartCreateCycleIndicies
(
 uint32_t pieces,
 uint32_t *count
 )
{
    // Each Piece has 4 surfaces
    // Each surface has 2 triangles
    // Each Triangles has 3 lines
    // Each Line has two point
    uint32_t _all = pieces * 4 * 2 * 3;
    if ( count != NULL ) {
        *count = _all;
    }
    GLuint *_v = (GLuint *)malloc(sizeof(GLuint) * _all);
    uint32_t _index = 0;
    for ( uint32_t i = 0; i < pieces; ++i ) {
        uint32_t _start = i;
        uint32_t _end = (i + 1) % pieces;
        // Upper
        PYCHART_SET_TRIANGLE_INDEX_GROUP(_v, _index, _start + (pieces * 0), _end + (pieces * 0), _start + (pieces * 1));
        ++_index;
        PYCHART_SET_TRIANGLE_INDEX_GROUP(_v, _index, _end + (pieces * 0), _end + (pieces * 1), _start + (pieces * 1));
        ++_index;
        
        // Inner-Vertical
        PYCHART_SET_TRIANGLE_INDEX_GROUP(_v, _index, _start + (pieces * 2), _end + (pieces * 2), _start + (pieces * 0));
        ++_index;
        PYCHART_SET_TRIANGLE_INDEX_GROUP(_v, _index, _end + (pieces * 2), _end + (pieces * 0), _start + (pieces * 0));
        ++_index;
        
        // Outer
        PYCHART_SET_TRIANGLE_INDEX_GROUP(_v, _index, _start + (pieces * 3), _end + (pieces * 3), _start + (pieces * 2));
        ++_index;
        PYCHART_SET_TRIANGLE_INDEX_GROUP(_v, _index, _end + (pieces * 3), _end + (pieces * 2), _start + (pieces *2));
        ++_index;
        
        // Outer-Vertical
        PYCHART_SET_TRIANGLE_INDEX_GROUP(_v, _index, _start + (pieces * 1), _end + (pieces * 1), _start + (pieces * 3));
        ++_index;
        PYCHART_SET_TRIANGLE_INDEX_GROUP(_v, _index, _end + (pieces * 1), _end + (pieces * 3), _start + (pieces * 3));
        ++_index;
    }
    return _v;
}

// Release the resources
void PYChartDeleteVertices(PYChart3DVertex* vectices)
{
    free(vectices);
}
void PYChartDeleteIndicies(GLuint* indicies)
{
    free(indicies);
}

float PYChartInterpolationIDW
(
 const PYChartSurface3DValue * static_points,
 uint32_t static_count,
 PYChartSurface3DPoint point,
 float *distance_buffer
 )
{
    float _v = 0.f;
    float _ad = 0.f;
    float *_d = distance_buffer;
    if ( _d == NULL ) _d = (float *)malloc(static_count * sizeof(float));
    for ( uint32_t i = 0; i < static_count; ++i ) {
        float _dist = powf(
                           powf(((float)point.row - (float)static_points[i].point.row), 2) +
                           powf(((float)point.column - (float)static_points[i].point.column), 2),
                           0.5);
        if ( _dist == 0.f ) {
            if ( distance_buffer == NULL ) free(_d);
            return static_points[i].value;
        }
        float _idw = powf(_dist, -2.5);
        _ad += _idw;
        _d[i] = _idw;
    }
    for ( uint32_t i = 0; i < static_count; ++i ) {
        _v += static_points[i].value * (_d[i] / _ad);
    }
    if ( distance_buffer == NULL ) free(_d);
    return _v;
}


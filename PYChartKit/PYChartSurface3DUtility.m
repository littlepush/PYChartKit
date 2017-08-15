//
//  PYChartSurface3DUtility.m
//  OpenGLTest
//
//  Created by Push Chen on 03/06/2017.
//  Copyright © 2017 PushLab. All rights reserved.
//

#import "PYChartSurface3DUtility.h"
#import <PYCore/PYCore.h>
#import <PYUIKit/PYUIKit.h>

const PYChartMatrix4 PYChartMatrixIdentity = {
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
};
PYChart3DVertex2 PYChart3DVertex2Make(float x, float y)
{
    PYChart3DVertex2 _v;
    _v.x = x; _v.y = y;
    return _v;
}

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
    renderGroup->renderType = GL_TRIANGLES;
    renderGroup->textureName = (GLuint)-1;
}
void PYChart3DRenderGroupRelease(PYChart3DRenderGroup *renderGroup)
{
    glDeleteBuffers(1, &renderGroup->verticesBuffer);
    glDeleteBuffers(1, &renderGroup->indicesBuffer);
    if ( renderGroup->textureName != (GLuint)-1 ) {
        glDeleteTextures(1, &renderGroup->textureName);
    }
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
// Convert a CATransform3D to normal Chart Matrix
// CATransfrom3D use CGFloat(aka double), we need to convert the data type
PYChartMatrix4 PYChartMatrixFromCATransform3D(const CATransform3D transform)
{
    PYChartMatrix4 _m;
    float *_pm = &_m.m11;
    const CGFloat *_cm = &transform.m11;
    for ( uint8_t i = 0; i < 16; ++i ) {
        _pm[i] = _cm[i];
    }
    return _m;
}

CATransform3D PYChartMatrixToCATransform3D(const PYChartMatrix4 transform)
{
    CATransform3D _m;
    CGFloat *_pm = &_m.m11;
    const float *_cm = &transform.m11;
    for ( uint8_t i = 0; i < 16; ++i ) {
        _pm[i] = _cm[i];
    }
    return _m;
}

// Multiply two matrix
PYChartMatrix4 PYChartMatrixMultiply(PYChartMatrix4 m1, PYChartMatrix4 m2)
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

// Calculate the length of two point
float PYChart3DLengthBetweenTwoVertex3(PYChart3DVertex3 v1, PYChart3DVertex3 v2)
{
    return powf(powf(v1.x - v2.x, 2) +
                powf(v1.y - v2.y, 2) +
                powf(v1.z - v2.z, 2),
                .5);
}

GLuint PYChart3DCreateTextureFromImage(CGImageRef imgRef)
{
    size_t width = CGImageGetWidth(imgRef) * [UIScreen mainScreen].scale;
    size_t height = CGImageGetHeight(imgRef) * [UIScreen mainScreen].scale;
    
    GLubyte *_imgData = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
    CGContextRef _imgCtx = CGBitmapContextCreate(_imgData, width, height, 8, width * 4,
                                                 CGImageGetColorSpace(imgRef),
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(_imgCtx, CGRectMake(0, 0, width, height), imgRef);
    CGContextRelease(_imgCtx);
    
    GLuint _texName;
    glGenTextures(1, &_texName);
    glBindTexture(GL_TEXTURE_2D, _texName);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width,
                 (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, _imgData);
    
    free(_imgData);
    return _texName;
}

UIImage* PYChart3DCreateImageFromTextWithBounds(NSString *text, UIColor *color, CGSize bounds)
{
    size_t width = bounds.width;
    size_t height = bounds.height;
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, [UIScreen mainScreen].scale);
    [text
     drawInRect:CGRectMake(0, 0, bounds.width, bounds.height)
     withAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:bounds.height * 0.95],
                      NSForegroundColorAttributeName: color,
                      NSBackgroundColorAttributeName: [UIColor clearColor]}];
    UIImage *_result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return _result;
}

GLuint PYChart3DCreateTextureFromTextWithBounds(NSString *text, UIColor *color, CGSize bounds)
{
    UIImage *_textImage = PYChart3DCreateImageFromTextWithBounds(text, color, bounds);
    return PYChart3DCreateTextureFromImage(_textImage.CGImage);
}

void PYChart3DReplaceTextureOfRenderGroup(PYChart3DRenderGroup *rg, GLuint newTexture)
{
    if ( rg->textureName != (GLuint)-1 ) {
        glDeleteTextures(1, &rg->textureName);
    }
    rg->textureName = newTexture;
}

PYChart3DRenderGroup PYChartCreateArrowLine
(
 PYChart3DVertex3 from,
 PYChart3DVertex3 to,
 UIColor *color
 )
{
    PYChart3DRenderGroup _rg;
    PYChart3DRenderGroupGenBuffer(&_rg);
    _rg.renderType = GL_LINES;
    _rg.vertices = (PYChart3DVertex *)calloc(4, sizeof(PYChart3DVertex));
    _rg.vertexCount = 4;
    _rg.indices = (GLuint *)malloc(sizeof(GLuint) * 3 * 2);
    _rg.indexCount = 3 * 2;
    
    _rg.vertices[0].position = from;
    _rg.vertices[1].position = to;
    
    if ( from.x == to.x && from.y == to.y ) {
        // Specifial line
        _rg.vertices[2].position = PYChart3DVertex3Make(from.x, to.y - 0.15, to.z - 0.15);
        _rg.vertices[3].position = PYChart3DVertex3Make(from.x, to.y + 0.15, to.z - 0.15);
    } else {
        float _l = pow(pow(to.x - from.x, 2) + pow(to.y - from.y, 2) + pow(to.z - from.z, 2), 0.5);
        float _ls = pow(pow(to.x - from.x, 2) + pow(to.y - from.y, 2), 0.5);
        float _cos = _ls / _l;
        float _sin = fabsf((from.z - to.z) / _l);
        float _coss = fabsf((to.x - from.x)) / _ls;
        float _sins = fabsf((to.y - from.y)) / _ls;
        float _lAEs = _ls - (0.15 * _cos);
        float _Ez = _sin * _l + from.z;
        if ( to.x == from.x ) {
            float _Ey = from.y + _lAEs * (to.y > from.y ? 1 : -1);
            _rg.vertices[2].position = PYChart3DVertex3Make(from.x - 0.15, _Ey, _Ez);
            _rg.vertices[3].position = PYChart3DVertex3Make(from.x + 0.15, _Ey, _Ez);
        } else {
            float _ks = (to.y - from.y) / (to.x - from.x);
            float _Ex = from.x + _lAEs;
            float _Ey = _ks * _Ex + to.y - _ks * to.x;
            float _lCDsx = 0.3 * _sins / 2.f * (to.x > from.x ? 1 : -1);
            float _lCDsy = 0.3 * _coss / 2.f * (to.y > from.y ? 1 : -1);
            _rg.vertices[2].position = PYChart3DVertex3Make(_Ex - _lCDsx, _Ey + _lCDsy, _Ez);
            _rg.vertices[3].position = PYChart3DVertex3Make(_Ex + _lCDsx, _Ey - _lCDsy, _Ez);
        }
    }
    PYColorInfo _ci = color.colorInfo;
    PYChart3DVertex4 _color = PYChart3DVertex4Make(_ci.red, _ci.green, _ci.blue, _ci.alpha);
    for ( uint32_t i = 0; i < 4; ++i ) {
        _rg.vertices[i].color = _color;
    }
    
    PYCHART_SET_INDEX_GROUP(_rg.indices, 0, 0, 1);
    PYCHART_SET_INDEX_GROUP(_rg.indices, 1, 1, 2);
    PYCHART_SET_INDEX_GROUP(_rg.indices, 2, 1, 3);
    
    return _rg;
}

PYChart3DRenderGroup PYChartCreateRuler
(
 PYChart3DVertex3 tl, PYChart3DVertex3 tr,
 PYChart3DVertex3 bl, PYChart3DVertex3 br,
 uint32_t hLineCount, uint32_t vLineCount, UIColor *color
 )
{
    PYChart3DRenderGroup _rg;
    PYChart3DRenderGroupGenBuffer(&_rg);
    _rg.renderType = GL_LINES;
    
    PYColorInfo _ci = color.colorInfo;
    PYChart3DVertex4 _color = PYChart3DVertex4Make(_ci.red, _ci.green, _ci.blue, _ci.alpha);
    // A line has two points, a rule has two directions
    _rg.vertexCount = (hLineCount * 2 + vLineCount * 2);
    _rg.vertices = (PYChart3DVertex *)calloc(_rg.vertexCount, sizeof(PYChart3DVertex));
    PYChart3DVertex3 _tDelta = PYChart3DVertex3Make((tr.x - tl.x) / (hLineCount - 1),
                                                    (tr.y - tl.y) / (hLineCount - 1),
                                                    (tr.z - tl.z) / (hLineCount - 1));
    PYChart3DVertex3 _bDelta = PYChart3DVertex3Make((br.x - bl.x) / (hLineCount - 1),
                                                    (br.y - bl.y) / (hLineCount - 1),
                                                    (br.z - bl.z) / (hLineCount - 1));
    PYChart3DVertex3 _lDelta = PYChart3DVertex3Make((bl.x - tl.x) / (vLineCount - 1),
                                                    (bl.y - tl.y) / (vLineCount - 1),
                                                    (bl.z - tl.z) / (vLineCount - 1));
    PYChart3DVertex3 _rDelta = PYChart3DVertex3Make((br.x - tr.x) / (vLineCount - 1),
                                                    (br.y - tr.y) / (vLineCount - 1),
                                                    (br.z - tr.z) / (vLineCount - 1));
    for ( uint32_t i = 0; i < hLineCount; ++i ) {
        _rg.vertices[0 * hLineCount + i].position = PYChart3DVertex3Make(tl.x + _tDelta.x * i,
                                                                         tl.y + _tDelta.y * i,
                                                                         tl.z + _tDelta.z * i);
        _rg.vertices[0 * hLineCount + i].color = _color;
        _rg.vertices[1 * hLineCount + i].position = PYChart3DVertex3Make(
                                                                         bl.x + _bDelta.x * i,
                                                                         bl.y + _bDelta.y * i,
                                                                         bl.z + _bDelta.z * i);
        _rg.vertices[1 * hLineCount + i].color = _color;
    }
    
    uint32_t _skippedCount = 2 * hLineCount;
    for ( uint32_t i = 0; i < vLineCount; ++i ) {
        _rg.vertices[_skippedCount + 0 * vLineCount + i].position = PYChart3DVertex3Make(
                                                                                         tl.x + _lDelta.x * i,
                                                                                         tl.y + _lDelta.y * i,
                                                                                         tl.z + _lDelta.z * i);
        _rg.vertices[_skippedCount + 0 * vLineCount + i].color = _color;
        _rg.vertices[_skippedCount + 1 * vLineCount + i].position = PYChart3DVertex3Make(
                                                                                         tr.x + _rDelta.x * i,
                                                                                         tr.y + _rDelta.y * i,
                                                                                         tr.z + _rDelta.z * i);
        _rg.vertices[_skippedCount + 1 * vLineCount + i].color = _color;
    }
    
    _rg.indexCount = (hLineCount * 2 + vLineCount * 2);
    _rg.indices = (GLuint *)malloc(sizeof(GLuint) * _rg.indexCount);
    for ( uint32_t i = 0; i < hLineCount; ++i ) {
        PYCHART_SET_INDEX_GROUP(_rg.indices, i, 0 * hLineCount + i, 1 * hLineCount + i);
    }
    for ( uint32_t i = 0; i < vLineCount; ++i ) {
        PYCHART_SET_INDEX_GROUP(_rg.indices, hLineCount + i, _skippedCount + i, _skippedCount + 1 * vLineCount + i);
    }
    
    return _rg;
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
    PYChart3DVertex* _v = (PYChart3DVertex *)calloc(pieces * 4, sizeof(PYChart3DVertex));
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
    PYChartMatrix4 _toZero = PYChartMatrixFromCATransform3D(CATransform3DMakeTranslation(-center.x, -center.y, -center.z));
    PYChartMatrix4 _comeBack = PYChartMatrixFromCATransform3D(CATransform3DMakeTranslation(center.x, center.y, center.z));
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

PYChart3DRenderGroup PYChartCreateCycle
(
 PYChart3DVertex3 center,
 uint32_t pieces,
 float radius,
 float thickness,
 float height,
 PYChartMatrix4 transform,
 UIColor *color
 )
{
    PYChart3DRenderGroup _rg;
    PYChart3DRenderGroupGenBuffer(&_rg);
    
    _rg.vertices = PYChartCreateCycleVerticesWithColor
    (center, pieces, radius, thickness, height, &_rg.vertexCount, transform, color);
    _rg.indices = PYChartCreateCycleIndicies(pieces, &_rg.indexCount);
    
    return _rg;
}

PYChart3DVertex* PYChartCreateSurfaceVertices(PYChartSurfaceDirection direction,
                                              float value, UIColor *color,
                                              uint32_t *count)
{
    PYChart3DVertex *_v = (PYChart3DVertex *)calloc(4, sizeof(PYChart3DVertex));
    
    if ( direction == PYChartSurfaceDirectionX ) {
        _v[0].position = PYChart3DVertex3Make(value, 3.f, 3.f);
        _v[1].position = PYChart3DVertex3Make(value, 3.f, 0.f);
        _v[2].position = PYChart3DVertex3Make(value, -3.f, 0.f);
        _v[3].position = PYChart3DVertex3Make(value, -3.f, 3.f);
    } else if ( direction == PYChartSurfaceDirectionY) {
        _v[0].position = PYChart3DVertex3Make(3.f, value, 3.f);
        _v[1].position = PYChart3DVertex3Make(3.f, value, 0.f);
        _v[2].position = PYChart3DVertex3Make(-3.f, value, 0.f);
        _v[3].position = PYChart3DVertex3Make(-3.f, value, 3.f);
    } else {
        _v[0].position = PYChart3DVertex3Make(3.f, 3.f, value);
        _v[1].position = PYChart3DVertex3Make(3.f, -3.f, value);
        _v[2].position = PYChart3DVertex3Make(-3.f, -3.f, value);
        _v[3].position = PYChart3DVertex3Make(-3.f, 3.f, value);
    }
    PYColorInfo _ci = color.colorInfo;
    PYChart3DVertex4 _color = PYChart3DVertex4Make(_ci.red, _ci.green, _ci.blue, _ci.alpha);
    for ( int i = 0; i < 4; ++i ) {
        _v[i].color = _color;
    }
    
    if ( count != NULL ) *count = 4;
    
    return _v;
}
GLuint* PYChartCreateSurfaceIndicies(uint32_t *count)
{
    GLuint *_v = (GLuint *)malloc(sizeof(GLuint) * 3 * 2);
    
    PYCHART_SET_TRIANGLE_INDEX_GROUP(_v, 0, 0, 1, 2);
    PYCHART_SET_TRIANGLE_INDEX_GROUP(_v, 1, 2, 3, 0);
    
    if ( count != NULL ) *count = 6;
    
    return _v;
}
PYChart3DRenderGroup PYChartCreateSurface(PYChartSurfaceDirection direction, float value, UIColor *color)
{
    PYChart3DRenderGroup _rg;
    PYChart3DRenderGroupGenBuffer(&_rg);
    
    _rg.vertices = PYChartCreateSurfaceVertices(direction, value, color, &_rg.vertexCount);
    _rg.indices = PYChartCreateSurfaceIndicies(&_rg.indexCount);
    
    return _rg;
}

PYChart3DRenderGroup PYChartCreateSurfaceWithText
(
 PYChart3DVertex3 tl,
 PYChart3DVertex3 tr,
 PYChart3DVertex3 bl,
 PYChart3DVertex3 br,
 NSString *text,
 UIColor *textColor
 )
{
    PYChart3DRenderGroup _rg;
    PYChart3DRenderGroupGenBuffer(&_rg);
    
    float _ts = PYChart3DLengthBetweenTwoVertex3(tl, tr);
    float _ls = PYChart3DLengthBetweenTwoVertex3(tl, bl);
    float _bs = PYChart3DLengthBetweenTwoVertex3(bl, br);
    float _rs = PYChart3DLengthBetweenTwoVertex3(tr, br);
    
    float _maxWidth = MAX(_ts, _bs);
    float _maxHeight = MAX(_ls, _rs);
    CGSize _bounds = CGSizeMake(_maxWidth * 50, _maxHeight * 50);
    _rg.textureName = PYChart3DCreateTextureFromTextWithBounds(text, textColor, _bounds);
    //_rg.textureName = PYChart3DCreateTextureFromImage([UIImage imageNamed:@"item_powerup_fish.png"].CGImage);
    
    _rg.vertexCount = 4;
    _rg.vertices = (PYChart3DVertex *)malloc(sizeof(PYChart3DVertex) * _rg.vertexCount);
    PYColorInfo _ci = [UIColor whiteColor].colorInfo;
    PYChart3DVertex4 _color = PYChart3DVertex4Make(_ci.red, _ci.green, _ci.blue, _ci.alpha);
    _rg.vertices[0].position = tl;
    _rg.vertices[0].color = _color;
    _rg.vertices[0].texCoord = PYChart3DVertex2Make(0, 0);
    
    _rg.vertices[1].position = tr;
    _rg.vertices[1].color = _color;
    _rg.vertices[1].texCoord = PYChart3DVertex2Make(1, 0);
    
    _rg.vertices[2].position = bl;
    _rg.vertices[2].color = _color;
    _rg.vertices[2].texCoord = PYChart3DVertex2Make(0, 1);
    
    _rg.vertices[3].position = br;
    _rg.vertices[3].color = _color;
    _rg.vertices[3].texCoord = PYChart3DVertex2Make(1, 1);
    
    _rg.indexCount = 2 * 3;
    _rg.indices = (GLuint *)malloc(sizeof(GLuint) * _rg.indexCount);
    
    PYCHART_SET_TRIANGLE_INDEX_GROUP(_rg.indices, 0, 0, 1, 2);
    PYCHART_SET_TRIANGLE_INDEX_GROUP(_rg.indices, 1, 1, 2, 3);
    
    return _rg;
}
void PYChartSurfaceChangeText
(
 PYChart3DRenderGroup *rg,
 NSString *text,
 UIColor *textColor
 )
{
    float _ts = PYChart3DLengthBetweenTwoVertex3(rg->vertices[0].position, rg->vertices[1].position);
    float _ls = PYChart3DLengthBetweenTwoVertex3(rg->vertices[0].position, rg->vertices[2].position);
    float _bs = PYChart3DLengthBetweenTwoVertex3(rg->vertices[2].position, rg->vertices[3].position);
    float _rs = PYChart3DLengthBetweenTwoVertex3(rg->vertices[1].position, rg->vertices[3].position);
    
    float _maxWidth = MAX(_ts, _bs);
    float _maxHeight = MAX(_ls, _rs);
    CGSize _bounds = CGSizeMake(_maxWidth * 50, _maxHeight * 50);
    GLuint _newTextTex = PYChart3DCreateTextureFromTextWithBounds(text, textColor, _bounds);
    PYChart3DReplaceTextureOfRenderGroup(rg, _newTextTex);
}

PYChart3DRenderGroup PYChartCreateFire(PYChart3DVertex3 from, PYChart3DVertex3 to)
{
    PYChart3DRenderGroup _rg;
    PYChart3DRenderGroupGenBuffer(&_rg);
    
    uint32_t _p = 48;
    _rg.vertexCount = 2 + _p * 36;
    _rg.vertices = (PYChart3DVertex *)calloc(_rg.vertexCount, sizeof(PYChart3DVertex));
    
    _rg.indexCount = 2 * 36 * 3 + (_p - 1) * 36 * 2 * 3;
    _rg.indices = (GLuint *)malloc(sizeof(GLuint) * _rg.indexCount);
    
    _rg.vertices[0].position = from;
    _rg.vertices[0].color = PYChart3DVertex4Make(1, 1, .5, .5);
    float a = (to.y + from.y) / 2;
    float b = (to.z + from.z) / 2/* + _randomDelta*/;
    float d = (to.x - from.x) / (_p + 1);
    float *_rds = (float *)malloc(sizeof(float) * _p);
    float _p0 = 0.2 * (to.x - from.x), _p1 = 0.3 * (to.x - from.x), _p2 = 0;
    for ( uint32_t i = 0; i < _p; ++i ) {
        float _t = (float)i / (float)_p;
        _rds[i] = (1 - _t) * (1 - _t) * _p0 + 2 * _t * (1 - _t) * _p1 + _t * _t * _p2;
    }
    float _corner = M_PI * 2 / 36.f;
    for ( uint32_t i = 0; i < _p; ++i ) {
        //        float _randomDelta = [PYRandom randomRealBetween:0.01 to:0.03];
        float rd = _rds[i]/* + _randomDelta*/;
        //        float b = (to.z + from.z) / 2/* + _randomDelta*/;
        for ( uint32_t r = 0; r < 36; ++r ) {
            float _c = r * _corner;
            float _cos = cosf(_c);
            float _sin = sinf(_c);
            float _cosY = _cos * rd + a;
            float _sinZ = _sin * rd + b;
            _rg.vertices[1 + i * 36 + r].position = PYChart3DVertex3Make(from.x + d * (i + 1), _cosY, _sinZ);
            _rg.vertices[1 + i * 36 + r].color = PYChart3DVertex4Make([PYRandom randomRealBetween:.85 to:1],
                                                                      [PYRandom randomRealBetween:.1 to:.7],
                                                                      [PYRandom randomRealBetween:.05 to:.1],
                                                                      [PYRandom randomRealBetween:.75 to:1]);
        }
    }
    free(_rds);
    _rg.vertices[_rg.vertexCount - 1].position = to;
    _rg.vertices[_rg.vertexCount - 1].color = PYChart3DVertex4Make(1, 1, .5, .5);
    
    uint32_t _indexCount = 0;
    for ( uint32_t i = 0; i < 36; ++i ) {
        uint32_t _c1 = i + 1;
        uint32_t _c2 = i + 2;
        if ( _c2 > 36 ) _c2 = 1;
        PYCHART_SET_TRIANGLE_INDEX_GROUP(_rg.indices, i, 0, _c1, _c2);
        _indexCount += 1;
    }
    
    for ( uint32_t i = 0; i < _p - 1; ++i ) {
        for ( uint32_t r = 0; r < 36; ++r ) {
            uint32_t _c1 = r;
            uint32_t _c2 = (r == 35 ? 0 : r + 1);
            PYCHART_SET_TRIANGLE_INDEX_GROUP(_rg.indices,
                                             _indexCount,
                                             1 + i * 36 + _c1,
                                             1 + (i + 1) * 36 + _c1,
                                             1 + (i + 1) * 36 + _c2);
            _indexCount += 1;
            PYCHART_SET_TRIANGLE_INDEX_GROUP(_rg.indices,
                                             _indexCount,
                                             1 + i * 36 + _c1,
                                             1 + (i + 1) * 36 + _c2,
                                             1 + i * 36 + _c2);
            _indexCount += 1;
        }
    }
    
    uint32_t _beginVertex = 1 + (_p - 1) * 36;
    for ( uint32_t i = 0; i < 36; ++i ) {
        uint32_t _c1 = _beginVertex + i;
        uint32_t _c2 = ( i == 35 ? _beginVertex : _beginVertex + i + 1);
        PYCHART_SET_TRIANGLE_INDEX_GROUP(_rg.indices, _indexCount, _c1, _c2, _rg.vertexCount - 1);
        _indexCount += 1;
    }
    return _rg;
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


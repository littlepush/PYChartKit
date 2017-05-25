//
//  PYChartSurface3D.m
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

#import "PYChartSurface3D.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <PYCore/PYCore.h>

/*
 attribute vec4 Position;
 attribute vec4 SourceColor;
 varying vec4 DestinationColor;
 uniform mat4 Projection;
 uniform mat4 Modelview;
 void main(void) {
 DestinationColor = SourceColor;
 gl_Position = Projection * Modelview * Position;
 }
 */
NSString * PYChartVertexShadarString;
/*
 varying lowp vec4 DestinationColor;
 void main(void) {
 gl_FragColor = DestinationColor;
 }
 */
NSString * PYChartFragmentShadarString;

typedef struct {
    float position[3];
    float color[4];
} PYChart3DVertex;

typedef struct {
    // Matrix data order in:
    float m11, m12, m13, m14;
    float m21, m22, m23, m24;
    float m31, m32, m33, m34;
    float m41, m42, m43, m44;
} PYChartMatrix;

void glMatrixFrustum(PYChartMatrix *m, float left, float right, float bottom, float top, float near, float far) {
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
}

void copyCATransform3DtoMatrix(const CATransform3D *transform, PYChartMatrix *m)
{
    m->m11 = (float)transform->m11;
    m->m12 = (float)transform->m12;
    m->m13 = (float)transform->m13;
    m->m14 = (float)transform->m14;
    m->m21 = (float)transform->m21;
    m->m22 = (float)transform->m22;
    m->m23 = (float)transform->m23;
    m->m24 = (float)transform->m24;
    m->m31 = (float)transform->m31;
    m->m32 = (float)transform->m32;
    m->m33 = (float)transform->m33;
    m->m34 = (float)transform->m34;
    m->m41 = (float)transform->m41;
    m->m42 = (float)transform->m42;
    m->m43 = (float)transform->m43;
    m->m44 = (float)transform->m44;
}

float _lagrange(float* _knownX, float* _knownY, uint32_t count, float x)
{
    float *_lvalue = (float *)malloc(sizeof(float) * count);
    float _y = 0.f;
    for ( uint32_t p = 0; p < count; ++p ) {
        float _t1 = 1.0, _t2 = 1.0;
        for ( uint32_t q = 0; q < count; ++q ) {
            if ( q == p ) continue;
            _t1 *= (x - _knownX[q]);
            _t2 *= (_knownX[p] - _knownX[q]);
        }
        _lvalue[p] = _t1 / _t2;
    }
    for ( uint32_t i = 0; i < count; ++i ) {
        _y += _knownY[i] * _lvalue[i];
    }
    free(_lvalue);
    return _y;
}

@interface PYChartSurface3D () <UIGestureRecognizerDelegate>
{
    CAEAGLLayer                     *_eaglLayer;
    EAGLContext                     *_context;
    GLuint                          _colorRenderBuffer;
    GLuint                          _depthRenderBuffer;
    GLuint                          _frameBuffer;
    GLuint                          _positionSlot;
    GLuint                          _colorSolt;
    GLuint                          _projectionUniform;
    GLuint                          _modelViewUniform;
    GLuint                          _verticesBuffer;
    GLuint                          _indicesBuffer;
    
    float                           _currentRotation;
    CGFloat                         _lastPanX;
    
    PYChartSurface3DVertexTable     _table;
    NSUInteger                      _expandTimes;
    PYChart3DVertex                 *_vertices;
    uint32_t                        _vertixCount;
    GLubyte                         *_indices;
    uint32_t                        _indexCount;
    
    // Grid Related
    BOOL                            _displayGrid;
    GLuint                          _gridVerticesBuffer;
    GLuint                          _gridIndexBuffer;
    PYChart3DVertex                 *_gridVertices;
    UIColor                         *_gridLineColor;
    CGFloat                         _gridLineWidth;
}

@end

@implementation PYChartSurface3D

@synthesize delegate;

@synthesize displayGrid = _displayGrid;
- (void)setDisplayGrid:(BOOL)displayGrid
{
    _displayGrid = displayGrid;
    [self render];
}

@synthesize gridColor = _gridLineColor;
- (void)setGridColor:(UIColor *)gridColor
{
    _gridLineColor = [gridColor copy];
    if ( _gridVertices == NULL ) return;
    PYColorInfo _pi = _gridLineColor.colorInfo;
    for ( uint32_t i = 0; i < _vertixCount; ++i ) {
        _gridVertices[i].color[0] = _pi.red;
        _gridVertices[i].color[1] = _pi.green;
        _gridVertices[i].color[2] = _pi.blue;
        _gridVertices[i].color[3] = _pi.alpha;
    }
    if ( _displayGrid ) [self render];
}

@synthesize gridLineWidth = _gridLineWidth;
- (void)setGridLineWidth:(CGFloat)gridLineWidth
{
    _gridLineWidth = gridLineWidth;
    if ( _displayGrid ) [self render];
}

+ (void)initialize
{
    PYChartVertexShadarString = [NSString stringWithFormat:@"%@;\n%@;\n%@;\n%@;\n%@;\n%@\n%@;\n%@;\n%@",
                                 @"attribute vec4 _pos",
                                 @"attribute vec4 _srcClr",
                                 @"varying vec4 _destClr",
                                 @"uniform mat4 _projection",
                                 @"uniform mat4 _modelView",
                                 @"void main(void) {",
                                 @"_destClr = _srcClr",
                                 @"gl_Position = _projection * _modelView * _pos",
                                 @"}"];
    PYChartFragmentShadarString = [NSString stringWithFormat:@"%@;\n%@\n%@;\n%@",
                                   @"varying lowp vec4 _destClr",
                                   @"void main(void) {",
                                   @"gl_FragColor = _destClr",
                                   @"}"];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+ (Class)layerClass { return [CAEAGLLayer class]; }

+ (GLuint)compileShadarString:(NSString *)shadarString withType:(GLenum)shaderType
{
    GLuint _shaderHandle = glCreateShader(shaderType);
    
    const char*_shaderStringCStr = shadarString.UTF8String;
    int _shaderStringLength = (int)shadarString.length;
    glShaderSource(_shaderHandle, 1, &_shaderStringCStr, &_shaderStringLength);
    glCompileShader(_shaderHandle);
    
    GLint _success;
    glGetShaderiv(_shaderHandle, GL_COMPILE_STATUS, &_success);
    if ( _success == GL_FALSE ) {
        GLchar _msg[256];
        glGetShaderInfoLog(_shaderHandle, sizeof(_msg), 0, &_msg[0]);
        PYLog(@"%s", _msg);
        return (GLuint)-1;
    }
    return _shaderHandle;
}

// Initialize the OpenGL Context
- (BOOL)setupContext
{
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context) {
        PYLog(@"Failed to initialize OpenGLES 2.0 context");
        return NO;
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        PYLog(@"Failed to set current OpenGL context");
        return NO;
    }
    return YES;
}

- (void)resizeBuffer {
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16,
                          self.frame.size.width * _eaglLayer.contentsScale,
                          self.frame.size.height * _eaglLayer.contentsScale);

    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _colorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                              GL_RENDERBUFFER, _depthRenderBuffer);
}

- (BOOL)compileShaders {
    GLuint _vertexShader = [PYChartSurface3D
                            compileShadarString:PYChartVertexShadarString
                            withType:GL_VERTEX_SHADER];
    GLuint _fragmentShader = [PYChartSurface3D
                              compileShadarString:PYChartFragmentShadarString
                              withType:GL_FRAGMENT_SHADER];
    
    GLuint _programHandle = glCreateProgram();
    glAttachShader(_programHandle, _vertexShader);
    glAttachShader(_programHandle, _fragmentShader);
    glLinkProgram(_programHandle);
    
    GLint _success;
    glGetProgramiv(_programHandle, GL_LINK_STATUS, &_success);
    if ( _success == GL_FALSE ) {
        GLchar _msg[256];
        glGetProgramInfoLog(_programHandle, sizeof(_msg), 0, &_msg[0]);
        PYLog(@"%s", _msg);
        return NO;
    }
    
    glUseProgram(_programHandle);
    
    _positionSlot = glGetAttribLocation(_programHandle, "_pos");
    _colorSolt = glGetAttribLocation(_programHandle, "_srcClr");
    _projectionUniform = glGetUniformLocation(_programHandle, "_projection");
    _modelViewUniform = glGetUniformLocation(_programHandle, "_modelView");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSolt);
    return YES;
}

- (void)setupVBOs {
    glGenBuffers(1, &_verticesBuffer);
    glGenBuffers(1, &_indicesBuffer);
    glGenBuffers(1, &_gridVerticesBuffer);
    glGenBuffers(1, &_gridIndexBuffer);
}

- (void)render {
    if ( !_context ) return;
    if ( _vertices == NULL ) return;
    PYColorInfo _ci = [self backgroundColor].colorInfo;
    glClearColor(_ci.red, _ci.green, _ci.blue, 1.f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);

    float h = 4.0f * self.frame.size.height / self.frame.size.width;
    PYChartMatrix _mProj;
    glMatrixFrustum(&_mProj, -2, 2, -h/2, h/2, 4, 10);
    glUniformMatrix4fv(_projectionUniform, 1, 0, &_mProj.m11);

    CATransform3D _modelTransform = CATransform3DMakeTranslation(0, 0, -7);
    _modelTransform = CATransform3DRotate(_modelTransform, -(M_PI_2 / 3 * 2 + M_PI_4 / 3), 1, 0, 0);
    _modelTransform = CATransform3DRotate(_modelTransform, _currentRotation, 0, 0, 1);
    PYChartMatrix _mModel;
    copyCATransform3DtoMatrix(&_modelTransform, &_mModel);
    glUniformMatrix4fv(_modelViewUniform, 1, 0, &_mModel.m11);

    glViewport(0, 0,
               self.frame.size.width * _eaglLayer.contentsScale,
               self.frame.size.height * _eaglLayer.contentsScale);

    glBindBuffer(GL_ARRAY_BUFFER, _verticesBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(PYChart3DVertex) * _vertixCount, _vertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indicesBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLubyte) * _indexCount, _indices, GL_STATIC_DRAW);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(PYChart3DVertex), 0);
    glVertexAttribPointer(_colorSolt, 4, GL_FLOAT, GL_FALSE, sizeof(PYChart3DVertex), (GLvoid *)(sizeof(float) * 3));
    glDrawElements(GL_TRIANGLES, _indexCount, GL_UNSIGNED_BYTE, 0);
    
    if ( _displayGrid ) {
        glLineWidth(_eaglLayer.contentsScale * _gridLineWidth);
        glBindBuffer(GL_ARRAY_BUFFER, _gridVerticesBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(PYChart3DVertex) * _vertixCount, _gridVertices, GL_STATIC_DRAW);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _gridIndexBuffer);
        uint32_t _row = (_table.row - 1) * (uint32_t)_expandTimes + 1;
        uint32_t _col = (_table.column - 1) * (uint32_t)_expandTimes + 1;
        GLubyte *_rowIndex = (GLubyte *)malloc(sizeof(GLubyte) * (_col - 1) * 2);
        for ( uint32_t r = 0; r < _row; ++r ) {
            for ( uint32_t c = 0; c < _col - 1; ++c ) {
                _rowIndex[2 * c + 0] = r * _col + c;
                _rowIndex[2 * c + 1] = r * _col + c + 1;
            }
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLubyte) * (_col - 1) * 2, _rowIndex, GL_STATIC_DRAW);
            glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(PYChart3DVertex), 0);
            glVertexAttribPointer(_colorSolt, 4, GL_FLOAT, GL_FALSE, sizeof(PYChart3DVertex), (GLvoid *)(sizeof(float) * 3));
            glDrawElements(GL_LINES, (_col - 1) * 2, GL_UNSIGNED_BYTE, 0);
        }
        free(_rowIndex);
        
        GLubyte *_colIndex = (GLubyte *)malloc(sizeof(GLubyte) * (_row - 1) * 2);
        for ( uint32_t c = 0; c < _col; ++c ) {
            for ( uint32_t r = 0; r < _row - 1; ++r ) {
                _colIndex[2 * r + 0] = r * _col + c;
                _colIndex[2 * r + 1] = (r + 1) * _col + c;
            }
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLubyte) * (_row - 1) * 2, _colIndex, GL_STATIC_DRAW);
            glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(PYChart3DVertex), 0);
            glVertexAttribPointer(_colorSolt, 4, GL_FLOAT, GL_FALSE, sizeof(PYChart3DVertex), (GLvoid *)(sizeof(float) * 3));
            glDrawElements(GL_LINES, (_row - 1) * 2, GL_UNSIGNED_BYTE, 0);
        }
        free(_colIndex);
    }

    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    if ( _context != nil ) [self render];
}

- (void)drawRect:(CGRect)rect
{
    if ( rect.size.width == 0 || rect.size.height == 0 ) return;
    [self render];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    if ( _context != nil ) {
        [self resizeBuffer];
    }
    PYLog(@"frame has been changed");
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    _lastPanX = [gestureRecognizer locationInView:self].x;
    return YES;
}

- (void)panGestureHandle:(UIPanGestureRecognizer *)gesture
{
    CGPoint _touchPoint = [gesture locationInView:self];
    CGFloat _delta = _touchPoint.x - _lastPanX;
    _lastPanX = _touchPoint.x;
    CGFloat _max = self.frame.size.width;
    _currentRotation += (_delta / _max) * (2 * M_PI);
    [self render];
}

- (void)viewJustBeenCreated
{
    [super viewJustBeenCreated];
    _vertices = NULL;
    _indices = NULL;
    _gridVertices = NULL;
    _currentRotation = 0.f;
    
    // Grid
    _gridLineWidth = 1.5f;
    _gridLineColor = [UIColor darkGrayColor];
    _displayGrid = YES;
    
    UIPanGestureRecognizer *_pg = [[UIPanGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(panGestureHandle:)];
    _pg.delegate = self;
    [self addGestureRecognizer:_pg];
    
    _eaglLayer = (CAEAGLLayer *)self.layer;
    _eaglLayer.opaque = YES;
    _eaglLayer.contentsScale = [[UIScreen mainScreen] scale];
    
    [self setBackgroundColor:[UIColor whiteColor]];
    if ( ![self setupContext] ) return;
    
    // Gen Buffers
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glGenFramebuffers(1, &_frameBuffer);

    // Resize and bind buffer
    if ( self.frame.size.width > 0 && self.frame.size.height > 0 ) {
        [self resizeBuffer];
    }
    [self setupVBOs];
    if ( ![self compileShaders] ) {
        _context = nil;
    };
}

- (void)dealloc
{
    _context = nil;
    if ( _vertices ) free(_vertices);
    if ( _indices ) free(_indices);
    if ( _gridVertices ) free(_gridVertices);
}

// Initialize the surface with specified vertices.
- (void)prepareSurfaceWithVertexTable:(PYChartSurface3DVertexTable)table expandTimes:(NSUInteger)expand
{
    if ( _vertices ) free(_vertices);
    if ( _indices ) free(_indices);
    if ( _gridVertices ) free(_gridVertices);
    _table = table;
    _expandTimes = expand;
    uint32_t _row = (table.row - 1) * (uint32_t)expand + 1;
    uint32_t _col = (table.column - 1) * (uint32_t)expand + 1;
    uint32_t _count = _row * _col;
    _vertixCount = _count;
    _vertices = (PYChart3DVertex *)malloc(sizeof(PYChart3DVertex) * _count);
    _gridVertices = (PYChart3DVertex *)malloc(sizeof(PYChart3DVertex) * _count);
    // Each Trangle need 3 vertices
    uint32_t _tcount = (_row - 1) * (_col - 1) * 2;
    _indexCount = _tcount * 3;
    _indices = (GLubyte *)malloc(sizeof(GLubyte) * _indexCount);
    for ( uint32_t r = 0; r < _row - 1; ++r ) {
        for ( uint32_t c = 0; c < _col - 1; ++c ) {
            uint32_t _beginIndex = ((_col - 1) * r + c) * 6;
            _indices[_beginIndex + 0] = _col * r + c;
            _indices[_beginIndex + 1] = _col * (r + 1) + c;
            _indices[_beginIndex + 2] = _col * (r + 1) + (c + 1);
            _indices[_beginIndex + 3] = _col * (r + 1) + (c + 1);
            _indices[_beginIndex + 4] = _col * r + (c + 1);
            _indices[_beginIndex + 5] = _col * r + c;
        }
    }
}


// Update the surface with vertex's value in Z, the values should contains table.row * table.column data
- (void)updateVertexValues:(float *)values
{
    float _maxValue = 0;
    for ( uint32_t i = 0; i < (_table.row * _table.column); ++i ) {
        float _av = fabsf(values[i]);
        if ( _av > _maxValue ) _maxValue = _av;
    }
    _maxValue *= 1.5;
    for ( uint32_t i = 0; i < (_table.row * _table.column); ++i ) {
        values[i] = (values[i]) / _maxValue * 2;
    }
    BOOL _customizedColor = [self.delegate respondsToSelector:@selector(surface3DChart:colorForValue:)];
    if ( _expandTimes == 1 ) {
        for ( uint32_t r = 0; r < _table.row; ++r ) {
            for ( uint32_t c = 0; c < _table.column; ++c ) {
                uint32_t _i = r * _table.row + c;
                _vertices[_i].position[0] = (float)c / ((float)_table.column - 1) * 4 - 2;
                _vertices[_i].position[1] = -((float)r / ((float)_table.row - 1) * 4 - 2);
                _vertices[_i].position[2] = values[_i];
                UIColor *_tc = nil;
                if ( _customizedColor ) {
                    _tc = [self.delegate surface3DChart:self colorForValue:values[_i] / 2 * _maxValue];
                } else {
                    _tc = [UIColor whiteColor];
                }
                PYColorInfo _ci = _tc.colorInfo;
                _vertices[_i].color[0] = _ci.red;
                _vertices[_i].color[1] = _ci.green;
                _vertices[_i].color[2] = _ci.blue;
                _vertices[_i].color[3] = _ci.alpha;
            }
        }
    } else {
        uint32_t _row = (_table.row - 1) * (uint32_t)_expandTimes + 1;
        uint32_t _col = (_table.column - 1) * (uint32_t)_expandTimes + 1;
        
        float *_cpos = (float *)malloc(sizeof(float) * _table.row);
        float *_zval = (float *)malloc(sizeof(float) * _table.row);
        
        for ( uint32_t c = 0; c < _col; ++c ) {
            if ( (c % _expandTimes) > 0 ) continue;
            for ( uint32_t r = 0; r < _table.row; ++r ) {
                _cpos[r] = -((float)r / ((float)_table.row - 1) * 4 - 2);
                _zval[r] = values[r * _table.row + c / _expandTimes];
            }
            for ( uint32_t r = 0; r < _row; ++r ) {
                uint32_t _i = r * _row + c;
                _vertices[_i].position[0] = (float)c / ((float)_col - 1) * 4 - 2;
                _vertices[_i].position[1] = -((float)r / ((float)_row - 1) * 4 - 2);
                float _value = _lagrange(_cpos, _zval, _table.row, -((float)r / ((float)_row - 1) * 4 - 2));
                _vertices[_i].position[2] = _value;
                UIColor *_tc = nil;
                if ( _customizedColor ) {
                    _tc = [self.delegate surface3DChart:self colorForValue:_value / 2 * _maxValue];
                } else {
                    _tc = [UIColor whiteColor];
                }
                PYColorInfo _ci = _tc.colorInfo;
                _vertices[_i].color[0] = _ci.red;
                _vertices[_i].color[1] = _ci.green;
                _vertices[_i].color[2] = _ci.blue;
                _vertices[_i].color[3] = _ci.alpha;
            }
        }
        free(_cpos);
        free(_zval);
        
        float *_rpos = (float *)malloc(sizeof(float) * _table.column);
        _zval = (float *)malloc(sizeof(float) * _table.column);
        for ( uint32_t r = 0; r < _row; ++r ) {
            for ( uint32_t c = 0; c < _table.column; ++c ) {
                _rpos[c] = (float)c / ((float)_table.column - 1) * 4 - 2;
                _zval[c] = _vertices[r * _row + c * _expandTimes].position[2];
            }
            for ( uint32_t c = 0; c < _col; ++c ) {
                uint32_t _i = r * _row + c;
                _vertices[_i].position[0] = (float)c / ((float)_col - 1) * 4 - 2;
                _vertices[_i].position[1] = -((float)r / ((float)_row - 1) * 4 - 2);
                float _value = _lagrange(_rpos, _zval, _table.column, (float)c / ((float)_col - 1) * 4 - 2);
                _vertices[_i].position[2] = _value;
                UIColor *_tc = nil;
                if ( _customizedColor ) {
                    _tc = [self.delegate surface3DChart:self colorForValue:_value / 2 * _maxValue];
                } else {
                    _tc = [UIColor whiteColor];
                }
                PYColorInfo _ci = _tc.colorInfo;
                _vertices[_i].color[0] = _ci.red;
                _vertices[_i].color[1] = _ci.green;
                _vertices[_i].color[2] = _ci.blue;
                _vertices[_i].color[3] = _ci.alpha;
            }
        }
        free(_rpos);
        free(_zval);
    }
    
    PYColorInfo _pi = _gridLineColor.colorInfo;
    for ( uint32_t i = 0; i < _vertixCount; ++i ) {
        memcpy(_gridVertices[i].position, _vertices[i].position, sizeof(float) * 3);
        _gridVertices[i].color[0] = _pi.red;
        _gridVertices[i].color[1] = _pi.green;
        _gridVertices[i].color[2] = _pi.blue;
        _gridVertices[i].color[3] = _pi.alpha;
    }
    [self render];
}

@end

// @littlepush
// littlepush@gmail.com
// PYLab

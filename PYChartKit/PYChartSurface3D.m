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
#import <PYCore/PYCore.h>
#import "PYChartSurface3DUtility.h"

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

/*float _lagrange(float* _knownX, float* _knownY, uint32_t count, float x)
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
 }*/

@interface PYChart3DRenderGroupObject : NSObject
{
    PYChart3DRenderGroup                _rg;
}
+ (instancetype)objectWithRenderGroup:(PYChart3DRenderGroup)renderGroup;
@property (nonatomic, readonly) PYChart3DRenderGroup renderGroup;
@end

@implementation PYChart3DRenderGroupObject
@synthesize renderGroup = _rg;
+ (instancetype)objectWithRenderGroup:(PYChart3DRenderGroup)renderGroup
{
    PYChart3DRenderGroupObject *_rgo = [PYChart3DRenderGroupObject object];
    _rgo->_rg = renderGroup;
    return _rgo;
}
@end

@interface PYChartSurface3D () <UIGestureRecognizerDelegate>
{
    // Open GL
    CAEAGLLayer                     *_eaglLayer;
    EAGLContext                     *_context;
    GLuint                          _colorRenderBuffer;
    GLuint                          _depthRenderBuffer;
    GLuint                          _frameBuffer;
    
    // Shader
    GLuint                          _positionSlot;
    GLuint                          _colorSolt;
    GLuint                          _projectionUniform;
    GLuint                          _modelViewUniform;
    
    // Grid Related
    BOOL                            _displayGrid;
    UIColor                         *_dataGridLineColor;
    CGFloat                         _dataGridLineWidth;
    // Axes Infos
    BOOL                            _displayAxes;
    CGFloat                         _axesLineWidth;
    UIColor                         *_axesLineColor;
    // Ruler
    BOOL                            _displayRules;
    CGFloat                         _rulesLineWidth;
    UIColor                         *_rulesLineColor;
    // Rotate
    float                           _currentRotationAroundZ;
    float                           _currentRotationAroundX;
    CGFloat                         _lastPanX;
    CGFloat                         _lastPanY;
    // Display Mode
    PYChartSurface3DDisplayMode     _displayMode;
    PYChartSurface3DZoom            _zoomMode;
    
    // Data
    float                           *_cachedValues;
    PYChartSurface3DVertexTable     _table;
    NSUInteger                      _expandTimes;
    
    // Buffers
    PYChart3DRenderGroup            _rgData;
    PYChart3DRenderGroup            _rgDataGrid;
    // X
    PYChart3DRenderGroup            _rgAxesX;
    // Y+
    PYChart3DRenderGroup            _rgAxesYPostive;
    // Y-
    PYChart3DRenderGroup            _rgAxesYNagitive;
    // Z
    PYChart3DRenderGroup            _rgAxesZ;
    // XY
    PYChart3DRenderGroup            _rgRulesXY;
    // YZ
    PYChart3DRenderGroup            _rgRulesYZ;
    
    NSMutableDictionary             *_expendObjects;
}

@end

@implementation PYChartSurface3D

- (void)__glUpdateVerticesOfRenderGroup:(PYChart3DRenderGroup *)rg withNewColor:(UIColor *)color
{
    PYColorInfo _pi = color.colorInfo;
    for ( uint32_t i = 0; i < rg->vertexCount; ++i ) {
        PYCHART_SET_VERTEX_COLOR(rg->vertices[i], _pi);
    }
}
- (void)__glUpdateVertexDataOfRenderGroup:(PYChart3DRenderGroup *)rg drawMode:(GLenum)mode
{
    glBindBuffer(GL_ARRAY_BUFFER, rg->verticesBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(PYChart3DVertex) * rg->vertexCount,
                 rg->vertices, mode);
}
- (void)__glUpdateIndexDataOfRenderGroup:(PYChart3DRenderGroup *)rg drawMode:(GLenum)mode
{
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, rg->indicesBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLuint) * rg->indexCount,
                 rg->indices, mode);
}
- (void)__glUpdateAllDataOfRenderGroup:(PYChart3DRenderGroup *)rg drawMode:(GLenum)mode
{
    [self __glUpdateVertexDataOfRenderGroup:rg drawMode:mode];
    [self __glUpdateIndexDataOfRenderGroup:rg drawMode:mode];
}

@synthesize allowRotateAroundX;
@synthesize allowRotateAroundZ;
@synthesize delegate;

@synthesize displayGrid = _displayGrid;
- (void)setDisplayGrid:(BOOL)displayGrid
{
    _displayGrid = displayGrid;
    [self render];
}

@synthesize gridColor = _dataGridLineColor;
- (void)setGridColor:(UIColor *)gridColor
{
    _dataGridLineColor = [gridColor copy];
    if ( _rgDataGrid.vertices == NULL ) return;
    [self __glUpdateVerticesOfRenderGroup:&_rgDataGrid withNewColor:gridColor];
    // Buffer the data
    [self __glUpdateVertexDataOfRenderGroup:&_rgDataGrid drawMode:GL_STREAM_DRAW];
    if ( _displayGrid ) [self render];
}

@synthesize gridLineWidth = _dataGridLineWidth;
- (void)setGridLineWidth:(CGFloat)gridLineWidth
{
    _dataGridLineWidth = gridLineWidth;
    if ( _displayGrid ) [self render];
}

@synthesize axesColor = _axesLineColor;
- (void)setAxesColor:(UIColor *)axesColor
{
    _axesLineColor = [axesColor copy];
    if ( _rgAxesX.vertices != NULL ) {
        [self __glUpdateVerticesOfRenderGroup:&_rgAxesX withNewColor:axesColor];
        [self __glUpdateVertexDataOfRenderGroup:&_rgAxesX drawMode:GL_STATIC_DRAW];
    }
    if ( _rgAxesYPostive.vertices != NULL ) {
        [self __glUpdateVerticesOfRenderGroup:&_rgAxesYPostive withNewColor:axesColor];
        [self __glUpdateVertexDataOfRenderGroup:&_rgAxesYPostive drawMode:GL_STATIC_DRAW];
    }
    if ( _rgAxesYNagitive.vertices != NULL ) {
        [self __glUpdateVerticesOfRenderGroup:&_rgAxesYNagitive withNewColor:axesColor];
        [self __glUpdateVertexDataOfRenderGroup:&_rgAxesYNagitive drawMode:GL_STATIC_DRAW];
    }
    if ( _rgAxesZ.vertices != NULL ) {
        [self __glUpdateVerticesOfRenderGroup:&_rgAxesZ withNewColor:axesColor];
        [self __glUpdateVertexDataOfRenderGroup:&_rgAxesZ drawMode:GL_STATIC_DRAW];
    }
    if ( _displayAxes ) [self render];
}
@synthesize axesLineWidth = _axesLineWidth;
- (void)setAxesLineWidth:(CGFloat)axesLineWidth
{
    _axesLineWidth = axesLineWidth;
    if ( _displayAxes ) [self render];
}

@synthesize rulesColor = _rulesLineColor;
- (void)setRulesColor:(UIColor *)rulesColor
{
    _rulesLineColor = [rulesColor copy];
    if ( _rgRulesXY.vertices != NULL ) {
        [self __glUpdateVerticesOfRenderGroup:&_rgRulesXY withNewColor:rulesColor];
        [self __glUpdateVertexDataOfRenderGroup:&_rgRulesXY drawMode:GL_STATIC_DRAW];
    }
    if ( _rgRulesYZ.vertices != NULL ) {
        [self __glUpdateVerticesOfRenderGroup:&_rgRulesYZ withNewColor:rulesColor];
        [self __glUpdateVertexDataOfRenderGroup:&_rgRulesYZ drawMode:GL_STATIC_DRAW];
    }
    if ( _displayRules ) [self render];
}
@synthesize rulesLineWidth = _rulesLineWidth;
- (void)setRulesLineWidth:(CGFloat)rulesLineWidth
{
    _rulesLineWidth = rulesLineWidth;
    if ( _displayRules ) [self render];
}

@synthesize displayMode = _displayMode;
- (void)setDisplayMode:(PYChartSurface3DDisplayMode)displayMode
{
    _displayMode = displayMode;
    if ( _cachedValues != NULL ) [self calculateAllVertexValues:_cachedValues];
}

@synthesize zoomMode = _zoomMode;
- (void)setZoomMode:(PYChartSurface3DZoom)zoomMode
{
    _zoomMode = zoomMode;
    if ( _cachedValues != NULL ) {
        [self calculateAllVertexValues:_cachedValues];
    }
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
- (BOOL)__setupGLContext
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

- (void)__resizeGLRenderBuffer {
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

- (BOOL)__compileShader {
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

- (void)__initAllRenderGroup {
    PYChart3DRenderGroupGenBuffer(&_rgData);
    PYChart3DRenderGroupGenBuffer(&_rgDataGrid);
    PYChart3DRenderGroupGenBuffer(&_rgAxesX);
    PYChart3DRenderGroupGenBuffer(&_rgAxesYPostive);
    PYChart3DRenderGroupGenBuffer(&_rgAxesYNagitive);
    PYChart3DRenderGroupGenBuffer(&_rgAxesZ);
    PYChart3DRenderGroupGenBuffer(&_rgRulesXY);
    PYChart3DRenderGroupGenBuffer(&_rgRulesYZ);
}

- (void)__renderVerticesInRenderGroup:(PYChart3DRenderGroup *)rg withDrawType:(GLenum)objType
{
    glBindBuffer(GL_ARRAY_BUFFER, rg->verticesBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, rg->indicesBuffer);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(PYChart3DVertex), 0);
    glVertexAttribPointer(_colorSolt, 4, GL_FLOAT, GL_FALSE, sizeof(PYChart3DVertex), (GLvoid *)(sizeof(float) * 3));
    glDrawElements(objType, rg->indexCount, GL_UNSIGNED_INT, 0);
}

- (void)render {
    PYSingletonLock
    if ( !_context ) return;
    if ( _rgData.vertices == NULL ) return;
    PYColorInfo _ci = [self backgroundColor].colorInfo;
    glClearColor(_ci.red, _ci.green, _ci.blue, 1.f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    // Projection
    float h = 4.0f * self.frame.size.height / self.frame.size.width;
    PYChartMatrix4 _mProj = PYChartMatrixFrustum(-2, 2, -h / 2, h / 2, 4, 15);
    glUniformMatrix4fv(_projectionUniform, 1, 0, &_mProj.m11);
    
    // Rotate
    CATransform3D _modelTransform = CATransform3DMakeTranslation(0, 0, -9);
    _modelTransform = CATransform3DRotate(_modelTransform, _currentRotationAroundX, 1, 0, 0);
    _modelTransform = CATransform3DRotate(_modelTransform, _currentRotationAroundZ, 0, 0, 1);
    _modelTransform = CATransform3DTranslate(_modelTransform, 0, 0, -1);
    PYChartMatrix4 _mModel = PYChartMartixFromCATransform3D(_modelTransform);
    glUniformMatrix4fv(_modelViewUniform, 1, 0, &_mModel.m11);
    
    glViewport(0, 0,
               self.frame.size.width * _eaglLayer.contentsScale,
               self.frame.size.height * _eaglLayer.contentsScale);
    
    // Draw The data
    [self __renderVerticesInRenderGroup:&_rgData withDrawType:GL_TRIANGLES];
    
    if ( _displayGrid ) {
        glLineWidth(_eaglLayer.contentsScale * _dataGridLineWidth);
        [self __renderVerticesInRenderGroup:&_rgDataGrid withDrawType:GL_LINES];
    }
    
    if ( _displayRules ) {
        glLineWidth(_eaglLayer.contentsScale * _rulesLineWidth);
        [self __renderVerticesInRenderGroup:&_rgRulesXY withDrawType:GL_LINES];
        [self __renderVerticesInRenderGroup:&_rgRulesYZ withDrawType:GL_LINES];
    }
    
    if ( _displayAxes ) {
        glLineWidth(_eaglLayer.contentsScale * _axesLineWidth);
        [self __renderVerticesInRenderGroup:&_rgAxesX withDrawType:GL_LINES];
        [self __renderVerticesInRenderGroup:&_rgAxesYPostive withDrawType:GL_LINES];
        [self __renderVerticesInRenderGroup:&_rgAxesYNagitive withDrawType:GL_LINES];
        [self __renderVerticesInRenderGroup:&_rgAxesZ withDrawType:GL_LINES];
    }
    
    for ( NSString *_key in _expendObjects ) {
        PYChart3DRenderGroupObject *_rgo = [_expendObjects objectForKey:_key];
        PYChart3DRenderGroup _rg = _rgo.renderGroup;
        [self __renderVerticesInRenderGroup:&_rg withDrawType:GL_TRIANGLES];
    }
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    PYSingletonUnLock
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
        [self __resizeGLRenderBuffer];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint _tp = [gestureRecognizer locationInView:self];
    _lastPanX = _tp.x;
    _lastPanY = _tp.y;
    return YES;
}

- (void)panGestureHandle:(UIPanGestureRecognizer *)gesture
{
    CGPoint _touchPoint = [gesture locationInView:self];
    if ( self.allowRotateAroundZ ) {
        CGFloat _deltaX = _touchPoint.x - _lastPanX;
        _lastPanX = _touchPoint.x;
        CGFloat _maxX = self.frame.size.width;
        _currentRotationAroundZ += (_deltaX / _maxX) * (2 * M_PI);
    }
    if ( self.allowRotateAroundX ) {
        CGFloat _deltaY = _touchPoint.y - _lastPanY;
        _lastPanY = _touchPoint.y;
        CGFloat _maxY = self.frame.size.height;
        _currentRotationAroundX += (_deltaY / _maxY) * (2 * M_PI);
    }
    [self render];
}

- (void)viewJustBeenCreated
{
    [super viewJustBeenCreated];
    self.allowRotateAroundZ = YES;
    self.allowRotateAroundX = NO;
    _cachedValues = NULL;
    _currentRotationAroundZ = 0.f;
    _currentRotationAroundX = -(M_PI_2 / 3 * 2 + M_PI_4 / 3);
    
    // Grid
    _dataGridLineWidth = 1.5f;
    _dataGridLineColor = [UIColor darkGrayColor];
    _displayGrid = YES;
    
    // Rule
    _displayRules = YES;
    _rulesLineWidth = 0.5f;
    _rulesLineColor = [UIColor lightGrayColor];
    
    // Axes
    _displayAxes = YES;
    _axesLineWidth = 1.f;
    _axesLineColor = [UIColor blackColor];
    
    // Display Mode
    _displayMode = PYChartSurface3DDisplayModeSquare;
    _zoomMode = PYChartSurface3DZoomNormal;
    
    _expendObjects = [NSMutableDictionary dictionary];
    
    UIPanGestureRecognizer *_pg = [[UIPanGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(panGestureHandle:)];
    _pg.delegate = self;
    [self addGestureRecognizer:_pg];
    
    _eaglLayer = (CAEAGLLayer *)self.layer;
    _eaglLayer.opaque = YES;
    _eaglLayer.contentsScale = [[UIScreen mainScreen] scale];
    
    [self setBackgroundColor:[UIColor whiteColor]];
    if ( ![self __setupGLContext] ) return;
    
    // Gen Buffers
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glGenFramebuffers(1, &_frameBuffer);
    
    // Resize and bind buffer
    if ( self.frame.size.width > 0 && self.frame.size.height > 0 ) {
        [self __resizeGLRenderBuffer];
    }
    
    [self __initAllRenderGroup];
    // Create all default data
    _rgAxesX.vertices = PYChartCreateXAxesVerticesWithColor(-3, 3.5, 0, 0, _axesLineColor, &_rgAxesX.vertexCount);
    _rgAxesX.indices = PYChartCreateXAxesIndicies(&_rgAxesX.indexCount);
    [self __glUpdateAllDataOfRenderGroup:&_rgAxesX drawMode:GL_STATIC_DRAW];
    _rgAxesYPostive.vertices = PYChartCreateYAxesVerticesWithColor(0, 3.5, -3, 0, _axesLineColor, &_rgAxesYPostive.vertexCount);
    _rgAxesYPostive.indices = PYChartCreateYAxesIndicies(&_rgAxesYPostive.indexCount);
    [self __glUpdateAllDataOfRenderGroup:&_rgAxesYPostive drawMode:GL_STATIC_DRAW];
    _rgAxesYNagitive.vertices = PYChartCreateYAxesVerticesWithColor(0, -3.5, -3, 0, _axesLineColor, &_rgAxesYNagitive.vertexCount);
    _rgAxesYNagitive.indices = PYChartCreateYAxesIndicies(&_rgAxesYNagitive.indexCount);
    [self __glUpdateAllDataOfRenderGroup:&_rgAxesYNagitive drawMode:GL_STATIC_DRAW];
    _rgAxesZ.vertices = PYChartCreateZAxesVerticesWithColor(0, 3.5, -3, 0, _axesLineColor, &_rgAxesZ.vertexCount);
    _rgAxesZ.indices = PYChartCreateZAxesIndicies(&_rgAxesZ.indexCount);
    [self __glUpdateAllDataOfRenderGroup:&_rgAxesZ drawMode:GL_STATIC_DRAW];
    
    _rgRulesXY.vertices = PYChartCreateXYRulerVerticesWithColor(-3, 3, 3, -3, 0, 0.5, _rulesLineColor, &_rgRulesXY.vertexCount);
    _rgRulesXY.indices = PYChartCreateXYRulerIndicies(-3, 3, 3, -3, 0.5, &_rgRulesXY.indexCount);
    [self __glUpdateAllDataOfRenderGroup:&_rgRulesXY drawMode:GL_STATIC_DRAW];
    _rgRulesYZ.vertices = PYChartCreateYZRulerVerticesWithColor(-3, 3, 0, 3, -3, 0.5, _rulesLineColor, &_rgRulesYZ.vertexCount);
    _rgRulesYZ.indices = PYChartCreateYZRulerIndicies(-3, 3, 0, 3, 0.5, &_rgRulesYZ.indexCount);
    [self __glUpdateAllDataOfRenderGroup:&_rgRulesYZ drawMode:GL_STATIC_DRAW];
    
    if ( ![self __compileShader] ) {
        _context = nil;
    };
}

- (void)dealloc
{
    _context = nil;
    PYChart3DRenderGroupRelease(&_rgData);
    PYChart3DRenderGroupRelease(&_rgDataGrid);
    PYChart3DRenderGroupRelease(&_rgAxesX);
    PYChart3DRenderGroupRelease(&_rgAxesYPostive);
    PYChart3DRenderGroupRelease(&_rgAxesYNagitive);
    PYChart3DRenderGroupRelease(&_rgAxesZ);
    PYChart3DRenderGroupRelease(&_rgRulesXY);
    PYChart3DRenderGroupRelease(&_rgRulesYZ);
    if ( _cachedValues ) free(_cachedValues);
    
    //_expendObjects
    for ( NSString *_key in _expendObjects ) {
        PYChart3DRenderGroupObject *_rgobj = [_expendObjects objectForKey:_key];
        PYChart3DRenderGroup _rg = _rgobj.renderGroup;
        PYChart3DRenderGroupRelease(&_rg);
    }
    [_expendObjects removeAllObjects];
}

// Initialize the surface with specified vertices.
- (void)prepareSurfaceWithVertexTable:(PYChartSurface3DVertexTable)table expandTimes:(NSUInteger)expand
{
    PYSingletonLock
    if ( _rgData.vertices ) {
        free(_rgData.vertices);
        free(_rgData.indices);
    }
    if ( _rgDataGrid.vertices ) {
        free(_rgDataGrid.vertices);
        free(_rgDataGrid.indices);
    }
    _table = table;
    _expandTimes = expand;
    uint32_t _row = (table.row - 1) * (uint32_t)expand + 1;
    uint32_t _col = (table.column - 1) * (uint32_t)expand + 1;
    uint32_t _count = _row * _col;
    _rgData.vertices = (PYChart3DVertex *)calloc(_count, sizeof(PYChart3DVertex));
    _rgData.vertexCount = _count;
    _rgDataGrid.vertices = (PYChart3DVertex *)calloc(_count, sizeof(PYChart3DVertex));
    _rgDataGrid.vertexCount = _count;
    
    // Each Trangle need 3 vertices
    uint32_t _tcount = (_row - 1) * (_col - 1) * 2;
    _rgData.indexCount = _tcount * 3;
    _rgData.indices = (GLuint *)malloc(sizeof(GLuint) * _rgData.indexCount);
    for ( uint32_t r = 0; r < _row - 1; ++r ) {
        for ( uint32_t c = 0; c < _col - 1; ++c ) {
            uint32_t _beginIndex = ((_col - 1) * r + c) * 6;
            _rgData.indices[_beginIndex + 0] = _col * r + c;
            _rgData.indices[_beginIndex + 1] = _col * (r + 1) + c;
            _rgData.indices[_beginIndex + 2] = _col * (r + 1) + (c + 1);
            _rgData.indices[_beginIndex + 3] = _col * (r + 1) + (c + 1);
            _rgData.indices[_beginIndex + 4] = _col * r + (c + 1);
            _rgData.indices[_beginIndex + 5] = _col * r + c;
        }
    }
    // Create data grid indices
    // Each row has (col - 1) lines
    // Each col has (row - 1) lines
    // All lines is row * (col - 1) + col * (row - 1)
    _rgDataGrid.indexCount = (_row * (_col - 1) + _col * (_row - 1)) * 2;
    _rgDataGrid.indices = (GLuint *)malloc(sizeof(GLuint) * _rgDataGrid.indexCount);
    uint32_t i = 0;
    for ( uint32_t r = 0; r < _row; ++r ) {
        for ( uint32_t c = 0; c < _col - 1; ++c ) {
            PYCHART_SET_INDEX_GROUP(_rgDataGrid.indices, i, (r * _col + c), (r * _col + c + 1));
            ++i;
        }
    }
    for ( uint32_t c = 0; c < _col; ++c ) {
        for ( uint32_t r = 0; r < _row - 1; ++r ) {
            PYCHART_SET_INDEX_GROUP(_rgDataGrid.indices, i, (r * _col + c), ((r + 1) * _col + c));
            ++i;
        }
    }
    [self __glUpdateAllDataOfRenderGroup:&_rgData drawMode:GL_DYNAMIC_DRAW];
    [self __glUpdateAllDataOfRenderGroup:&_rgDataGrid drawMode:GL_DYNAMIC_DRAW];
    PYSingletonUnLock
}

- (void)updateVertexValues:(float *)values
{
    if ( _cachedValues ) free(_cachedValues);
    _cachedValues = (float *)malloc(sizeof(float) * _table.row * _table.column);
    memcpy(_cachedValues, values, _table.row * _table.column * sizeof(float));
    [self calculateAllVertexValues:_cachedValues];
}
// Update the surface with vertex's value in Z, the values should contains table.row * table.column data
- (void)calculateAllVertexValues:(float *)values
{
    PYSingletonLock
    float _maxX = 4.f, _maxY = 4.f, _maxZ = 2.f;
    if ( _zoomMode == PYChartSurface3DZoomSmall ) {
        _maxX *= 0.75;
        _maxY *= 0.75;
        _maxZ *= 0.75;
    } else if ( _zoomMode == PYChartSurface3DZoomBig ) {
        _maxX *= 1.25;
        _maxY *= 1.25;
        _maxZ *= 1.25;
    }
    if ( _displayMode == PYChartSurface3DDisplayModeRelated ) {
        if ( _table.row >= _table.column ) {
            _maxY = ((float)_table.column / (float)_table.row) * _maxY;
        } else {
            _maxX = ((float)_table.row / (float)_table.column) * _maxX;
        }
    }
    
    float _maxValue = -FLT_MAX, _minValue = FLT_MAX;
    for ( uint32_t i = 0; i < (_table.row * _table.column); ++i ) {
        float _av = fabsf(values[i]);
        if ( _av > _maxValue ) _maxValue = _av;
        if ( values[i] < _minValue ) _minValue = values[i];
    }
    float _delta = _maxValue - _minValue;
    _maxValue *= 1.5;
    float _originMaxV = _maxValue;
    for ( uint32_t i = 0; i < (_table.row * _table.column); ++i ) {
        values[i] = (values[i]) / _maxValue * _maxZ;
    }
    _delta = _delta / _maxValue * _maxZ;
    _maxValue = 1.f / 1.5f * _maxZ;
    _minValue = _maxValue - _delta;
    BOOL _customizedColor = [self.delegate respondsToSelector:@selector(surface3DChart:colorForValue:)];
    if ( _expandTimes == 1 ) {
        for ( uint32_t r = 0; r < _table.row; ++r ) {
            for ( uint32_t c = 0; c < _table.column; ++c ) {
                uint32_t _i = r * _table.column + c;
                float _x = (float)c / ((float)_table.column - 1) * _maxX - _maxX / 2;
                float _y = -((float)r / ((float)_table.row - 1) * _maxY - _maxY / 2);
                float _value = values[_i];
                UIColor *_tc = nil;
                if ( _customizedColor ) {
                    _tc = [self.delegate surface3DChart:self colorForValue:values[_i] / _maxZ * _originMaxV];
                } else {
                    _tc = [UIColor whiteColor];
                }
                PYColorInfo _ci = _tc.colorInfo;
                PYCHART_SET_VERTEX(_rgData.vertices[_i], _x, _y, _value, _ci);
            }
        }
    } else {
        uint32_t _row = (_table.row - 1) * (uint32_t)_expandTimes + 1;
        uint32_t _col = (_table.column - 1) * (uint32_t)_expandTimes + 1;
        PYChartSurface3DValue _static_values[4];
        float _distance_buffer[4];
        for ( uint32_t r = 0; r < _row; ++r ) {
            for ( uint32_t c = 0; c < _col; ++c ) {
                uint32_t _i = r * _col + c;
                float _x = (float)c / ((float)_col - 1) * _maxX - _maxX / 2;
                float _y = -((float)r / ((float)_row - 1) * _maxY - _maxY / 2);
                float _value = 0.f;
                if ( r % _expandTimes == 0 && c % _expandTimes == 0) {
                    _value = values[(r / _expandTimes) * _table.column + (c / _expandTimes)];
                } else {
                    uint32_t _r = r / (uint32_t)_expandTimes;
                    if ( _r == _table.row - 1 ) _r -= 1;
                    uint32_t _c = c / (uint32_t)_expandTimes;
                    if ( _c == _table.column - 1 ) _c -= 1;
                    uint32_t _re = _r * (uint32_t)_expandTimes;
                    uint32_t _ce = _c * (uint32_t)_expandTimes;
                    uint32_t _r1e = (_r + 1) * (uint32_t)_expandTimes;
                    uint32_t _c1e = (_c + 1) * (uint32_t)_expandTimes;
                    _static_values[0] = PYChartSurface3DValueMake(_re, _ce, values[_r * _table.column + _c]);
                    _static_values[1] = PYChartSurface3DValueMake(_re, _c1e, values[_r * _table.column + _c + 1]);
                    _static_values[2] = PYChartSurface3DValueMake(_r1e, _ce, values[(_r + 1) * _table.column + _c]);
                    _static_values[3] = PYChartSurface3DValueMake(_r1e, _c1e, values[(_r + 1) * _table.column + _c + 1]);
                    
                    _value = PYChartInterpolationIDW(_static_values, 4, PYChartSurface3DPointMake(r, c), _distance_buffer);
                }
                UIColor *_tc = nil;
                if ( _customizedColor ) {
                    _tc = [self.delegate surface3DChart:self colorForValue:_value / _maxZ * _originMaxV];
                } else {
                    _tc = [UIColor whiteColor];
                }
                PYColorInfo _ci = _tc.colorInfo;
                PYCHART_SET_VERTEX(_rgData.vertices[_i], _x, _y, _value, _ci);
            }
        }
    }
    
    PYColorInfo _pi = _dataGridLineColor.colorInfo;
    for ( uint32_t i = 0; i < _rgData.vertexCount; ++i ) {
        _rgDataGrid.vertices[i].position = _rgData.vertices[i].position;
        PYCHART_SET_VERTEX_COLOR(_rgDataGrid.vertices[i], _pi);
    }
    
    [self __glUpdateVertexDataOfRenderGroup:&_rgData drawMode:GL_DYNAMIC_DRAW];
    [self __glUpdateVertexDataOfRenderGroup:&_rgDataGrid drawMode:GL_DYNAMIC_DRAW];
    PYSingletonUnLock
    [self render];
}

- (void)addRenderGroupObject:(PYChart3DRenderGroup)renderGroup forKey:(NSString *)key
{
    PYSingletonLock
    if ( renderGroup.vertices == NULL ) return;
    [self removeRenderGroupForKey:key];
    
    PYChart3DRenderGroup _rg;
    PYChart3DRenderGroupGenBuffer(&_rg);
    _rg.vertices = renderGroup.vertices;
    _rg.vertexCount = renderGroup.vertexCount;
    _rg.indices = renderGroup.indices;
    _rg.indexCount = renderGroup.indexCount;
    [self __glUpdateAllDataOfRenderGroup:&_rg drawMode:GL_STATIC_DRAW];
    PYChart3DRenderGroupObject *_rgo = [PYChart3DRenderGroupObject objectWithRenderGroup:_rg];
    
    [_expendObjects setObject:_rgo forKey:key];
    [self render];
    PYSingletonUnLock
}

- (void)removeRenderGroupForKey:(NSString *)key
{
    PYChart3DRenderGroupObject *_oldObjValue = [_expendObjects objectForKey:key];
    if ( _oldObjValue != nil ) {
        // Remove the old object
        PYChart3DRenderGroup _rg = _oldObjValue.renderGroup;
        PYChart3DRenderGroupRelease(&_rg);
        [_expendObjects removeObjectForKey:key];
    }
}

@end

// @littlepush
// littlepush@gmail.com
// PYLab

//
//  DBOpenGLView.m
//  Tutorial5
//
//  Created by David Brown on 12/11/13.
//  Copyright (c) 2013 David T. Brown.
//  This file is licensed under the MIT License.
//

#import "DBOpenGLView.h"
#import "OpenGL/gl3.h"
#import "GLKit/GLKMatrix4.h"

@implementation DBOpenGLView

#pragma mark private instance methods

// this method generates a compiled shader from a file in the applications resource bundle
// caller provides the resource name (file name) and the shader type
// reference to shader object is returned
- (GLuint) makeShaderOfType:(GLenum)shaderType withShaderResource:(NSString *)shaderResource
{
    GLuint newShader;
    
    NSString *shaderResourceType = nil;
    
    if( shaderType == GL_VERTEX_SHADER) {
        shaderResourceType = @"vs";
    } else if( shaderType == GL_FRAGMENT_SHADER ) {
        shaderResourceType = @"fs";
    }
    
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderResource ofType:shaderResourceType];
    
    NSData *shaderData = [NSData dataWithContentsOfFile:shaderPath];
    
    GLchar *source = calloc(sizeof(GLchar),[shaderData length]+1);
    [shaderData getBytes:(void *)source length:[shaderData length]];
    *(source+[shaderData length]) = (GLchar)0x00;
    
    newShader = glCreateShader(shaderType);
    glShaderSource(newShader, 1, (const GLchar *const *)&source, NULL);
    glCompileShader(newShader);
    
    // parse errors after compiling
    GLint status;
    glGetShaderiv(newShader, GL_COMPILE_STATUS, &status);
    
    if(status == GL_FALSE) {
        
        GLint infoLogLength;
        glGetShaderiv(newShader, GL_INFO_LOG_LENGTH, &infoLogLength);
        
        GLchar *strInfoLog = calloc(sizeof(GLchar), infoLogLength);
        glGetShaderInfoLog(newShader, infoLogLength, NULL, strInfoLog);
        
        NSLog(@"Compile failure in shader:\n%s\nSource:\n%s",strInfoLog,source);
        free(strInfoLog);
    }
    
    return newShader;
}

// this method initializes the required shaders and combines them into a program reference
// the program reference is held in an ivar to allow other methods (primarily drawing methods)
// to access the shader program
- (void) initializeShaders
{
    GLuint shader1, shader2;

    shader1 = [self makeShaderOfType:GL_VERTEX_SHADER withShaderResource:@"matrixPerspective"];
    shader2 = [self makeShaderOfType:GL_FRAGMENT_SHADER withShaderResource:@"vertexColor"];
    
    shaderProgram = glCreateProgram();
    
    glAttachShader(shaderProgram, shader1);
    glAttachShader(shaderProgram, shader2);
    
    glLinkProgram(shaderProgram);
    glValidateProgram(shaderProgram);
    
    GLint infoLogLength;
    glGetProgramiv(shaderProgram, GL_INFO_LOG_LENGTH, &infoLogLength);
    if( infoLogLength > 0 ) {
        GLchar *strInfoLog = calloc(sizeof(GLchar), infoLogLength);
        glGetProgramInfoLog(shaderProgram, infoLogLength, NULL, strInfoLog);
        
        NSLog(@"Program link/validate failure:\n%s\n",strInfoLog);
        free(strInfoLog);
    }
}

const int numberOfVertices = 36;

// the vertex positions we plan to render, and their colors
#define RIGHT_EXTENT 0.8f
#define LEFT_EXTENT -RIGHT_EXTENT
#define TOP_EXTENT 0.20f
#define MIDDLE_EXTENT 0.0f
#define BOTTOM_EXTENT -TOP_EXTENT
#define FRONT_EXTENT -1.25f
#define REAR_EXTENT -1.75f

#define GREEN_COLOR 0.75f, 0.75f, 1.0f, 1.0f
#define BLUE_COLOR 	0.0f, 0.5f, 0.0f, 1.0f
#define RED_COLOR 1.0f, 0.0f, 0.0f, 1.0f
#define GREY_COLOR 0.8f, 0.8f, 0.8f, 1.0f
#define BROWN_COLOR 0.5f, 0.5f, 0.0f, 1.0f

const float vertexData[] = {
	//Object 1 positions
	LEFT_EXTENT,	TOP_EXTENT,		REAR_EXTENT,
	LEFT_EXTENT,	MIDDLE_EXTENT,	FRONT_EXTENT,
	RIGHT_EXTENT,	MIDDLE_EXTENT,	FRONT_EXTENT,
	RIGHT_EXTENT,	TOP_EXTENT,		REAR_EXTENT,
    
	LEFT_EXTENT,	BOTTOM_EXTENT,	REAR_EXTENT,
	LEFT_EXTENT,	MIDDLE_EXTENT,	FRONT_EXTENT,
	RIGHT_EXTENT,	MIDDLE_EXTENT,	FRONT_EXTENT,
	RIGHT_EXTENT,	BOTTOM_EXTENT,	REAR_EXTENT,
    
	LEFT_EXTENT,	TOP_EXTENT,		REAR_EXTENT,
	LEFT_EXTENT,	MIDDLE_EXTENT,	FRONT_EXTENT,
	LEFT_EXTENT,	BOTTOM_EXTENT,	REAR_EXTENT,
    
	RIGHT_EXTENT,	TOP_EXTENT,		REAR_EXTENT,
	RIGHT_EXTENT,	MIDDLE_EXTENT,	FRONT_EXTENT,
	RIGHT_EXTENT,	BOTTOM_EXTENT,	REAR_EXTENT,
    
	LEFT_EXTENT,	BOTTOM_EXTENT,	REAR_EXTENT,
	LEFT_EXTENT,	TOP_EXTENT,		REAR_EXTENT,
	RIGHT_EXTENT,	TOP_EXTENT,		REAR_EXTENT,
	RIGHT_EXTENT,	BOTTOM_EXTENT,	REAR_EXTENT,
    
	//Object 2 positions
	TOP_EXTENT,		RIGHT_EXTENT,	REAR_EXTENT,
	MIDDLE_EXTENT,	RIGHT_EXTENT,	FRONT_EXTENT,
	MIDDLE_EXTENT,	LEFT_EXTENT,	FRONT_EXTENT,
	TOP_EXTENT,		LEFT_EXTENT,	REAR_EXTENT,
    
	BOTTOM_EXTENT,	RIGHT_EXTENT,	REAR_EXTENT,
	MIDDLE_EXTENT,	RIGHT_EXTENT,	FRONT_EXTENT,
	MIDDLE_EXTENT,	LEFT_EXTENT,	FRONT_EXTENT,
	BOTTOM_EXTENT,	LEFT_EXTENT,	REAR_EXTENT,
    
	TOP_EXTENT,		RIGHT_EXTENT,	REAR_EXTENT,
	MIDDLE_EXTENT,	RIGHT_EXTENT,	FRONT_EXTENT,
	BOTTOM_EXTENT,	RIGHT_EXTENT,	REAR_EXTENT,
    
	TOP_EXTENT,		LEFT_EXTENT,	REAR_EXTENT,
	MIDDLE_EXTENT,	LEFT_EXTENT,	FRONT_EXTENT,
	BOTTOM_EXTENT,	LEFT_EXTENT,	REAR_EXTENT,
    
	BOTTOM_EXTENT,	RIGHT_EXTENT,	REAR_EXTENT,
	TOP_EXTENT,		RIGHT_EXTENT,	REAR_EXTENT,
	TOP_EXTENT,		LEFT_EXTENT,	REAR_EXTENT,
	BOTTOM_EXTENT,	LEFT_EXTENT,	REAR_EXTENT,
    
	//Object 1 colors
	GREEN_COLOR,
	GREEN_COLOR,
	GREEN_COLOR,
	GREEN_COLOR,
    
	BLUE_COLOR,
	BLUE_COLOR,
	BLUE_COLOR,
	BLUE_COLOR,
    
	RED_COLOR,
	RED_COLOR,
	RED_COLOR,
    
	GREY_COLOR,
	GREY_COLOR,
	GREY_COLOR,
    
	BROWN_COLOR,
	BROWN_COLOR,
	BROWN_COLOR,
	BROWN_COLOR,
    
	//Object 2 colors
	RED_COLOR,
	RED_COLOR,
	RED_COLOR,
	RED_COLOR,
    
	BROWN_COLOR,
	BROWN_COLOR,
	BROWN_COLOR,
	BROWN_COLOR,
    
	BLUE_COLOR,
	BLUE_COLOR,
	BLUE_COLOR,
    
	GREEN_COLOR,
	GREEN_COLOR,
	GREEN_COLOR,
    
	GREY_COLOR,
	GREY_COLOR,
	GREY_COLOR,
	GREY_COLOR,
};

const GLshort indexData[] =
{
	0, 2, 1,
	3, 2, 0,
    
	4, 5, 6,
	6, 7, 4,
    
	8, 9, 10,
	11, 13, 12,
    
	14, 16, 15,
	17, 16, 14,
};

// this method obtains a buffer from the OpenGL server and loads our static data into it
- (void) initializeVertexBuffer
{
    glGenBuffers(1, &vertexBufferObject);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferObject);
    
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER,0);
    
    glGenBuffers(1, &indexBufferObject);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferObject);
    
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexData), indexData, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,0);
}

// this method sets up vertex array objects on the OpenGL server
- (void) initializeVertexArrayObjects
{
    // vertex array object for first object (in first half of buffer data)
    glGenVertexArrays(1, &vaObject1);
    
    glBindVertexArray(vaObject1);
    
    size_t colorDataOffset = sizeof(float) * 3 * numberOfVertices;
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferObject);
    
    glEnableVertexAttribArray(0); // this attribute array is for position data
    glEnableVertexAttribArray(1); // this attribute array is for color data
    
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
    glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, 0, (void *)colorDataOffset);
    
    // the binding of the index buffer to the GL_ELEMENT_ARRAY_BUFFER binding
    // point is stored in the VAO (vaObject1) we are initializing
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferObject);
    
    glBindVertexArray(0);
    
    // vertex array for second object (in second half of buffer data)
    glGenVertexArrays(1, &vaObject2);
    
    glBindVertexArray(vaObject2);
    
    size_t posDataOffset = sizeof(float) * 3 * (numberOfVertices/2);
    colorDataOffset += sizeof(float) * 4 * (numberOfVertices/2);
    
    // our vertex buffer is still bound to the GL_ARRAY_BUFFER binding point,
    // so no need to bind it
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, (void*)posDataOffset);
    glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, 0, (void*)colorDataOffset);
    
    // this binding is stored in the VAO (vaObject2) we are initializing
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferObject);

    // shader program won't validate without having a VAO bound
//    glBindVertexArray(0);

}

// this method redraws the view and needs to be threadsafe since it will
// be invoked by both the video callback and window system (e.g., resize)
- (void)drawGLView
{
    [[self openGLContext] makeCurrentContext];
    
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClearDepth(1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glUseProgram(shaderProgram);
    
    GLuint offsetUniform = glGetUniformLocation(shaderProgram, "offset");

    glBindVertexArray(vaObject1);
    glUniform3f(offsetUniform, 0.0f, 0.0f, 0.0f);
    glDrawElements(GL_TRIANGLES, sizeof(indexData)/sizeof(GLshort), GL_UNSIGNED_SHORT, 0);

    glBindVertexArray(vaObject2);
    // to show various stages of overlap, modify z component of offset between -1 and 0.0
    glUniform3f(offsetUniform, 0.0f, 0.0f, -1.0f);
    glDrawElements(GL_TRIANGLES, sizeof(indexData)/sizeof(GLshort), GL_UNSIGNED_SHORT, 0);
    
    glBindVertexArray(0);
    
    glUseProgram(0);

    glFlush();
}


// this method resizes the OpenGL viewport to match this view's bounds when needed
- (void) reshape
{
    GLsizei newHeight = (GLsizei)self.bounds.size.height;
    GLsizei newWidth = (GLsizei)self.bounds.size.width;
    
    if( (viewHeight != newHeight) || (viewWidth != newWidth) ) {
        
        viewHeight = newHeight;
        viewWidth = newWidth;
        
        GLuint perspectiveMatrixLocation = glGetUniformLocation(shaderProgram, "perspectiveMatrix");
        
        GLfloat aRatio = self.bounds.size.height / self.bounds.size.width;
        
        GLKMatrix4 frustum;
        
        if( aRatio > 1 ) {
            frustum = GLKMatrix4MakeFrustum(-1.0, 1.0, -aRatio, aRatio, 1.0, 3.0);
        } else {
            frustum = GLKMatrix4MakeFrustum(-1/aRatio, 1/aRatio, -1.0, 1.0, 1.0, 3.0);
        }
        
        glUseProgram(shaderProgram);
        glUniformMatrix4fv(perspectiveMatrixLocation, 1, GL_FALSE, (GLfloat *)&frustum);
        glUseProgram(0);
        
        glViewport(0, 0, viewWidth, viewHeight);
        
    }
}


#pragma mark superclass method overrides

//
- (void) awakeFromNib
{
    NSOpenGLPixelFormatAttribute attributes [] = {
        NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)24,
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        (NSOpenGLPixelFormatAttribute)0
    };
    
    NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
    [self setPixelFormat:pf];
}

// if this method gets called (e.g., this class is no longer unarchived from the NIB) the
// pixel format won't get set up.  in this case you can still init super with the
// initWithFrame:pixelformat: method.
- (id)initWithFrame:(NSRect)frame
{
    NSOpenGLPixelFormatAttribute attributes [] = {
        NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)24,
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        (NSOpenGLPixelFormatAttribute)0
    };
    
    NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
    
    self = [super initWithFrame:frame pixelFormat:pf];
    if (self) {
        // Initialization code here.
    }
    return self;
}

// this method is called anytime the view needs to be updated
- (void)drawRect:(NSRect)dirtyRect
{
    // right now the only thing to do is render the OpenGL view
    [self drawGLView];
}

// this method sets up the OpenGL context we will write into, and calls the init code
// for shaders and our example vertex data
- (void) prepareOpenGL
{
    GLint swapInt = 1;
    
    // set to vbl sync
    [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
    
	// init GL stuff here
    
    // vertex data is loaded into buffers
    [self initializeVertexBuffer];
    
    // shader programs need a bound VAO before they will validate successfully
    [self initializeVertexArrayObjects];
    
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glFrontFace(GL_CW);
    
    glEnable(GL_DEPTH_TEST);
    glDepthMask(GL_TRUE);
    glDepthFunc(GL_LEQUAL);
    glDepthRange(0.0f, 1.0f);
    
    [self initializeShaders];
    
    GLuint offsetUniform = glGetUniformLocation(shaderProgram, "offset");
    GLuint perspectiveUniform = glGetUniformLocation(shaderProgram, "perspectiveMatrix");
    
    GLfloat aRatio = self.bounds.size.height / self.bounds.size.width;
    
    GLKMatrix4 frustum;
    
    if( aRatio > 1 ) {
        frustum = GLKMatrix4MakeFrustum(-1.0, 1.0, -aRatio, aRatio, 1.0, 3.0);
    } else {
        frustum = GLKMatrix4MakeFrustum(-1/aRatio, 1/aRatio, -1.0, 1.0, 1.0, 3.0);
    }
    
    glUseProgram(shaderProgram);
    
    glUniform3f(offsetUniform, 0.5f, 0.5f, -2.0f);
    glUniformMatrix4fv(perspectiveUniform, 1, GL_FALSE, (GLfloat *)&frustum);

    glUseProgram(0);
    
    // log some information about the OpenGL session we've started.
    NSLog(@"OpenGL vendor name = %s\n",glGetString(GL_VENDOR));
    NSLog(@"OpenGL renderer name = %s\n",glGetString(GL_RENDERER));
    NSLog(@"OpenGL version = %s\n",glGetString(GL_VERSION));
    NSLog(@"Shader language version = %s\n",glGetString(GL_SHADING_LANGUAGE_VERSION));
}

@end

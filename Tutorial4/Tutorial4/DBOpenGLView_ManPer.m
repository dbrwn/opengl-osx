//
//  DBOpenGLView.m
//  Tutorial1
//
//  Created by David Brown on 12/11/13.
//  Copyright (c) 2013 David T. Brown.
//  This file is licensed under the MIT License.
//

#import "DBOpenGLView.h"
#import "OpenGL/gl3.h"


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

    shader1 = [self makeShaderOfType:GL_VERTEX_SHADER withShaderResource:@"manualPerspective"];
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

// the vertex positions we plan to render, and their colors
const GLfloat vertexPositions[] = {
    0.25f,  0.25f, 0.75f, 1.0f,
    0.25f, -0.25f, 0.75f, 1.0f,
	-0.25f,  0.25f, 0.75f, 1.0f,
    
    0.25f, -0.25f, 0.75f, 1.0f,
	-0.25f, -0.25f, 0.75f, 1.0f,
	-0.25f,  0.25f, 0.75f, 1.0f,
    
    0.25f,  0.25f, -0.75f, 1.0f,
	-0.25f,  0.25f, -0.75f, 1.0f,
    0.25f, -0.25f, -0.75f, 1.0f,
    
    0.25f, -0.25f, -0.75f, 1.0f,
	-0.25f,  0.25f, -0.75f, 1.0f,
	-0.25f, -0.25f, -0.75f, 1.0f,
    
	-0.25f,  0.25f,  0.75f, 1.0f,
	-0.25f, -0.25f,  0.75f, 1.0f,
	-0.25f, -0.25f, -0.75f, 1.0f,
    
	-0.25f,  0.25f,  0.75f, 1.0f,
	-0.25f, -0.25f, -0.75f, 1.0f,
	-0.25f,  0.25f, -0.75f, 1.0f,
    
    0.25f,  0.25f,  0.75f, 1.0f,
    0.25f, -0.25f, -0.75f, 1.0f,
    0.25f, -0.25f,  0.75f, 1.0f,
    
    0.25f,  0.25f,  0.75f, 1.0f,
    0.25f,  0.25f, -0.75f, 1.0f,
    0.25f, -0.25f, -0.75f, 1.0f,
    
    0.25f,  0.25f, -0.75f, 1.0f,
    0.25f,  0.25f,  0.75f, 1.0f,
	-0.25f,  0.25f,  0.75f, 1.0f,
    
    0.25f,  0.25f, -0.75f, 1.0f,
	-0.25f,  0.25f,  0.75f, 1.0f,
	-0.25f,  0.25f, -0.75f, 1.0f,
    
    0.25f, -0.25f, -0.75f, 1.0f,
	-0.25f, -0.25f,  0.75f, 1.0f,
    0.25f, -0.25f,  0.75f, 1.0f,
    
    0.25f, -0.25f, -0.75f, 1.0f,
	-0.25f, -0.25f, -0.75f, 1.0f,
	-0.25f, -0.25f,  0.75f, 1.0f,
    
    
    
    
	0.0f, 0.0f, 1.0f, 1.0f,
	0.0f, 0.0f, 1.0f, 1.0f,
	0.0f, 0.0f, 1.0f, 1.0f,
    
	0.0f, 0.0f, 1.0f, 1.0f,
	0.0f, 0.0f, 1.0f, 1.0f,
	0.0f, 0.0f, 1.0f, 1.0f,
    
	0.8f, 0.8f, 0.8f, 1.0f,
	0.8f, 0.8f, 0.8f, 1.0f,
	0.8f, 0.8f, 0.8f, 1.0f,
    
	0.8f, 0.8f, 0.8f, 1.0f,
	0.8f, 0.8f, 0.8f, 1.0f,
	0.8f, 0.8f, 0.8f, 1.0f,
    
	0.0f, 1.0f, 0.0f, 1.0f,
	0.0f, 1.0f, 0.0f, 1.0f,
	0.0f, 1.0f, 0.0f, 1.0f,
    
	0.0f, 1.0f, 0.0f, 1.0f,
	0.0f, 1.0f, 0.0f, 1.0f,
	0.0f, 1.0f, 0.0f, 1.0f,
    
	0.5f, 0.5f, 0.0f, 1.0f,
	0.5f, 0.5f, 0.0f, 1.0f,
	0.5f, 0.5f, 0.0f, 1.0f,
    
	0.5f, 0.5f, 0.0f, 1.0f,
	0.5f, 0.5f, 0.0f, 1.0f,
	0.5f, 0.5f, 0.0f, 1.0f,
    
	1.0f, 0.0f, 0.0f, 1.0f,
	1.0f, 0.0f, 0.0f, 1.0f,
	1.0f, 0.0f, 0.0f, 1.0f,
    
	1.0f, 0.0f, 0.0f, 1.0f,
	1.0f, 0.0f, 0.0f, 1.0f,
	1.0f, 0.0f, 0.0f, 1.0f,
    
	0.0f, 1.0f, 1.0f, 1.0f,
	0.0f, 1.0f, 1.0f, 1.0f,
	0.0f, 1.0f, 1.0f, 1.0f,
    
	0.0f, 1.0f, 1.0f, 1.0f,
	0.0f, 1.0f, 1.0f, 1.0f,
	0.0f, 1.0f, 1.0f, 1.0f
};

// this method obtains a buffer from the OpenGL server and loads our static data into it
- (void) initializeVertexBuffer
{
    glGenBuffers(1, &positionBufferObject);
    glBindBuffer(GL_ARRAY_BUFFER, positionBufferObject);
    
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexPositions), vertexPositions, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER,0);
}

// this method redraws the view and needs to be threadsafe since it will
// be invoked by both the video callback and window system (e.g., resize)
- (void)drawGLView
{
    [[self openGLContext] makeCurrentContext];
    
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(shaderProgram);
    
    size_t colorData = sizeof(vertexPositions) / 2;
    GLuint triangleCt = ( sizeof(vertexPositions) / 2 ) / 4;
    
    glBindBuffer(GL_ARRAY_BUFFER, positionBufferObject);
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    
    glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, 0);
    glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, 0, (void*)(colorData));
    
    glDrawArrays(GL_TRIANGLES, 0, triangleCt);
    
    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glUseProgram(0);

    glFlush();
    
}


// this method resizes the OpenGL viewport to match this view's bounds when needed
- (void) reshape
{
    if( (viewHeight != self.bounds.size.height) || (viewWidth != self.bounds.size.width) ) {
        
        viewHeight = self.bounds.size.height;
        viewWidth = self.bounds.size.width;
        
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
    [self initializeVertexBuffer];
    
    // shader programs need a bound VAO before they will validate successfully
    glGenVertexArrays(1, &vectorArrayObject);
    glBindVertexArray(vectorArrayObject);
    
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glFrontFace(GL_CW);
    
    [self initializeShaders];
    
    GLuint offsetLocation = glGetUniformLocation(shaderProgram, "offset");
    
    GLuint frustumScaleLocation = glGetUniformLocation(shaderProgram, "frustumScale");
    GLuint zNearLocation = glGetUniformLocation(shaderProgram, "zNear");
    GLuint zFarLocation = glGetUniformLocation(shaderProgram, "zFar");
    
    glUseProgram(shaderProgram);
    
    glUniform3f(offsetLocation, 0.5f, 0.5f, -2.0f);
    glUniform1f(frustumScaleLocation, 1.0f);
    glUniform1f(zNearLocation, 1.0f);
    glUniform1f(zFarLocation, 3.0f);

    glUseProgram(0);
    
    // log some information about the OpenGL session we've started.
    NSLog(@"OpenGL vendor name = %s\n",glGetString(GL_VENDOR));
    NSLog(@"OpenGL renderer name = %s\n",glGetString(GL_RENDERER));
    NSLog(@"OpenGL version = %s\n",glGetString(GL_VERSION));
    NSLog(@"Shader language version = %s\n",glGetString(GL_SHADING_LANGUAGE_VERSION));
}

@end

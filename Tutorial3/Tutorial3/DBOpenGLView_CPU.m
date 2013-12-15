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

#pragma mark callbacks

// this is the displayLink callback function, called before the next
// video frame needs to be rendered.
static CVReturn DBDisplayLinkCallback(CVDisplayLinkRef displayLink,
									  const CVTimeStamp* now,
									  const CVTimeStamp* outputTime,
									  CVOptionFlags flagsIn,
									  CVOptionFlags* flagsOut,
									  void* displayLinkContext)
{
    CVReturn result = [(__bridge DBOpenGLView*)displayLinkContext getFrameForTime:outputTime];
    return result;
}


#pragma mark private instance methods

// this method calculates the current render time and redraws the view
- (CVReturn) getFrameForTime:(const CVTimeStamp*)outputTime
{
    if(videoLoopInit) {
        videoStartTime = outputTime->videoTime;
        videoLoopInit = NO;
    }
    
    renderTime = (GLfloat)(outputTime->videoTime - videoStartTime) /
                    (GLfloat)outputTime->videoTimeScale;
    
    [self drawGLView];
	return kCVReturnSuccess;
}

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

    shader1 = [self makeShaderOfType:GL_VERTEX_SHADER withShaderResource:@"VertexPosition"];
    shader2 = [self makeShaderOfType:GL_FRAGMENT_SHADER withShaderResource:@"VertexPosition"];
    
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
	0.25f, 0.25f, 0.0f, 1.0f,
	0.25f, -0.25f, 0.0f, 1.0f,
	-0.25f, -0.25f, 0.0f, 1.0f,
    1.0f,    0.0f, 0.0f, 1.0f,
    0.0f,    1.0f, 0.0f, 1.0f,
    0.0f,    0.0f, 1.0f, 1.0f
};

// this method obtains a buffer from the OpenGL server and loads our static data into it
- (void) initializeVertexBuffer
{
    glGenBuffers(1, &positionBufferObject);
    glBindBuffer(GL_ARRAY_BUFFER, positionBufferObject);
    
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexPositions), vertexPositions, GL_STREAM_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER,0);
}

// these parameters control the speed the triangle circles the view
const GLfloat kLoopDuration = 5.0f;
const GLfloat kScale = M_PI * 2.0f / kLoopDuration;

// this method calculates new vertex positions based on the current time delta
// from start of animation.  Since it applies the same offset to each point
// the triangle doesn't rotate.
- (void) adjustVerticesWithTimeFromStart:(GLfloat)deltaT
{
    GLuint i = 0;
    
    GLfloat timeThruLoop = fmodf(deltaT, kLoopDuration);
    
    GLfloat offsetX = cosf(timeThruLoop * kScale) * 0.5f;
    GLfloat offsetY = sinf(timeThruLoop * kScale) * 0.5f;
    
    GLfloat *newVertices = malloc(sizeof(vertexPositions));
    memcpy(newVertices,vertexPositions,sizeof(vertexPositions));
    
    for(i=0; i<3; i++) {

        newVertices[i*4] += offsetX;
        newVertices[i*4+1] += offsetY;
        
    }
    
    // select the buffer object and provide the new vertices
    // the colors are copied too, but they are unchanged.
    glBindBuffer(GL_ARRAY_BUFFER, positionBufferObject);
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(vertexPositions), newVertices);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    free(newVertices);
}

// this method redraws the view and needs to be threadsafe since it will
// be invoked by both the video callback and window system (e.g., resize)
- (void)drawGLView
{
    [[self openGLContext] makeCurrentContext];
    
    CGLLockContext([[self openGLContext] CGLContextObj]);
    
    [self adjustVerticesWithTimeFromStart:renderTime];
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(shaderProgram);
    
    glBindBuffer(GL_ARRAY_BUFFER, positionBufferObject);
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    
    glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, 0);
    glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, 0, (void*)(sizeof(GL_FLOAT)*12));
    
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    glDisableVertexAttribArray(0);
    glUseProgram(0);

    glFlush();
    
    CGLFlushDrawable([[self openGLContext] CGLContextObj]);
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
    
}


// this method resizes the OpenGL viewport to match this view's bounds when needed
- (void) reshape
{
    if( (viewHeight != self.bounds.size.height) || (viewWidth != self.bounds.size.width) ) {
        
        viewHeight = self.bounds.size.height;
        viewWidth = self.bounds.size.width;
        
        CGLLockContext([[self openGLContext] CGLContextObj]);

        glViewport(0, 0, viewWidth, viewHeight);
        
        CGLUnlockContext([[self openGLContext] CGLContextObj]);

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
    
    [self initializeShaders];
    
    // log some information about the OpenGL session we've started.
    NSLog(@"OpenGL vendor name = %s\n",glGetString(GL_VENDOR));
    NSLog(@"OpenGL renderer name = %s\n",glGetString(GL_RENDERER));
    NSLog(@"OpenGL version = %s\n",glGetString(GL_VERSION));
    NSLog(@"Shader language version = %s\n",glGetString(GL_SHADING_LANGUAGE_VERSION));
    
    // Create a display link capable of being used with all active displays
	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	
	// Set the renderer output callback function
	CVDisplayLinkSetOutputCallback(displayLink, &DBDisplayLinkCallback, (__bridge void *)(self));
	
	// Set the display link for the current renderer
	CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
	CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
	CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
	
	// Activate the display link
	CVDisplayLinkStart(displayLink);
    
    // mark the video timer for initialization the first time through the callback
    videoStartTime = 0;
    videoLoopInit = YES;
	
	// Register to be notified when the window closes so we can stop the displaylink
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowWillClose:)
												 name:NSWindowWillCloseNotification
											   object:[self window]];

}

- (void) windowWillClose:(NSNotification*)notification
{
	// Stop the display link when the window is closing because default
	// OpenGL render buffers will be destroyed.  If display link continues to
	// fire without renderbuffers, OpenGL draw calls will set errors.
	CVDisplayLinkStop(displayLink);
}


@end

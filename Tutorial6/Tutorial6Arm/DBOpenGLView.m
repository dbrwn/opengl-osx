//
//  DBOpenGLView.m
//  Tutorial6Arm
//
//  Created by David Brown on 01/05/14.
//  Copyright (c) 2014 David T. Brown.
//  This file is licensed under the MIT License.
//

#import "DBOpenGLView.h"
#import "OpenGL/gl3.h"
#import "GLKit/GLKMatrix4.h"    
#import "DBArmModel.h"

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
    
    renderTime = (GLfloat)(outputTime->videoTime - videoStartTime) / (GLfloat)outputTime->videoTimeScale;
    
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
    // bind a bogus VAO to the context before trying to link and validate the program
    // this VAO is never used again
    GLuint tempVAO;
    glGenVertexArrays(1, &tempVAO);
    
    glBindVertexArray(tempVAO);

    GLuint shader1, shader2;

    shader1 = [self makeShaderOfType:GL_VERTEX_SHADER withShaderResource:@"localTransform"];
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
    
    glBindVertexArray(0);
}


// this method redraws the view and needs to be threadsafe since it will
// be invoked by both the video callback and window system (e.g., resize)
- (void)drawGLView
{
    [[self openGLContext] makeCurrentContext];
    
    CGLLockContext([[self openGLContext] CGLContextObj]);
    
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClearDepth(1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glUseProgram(shaderProgram);
       
    [_armModel drawModel];

    glUseProgram(0);

    glFlush();

    CGLFlushDrawable([[self openGLContext] CGLContextObj]);
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
}


// this method resizes the OpenGL viewport to match this view's bounds when needed
- (void) reshape
{
    GLsizei newHeight = (GLsizei)self.bounds.size.height;
    GLsizei newWidth = (GLsizei)self.bounds.size.width;
    
    if( (viewHeight != newHeight) || (viewWidth != newWidth) ) {
        
        viewHeight = newHeight;
        viewWidth = newWidth;
        
        CGLLockContext([[self openGLContext] CGLContextObj]);

        glUseProgram(shaderProgram);

        GLKMatrix4 frustum = [self generateFrustumForSize:self.bounds.size];
        glUniformMatrix4fv(cameraOffsetUniform, 1, GL_FALSE, (GLfloat *)&frustum);
        
        glUseProgram(0);
        
        glViewport(0, 0, viewWidth, viewHeight);
        
        CGLUnlockContext([[self openGLContext] CGLContextObj]);

    }
}


// this method generates a frustum matrix based on the size parameter and some pre-set z coordinates
- (GLKMatrix4) generateFrustumForSize:(CGSize)size {
    
    GLfloat fzNear = 1.0f;
    GLfloat fzFar = 100.0f;
    
    GLfloat aRatio = self.bounds.size.height / self.bounds.size.width;
    
    GLKMatrix4 frustum;
    
    if( aRatio > 1 ) {
        frustum = GLKMatrix4MakeFrustum(-1.0, 1.0, -aRatio, aRatio, fzNear, fzFar);
    } else {
        frustum = GLKMatrix4MakeFrustum(-1/aRatio, 1/aRatio, -1.0, 1.0, fzNear, fzFar);
    }
    
    return( frustum );
    
}

#pragma mark superclass method overrides

// wakey wakey
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

- (void) windowWillClose:(NSNotification*)notification
{
	// Stop the display link when the window is closing because default
	// OpenGL render buffers will be destroyed.  If display link continues to
	// fire without renderbuffers, OpenGL draw calls will set errors.
	CVDisplayLinkStop(displayLink);
}

// this method sets up the OpenGL context we will write into, and calls the init code
// for shaders and our example vertex data
- (void) prepareOpenGL
{
    GLint swapInt = 1;
    
    // set to vbl sync
    [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
    
	// init GL stuff here
    
    [self initializeShaders];

    // set up references
    glUseProgram(shaderProgram);

    cameraOffsetUniform = glGetUniformLocation(shaderProgram, "cameraToClipMatrix");

    _armModel.modelMatrixUniform = glGetUniformLocation(shaderProgram, "modelToCameraMatrix");
    _armModel.positionAttrib = glGetAttribLocation(shaderProgram, "position");
    _armModel.colorAttrib = glGetAttribLocation(shaderProgram, "color");
    
    glUseProgram(0);
    
    // preparing the model object required the position and color attributes to be
    // set up (see above)
    [_armModel prepareOpenGL];
    
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glFrontFace(GL_CW);
    
    glEnable(GL_DEPTH_TEST);
    glDepthMask(GL_TRUE);
    glDepthFunc(GL_LEQUAL);
    glDepthRange(0.0f, 1.0f);
    
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

@end

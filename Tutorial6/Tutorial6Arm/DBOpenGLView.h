//
//  DBOpenGLView.h
//  Tutorial6Arm
//
//  Created by David Brown on 01/05/14.
//  Copyright (c) 2014 David T. Brown.
//  This file is licensed under the MIT License.
//

#import <Cocoa/Cocoa.h>

@class DBArmModel;

@interface DBOpenGLView : NSOpenGLView

{
    // stores the reference to the shader program we use in the OpenGL server
    GLuint shaderProgram;
    
    // stores the height and width of the view at last resize
    GLsizei viewHeight, viewWidth;
    
    // reference to the display link resource
    CVDisplayLinkRef displayLink;
    
    // holds the initial start time for determining the loop delta
    int64_t videoStartTime;
    
    // flags the need to init the videoStartTime
    BOOL videoLoopInit;
    
    // current render time, measured in seconds from the start of animation
    GLfloat renderTime;
    
    // uniform references
    GLuint cameraOffsetUniform;
    
    IBOutlet DBArmModel *_armModel;
   
}

@end

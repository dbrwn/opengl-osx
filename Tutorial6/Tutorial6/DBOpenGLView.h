//
//  DBOpenGLView.h
//  Tutorial6
//
//  Created by David Brown on 12/11/13.
//  Copyright (c) 2013 David T. Brown.
//  This file is licensed under the MIT License.
//

#import <Cocoa/Cocoa.h>

@interface DBOpenGLView : NSOpenGLView

{
    // stores the reference to the position buffer we use in the OpenGL server
    GLuint vertexBufferObject;
    
    // stores the reference to the index buffer we use in the OpenGL server
    GLuint indexBufferObject;
    
    // stores the references to the vertex array we use in the OpenGL server
    GLuint vaObject;
    
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

}

@end

//
//  DBOpenGLView.h
//  Tutorial1
//
//  Created by David Brown on 12/11/13.
//  Copyright (c) 2013 David T. Brown.
//  This file is licensed under the MIT License.
//

#import <Cocoa/Cocoa.h>

@interface DBOpenGLView : NSOpenGLView

{
    // stores the reference to the position buffer we use in the OpenGL server
    GLuint positionBufferObject;
    
    // stores the reference to the vertex array we use in the OpenGL server
    GLuint vectorArrayObject;
    
    // stores the reference to the shader program we use in the OpenGL server
    GLuint shaderProgram;
    
    // stores the height and width of the view at last resize
    GLsizei viewHeight, viewWidth;

    // stores the location of the offset vector
    GLuint offsetLocation;
}

@end

//
//  DBArmModel.h
//  Tutorial6Arm
//
//  Created by David Brown on 01/05/14.
//  Copyright (c) 2014 David T. Brown.
//  This file is licensed under the MIT License.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKVector3.h>

@interface DBArmModel : NSObject
{
    // stores the angle of the base
    GLfloat _baseRotation;
    
    // stores the angle of the upper arm
    GLfloat _upperArmAngle;
    
    // stores the angle of the lower arm
    GLfloat _lowerArmAngle;
    
    // stores the angle of the wrist
    GLfloat _wristAngle;
    
    // stores the rotation of the wrist
    GLfloat _wristRotation;
    
    // stores the angle of the fingers
    GLfloat _fingerAngle;
    
    // attribute references
    GLuint _positionAttrib;
    GLuint _colorAttrib;
    
    GLuint _modelMatrixUniform;
    
}

@property (assign) GLfloat baseRotation;
@property (assign) GLfloat upperArmAngle;
@property (assign) GLfloat lowerArmAngle;
@property (assign) GLfloat wristAngle;
@property (assign) GLfloat wristRotation;
@property (assign) GLfloat fingerAngle;

@property (assign) GLuint positionAttrib;
@property (assign) GLuint colorAttrib;
@property (assign) GLuint modelMatrixUniform;

- (void) drawModel;
- (void) drawModelAtLocation:(GLKVector3)location;

- (void) prepareOpenGL;

@end

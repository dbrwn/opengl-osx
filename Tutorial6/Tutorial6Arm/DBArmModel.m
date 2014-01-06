//
//  DBArmModel.m
//  Tutorial6Arm
//
//  Created by David Brown on 01/05/14.
//  Copyright (c) 2014 David T. Brown.
//  This file is licensed under the MIT License.
//

#import "DBArmModel.h"
#import "OpenGL/gl3.h"
#import "GLKit/GLKMatrix4.h"
#import "GLKit/GLKMatrixStack.h"

const GLfloat kRadPerDeg = 2.0f * M_PI / 360.0f;

@implementation DBArmModel
{
    // stores the position vector of the arm base
    GLKVector3 basePosition;
    
    // stores the position of the right and left base relative to base position
    GLKVector3 baseLeftPosition;
    GLKVector3 baseRightPosition;
    
    // stores the scaling for the base
    GLKVector3 baseScale;
    
    // stores the position for the upper arm, relative to base position
    GLKVector3 upperArmPosition;
    
    // stores the scaling for the upper arm
    GLKVector3 upperArmScale;
    
    // stores the position for the lower arm, relative to the base position + arm rotation
    GLKVector3 lowerArmPosition;
    GLKVector3 lowerArmMidPosition;
    
    // stores the scaling for the lower arm
    GLKVector3 lowerArmScale;
    
    // stores the position for the wrist
    GLKVector3 wristPosition;
    GLKVector3 wristMidPosition;
    
    // stores the scaling for the wrist
    GLKVector3 wristScale;
    
    // stores the finger positions
    GLKVector3 leftFingerPosition;
    GLKVector3 rightFingerPosition;
    GLKVector3 fingerMidPosition;
    GLKVector3 fingerEndPosition;
    
    // stores the finger scale
    GLKVector3 fingerScale;
    
    GLfloat lowerFingerAngle;
    
    // stores the reference to the position buffer we use in the OpenGL server
    GLuint vertexBufferObject;
    
    // stores the reference to the index buffer we use in the OpenGL server
    GLuint indexBufferObject;
    
    // stores the references to the vertex array we use in the OpenGL server
    GLuint vaObject;
    
}

- (void) awakeFromNib
{
    // do init stuff here, prep model data
    
    basePosition = GLKVector3Make(3.0f, -5.0f, -20.0f);
    
    self.baseRotation = -45.0f;
    
    baseLeftPosition = GLKVector3Make(2.0f, 0.0f, 0.0f);
    baseRightPosition = GLKVector3Make(-2.0f, 0.0f, 0.0f);
    
    baseScale = GLKVector3Make(1.0f, 1.0f, 3.0f);
    
    self.upperArmAngle = 90.0f;
    
    const GLfloat upperArmSize = 9.0f;
    
    upperArmPosition = GLKVector3Make(0.0f, 0.0f, upperArmSize / 2.0f);
    upperArmScale = GLKVector3Make(1.0f, 1.0f, upperArmSize / 2.0f - 1.0f);
    
    self.lowerArmAngle = 80.0f;
    
    const GLfloat lowerArmWidth = 1.5f;
    const GLfloat lowerArmLength = 5.0f;
    
    lowerArmPosition = GLKVector3Make(0.0f, 0.0f, 8.0f);
    lowerArmMidPosition = GLKVector3Make(0.0f, 0.0f, lowerArmLength / 2.0f);
    lowerArmScale = GLKVector3Make(lowerArmWidth / 2.0f, lowerArmWidth / 2.0f, lowerArmLength / 2.0f);
    
    self.wristAngle = 32.5f;
    self.wristRotation = 200.0f;
    
    const GLfloat wristLength = 2.0f;
    const GLfloat wristWidth = 2.0f;
    
    wristPosition = GLKVector3Make(0.0f, 0.0f, 5.0f);
    wristMidPosition = GLKVector3Make(0.0f, 0.0f, wristLength / 2.0f);
    wristScale = GLKVector3Make(wristWidth / 2.0f, wristWidth / 2.0f, wristLength / 2.0f);
    
    self.fingerAngle = 45.0f;
    
    const GLfloat fingerLength = 2.0f;
    const GLfloat fingerWidth = 0.5f;
    
    lowerFingerAngle = 45.0f;
    
    leftFingerPosition = GLKVector3Make(1.0f, 0.0f, 1.0f);
    rightFingerPosition = GLKVector3Make(-1.0f, 0.0f, 1.0f);
    fingerMidPosition = GLKVector3Make(0.0f, 0.0f, fingerLength / 2.0f);
    fingerEndPosition = GLKVector3Make(0.0f, 0.0f, fingerLength);
    
    fingerScale = GLKVector3Make(fingerWidth / 2.0f, fingerWidth / 2.0f, fingerLength / 2.0f);

}

// one of these days this data will not be buried in the view object!
const int numberOfVertices = 24;

#define RED_COLOR 1.0f, 0.0f, 0.0f, 1.0f
#define GREEN_COLOR 0.0f, 1.0f, 0.0f, 1.0f
#define BLUE_COLOR 	0.0f, 0.0f, 1.0f, 1.0f

#define YELLOW_COLOR 1.0f, 1.0f, 0.0f, 1.0f
#define CYAN_COLOR 0.0f, 1.0f, 1.0f, 1.0f
#define MAGENTA_COLOR 	1.0f, 0.0f, 1.0f, 1.0f

const float vertexData[] =
{
	//Front
	+1.0f, +1.0f, +1.0f,
	+1.0f, -1.0f, +1.0f,
	-1.0f, -1.0f, +1.0f,
	-1.0f, +1.0f, +1.0f,
    
	//Top
	+1.0f, +1.0f, +1.0f,
	-1.0f, +1.0f, +1.0f,
	-1.0f, +1.0f, -1.0f,
	+1.0f, +1.0f, -1.0f,
    
	//Left
	+1.0f, +1.0f, +1.0f,
	+1.0f, +1.0f, -1.0f,
	+1.0f, -1.0f, -1.0f,
	+1.0f, -1.0f, +1.0f,
    
	//Back
	+1.0f, +1.0f, -1.0f,
	-1.0f, +1.0f, -1.0f,
	-1.0f, -1.0f, -1.0f,
	+1.0f, -1.0f, -1.0f,
    
	//Bottom
	+1.0f, -1.0f, +1.0f,
	+1.0f, -1.0f, -1.0f,
	-1.0f, -1.0f, -1.0f,
	-1.0f, -1.0f, +1.0f,
    
	//Right
	-1.0f, +1.0f, +1.0f,
	-1.0f, -1.0f, +1.0f,
	-1.0f, -1.0f, -1.0f,
	-1.0f, +1.0f, -1.0f,
    
    
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
	RED_COLOR,
    
	YELLOW_COLOR,
	YELLOW_COLOR,
	YELLOW_COLOR,
	YELLOW_COLOR,
    
	CYAN_COLOR,
	CYAN_COLOR,
	CYAN_COLOR,
	CYAN_COLOR,
    
	MAGENTA_COLOR,
	MAGENTA_COLOR,
	MAGENTA_COLOR,
	MAGENTA_COLOR,
};

const GLshort indexData[] =
{
	0, 1, 2,
	2, 3, 0,
    
	4, 5, 6,
	6, 7, 4,
    
	8, 9, 10,
	10, 11, 8,
    
	12, 13, 14,
	14, 15, 12,
    
	16, 17, 18,
	18, 19, 16,
    
	20, 21, 22,
	22, 23, 20,
};


// this method obtains a buffer from the OpenGL server and loads our static data into it
- (void) prepareOpenGL
{
    glGenBuffers(1, &vertexBufferObject);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferObject);
    
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER,0);
    
    glGenBuffers(1, &indexBufferObject);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferObject);
    
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexData), indexData, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,0);

    // vertex array object for our object (in first half of buffer data)
    glGenVertexArrays(1, &vaObject);
    
    glBindVertexArray(vaObject);
    
    size_t colorDataOffset = sizeof(float) * 3 * numberOfVertices;
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferObject);
    
    glEnableVertexAttribArray(_positionAttrib);
    glEnableVertexAttribArray(_colorAttrib);
    
    glVertexAttribPointer(_positionAttrib, 3, GL_FLOAT, GL_FALSE, 0, 0);
    glVertexAttribPointer(_colorAttrib, 4, GL_FLOAT, GL_FALSE, 0, (void *)colorDataOffset);
    
    // the binding of the index buffer to the GL_ELEMENT_ARRAY_BUFFER binding
    // point is stored in the VAO (vaObject1) we are initializing
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferObject);
    
    glBindVertexArray(0);
    
}

// drawing model assumes the shader program has been selected with glUseProgram()
- (void) drawModelAtLocation:(GLKVector3)location
{
    // create a matrix stack to handle the hierarchial model display
    GLKMatrixStackRef modelStack = GLKMatrixStackCreate(kCFAllocatorDefault);
    
    glBindVertexArray(vaObject);
    
    GLKMatrixStackTranslateWithVector3(modelStack, location);
    GLKMatrixStackRotateY(modelStack, _baseRotation * kRadPerDeg);
    
    // draw left base -----------------------------------------------------------------------
    GLKMatrixStackPush(modelStack);
    GLKMatrixStackTranslateWithVector3(modelStack, baseLeftPosition);
    GLKMatrixStackScaleWithVector3(modelStack, baseScale);
    
    [self drawElementsWithMatrixStack:modelStack];
    
    GLKMatrixStackPop(modelStack);
    
    // draw right base -----------------------------------------------------------------------
    GLKMatrixStackPush(modelStack);
    GLKMatrixStackTranslateWithVector3(modelStack, baseRightPosition);
    GLKMatrixStackScaleWithVector3(modelStack, baseScale);
    
    [self drawElementsWithMatrixStack:modelStack];
    
    GLKMatrixStackPop(modelStack);
    
    // draw upper arm -----------------------------------------------------------------------
    GLKMatrixStackPush(modelStack);
    
    // this rotation will apply to the rest of the hierarchy
    GLKMatrixStackRotateX(modelStack, -_upperArmAngle * kRadPerDeg);
    
    // so push another copy onto the stack
    GLKMatrixStackPush(modelStack);
    GLKMatrixStackTranslateWithVector3(modelStack, upperArmPosition);
    GLKMatrixStackScaleWithVector3(modelStack, upperArmScale);
    
    [self drawElementsWithMatrixStack:modelStack];
    
    // remove the upper arm translation & scaling from the stack (leaves its rotation though)
    GLKMatrixStackPop(modelStack);
    
    // draw lower arm -----------------------------------------------------------------------
    GLKMatrixStackPush(modelStack);
    
    // this translation and rotation will apply to the rest of the hierarchy
    GLKMatrixStackTranslateWithVector3(modelStack, lowerArmPosition);
    GLKMatrixStackRotateX(modelStack, _lowerArmAngle * kRadPerDeg);

    // so push another copy onto the stack
    GLKMatrixStackPush(modelStack);
    
    GLKMatrixStackTranslateWithVector3(modelStack, lowerArmMidPosition);
    GLKMatrixStackScaleWithVector3(modelStack, lowerArmScale);
    
    [self drawElementsWithMatrixStack:modelStack];
    
    // remove the lower arm midposition translation & scaling from the stack (leaves its rotation though)
    GLKMatrixStackPop(modelStack);
    
    // draw wrist -----------------------------------------------------------------------

    GLKMatrixStackPush(modelStack);
    
    // this translation and rotation will apply to the rest of the hierarchy
    GLKMatrixStackTranslateWithVector3(modelStack, wristPosition);
    GLKMatrixStackRotateX(modelStack, _wristAngle * kRadPerDeg);
    GLKMatrixStackRotateZ(modelStack, _wristRotation * kRadPerDeg);
    
    // so push another copy onto the stack
    GLKMatrixStackPush(modelStack);
    
    GLKMatrixStackTranslateWithVector3(modelStack, wristMidPosition);
    GLKMatrixStackScaleWithVector3(modelStack, wristScale);
    
    [self drawElementsWithMatrixStack:modelStack];

    // remove the wrist midposition translation & scaling from the stack
    GLKMatrixStackPop(modelStack);
    
    // draw left finger -----------------------------------------------------------------------
    GLKMatrixStackPush(modelStack);

    GLKMatrixStackTranslateWithVector3(modelStack, leftFingerPosition);
    GLKMatrixStackRotateY(modelStack, _fingerAngle * kRadPerDeg);
   
    GLKMatrixStackPush(modelStack); // left upper finger
    
    GLKMatrixStackTranslateWithVector3(modelStack, fingerMidPosition);
    GLKMatrixStackScaleWithVector3(modelStack, fingerScale);
    
    [self drawElementsWithMatrixStack:modelStack];
    
    GLKMatrixStackPop(modelStack); // left upper finger
    
    GLKMatrixStackPush(modelStack); // left lower finger

    GLKMatrixStackTranslateWithVector3(modelStack, fingerEndPosition);
    GLKMatrixStackRotateY(modelStack,-lowerFingerAngle * kRadPerDeg);
    
    GLKMatrixStackTranslateWithVector3(modelStack, fingerMidPosition);
    GLKMatrixStackScaleWithVector3(modelStack, fingerScale);
    
    [self drawElementsWithMatrixStack:modelStack];
    
    GLKMatrixStackPop(modelStack); // left lower finger
    
    GLKMatrixStackPop(modelStack); // from draw left finger
    
    // draw right finger -----------------------------------------------------------------------
    GLKMatrixStackPush(modelStack);
    
    GLKMatrixStackTranslateWithVector3(modelStack, rightFingerPosition);
    GLKMatrixStackRotateY(modelStack, -_fingerAngle * kRadPerDeg);
    
    GLKMatrixStackPush(modelStack); // right upper finger
    
    GLKMatrixStackTranslateWithVector3(modelStack, fingerMidPosition);
    GLKMatrixStackScaleWithVector3(modelStack, fingerScale);
    
    [self drawElementsWithMatrixStack:modelStack];
    
    GLKMatrixStackPop(modelStack); // right upper finger
    
    GLKMatrixStackPush(modelStack); // right lower finger
    
    GLKMatrixStackTranslateWithVector3(modelStack, fingerEndPosition);
    GLKMatrixStackRotateY(modelStack,lowerFingerAngle * kRadPerDeg);
    
    GLKMatrixStackTranslateWithVector3(modelStack, fingerMidPosition);
    GLKMatrixStackScaleWithVector3(modelStack, fingerScale);
    
    [self drawElementsWithMatrixStack:modelStack];
    
    // these pops probably don't matter since we're going to release the whole stack later
    GLKMatrixStackPop(modelStack); // right lower finger
    GLKMatrixStackPop(modelStack); // from draw right finger
    GLKMatrixStackPop(modelStack); // from draw wrist
    GLKMatrixStackPop(modelStack); // from draw lower arm
    GLKMatrixStackPop(modelStack); // from draw upper arm

    glBindVertexArray(0);
    
    CFRelease(modelStack);
}

// draw model at an already established base position
- (void) drawModel
{
    [self drawModelAtLocation:basePosition];
}

// draw the elements for the model with the matrix at the top of the supplied stack
- (void) drawElementsWithMatrixStack:(GLKMatrixStackRef)matrixStack
{
    GLKMatrix4 modelMatrix = GLKMatrixStackGetMatrix4(matrixStack);
    glUniformMatrix4fv(_modelMatrixUniform, 1, GL_FALSE, (GLfloat *)&modelMatrix);
    
    glDrawElements(GL_TRIANGLES, sizeof(indexData)/sizeof(GLshort), GL_UNSIGNED_SHORT, 0);
}


@end

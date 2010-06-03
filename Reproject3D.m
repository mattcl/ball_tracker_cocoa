//
//  Reproject3D.m
//  CVOCV
//
//  Created by Matt Chun-Lum on 6/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Reproject3D.h"
#import "cv.h"


@implementation Reproject3D

-(void)setFocalLengthsForCamera1:(CvPoint2D32f) l1 andCamera2:(CvPoint2D32f) l2
{
	fxs = l1.x;
	fys = l1.y;
	fxt = l2.x;
	fyt = l2.y;
}

-(void)setCenterPointsForCamera1:(CvPoint2D32f) c1 andCamera2:(CvPoint2D32f) c2
{
	cxs = c1.x;
	cys = c1.y;
	cxt = c2.x;
	cyt = c2.y;
}

-(void)setOffsetsForCamera1:(CvPoint3D32f) o1 andCamera2:(CvPoint3D32f) o2
{
	xos = o1.x;
	yos = o1.y;
	zos = o1.z;
	xot = o2.x;
	yot = o2.y;
	zot = o2.z;
}

-(CvPoint3D32f) reprojectFromPoint1:(CvPoint2D32f) p1 andPoint2:(CvPoint2D32f) p2
{
	float us = p1.x;
	float vs = p1.y;
	float ut = p2.x;
	float vt = p2.y;
	
	float a = 1/fxs * (us - cxs);
	float b = 1/fys * (vs - cys);
	float c = 1/fxt * (ut - cxt);
	float d = 1/fyt * (vt - cyt);
	float e = zos + yot;
	float f = zot - yos;
	
	float xs = a * (e - d * f) / (1 + b * d);
	float ys = b * (e - d * f) / (1 + b * d);
	float zs = (e - d * f) / (1 + b * d);
	
	
	
	float X = xos - xs;
	float Y = zos - zs;
	float Z = yos - ys;
	
	return cvPoint3D32f(X, Y, Z);
}

@end

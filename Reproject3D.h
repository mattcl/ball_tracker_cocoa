//
//  Reproject3D.h
//  CVOCV
//
//  Created by Matt Chun-Lum on 6/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "cv.h"

@interface Reproject3D : NSObject {

	float fxs, fxt, fys, fyt;
	float cxs, cys, cxt, cyt;
	float xos, yos, zos, xot, yot, zot;
}

-(void)setFocalLengthsForCamera1:(CvPoint2D32f) l1 andCamera2:(CvPoint2D32f) l2;
-(void)setCenterPointsForCamera1:(CvPoint2D32f) c1 andCamera2:(CvPoint2D32f) c2;
-(void)setOffsetsForCamera1:(CvPoint3D32f) o1 andCamera2:(CvPoint3D32f) o2;
-(CvPoint3D32f) reprojectFromPoint1:(CvPoint2D32f) p1 andPoint2:(CvPoint2D32f) p2;


@end

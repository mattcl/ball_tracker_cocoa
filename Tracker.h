//
//  Tracker.h
//  CVOCV
//
//  Created by Matt Chun-Lum on 5/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "cv.h"

@interface Tracker : NSObject {
	const char *name;
	
	char hist_w[256];
	char mask_w[256];
	
	IplImage *hsv, *hue, *mask, *backproject, *histimg;
	CvHistogram *hist;
	CvRect track_window;
	CvBox2D track_box;
	CvBox2D last_track_box;
	CvConnectedComp track_comp;
	
	int select_object;
	int track_object;
	CvRect selection;
	CvPoint origin;
	
	BOOL backproject_mode;
	BOOL show_tracking_window;
	
	int hdims;
	float hranges_arr[2];
	float start_clock;
	
	int vmin, vmax, smin;
	
	float dt, dx, dy;
	int first_iter;
	
	float xOffset, yOffset, zOffset;
	float wPM, hPM;
}

-(id) initWithName:(NSString *)mname;
-(void) initImages;
-(void) processFrame:(IplImage *) frame;
-(void) loadHistogramAndMask;
-(void) reset;
-(void) setOffsetsX:(float) xo andY:(float) yo andZ:(float) zo;
-(void) setVmin:(int)vm vMax:(int)vmx sMin:(int)sm;
-(void) setPMW:(float) wpm h:(float)hpm;
-(void) setBackproject:(BOOL)value andDrawWindow:(BOOL)value2;
-(CvPoint2D32f) getBallCenter;
-(float) getXOffset;
-(float) getYOffset;
-(float) getZOffset;
-(float) getWPM;
-(float) getHPM;
-(float) getDx;
-(float) getDy;

@end

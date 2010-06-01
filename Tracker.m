//
//  Tracker.m
//  CVOCV
//
//  Created by Matt Chun-Lum on 5/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Tracker.h"
#import "cv.h"


@implementation Tracker

-(id) initWithName:(NSString *)mname
{
	[super init];
	name = [mname cStringUsingEncoding:NSUTF8StringEncoding];
	hdims = 16;
	hranges_arr[0] = 0;
	hranges_arr[1] = 180;
	start_clock = clock();
	backproject_mode = YES;
	vmin = 10;
	vmax = 200;
	smin = 1;
	first_iter = 1;
	return self;
}

-(void) initImages
{	
	hsv = cvCreateImage(cvSize(320, 240), 8, 3);
	hue = cvCreateImage(cvSize(320, 240), 8, 1);
	mask = cvCreateImage(cvSize(320, 240), 8, 1);
	backproject = cvCreateImage(cvSize(320, 240), 8, 1);
	float *hranges = hranges_arr;
	hist = cvCreateHist(1, &hdims, CV_HIST_ARRAY, &hranges, 1);
	histimg = cvCreateImage(cvSize(320, 200), 8, 3);
	cvZero(histimg);
}

static CvScalar hsv2rgb( float hue ) {
	int rgb[3], p, sector;
	static const int sector_data[][3]=
	{{0,2,1}, {1,2,0}, {1,0,2}, {2,0,1}, {2,1,0}, {0,1,2}};
	hue *= 0.033333333333333333333333333333333f;
	sector = cvFloor(hue);
	p = cvRound(255*(hue - sector));
	p ^= sector & 1 ? 255 : 0;
	
	rgb[sector_data[sector][0]] = 255;
	rgb[sector_data[sector][1]] = 0;
	rgb[sector_data[sector][2]] = p;
	
	return cvScalar(rgb[2], rgb[1], rgb[0],0);
}

-(void) processFrame:(IplImage *)img
{
	cvCvtColor(img, hsv, CV_BGR2HSV);
	
	if (track_object) {
		int _vmin = vmin, _vmax = vmax;
		cvInRangeS(hsv, cvScalar(0, smin, MIN(_vmin, _vmax), 0), cvScalar(180, 256, MAX(_vmin, _vmax), 0), mask);
		cvSplit(hsv, hue, 0, 0, 0);
		
		
		if( track_object < 0 ) {
			start_clock = clock();
			float max_val = 0.f;
			cvSetImageROI( hue, selection );
			cvSetImageROI( mask, selection );
			cvCalcHist( &hue, hist, 0, mask );
			cvGetMinMaxHistValue( hist, 0, &max_val, 0, 0 );
			cvConvertScale( hist->bins, hist->bins, max_val ? 255. / max_val : 0., 0 );
			cvResetImageROI( hue );
			cvResetImageROI( mask );
			track_window = selection;
			track_object = 1;
			
			cvZero( histimg );
			int bin_w = histimg->width / hdims;
			int j;
			for( j = 0; j < hdims; j++ )
			{
				int val = cvRound( cvGetReal1D(hist->bins,j)*histimg->height/255 );
				CvScalar color = hsv2rgb(j*180.f/hdims);
				cvRectangle( histimg, cvPoint(j*bin_w,histimg->height),
							cvPoint((j+1)*bin_w,histimg->height - val),
							color, -1, 8, 0 );
			}
			//saveHistogramAndMask();
			
		}
		
		cvCalcBackProject(&(hue), backproject, hist);
		cvAnd(backproject, mask, backproject, 0);
		
		cvCamShift(backproject, track_window, cvTermCriteria(CV_TERMCRIT_EPS | CV_TERMCRIT_ITER, 10, 1), &track_comp, &track_box);
		//track_window = track_comp.rect;
		track_window.x = 1;
		track_window.y = 1;
		track_window.width = img->width - 2;
		track_window.height = img->height - 2;
		
		
		// draw the backprojection only
		if (backproject_mode) {
			cvCvtColor(backproject, img, CV_GRAY2BGR);
		}
		
		
		if(show_tracking_window) {
			// draw a rectangle representing the tracking window
			cvRectangle(img, cvPoint(track_window.x, track_window.y), 
						cvPoint(track_window.x + track_window.width, track_window.y + track_window.height), 
						CV_RGB(0, 0, 255), 2, CV_AA, 0);
		}
		
		//cvPutText(img, "Test", cvPoint(0, 10), &font, CV_RGB(0,225,0));
		
		
		// draw a circle around the center of the object
		cvCircle(img, cvPointFrom32f(track_box.center), 10, CV_RGB(225, 0, 0), 2, CV_AA, 0);
		
		
		if (!first_iter) {
			// compute dx and dy for this iteration
			dx = track_box.center.x - last_track_box.center.x;
			dy = -(track_box.center.y - last_track_box.center.y);
		} else {
			first_iter = 0;
		}
		float cclock = clock();
		dt = (cclock - start_clock) / CLOCKS_PER_SEC;
		start_clock = cclock;
		last_track_box = track_box;
		
		cvCvtColor(img, img, CV_BGR2RGB);
	}
}

-(void)loadHistogramAndMask
{
	sprintf(hist_w, "%s_hist.xml", name);
	sprintf(mask_w, "%s_mask.xml", name);
	
	NSLog(@"attempting to load %s", hist_w);
	hist = (CvHistogram *)cvLoad(hist_w, 0, 0, 0);
	mask = (IplImage *)cvLoad(mask_w, 0, 0, 0);
	if(hist && mask) {
		NSLog(@"success loading histogram");
		track_object = 1;
		cvResetImageROI( mask );
		[self reset];
	}
}

-(void) reset
{
	if(track_object) {
		NSLog(@"resetting");
		track_window.x = 5;
		track_window.y = 5;
		track_window.width = 310;
		track_window.height = 230;
	}
}

-(void) setOffsetsX:(float) xo andY:(float) yo andZ:(float) zo
{
	xOffset = xo;
	yOffset = yo;
	zOffset = zo;
}

-(void) setVmin:(int)vm vMax:(int)vmx sMin:(int)sm
{
	vmin = vm;
	vmax = vmx;
	smin = sm;
}

-(void) setPMW:(float) wpm h:(float)hpm
{
	wPM = wpm;
	hPM = hpm;
}

-(void) setBackproject:(BOOL)value andDrawWindow:(BOOL)value2
{
	backproject_mode = value;
	show_tracking_window = value2;
}

-(CvPoint2D32f) getBallCenter
{
	if(track_object)
		return track_box.center;
	
	return cvPoint2D32f(0,0);
}

-(float) getXOffset
{
	return xOffset;
}

-(float) getYOffset
{
	return yOffset;
}

-(float) getZOffset
{
	return zOffset;
}

-(float) getWPM;
{
	return wPM;
}

-(float) getHPM;
{
	return hPM;
}

-(float) getDx
{
	return dx;
}

-(float) getDy
{
	return dy;
}


@end

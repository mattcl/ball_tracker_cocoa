/*
 *  CVOCVController.h
 *
 *  Created by buza on 10/02/08.
 *
 *  Brought to you by buzamoto. http://buzamoto.com
 */

#include "cv.h"

#import <Cocoa/Cocoa.h>
#import <QTKit/QTkit.h>
#import <Quartz/Quartz.h>
#import <sys/time.h>

#import "CVOCVView.h"
#import "Tracker.h"
#import "Reproject3D.h"

@interface CVOCVController : NSObject 
{
	IBOutlet NSTextField *sideXOffsetField;
	IBOutlet NSTextField *sideYOffsetField;
	IBOutlet NSTextField *sideZOffsetField;
	IBOutlet NSTextField *sidePMHField;
	IBOutlet NSTextField *sidePMWField;
	
	IBOutlet NSTextField *topXOffsetField;
	IBOutlet NSTextField *topYOffsetField;
	IBOutlet NSTextField *topZOffsetField;
	IBOutlet NSTextField *topPMHField;
	IBOutlet NSTextField *topPMWField;
	
	IBOutlet NSSlider *sideVMinSlider;
	IBOutlet NSSlider *sideVMaxSlider;
	IBOutlet NSSlider *sideSMinSlider;
	
	IBOutlet NSSlider *topVMinSlider;
	IBOutlet NSSlider *topVMaxSlider;
	IBOutlet NSSlider *topSMinSlider;
	
	IBOutlet NSTextField *serverIPField;
	IBOutlet NSButton    *connectButton;
	IBOutlet NSButton    *closeButton;
	IBOutlet NSButton    *transButton;
	IBOutlet NSButton    *sideCalibrateCenterButton;
	IBOutlet NSButton    *topCalibrateCenterButton;
	
	IBOutlet NSTextFieldCell *xPosCell;
	IBOutlet NSTextFieldCell *yPosCell;
	IBOutlet NSTextFieldCell *zPosCell;
	IBOutlet NSTextFieldCell *ballWidthCell;
	IBOutlet NSTextFieldCell *ballHeightCell;
	IBOutlet NSTextFieldCell *timeCell;
	IBOutlet NSTextFieldCell *dtFieldCell;
	IBOutlet NSTextFieldCell *conStatFieldCell;
	IBOutlet NSTextFieldCell *transStateFieldCell;
	
	IBOutlet NSButtonCell    *enableVideoCell;
	IBOutlet NSButtonCell    *backprojectCell;
	IBOutlet NSButtonCell    *showSizeCell;
	IBOutlet NSButtonCell    *windowCell;
	
    IBOutlet CVOCVView *sideOpenGLView;
	IBOutlet CVOCVView *topOpenGLView;
    IBOutlet QTCaptureView *mSideCaptureView;
    IBOutlet QTCaptureView *mTopCaptureView;
   
    QTCaptureSession                    *sideCaptureSession;
	QTCaptureSession                    *topCaptureSession;
    QTCaptureMovieFileOutput            *sideCaptureMovieFileOutput;
	QTCaptureMovieFileOutput            *topCaptureMovieFileOutput;
	QTCaptureDeviceInput                *sideCaptureVideoDeviceInput;
    QTCaptureDeviceInput                *topCaptureVideoDeviceInput;
    QTCaptureDecompressedVideoOutput    *mSideOutput;
	QTCaptureDecompressedVideoOutput    *mTopOutput;
	

    IplImage *sideFrameImage;
	IplImage *topFrameImage;
	
	Tracker* sideTracker;
	Tracker* topTracker;
	
	Reproject3D *reprojector;
	
	int newsockfd;
	char buffer[256];
	
	int s;
	
	float rawX;
	float rawY;
	float rawZ;
	
	float centerX;
	float centerY;
	float centerZ;
	
	BOOL grabTop;
	BOOL grabSide;
	
	struct timeval tim;
	double startTime;
	double curTime;
	double lastTime;
	double dt;
}

+ (void) grabImage;

+ (IplImage*) capturedImage;

+ (BOOL) bgUpdated;
+ (void) setViewed;

-(IBAction)setTopPM:(id)sender;
-(IBAction)setSidePM:(id)sender;

-(IBAction)setTopOffsets:(id)sender;
-(IBAction)setSideOffsets:(id)sender;

-(IBAction)setTopThresh:(id)sender;
-(IBAction)setSideThresh:(id)sender;

-(IBAction)connectToServer:(id)sender;
-(IBAction)closeConnection:(id)sender;
-(IBAction)toogleTransmitting:(id)sender;

-(IBAction)setVideoParameters:(id)sender;

-(IBAction)calibrateTopCenter:(id)sender;
-(IBAction)calibrateSideCenter:(id)sender;

-(void) texturizeImage:(IplImage*) image;
-(void) texturizeImage2:(IplImage*) image;
-(void) setPositionDisplayWithX:(float) x andY:(float) y andZ:(float) z;
-(void) updateReprojector;

@end

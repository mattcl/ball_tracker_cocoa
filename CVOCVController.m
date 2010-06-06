/*
 *  CVOCVController.m
 *
 *  Created by buza on 10/02/08.
 *
 *  Brought to you by buzamoto. http://buzamoto.com
 */

#include "cv.h"
#import "CVOCVController.h"
#import "OpenCVProcessor.h"

//For IKImageView dealings.
#import "CGImageWrapper.h"
#import "Tracker.h"
#import <sys/time.h>
#import "Reproject3D.h"

extern "C" int connect_client(int* sockfd, char * buffer, const char * ip_addr);
extern "C" int read_client(int sockfd, char * buffer);
extern "C" int write_client(int sockfd, char * buffer, int length);
extern "C" int close_connection(int sockfd);

@implementation CVOCVController

static BOOL enableVideo;
static BOOL connected;
static BOOL transmit;
static BOOL updated;
static BOOL grabImage;
static IplImage *capturedImage;

+ (void) grabImage
{
    grabImage = YES;
}

+ (IplImage*) capturedImage
{
    return capturedImage;
}

+ (BOOL) bgUpdated
{
    return updated;
}

+ (void) setViewed
{       
    updated = NO;
}

- (void)awakeFromNib
{	
	reprojector = [[Reproject3D alloc] init];
	s = 0;
	transmit = NO;
	grabTop = YES;
	grabSide = YES;
	[self setPositionDisplayWithX:0.0 andY:0.0 andZ:0.0];
	connected = NO;
	BOOL success = NO;
	NSError *error;
    // Create the capture session
	sideCaptureSession = [[QTCaptureSession alloc] init];
    mSideOutput = [[QTCaptureDecompressedVideoOutput alloc] init];
    [mSideOutput setPixelBufferAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithDouble:320.0], (id)kCVPixelBufferWidthKey,
                                        [NSNumber numberWithDouble:240.0], (id)kCVPixelBufferHeightKey,
                                        [NSNumber numberWithUnsignedInt:kCVPixelFormatType_24RGB], (id)kCVPixelBufferPixelFormatTypeKey,
                                        nil]];
    
    [mSideOutput setDelegate:self];
    sideFrameImage = (IplImage*)malloc(sizeof(IplImage));
    //Find a device  
    QTCaptureDevice *videoDevice = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
    success = [videoDevice open:&error];
    videoDevice = [[QTCaptureDevice inputDevices] objectAtIndex:7];
    NSLog(@"Selecting device %@", videoDevice);
    [videoDevice open:&error];
    if (error != nil) {
        NSLog(@"Had some trouble selecting that device. I'm leaving now.");
        return;
    }
    //Add the video device to the session as a device input
    if (videoDevice) {
		sideCaptureVideoDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:videoDevice];
		success = [sideCaptureSession addInput:sideCaptureVideoDeviceInput error:&error];
		if (!success) {
            NSLog(@"Couldn't set up the input device. I'm leaving now.");
            return;
		}
        success = [sideCaptureSession addOutput:mSideOutput error:&error];
		if (!success) {
            NSLog(@"Couldn't set up the output device. I'm leaving now.");
            return;
		}
        //[mSideCaptureView setCaptureSession:sideCaptureSession];
        //Looks like we're good to go.
        [sideCaptureSession startRunning];
	}
	
	// top camera
	topCaptureSession = [[QTCaptureSession alloc] init];
    mTopOutput = [[QTCaptureDecompressedVideoOutput alloc] init];
    [mTopOutput setPixelBufferAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
										   [NSNumber numberWithDouble:320.0], (id)kCVPixelBufferWidthKey,
										   [NSNumber numberWithDouble:240.0], (id)kCVPixelBufferHeightKey,
										   [NSNumber numberWithUnsignedInt:kCVPixelFormatType_24RGB], (id)kCVPixelBufferPixelFormatTypeKey,
										   nil]];
    
    [mTopOutput setDelegate:self];
    topFrameImage = (IplImage*)malloc(sizeof(IplImage));
    //Find a device  
    videoDevice = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
    success = [videoDevice open:&error];
    videoDevice = [[QTCaptureDevice inputDevices] objectAtIndex:6];
    NSLog(@"Selecting device %@", videoDevice);
    [videoDevice open:&error];
    if (error != nil) {
        NSLog(@"Had some trouble selecting that device. I'm leaving now.");
        return;
    }
    //Add the video device to the session as a device input
    if (videoDevice) {
		topCaptureVideoDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:videoDevice];
		success = [topCaptureSession addInput:topCaptureVideoDeviceInput error:&error];
		if (!success) {
            NSLog(@"Couldn't set up the input device. I'm leaving now.");
            return;
		}
        success = [topCaptureSession addOutput:mTopOutput error:&error];
		if (!success) {
            NSLog(@"Couldn't set up the output device. I'm leaving now.");
            return;
		}
        //[mTopCaptureView setCaptureSession:topCaptureSession];
        //Looks like we're good to go.
        [topCaptureSession startRunning];
	}
	
	// initialize trackers
	topTracker = [[Tracker alloc] initWithName:@"top camera"];
	[topTracker initImages];
	[topTracker loadHistogramAndMask];
	
	sideTracker = [[Tracker alloc] initWithName:@"front camera"];
	[sideTracker initImages];
	[sideTracker loadHistogramAndMask];
	
	[sideTracker setVmin:117 vMax:255 sMin:174];
	[sideVMinSlider setIntValue:117];
	[sideVMaxSlider setIntValue:255];
	[sideSMinSlider setIntValue:174];
	
	[topTracker setVmin:117 vMax:255 sMin:184];
	[topVMinSlider setIntValue:117];
	[topVMaxSlider setIntValue:255];
	[topSMinSlider setIntValue:184];
	
	[topTracker setOffsetsX:2.3495 andY:0.340 andZ:1.29];
	[topXOffsetField setFloatValue:[topTracker getXOffset]];
	[topYOffsetField setFloatValue:[topTracker getYOffset]];
	[topZOffsetField setFloatValue:[topTracker getZOffset]];
	
	//[topTracker setPMW:0.096 h:0.096];
	//[topPMHField setFloatValue:[topTracker getHPM]];
	//[topPMWField setFloatValue:[topTracker getWPM]];
	
	[sideTracker setOffsetsX:2.209 andY:2.55 andZ:0.27];
	[sideXOffsetField setFloatValue:[sideTracker getXOffset]];
	[sideYOffsetField setFloatValue:[sideTracker getYOffset]];
	[sideZOffsetField setFloatValue:[sideTracker getZOffset]];
	
	//[sideTracker setPMW:0.009325 h:0.008291];
	//[sidePMHField setFloatValue:[sideTracker getHPM]];
	//[sidePMWField setFloatValue:[sideTracker getWPM]];
	
	[conStatFieldCell setStringValue:@"Not Connected"];
	
	[self setVideoParameters:nil];
	
	[self updateReprojector];
	
	[reprojector setCenterPointsForCamera1:cvPoint2D32f(149.9492060878939412, 108.1980667440229666) 
								andCamera2:cvPoint2D32f(149.9492060878939412, 108.1980667440229666)];
	
	[reprojector setFocalLengthsForCamera1:cvPoint2D32f(264.8570031668078855, 264.2436888796606809) 
								andCamera2:cvPoint2D32f(264.8570031668078855, 264.2436888796606809)];
	
	gettimeofday(&tim, NULL);
	startTime = tim.tv_sec+(tim.tv_usec/1000000.0);
	lastTime = startTime;
	dt = startTime;
	
	//[dtFieldCell setDoubleValue:dt];
	
	enableVideo = [enableVideoCell state] == NSOnState;
	
}

- (void)windowWillClose:(NSNotification *)notification
{
	[sideCaptureSession stopRunning];
    
    if ([[sideCaptureVideoDeviceInput device] isOpen])
        [[sideCaptureVideoDeviceInput device] close];
	
	[topCaptureSession stopRunning];
    
    if ([[topCaptureVideoDeviceInput device] isOpen])
        [[topCaptureVideoDeviceInput device] close];
}

- (void)dealloc
{
	[sideCaptureSession release];
	[sideCaptureVideoDeviceInput release];

    free(sideFrameImage);
	
	[topCaptureSession release];
	[topCaptureVideoDeviceInput release];
	
    free(topFrameImage);
	
	[super dealloc];
}

//Create a CGImageRef from the video frame so we can send it to the ImageKitView.
static CGImageRef CreateCGImageFromPixelBuffer(CVImageBufferRef inImage, OSType inPixelFormat)
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    
    void *baseAddress = CVPixelBufferGetBaseAddress(inImage);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(inImage);
    
    size_t width = CVPixelBufferGetWidth(inImage);
    size_t height = CVPixelBufferGetHeight(inImage);
    CGImageAlphaInfo alphaInfo = kCGImageAlphaNone;
    CGDataProviderRef provider = provider = CGDataProviderCreateWithData(NULL, baseAddress, bytesPerRow * height, NULL);

    CGImageRef image = CGImageCreate(width, height, 8, 24, bytesPerRow, colorSpace, alphaInfo, provider, NULL, false, kCGRenderingIntentDefault);
    
    // Once the image is created we can release our reference to the provider and the colorspace, they are retained by the image
    if (provider) {
        CGDataProviderRelease(provider);
    if (colorSpace) 
        CGColorSpaceRelease(colorSpace);
    }
    
    return image;
}

/*
 * Here's one reference that I found moderately useful for this CoreVideo stuff:
 * http://developer.apple.com/documentation/graphicsimaging/Reference/CoreVideoRef/Reference/reference.html
 */
- (void)captureOutput:(QTCaptureOutput *)captureOutput didOutputVideoFrame:(CVImageBufferRef)videoFrame withSampleBuffer:(QTSampleBuffer *)sampleBuffer fromConnection:(QTCaptureConnection *)connection
{
	if (captureOutput == mSideOutput) {
		CVPixelBufferLockBaseAddress((CVPixelBufferRef)videoFrame, 0);
		
		//Fill in the OpenCV image struct from the data from CoreVideo.
		sideFrameImage->nSize       = sizeof(IplImage);
		sideFrameImage->ID          = 0;
		sideFrameImage->nChannels   = 3;
		sideFrameImage->depth       = IPL_DEPTH_8U;
		sideFrameImage->dataOrder   = 0;
		sideFrameImage->origin      = 0; //Top left origin.
		sideFrameImage->width       = CVPixelBufferGetWidth((CVPixelBufferRef)videoFrame);
		sideFrameImage->height      = CVPixelBufferGetHeight((CVPixelBufferRef)videoFrame);
		sideFrameImage->roi         = 0; //Region of interest. (struct IplROI).
		sideFrameImage->maskROI     = 0;
		sideFrameImage->imageId     = 0;
		sideFrameImage->tileInfo    = 0;
		sideFrameImage->imageSize   = CVPixelBufferGetDataSize((CVPixelBufferRef)videoFrame);
		sideFrameImage->imageData   = (char*)CVPixelBufferGetBaseAddress((CVPixelBufferRef)videoFrame);
		sideFrameImage->widthStep   = CVPixelBufferGetBytesPerRow((CVPixelBufferRef)videoFrame);
		sideFrameImage->imageDataOrigin = (char*)CVPixelBufferGetBaseAddress((CVPixelBufferRef)videoFrame);
		
		//Process the frame, and get the result.
		IplImage *resultImage = [OpenCVProcessor passThrough:sideFrameImage];
		//IplImage *resultImage = [OpenCVProcessor noiseFilter:sideFrameImage];
		//IplImage *resultImage = [OpenCVProcessor findSquares:sideFrameImage];
		//IplImage *resultImage = [OpenCVProcessor hueSatHistogram:sideFrameImage];
		//IplImage *resultImage = [OpenCVProcessor downsize8:sideFrameImage];
		
		//Back project example. Hit the space bar to capture the reference image.
		//IplImage *resultImage = [OpenCVProcessor backProject:sideFrameImage];
		
		
		//IplImage *resultImage = [OpenCVProcessor cannyTest:sideFrameImage];

		[sideTracker processFrame:resultImage];
		
		if (grabSide) {
			grabSide = NO;
			CvPoint2D32f center = [sideTracker getBallCenter];
			rawX = center.x;
			rawZ = center.y;
		}
		
		if (enableVideo) {
			[self texturizeImage:resultImage];
		}
		
		CVPixelBufferUnlockBaseAddress((CVPixelBufferRef)videoFrame, 0);
	} else {
		CVPixelBufferLockBaseAddress((CVPixelBufferRef)videoFrame, 0);
		
		//Fill in the OpenCV image struct from the data from CoreVideo.
		topFrameImage->nSize       = sizeof(IplImage);
		topFrameImage->ID          = 0;
		topFrameImage->nChannels   = 3;
		topFrameImage->depth       = IPL_DEPTH_8U;
		topFrameImage->dataOrder   = 0;
		topFrameImage->origin      = 0; //Top left origin.
		topFrameImage->width       = CVPixelBufferGetWidth((CVPixelBufferRef)videoFrame);
		topFrameImage->height      = CVPixelBufferGetHeight((CVPixelBufferRef)videoFrame);
		topFrameImage->roi         = 0; //Region of interest. (struct IplROI).
		topFrameImage->maskROI     = 0;
		topFrameImage->imageId     = 0;
		topFrameImage->tileInfo    = 0;
		topFrameImage->imageSize   = CVPixelBufferGetDataSize((CVPixelBufferRef)videoFrame);
		topFrameImage->imageData   = (char*)CVPixelBufferGetBaseAddress((CVPixelBufferRef)videoFrame);
		topFrameImage->widthStep   = CVPixelBufferGetBytesPerRow((CVPixelBufferRef)videoFrame);
		topFrameImage->imageDataOrigin = (char*)CVPixelBufferGetBaseAddress((CVPixelBufferRef)videoFrame);
		
		//Process the frame, and get the result.
		IplImage *resultImage = [OpenCVProcessor passThrough:topFrameImage];
		//IplImage *resultImage = [OpenCVProcessor noiseFilter:sideFrameImage];
		//IplImage *resultImage = [OpenCVProcessor findSquares:sideFrameImage];
		//IplImage *resultImage = [OpenCVProcessor hueSatHistogram:sideFrameImage];
		//IplImage *resultImage = [OpenCVProcessor downsize8:sideFrameImage];
		
		//Back project example. Hit the space bar to capture the reference image.
		//IplImage *resultImage = [OpenCVProcessor backProject:sideFrameImage];
		
		
		//IplImage *resultImage = [OpenCVProcessor cannyTest:sideFrameImage];
		
		[topTracker processFrame:resultImage];
		
		if (grabTop) {
			grabTop = NO;
			CvPoint2D32f center = [topTracker getBallCenter];
			rawY = center.y;
		}
		
		if (enableVideo) {
			[self texturizeImage2:resultImage];
		}
		
		
		CVPixelBufferUnlockBaseAddress((CVPixelBufferRef)videoFrame, 0);
	}
	
	if(!grabTop && !grabSide) {
		grabTop = YES;
		grabSide = YES;
		
		//centerX = [sideTracker getWPM] * (160 - rawX) + [sideTracker getXOffset];
//		centerY = [topTracker getHPM] * (120 - rawY) + [topTracker getYOffset];
//		centerZ = [sideTracker getHPM] * (120 - rawZ) + [sideTracker getZOffset];
		
		CvPoint3D32f ballCenter = [reprojector reprojectFromPoint1:[sideTracker getBallCenter] andPoint2:[topTracker getBallCenter]];
		centerX = -ballCenter.x;
		centerY = -ballCenter.y;
		centerZ = -ballCenter.z;
		
		gettimeofday(&tim, NULL);
		curTime = (tim.tv_sec+(tim.tv_usec/1000000.0)) - startTime;
		dt = 1.0/(curTime - lastTime);
		lastTime = curTime;
		
		[self setPositionDisplayWithX:centerX andY:centerY andZ:centerZ];
		sprintf(buffer,"%35d %35d %35d %35d %35d %35d %35d   \n",
				(int)(s),
				(int)(1000000*centerX),
				(int)(1000000*centerY),
				(int)(1000000*centerZ),
				(int)(1000000*-[topTracker getDx]),
				(int)(1000000*(curTime)),
				(int)(1000000*0));
		
		s++;
		
		[ballWidthCell setFloatValue:[sideTracker getBallSize].width];
		[ballHeightCell setFloatValue:[sideTracker getBallSize].height];
		
		if (centerX < 0.8) {
			transmit = NO;
			[transStateFieldCell setStringValue:@"Not Transmitting"];
		}
		
		if(connected && transmit) {
			if ([topTracker shouldIgnore] || [sideTracker shouldIgnore]) {
				//NSLog(@"ignoring");
			} else {
				write_client(newsockfd, buffer, strlen(buffer));
			}
		}
	}
}

-(void) texturizeImage:(IplImage*) image
{
    int newIndex = sideOpenGLView->imageIndex;
    newIndex = (newIndex + 1) % IMAGE_CACHE_SIZE;
    sideOpenGLView->cvTextures[newIndex].texImage = image;
    sideOpenGLView->imageIndex = newIndex;
    [sideOpenGLView setNeedsDisplay:YES];
}

-(void) texturizeImage2:(IplImage*) image
{
    int newIndex = topOpenGLView->imageIndex;
    newIndex = (newIndex + 1) % IMAGE_CACHE_SIZE;
    topOpenGLView->cvTextures[newIndex].texImage = image;
    topOpenGLView->imageIndex = newIndex;
    [topOpenGLView setNeedsDisplay:YES];
}

-(void) setPositionDisplayWithX:(float) x andY:(float) y andZ:(float) z
{
	[xPosCell setFloatValue:x];
	[yPosCell setFloatValue:y];
	[zPosCell setFloatValue:z];
}

-(void)updateReprojector
{
	[reprojector setOffsetsForCamera1:cvPoint3D32f(-[sideTracker getXOffset],
												   -[sideTracker getZOffset],
												   -[sideTracker getYOffset]) 
						   andCamera2:cvPoint3D32f(-[topTracker getXOffset],
												   [topTracker getYOffset],
												   -[topTracker getXOffset])];
}

// tracker code here
-(IBAction)setTopOffsets:(id)sender 
{
	float xo = [topXOffsetField floatValue];
	float yo = [topYOffsetField floatValue];
	float zo = [topZOffsetField floatValue];
	
	[topTracker setOffsetsX:xo andY:yo andZ:zo];
	[self updateReprojector];
}

-(IBAction)setSideOffsets:(id)sender
{
	float xo = [sideXOffsetField floatValue];
	float yo = [sideYOffsetField floatValue];
	float zo = [sideZOffsetField floatValue];
	
	[sideTracker setOffsetsX:xo andY:yo andZ:zo];
	[self updateReprojector];
}

-(IBAction)setTopThresh:(id)sender 
{
	int vmin = [topVMinSlider intValue];
	int vmax = [topVMaxSlider intValue];
	int smin = [topSMinSlider intValue];
	
	[topTracker setVmin:vmin vMax:vmax sMin:smin];
}

-(IBAction)setSideThresh:(id)sender
{
	int vmin = [sideVMinSlider intValue];
	int vmax = [sideVMaxSlider intValue];
	int smin = [sideSMinSlider intValue];
	
	[sideTracker setVmin:vmin vMax:vmax sMin:smin];
}

-(IBAction)setSidePM:(id)sender
{
	[sideTracker setPMW:[sidePMWField floatValue] h:[sidePMHField floatValue]];
}

-(IBAction)setTopPM:(id)sender
{
	[topTracker setPMW:[topPMWField floatValue] h:[topPMHField floatValue]];
}

-(IBAction)connectToServer:(id)sender
{
	if(!connected) {
		const char * server_ip = [[serverIPField stringValue] cStringUsingEncoding:NSUTF8StringEncoding];
		NSLog(@"Attempting to connect to server: %s", server_ip);
		connect_client(&newsockfd, buffer, server_ip);
		connected = YES;
		[connectButton setEnabled:NO];
		[closeButton setEnabled:YES];
		[conStatFieldCell setStringValue:@"Connected"];
	}
}

-(IBAction)closeConnection:(id)sender 
{
	if (connected) {
		NSLog(@"Attempting to close connection");
		close(newsockfd);
		connected = NO;
		[connectButton setEnabled:YES];
		[closeButton setEnabled:NO];
	}
}

-(IBAction)toogleTransmitting:(id)sender
{
	transmit = !transmit;
	if(transmit)
		[transStateFieldCell setStringValue:@"Transmitting"];
	else
		[transStateFieldCell setStringValue:@"Not Transmitting"];
}

-(IBAction)setVideoParameters:(id)sender
{
	enableVideo = [enableVideoCell state] == NSOnState;
	BOOL bp = [backprojectCell state] == NSOnState;
	BOOL dw = [windowCell state] == NSOnState;
	BOOL ds = [showSizeCell state] == NSOnState;
	[topTracker setBackproject:bp andDrawWindow:dw andDrawSize:ds];
	[sideTracker setBackproject:bp andDrawWindow:dw andDrawSize:ds];
}

-(IBAction)calibrateTopCenter:(id)sender
{
	[topTracker setCenterIgnore];
}

-(IBAction)calibrateSideCenter:(id)sender
{
	[sideTracker setCenterIgnore];
}

@end

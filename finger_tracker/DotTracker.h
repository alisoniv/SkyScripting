#ifndef DOTTRACKER_H
#define DOTTRACKER_H

#include <opencv2/opencv.hpp>
#include <vector>
#include <chrono>

/**
* Tracks the location of a colored dot to produce traces.
*/

class DotTracker {
public:

	/* Default constructor */
	DotTracker();
	
	/* Custom constructor */
	DotTracker(cv::Scalar lower, cv::Scalar upper, int area);

	/* Run the dot tracker application */
	void run();

private:
	cv::VideoCapture cap;

	cv::Mat currentFrame;
	cv::Mat hsvFrame;
	cv::Mat mask;
	cv::Mat drawingLayer;
	cv::Mat buttonLayer;
	cv::Mat canvas;

	cv::Scalar lowerRange;
	cv::Scalar upperRange;

	int frameWidth;
	int frameHeight;
	int areaThreshold;

	std::vector<std::vector<cv::Point>> contours;
	std::vector<cv::Point> tracePoints;

	/* Return true if the dot is detected in the frame */
	bool dotIsDetected(const cv::Point& pt);

	/* Return true if the point is on the button bar */
	bool isCommand(const cv::Point& pt);

	/* Return true if nothing has been drawn */
	bool isDrawingBlank();

	/* Return true if the point is on the left half of the frame */
	bool isOnLeftHalf(const cv::Point& pt);

	/* Return the location of the dot in the frame or (-1, -1) if it is not detected */
	cv::Point findDotLocation();

	/* Return the height of the button bar */
	int buttonBarHeight();

	/* Add the given point to the drawing */
	void addToDrawing(cv::Point pt);

	/* Apply the mask to identify the colored dot */
	void applyMask();

	/* Erase what has been drawn so far */
	void eraseDrawing();

	/* Execute either the 'Save Drawing' or 'Clear Drawing' command */
	void executeCommand(const cv::Point& pt);

	/* Show the live camera feed and the drawing */
	void display();

	/* Initialize the screen */
	void initializeScreen();

	/* Read in a single frame from the live camera */
	void readFrame();

	/* Save the current state of the drawing in a PNG file called letter.png */
	void saveImage();

	/* Start camera */
	void startVideoCapture();
};

#endif
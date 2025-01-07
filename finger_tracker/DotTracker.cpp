#include "DotTracker.h"

DotTracker::DotTracker() 
	: frameWidth{ 0 }, frameHeight{ 0 }, lowerRange { cv::Scalar(0, 130, 210) }, upperRange{ cv::Scalar(25, 240, 255) }, areaThreshold{ 20 } {
}

DotTracker::DotTracker(cv::Scalar lower, cv::Scalar upper, int area)
	: frameWidth{ 0 }, frameHeight{ 0 }, lowerRange{ lower }, upperRange{ upper }, areaThreshold{ area } {
}

void DotTracker::startVideoCapture() {
	cap.open(0);

	if (!cap.isOpened()) {
		std::cerr << "Video capture could not be opened!" << std::endl;
		return;
	}
}

void DotTracker::initializeScreen() {
	if (!cap.isOpened()) {
		std::cerr << "Video capture is not open!" << std::endl;
		return;
	}

	frameWidth = static_cast<int>(cap.get(cv::CAP_PROP_FRAME_WIDTH));
	frameHeight = static_cast<int>(cap.get(cv::CAP_PROP_FRAME_HEIGHT));

	drawingLayer = cv::Mat::zeros(frameHeight, frameWidth, CV_8UC3);
	buttonLayer = cv::Mat::zeros(frameHeight, frameWidth, CV_8UC3);
	canvas = cv::Mat::zeros(frameHeight, frameWidth, CV_8UC3);

	int y = buttonBarHeight();
	int x = frameWidth / 2;

	cv::rectangle(buttonLayer, cv::Point(0, y), cv::Point(x, frameHeight), cv::Scalar(0, 255, 0), -1);
	cv::rectangle(buttonLayer, cv::Point(x, y), cv::Point(frameWidth, frameHeight), cv::Scalar(0, 0, 255), -1);
}

int DotTracker::buttonBarHeight() {
	return frameHeight - frameHeight / 10;
}

void DotTracker::readFrame() {
	cap.read(currentFrame);
	cv::flip(currentFrame, currentFrame, 1);
	cv::cvtColor(currentFrame, hsvFrame, cv::COLOR_BGR2HSV);
}

void DotTracker::applyMask() {
	cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(5, 5));
	cv::inRange(hsvFrame, lowerRange, upperRange, mask);
	morphologyEx(mask, mask, cv::MORPH_OPEN, kernel);
	morphologyEx(mask, mask, cv::MORPH_CLOSE, kernel);
}

cv::Point DotTracker::findDotLocation() {
	cv::findContours(mask, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);

	if (!contours.empty()) {
		auto largestContour = std::max_element(contours.begin(), contours.end(), [](const std::vector<cv::Point>& a, const std::vector<cv::Point>& b) {return cv::contourArea(a) < cv::contourArea(b); });

		if (cv::contourArea(*largestContour) > areaThreshold) {
			cv::Moments m = cv::moments(*largestContour);
			if (m.m00 != 0) {
				int cx = static_cast<int>(m.m10 / m.m00);
				int cy = static_cast<int>(m.m01 / m.m00);

				return cv::Point(cx, cy);
			}
		}
	}

	return cv::Point(-1, -1);
}

bool DotTracker::dotIsDetected(const cv::Point& pt) {
	return pt.x != -1 && pt.y != -1;
}

bool DotTracker::isCommand(const cv::Point& pt) {
	return pt.y >= buttonBarHeight();
}

bool DotTracker::isOnLeftHalf(const cv::Point& pt) {
	return pt.x < frameWidth / 2;
}

bool DotTracker::isDrawingBlank() {
	return tracePoints.empty();
}

void DotTracker::executeCommand(const cv::Point& pt) {
	if (isOnLeftHalf(pt)) {
		saveImage();
	}

	eraseDrawing();
}

void DotTracker::eraseDrawing() {
	drawingLayer = cv::Mat::zeros(frameHeight, frameWidth, CV_8UC3);
	canvas = cv::Mat::zeros(frameHeight, frameWidth, CV_8UC3);
	tracePoints.clear();
}

void DotTracker::addToDrawing(cv::Point pt) {
	cv::circle(drawingLayer, pt, 7, cv::Scalar(0, 255, 0), -1);
	cv::circle(canvas, pt, 7, cv::Scalar(255, 255, 255), -1);
	tracePoints.push_back(pt);
}

void DotTracker::saveImage() {
	cv::imwrite("letter.png", canvas);
}

void DotTracker::display() {
	cv::addWeighted(currentFrame, 1.0, drawingLayer, 1.0, 0, currentFrame);
	cv::addWeighted(currentFrame, 1.0, buttonLayer, 1.0, 0, currentFrame);

	cv::imshow("Live Camera", currentFrame);
	cv::imshow("Mask", mask);
	// cv::imshow("HSV", hsvFrame);
	cv::imshow("Canvas", canvas);
}

void DotTracker::run() {
	startVideoCapture();
	initializeScreen();

	auto start = std::chrono::steady_clock::now();

	for (;;) {
		readFrame();
		applyMask();

		cv::Point dot = findDotLocation();
		if (dotIsDetected(dot)) {
			if (isCommand(dot)) {
				executeCommand(dot);
			}
			else {
				addToDrawing(dot);
			}

			start = std::chrono::steady_clock::now();
		}
		else {
			if (!isDrawingBlank()) {
				auto now = std::chrono::steady_clock::now();
				auto timeSinceLastTrace = std::chrono::duration_cast<std::chrono::seconds>(now - start).count();

				if (timeSinceLastTrace > 4) {
					saveImage();
					eraseDrawing();
				}
			}
		}

		display();

		if (cv::waitKey(1) == 'q') {
			break;
		}
	}

	cap.release();
	cv::destroyAllWindows();
}
#include <opencv2/opencv.hpp>
#include <vector>
#include <chrono>
#include "DotTracker.h"

int script() {
	cv::VideoCapture cap(0);

	cv::Mat frame;
	cv::Mat hsv;
	cv::Mat mask;

	cv::Scalar lowerOrange(0, 130, 210);
	cv::Scalar upperOrange(25, 240, 255);

	std::vector<std::vector<cv::Point>> contours;
	std::vector<cv::Point> tracePoints;

	const int areaThreshold = 20;

	int rows = static_cast<int>(cap.get(cv::CAP_PROP_FRAME_HEIGHT));
	int cols = static_cast<int>(cap.get(cv::CAP_PROP_FRAME_WIDTH));;

	cv::Mat drawingLayer = cv::Mat::zeros(rows, cols, CV_8UC3);
	cv::Mat buttonLayer = cv::Mat::zeros(rows, cols, CV_8UC3);
	cv::Mat canvas = cv::Mat::zeros(rows, cols, CV_8UC3);
	cv::Mat maskKernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(5, 5));

	int y = rows - (rows / 10);
	int x = cols / 2;

	cv::rectangle(buttonLayer, cv::Point(0, y), cv::Point(x, rows), cv::Scalar(0, 255, 0), -1);
	cv::rectangle(buttonLayer, cv::Point(x, y), cv::Point(cols, rows), cv::Scalar(0, 0, 255), -1);

	auto start = std::chrono::steady_clock::now();

	// Stream video
	for (;;) {
		cap.read(frame);
		cv::flip(frame, frame, 1);

		cv::cvtColor(frame, hsv, cv::COLOR_BGR2HSV);
		cv::inRange(hsv, lowerOrange, upperOrange, mask);

		morphologyEx(mask, mask, cv::MORPH_OPEN, maskKernel);
		morphologyEx(mask, mask, cv::MORPH_CLOSE, maskKernel);

		cv::findContours(mask, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);

		if (!contours.empty()) {
			auto largestContour = std::max_element(contours.begin(), contours.end(), [](const std::vector<cv::Point>& a, const std::vector<cv::Point>& b) {return cv::contourArea(a) < cv::contourArea(b); });

			if (cv::contourArea(*largestContour) > areaThreshold) {
				cv::Moments m = cv::moments(*largestContour);
				if (m.m00 != 0) {
					int cx = static_cast<int>(m.m10 / m.m00);
					int cy = static_cast<int>(m.m01 / m.m00);

					if (cy > y) {
						if (cx < x) {
							cv::imwrite("letter.png", canvas);
						}
						
						canvas = cv::Mat::zeros(rows, cols, CV_8UC3);
						drawingLayer = cv::Mat::zeros(rows, cols, CV_8UC3);
						tracePoints.clear();
					}
					else {
						cv::drawContours(frame, std::vector<std::vector<cv::Point>>{*largestContour}, -1, cv::Scalar(0, 255, 0), 2);
						cv::circle(drawingLayer, cv::Point(cx, cy), 7, cv::Scalar(0, 255, 0), -1);
						cv::circle(canvas, cv::Point(cx, cy), 7, cv::Scalar(255, 255, 255), -1);
						// cv::putText(frame, "Orange Dot: (" + std::to_string(cx) + ", " + std::to_string(cy) + ")", cv::Point(cx + 10, cy - 10), cv::FONT_HERSHEY_SIMPLEX, 0.5, cv::Scalar(255, 255, 255), 2);

						tracePoints.push_back(cv::Point(cx, cy));
						start = std::chrono::steady_clock::now();
					}
				}
			}
		}

		if (contours.empty()) {
			if (!tracePoints.empty()) {
				auto now = std::chrono::steady_clock::now();
				auto elapsed = std::chrono::duration_cast<std::chrono::seconds>(now - start).count();
				if (elapsed >= 4) {
					cv::imwrite("letter.png", canvas);
					canvas = cv::Mat::zeros(rows, cols, CV_8UC3);
					drawingLayer = cv::Mat::zeros(rows, cols, CV_8UC3);
					tracePoints.clear();
				}
			}
		}

		cv::addWeighted(frame, 1.0, drawingLayer, 1.0, 0, frame);
		cv::addWeighted(frame, 1.0, buttonLayer, 1.0, 0, frame);

		cv::imshow("Live Camera", frame);
		cv::imshow("Mask", mask);
		cv::imshow("Canvas", canvas);

		if (cv::waitKey(1) == 'q') {
			break;
		}
	}

	cap.release();
	cv::destroyAllWindows();
	return 0;
}

int main() {
	DotTracker dt = DotTracker();
	// dt.run();
	return script();
}
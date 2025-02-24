#include <opencv2/opencv.hpp>
#include <vector>
#include <cstring>
#include <cstdint>
#include <iostream>
#include <android/log.h>

#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, "MyTag", __VA_ARGS__)
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, "MyTag", __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, "MyTag", __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, "MyTag", __VA_ARGS__)

std::mutex frameMutex;

extern "C"
{
    __attribute__((visibility("default")))
    __attribute__((used))
    void detectFingertipOrange(
            uint8_t *yPlane, uint8_t *uPlane, uint8_t *vPlane,
            int width, int height, int rowStride, int pixelStride, int isSamsungTablet,
            uint8_t **outputBuf, int *outputSize, int *cxPtr, int *cyPtr) {
        std::lock_guard<std::mutex> lock(frameMutex);
        //LOGD("Grab Lock");
        //LOGD("Image width: %d, height: %d", width, height);

        // 1. Converting YUV to BGR Format because:
        // "manipulating frames needed to be more difficult" - Android

        // Copy over the Y plane to Empty MAT-compatible format
        cv::Mat yuvImg(height + height / 2, width, CV_8UC1);
        memcpy(yuvImg.data, yPlane, width * height);
        //LOGD("Y Planes Done");

        // Combine U and V planes and integrate into MAT image
        uint8_t *uvPtr = yuvImg.data + width * height;
        for (int i = 0; i < height / 2; i++) {
            for (int j = 0; j < width / 2; j++) {
                int uvIndex = i * (width / 2) + j;
                int maxIndex = (width * height) / 4;

                if (uvIndex >= 0 && uvIndex < maxIndex) {
                    uvPtr[i * width + j * 2] = vPlane[uvIndex];
                    uvPtr[i * width + j * 2 + 1] = uPlane[uvIndex];
                } else {
                    LOGE("Invalid UV index: %d (max: %d)", uvIndex, maxIndex);
                }
            }
        }
        //LOGD("UV Planes Done");
        if (yuvImg.empty()) {
            LOGE("YUV frame is empty!");
        }

        // Complete Conversion, so OpenCV works properly
        cv::Mat frame;
        cv::cvtColor(yuvImg, frame, cv::COLOR_YUV2BGR_NV21);
//        cv::cvtColor(yuvImg, frame, cv::COLOR_YUV2BGR_I420);
        //LOGD("BGR CONVERTED Image");

        if (frame.empty()) {
            LOGE("Frame is empty!");
        }
        // 2. Apply Machine Vision Witchcraft to track the color orange

        // Convert Image to HSV format
        cv::Mat hsv;
        cv::cvtColor(frame, hsv, cv::COLOR_BGR2HSV);
        //LOGD("HSV CONVERTED Image");

        if (hsv.empty()) {
            LOGE("HSV is empty!");
        }

        // Define Orange Color Range to Isolate
        cv::Scalar lowerOrange(0, 130, 210);
        cv::Scalar upperOrange(25, 240, 255);
//
//        // Isolate orange (set to white) from rest of frame (black)
        cv::Mat mask;
        cv::inRange(hsv, lowerOrange, upperOrange, mask);
        if(isSamsungTablet == 0) {
            cv::rotate(mask, mask, cv::ROTATE_90_CLOCKWISE);
        }

        // Remove Noise
        cv::Mat maskKernel = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(5, 5));
        cv::morphologyEx(mask, mask, cv::MORPH_OPEN, maskKernel);
        cv::morphologyEx(mask, mask, cv::MORPH_CLOSE, maskKernel);

        std::vector<std::vector<cv::Point>> contours;
        const int areaThreshold = 20;
        int cx = -100;
        int cy = -100;
        cv::findContours(mask, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
        if (!contours.empty()) {
            auto largestContour = std::max_element(contours.begin(), contours.end(), [](const std::vector<cv::Point>& a, const std::vector<cv::Point>& b) {return cv::contourArea(a) < cv::contourArea(b); });

            if (cv::contourArea(*largestContour) > areaThreshold) {
                cv::Moments m = cv::moments(*largestContour);
                if (m.m00 != 0) {
                    cx = height - static_cast<int>(m.m10 / m.m00);
                    cy = static_cast<int>(m.m01 / m.m00);
                }
            }
        }


        std::vector<uint8_t> encodedData;
        bool success = cv::imencode(".jpg", mask, encodedData);
        //LOGD("Encode Image");
        if (!success) {
            LOGE("Image encoding failed");
            return;
        }
        if (encodedData.empty()) {
            LOGE("Encoded image data is empty");
            return;
        }

//        LOGD("X, Y = (%d, %d)", cx, cy);
        *outputBuf = (uint8_t*)malloc(encodedData.size());
        if (*outputBuf == nullptr) {
            __android_log_print(ANDROID_LOG_ERROR, "MyTag", "Memory allocation failed!");
            *outputSize = 0;
            return;
        }
        //LOGD("Copy Done to Output Buffer");

        // Copy to output buffer
        memcpy(*outputBuf, encodedData.data(), encodedData.size());
        *outputSize = encodedData.size();
        *cxPtr = cx;
        *cyPtr = cy;
        //LOGD("Lock Freed");
    }
    // Function to free the allocated memory in Dart
    __attribute__((visibility("default")))
    __attribute__((used))
    void freeImageMemory(uint8_t *buffer) {
        std::lock_guard<std::mutex> lock(frameMutex);
        //LOGD("Lock Taken");
        if (buffer) {
            //LOGD("Freeing Frame Buffer Memory");
            free(buffer);
        }
        //LOGD("Lock Freed");
    }
}
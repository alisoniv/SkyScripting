cmake_minimum_required(VERSION 3.22.1)

project(finger_tracker-lib)


set(OpenCV_DIR sdk/native/jni)
find_package(OpenCV REQUIRED)
add_library(finger_tracker SHARED ../lib/ffi/finger_tracker.cpp)
target_include_directories(finger_tracker PRIVATE ${OpenCV_INCLUDE_DIRS})
target_link_libraries(finger_tracker ${OpenCV_LIBS} log)
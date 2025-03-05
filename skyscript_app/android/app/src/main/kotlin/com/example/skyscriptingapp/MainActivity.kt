//package com.example.skyscriptingapp
package com.example.skyscriptingapp

import android.graphics.Bitmap
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.opencv.android.OpenCVLoader
import org.opencv.android.Utils
import org.opencv.core.Core
import org.opencv.core.CvType
import org.opencv.core.Mat
import org.opencv.core.Scalar
import org.opencv.core.Size
import org.opencv.core.Point
import org.opencv.core.MatOfPoint
import org.opencv.imgproc.Imgproc


import java.io.ByteArrayOutputStream


class MainActivity : FlutterActivity() {
    private val CHANNEL = "camera_frame_channel"

    //Initialize OpenCV sdk to run on Android Native
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Initialize OpenCV
        if (OpenCVLoader.initDebug()) {
            Log.d("OpenCV", "OpenCV is successfully loaded my message")
        } else {
            Log.e("OpenCV", "OpenCV initialization failed")
        }
    }
    //Handle Flutter MethodChannel communcation
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine){
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "inferLetter"){
                val points = call.arguments as List<List<Double>>
                //CREATE IMAGE FUNCTION
                val byteArray = generateImage(points);
                //INFER LETTER FUNCTION
                result.success(mapOf("top3" to listOf("A", "B", "C"), "byteArray" to byteArray))
            }else {
                result.notImplemented()
            }
        }
    }

    private fun generateImage(points: List<List<Double>>): ByteArray {
        var maxX = Int.MIN_VALUE
        var maxY = Int.MIN_VALUE
        var minX = Int.MAX_VALUE
        var minY = Int.MAX_VALUE
        for (point in points){
            var x = point[0].toInt()
            var y = point[1].toInt()

            maxX = maxOf(maxX, x)
            maxY = maxOf(maxY, y)
            minX = minOf(minX, x)
            minY = minOf(minY, y)
        }
        val width = maxOf(1, maxX - minX)
        val height = maxOf(1, maxY - minY)
        Log.d("MyTag", "Width: $width , Height: $height")
        var xOffset = 0;
        var yOffset = 0;
        xOffset = -1 * minX;
        yOffset = -1 * minY;

        val mat = Mat(height, width, CvType.CV_8UC1, Scalar(0.0))
        val radius = 10.0
        val gaussian_kernel = Size(radius * 3 + 1, radius * 3 + 1)
        for (point in points){
            Imgproc.circle(mat, Point(point[0] + xOffset, point[1] + yOffset), 10, Scalar(255.0), -1)
        }
        Imgproc.GaussianBlur(mat, mat, gaussian_kernel, 0.0)
        var bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        Utils.matToBitmap(mat, bitmap)
//        bitmap = Bitmap.createScaledBitmap(bitmap, 28, 28, true)

        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)

        return outputStream.toByteArray()
    }
// If for some reason you want Kotlin side to process frames
    /*
            else if (call.method == "processFrame") {
                val frameArgs = call.arguments as? Map<String, Any>

                var yPlane: ByteArray? = null
                var uPlane: ByteArray? = null
                var vPlane: ByteArray? = null
                var imageWidth: Int = 0
                var imageHeight: Int = 0
                var rowStride: Int = 0
                var pixelStride: Int = 0

                if (frameArgs != null) {
                    yPlane = frameArgs["yPlane"] as? ByteArray ?: byteArrayOf()
                    uPlane = frameArgs["uPlane"] as? ByteArray ?: byteArrayOf()
                    vPlane = frameArgs["vPlane"] as? ByteArray ?: byteArrayOf()
                    imageWidth = frameArgs["imageWidth"] as? Int ?: 0
                    imageHeight = frameArgs["imageHeight"] as? Int ?: 0
                    rowStride = frameArgs["rowStride"] as? Int ?: 0
                    pixelStride = frameArgs["pixelStride"] as? Int ?: 0
                }else{
                    result.error("NULL_ARGS", "Data from flutter not passed properly", null)
                }

                if (yPlane != null && uPlane != null && vPlane != null) {
                    var hsvMat = convertYUVtoHSV(yPlane, uPlane, vPlane, imageWidth, imageHeight, rowStride, pixelStride)
                    val (frameBytes, cx, cy) = detectFingertip(hsvMat)
                    result.success(mapOf("frameBytes" to frameBytes, "cx" to cx, "cy" to cy))
                }else{
                    result.error("INVALID_ARGUMENT", "Frame data is incorrect", null)
                }
            } */
/*
    private fun convertYUVtoHSV(yPlane: ByteArray, uPlane: ByteArray, vPlane: ByteArray, imageWidth: Int, imageHeight: Int, rowStride: Int, pixelStride: Int): Mat {
        // Copy Y-plane data directly
        val yuvMat = Mat(imageHeight + imageHeight / 2, imageWidth, CvType.CV_8UC1)
        yuvMat.put(0, 0, yPlane ?: byteArrayOf())

        // Step 2: Fill UV plane correctly (Interleaved format)
        val uvMat = ByteArray(uPlane.size * 2) // UV interleaved array
        var index = 0
        for (i in uPlane.indices) {
            uvMat[index++] = uPlane[i] // U value
            uvMat[index++] = vPlane[i] // V value
        }

        // Copy interleaved UV data at the right position
        yuvMat.put(imageHeight, 0, uvMat)

        // Step 3: Convert YUV to HSV using OpenCV
//        val hsvMat = Mat()
        Imgproc.cvtColor(yuvMat, yuvMat, Imgproc.COLOR_YUV2BGR_NV21)
        Imgproc.cvtColor(yuvMat, yuvMat, Imgproc.COLOR_BGR2HSV)
        return yuvMat
    }

    private fun detectFingertip(hsvMat: Mat): Triple<ByteArray, Double, Double> {
        // Witchcraft that does the cool stuff. I can't be bothered understanding it
        val kernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, Size(5.0, 5.0))
        val contours = ArrayList<MatOfPoint>()
        val areaThreshold = 20;

        var cx = -1.0;
        var cy = -1.0;

//        val lowerOrange = Scalar(0.0, 0.0, 0.0)
        //Adjusted Hue because usual range detected blue instead for some reason
        val lowerOrange = Scalar(90.0, 130.0, 210.0);  // Lower V to detect darker shades
        val upperOrange = Scalar(120.0, 240.0, 255.0);  // Increase hue range

//        val lowerOrange = Scalar(0.0, 130.0, 210.0);  // Lower V to detect darker shades
//        val upperOrange = Scalar(25.0, 240.0, 255.0);  // Increase hue range

        var mask = Mat()
        Core.inRange(hsvMat, lowerOrange, upperOrange, mask)
        Core.rotate(mask, mask, Core.ROTATE_90_CLOCKWISE)
        Core.flip(mask, mask, 1)

        Imgproc.morphologyEx(mask, mask, Imgproc.MORPH_OPEN, kernel)
        Imgproc.morphologyEx(mask, mask, Imgproc.MORPH_CLOSE, kernel)
        Imgproc.findContours(mask, contours, Mat(), Imgproc.RETR_EXTERNAL, Imgproc.CHAIN_APPROX_SIMPLE)

//        val width = mask.cols()
//        val height = mask.rows()

        if (!contours.isEmpty()) {
            //Find Largest Contour
            val largestContour = contours.maxByOrNull { Imgproc.contourArea(it) }
            val maxArea = Imgproc.contourArea(largestContour)

//            val (largestContour, maxArea) = contours.fold<Pair<MatOfPoint?, Double>>(null to 0.0) { acc, contour ->
//                val area = Imgproc.contourArea(contour)
//                if (area > acc.second) contour to area else acc
//            }

            //Locate Orange Area Centroid
            if (maxArea > areaThreshold) {
                val m = Imgproc.moments(largestContour)
                if (m.m00 != 0.0) {
//                    cx = (m.m10 / m.m00).toInt()
//                    cy = (m.m01 / m.m00).toInt()
                    cx = (m.m10 / m.m00)
                    cy = (m.m01 / m.m00)
                }
            }
        }

        // Convert Mat back to Bitmap
        val bitmap = Bitmap.createBitmap(mask.cols(), mask.rows(), Bitmap.Config.ARGB_8888)
//        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        Utils.matToBitmap(mask, bitmap)

        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream)

        return Triple(stream.toByteArray(), cx, cy)
    }

 */
}
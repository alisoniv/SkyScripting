//package com.example.skyscriptingapp
package com.example.skyscriptingapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

import android.os.Bundle
import android.util.Log
//import com.example.skyscriptingapp.R

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Base64
import java.nio.ByteBuffer
import java.io.ByteArrayOutputStream

//import androidx.appcompat.app.AppCompatActivity
import io.flutter.plugin.common.MethodChannel

import org.opencv.android.OpenCVLoader
import org.opencv.core.CvType
import org.opencv.core.Mat
import org.opencv.core.Size
import org.opencv.imgproc.Imgproc
import org.opencv.core.Core
import org.opencv.android.Utils

import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES

import androidx.annotation.NonNull



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
            if (call.method == "processFrame") {
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
                    val rgbMat = convertYUVtoRGB(yPlane, uPlane, vPlane, imageWidth, imageHeight, rowStride, pixelStride)
                    val dotCoords = detectFingertip(rgbMat)
                    result.success(dotCoords)
                }else{
                    result.error("INVALID_ARGUMENT", "Frame data is incorrect", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
    fun convertYUVtoRGB(yPlane: ByteArray, uPlane: ByteArray, vPlane: ByteArray, imageWidth: Int, imageHeight: Int, rowStride: Int, pixelStride: Int): Mat {
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

        // Step 3: Convert YUV to RGB using OpenCV
        val rgbMat = Mat()
        Imgproc.cvtColor(yuvMat, rgbMat, Imgproc.COLOR_YUV2BGR_NV21)
//        Imgproc.cvtColor(yuvMat, rgbMat, Imgproc.COLOR_YUV2RGB_I420)
//        Imgproc.cvtColor(yuvMat, rgbMat, Imgproc.COLOR_YUV2RGB_NV21) // NV21 is closest to YUV_420_888
        return rgbMat
    }

    private fun detectFingertip(rgbMat: Mat): ByteArray {

        // Convert to grayscale
//        val grayMat = Mat()
//        Imgproc.cvtColor(mat, grayMat, Imgproc.COLOR_RGB2GRAY)
//        println("GrayMat dimensions: rows = ${grayMat.rows()}, cols = ${grayMat.cols()}, type = ${grayMat.type()}")

        // Convert Mat back to Bitmap
        Core.rotate(rgbMat, rgbMat, Core.ROTATE_90_CLOCKWISE)
        val bitmap = Bitmap.createBitmap(rgbMat.cols(), rgbMat.rows(), Bitmap.Config.ARGB_8888)
        Utils.matToBitmap(rgbMat, bitmap)
//        Utils.matToBitmap(grayMat, bitmap)

        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        val byteArray = stream.toByteArray()

        println("ByteArray length: ${byteArray.size}")
        return byteArray
    }
}
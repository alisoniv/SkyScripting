package com.example.skyscriptingapp

import android.os.Bundle
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import org.openCV.android.OpenCVLoader
import org.openCV.core.CvType
import org.openCV.core.Mat
import org.openCV.core.Size
import org.openCV.imgproc.Imgproc
import org.openCV.core.Core
import java.nio.ByteBuffer

class MainActivity: FlutterActivity(){
    private val CHANNEL = "camera_frame_channel"

    override fun onCreate(savedInstanceState: Bundle?){
        super.onCreate(savedInstanceState)

        // Initialize openCV
        if (!OpenCVLoader.initDebug()) {
            Log.e("OpenCV", "OpenCV initialization failed")
        } else {
            Log.d("OpenCV", "OpenCV initialization succeeded")
        }

        MethodChannel(flutterEnginer?.dartExecutor, CHANNEL).setMethodCallHandler {call, result ->
            if (call.method == "processFrame"){
                val frameData: ByteArray? = call.argument("frameData")

                if (frameData != null){
                    val processedImage = processFrameWithOpenCV(frameData)
                    result.success("Frame Processed")
                }else{
                    result.error("INVALID_ARGUMENT", "Frame data is null", null)
                }
            }else{
                result.notImplemented()
            }
        }
    }
    private fun processFrameWithOpenCV(frameData: ByteArray): Bitmap {
        val byteBuffer = ByteBuffer.wrap(frameData)
        val mat = Mat(frameData.size / 3, 1, CvType.CV_8UC3)
        mat.put(0, 0, byteBuffer)

        // Convert to grayscale
        val grayMat = Mat()
        Imgproc.cvtColor(mat, grayMat, Imgproc.COLOR_RGB2GRAY)

        // Convert Mat back to Bitmap
        val bitmap = Bitmap.createBitmap(mat.cols(), mat.rows(), Bitmap.Config.ARGB_8888)
        Utils.matToBitmap(grayMat, bitmap)

        // Convert Bitmap to ByteArray
        val byteArrayOutputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, byteArrayOutputStream)
        val byteArray = byteArrayOutputStream.toByteArray()

        // Convert ByteArray to Base64
        return Base64.encodeToString(byteArray, Base64.DEFAULT)
    }
}

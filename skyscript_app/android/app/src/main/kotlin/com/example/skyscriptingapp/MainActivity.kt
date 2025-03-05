package com.example.skyscriptingapp

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Bundle
import android.util.Log

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import org.pytorch.IValue
import org.pytorch.Module
import org.pytorch.Tensor
import org.pytorch.torchvision.TensorImageUtils

import java.io.File
import java.io.FileInputStream

import java.nio.FloatBuffer

import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint
import java.nio.ByteBuffer
import java.nio.ByteOrder

import org.opencv.android.OpenCVLoader
import org.opencv.core.CvType
import org.opencv.core.Mat
import org.opencv.core.Size
import org.opencv.imgproc.Imgproc


class MainActivity: FlutterActivity(){
    private val PYTORCH_CHANNEL = "com.pytorch_channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (!OpenCVLoader.initDebug()) {
            Log.e("OpenCV", "OpenCV initialization failed!")
        } else {
            Log.d("OpenCV", "OpenCV initialized successfully!")
        }
    }


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {

        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PYTORCH_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "predict_image_hanna" -> {
                    try {
                        // path variables from flutter
                        val absPath: String? = call.argument("model_path")
                        val boffset: Int? = call.argument("data_offset")
                        val blength: Int? = call.argument("data_length")
                        val byteStream: ByteArray? = call.argument("image_data")
                        
                        //check if they are valid paths
                        if (absPath == null || boffset == null || blength == null || byteStream == null) {
                            result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                            return@setMethodCallHandler
                        }
                        //possibly resize image AFTER greyscale
                        val bitmap = BitmapFactory.decodeByteArray(byteStream, boffset, blength)?: throw Exception("Failed to decode image from byte array")
                        val module = Module.load(absPath)
                        val inputTensor = preprocessImage(bitmap)

                        //debugging
                        printTensor(inputTensor)
                        val resultMapinput = findMaxValue(inputTensor)
                        Log.d("TensorDebug", "Tensor Max: ${resultMapinput}")

                        val shape = inputTensor.shape()
                        val outputTensor: Tensor = module.forward(IValue.from(inputTensor)).toTensor()
                        val scores: FloatArray = outputTensor.dataAsFloatArray
                        println(scores.contentToString())

                        val resultMap = findMaxValue(outputTensor) 
                        

                        result.success(resultMap)

                    } catch (e: Exception) {
                        Log.e("Pytorch: MainActivity", "Error in prediction", e)
                        result.error("MODEL_ERROR", "Failed to process image", e.localizedMessage)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
    fun preprocessImage(bitmap: Bitmap): Tensor {
        // Convert Bitmap to OpenCV Mat
        val mat = Mat()
        val bmp32 = bitmap.copy(Bitmap.Config.ARGB_8888, true)
        org.opencv.android.Utils.bitmapToMat(bmp32, mat)

        // Convert to Grayscale
        Imgproc.cvtColor(mat, mat, Imgproc.COLOR_RGBA2GRAY)
        
        //Core.subtract(Scalar(255.0), mat, mat) 
        mat.convertTo(mat, CvType.CV_32F, -1.0 / 255.0, 1.0)  //invert then Scale 0-255 to 0-1

        // Resize to 28x28
        Imgproc.resize(mat, mat, Size(28.0, 28.0), 0.0, 0.0, Imgproc.INTER_AREA)

        // Extract pixel values into float array
        val floatArray = FloatArray(28 * 28)
        mat.get(0, 0, floatArray)

        // Normalize to [-1, 1] (PyTorch normalization)
        for (i in floatArray.indices) {
            floatArray[i] = (floatArray[i] * 2) - 1  // Scale 0-1 to -1 to 1
        }
        
        Log.d("OpenCV", "Mat size: " + mat.size())
        Log.d("OpenCV", "Mat channels: " + mat.channels())
        Log.d("OpenCV", "Mat type: " + mat.type()) 

        // Convert to PyTorch Tensor
        return Tensor.fromBlob(floatArray, longArrayOf(1, 1, 28, 28))
        
    }

   

    fun findMaxValue(tensor: Tensor): Map<String, Any> {
        val data: FloatArray = tensor.dataAsFloatArray
        var maxValue = Float.NEGATIVE_INFINITY
        var maxIndex = -1

        for (i in data.indices) {
            if (data[i] > maxValue) {
                maxValue = data[i]
                maxIndex = i
            }
        }
        return hashMapOf("index" to maxIndex, "value" to maxValue)
    }
    
    fun printTensor(tensor: Tensor) {
        val data = tensor.dataAsFloatArray
        val shape = tensor.shape()

        Log.d("TensorDebug", "Tensor Shape: ${shape.contentToString()}")
        Log.d("TensorDebug", "Tensor Data: ${data.contentToString()}")
    }

}

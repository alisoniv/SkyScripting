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

import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint
import java.nio.ByteBuffer
import java.nio.ByteOrder


class MainActivity: FlutterActivity(){
    private val PYTORCH_CHANNEL = "com.pytorch_channel"
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

                        val bitmap = BitmapFactory.decodeByteArray(byteStream, boffset, blength)?: throw Exception("Failed to decode image from byte array")
                        val resizedBitmap = Bitmap.createScaledBitmap(bitmap, 28, 28, true)
                        val module = Module.load(absPath)
                        val inputTensor = bitmapToGrayscaleTensor(resizedBitmap)
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
    fun bitmapToGrayscaleTensor(bitmap: Bitmap): Tensor {
        val width = bitmap.width
        val height = bitmap.height

        // Create a 1-channel grayscale Bitmap
        val grayscaleBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ALPHA_8)
        val canvas = Canvas(grayscaleBitmap)
        val paint = Paint()
        val colorMatrix = ColorMatrix()
        colorMatrix.setSaturation(0f)  // Convert to grayscale
        paint.colorFilter = ColorMatrixColorFilter(colorMatrix)
        canvas.drawBitmap(bitmap, 0f, 0f, paint)

        // Convert grayscale bitmap to FloatTensor
        val floatArray = FloatArray(width * height)

        for (y in 0 until height) {
            for (x in 0 until width) {
                val pixel = grayscaleBitmap.getPixel(x, y) and 0xFF  // Extract grayscale value
                val normalizedGray = ((pixel / 255.0f) * 2) - 1  // Normalize to [-1,1] for PyTorch
                floatArray[y * width + x] = normalizedGray
            }
        }

        return Tensor.fromBlob(floatArray, longArrayOf(1, 1, height.toLong(), width.toLong()))
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
}

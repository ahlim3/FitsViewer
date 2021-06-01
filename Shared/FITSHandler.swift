//
//  Extension.swift
//  FitsViewer
//
//  Created by anthony lim on 5/18/21.
//

import Foundation
import Accelerate
import Accelerate.vImage
import FITS
import FITSKit


class FITSHandler: ObservableObject{
    ///initial value for loading, good for 85% of Monochromatic FITS Images tested.
    var MaxPixel_F = Pixel_F(1.00)
    var MinPixel_F = Pixel_F(0.03)
    var xpoints = [Double]()
    var ypoints = [Double]()
    var threeData: ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat)?
    var procssedImage: CGImage!

    
    /// func histogram
    /// function for histogram. Generate histogram in terms of histogramcount
    /// dataMaxPixel : Pixel_F value of the image usually set to the 1.0 in terms of Swift Language
    /// dataMinPixel : Pixel_F value of the image usaully set to 0.0 in terms of Swift Language
    /// buffer : vImage_Buffer of FITS files. The buffer is translated with the FITSKit Extension.
    /// histogramcount : number of bins for histogram generation.
    func histogram(dataMaxPixel: Pixel_F, dataMinPixel: Pixel_F, buffer : vImage_Buffer, histogramcount: Int) -> [vImagePixelCount]
    {
        var buffer = buffer
        var histogramBin = [vImagePixelCount](repeating: 0, count: histogramcount)
        let histogramBinPtr = UnsafeMutablePointer<vImagePixelCount>(mutating: histogramBin)
        histogramBin.withUnsafeMutableBufferPointer()
            { Ptr in
                        let error =
                            vImageHistogramCalculation_PlanarF(
                                            &buffer,
                                            histogramBinPtr,
                                            UInt32(histogramcount),
                                            dataMinPixel,
                                            dataMaxPixel,
                                            vImage_Flags(kvImageNoFlags)
                                            )
                            guard error == kvImageNoError else {
                            fatalError("Error calculating histogram: \(error)")
                                                                }
            }
        return histogramBin
    }
    /// func retruningCGImage
    /// Returning data as CGImage
    /// Data : Array of the pixel in terms of Float
    /// width: Width of image in integer
    /// height: Height of image in integer
    /// rowBytes: width * 4
func returningCGImage(data: [Float], width: Int, height: Int, rowBytes: Int) -> CGImage
    {
        let pixelDataAsData = Data(fromArray: data)
        let cfdata = NSData(data: pixelDataAsData) as CFData
        let provider = CGDataProvider(data: cfdata)!
        let bitmapInfo: CGBitmapInfo = [
                                        .byteOrder32Little,
                                        .floatComponents
                                        ]
              
        let pixelCGImage = CGImage(
                                    width:  width,
                                    height: height,
                                    bitsPerComponent: 32,
                                    bitsPerPixel: 32,
                                    bytesPerRow: rowBytes,
                                    space: CGColorSpaceCreateDeviceGray(),
                                    bitmapInfo: bitmapInfo,
                                    provider: provider,
                                    decode: nil,
                                    shouldInterpolate: false,
                                    intent: .defaultIntent
                                    )!
        return pixelCGImage
    }

    /// Replacing the pixel value that is lower than the adjusted minium and higher than the adjusted maximum to adjusted maximum or adjusted maxium
    /// Returns Pixel data in Float Array.
    /// PixelData : Array of Pixel data obtained from the FITS File
    /// MinimumLimit : User selected minimum pixel value, Corresponds to Min B in controller
    /// MaximumLimit : User selected maximum pixel value, Corresponds to Max B in controller
    func forcingMeanData(PixelData : [Float], MinimumLimit: Float, MaximumLimit:Float) -> [Float]
    {
        var PixelData = PixelData
        for i in 0 ..< PixelData.count
            {
            if PixelData[i] < MinimumLimit
                {
                PixelData[i] = MinimumLimit
                }
            }
        for i in 0 ..< PixelData.count
        {
            if PixelData[i] > Float(MaximumLimit)
            {
                PixelData[i] = MaximumLimit
            }
        }
        return PixelData
    }
    /// func returnInfo
    /// Returning three sets of data. (Histogram, CGImage of raw Image, CGImage of adjusted Image)
    /// example use : var Info = retrunInfo(ThreeData)
    ///     Access to Histogram, info.0
    ///     Access to rawImage, info.1
    ///     Access to adjusted image, info.2
    func returnInfo(ThreeData : ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat)) -> ([vImagePixelCount], CGImage, CGImage)
    {
        let threedata = ThreeData
        //target data
        let data = threedata.0
        //Buffer from FITS File
        let buffer = threedata.1
        //Grayscale format from FITS file
        let format = threedata.2
        // Initializing width, height, rowByetes of Image.
        let width :Int = Int(buffer.width)
        let height: Int = Int(buffer.height)
        let rowBytes :Int = width*4
        // setting number of histogram Bins
        let histogramcount = 1024
        // returning histogram based on the original image
        let histogramBin = histogram(
                                         dataMaxPixel: Pixel_F(data.max()!),
                                         dataMinPixel: Pixel_F(data.min()!),
                                         buffer: buffer,
                                         histogramcount: histogramcount
                                    )
        //initializing empty set for Histogram that can be used with CorePlot
        var xpointsinside = [Double]()
        var ypointsinside = [Double]()
        //Adding each value of histogram to empty set
        for i in 0 ..< histogramcount{
            xpointsinside.append(Double(i) / Double(histogramcount))
            ypointsinside.append(log(Double(histogramBin[i])))
        }
        //Storing variables to global array xpoint and ypoint that CorePlot can access the variables
        xpoints = xpointsinside
        ypoints = ypointsinside
        // Initializing the minimum brightness and maximum brightness from the controlled values. Min B and Max B.
        let lowerPixelLimit = MinPixel_F
        let upperPixelLimit = MaxPixel_F
        // Initializing the
        var OriginalPixelData = (buffer.data.toArray(to: Float.self, capacity: Int(buffer.width*buffer.height)))
        OriginalPixelData = forcingMeanData(PixelData: OriginalPixelData, MinimumLimit: lowerPixelLimit, MaximumLimit: upperPixelLimit)
        let forcedOriginalData = returningCGImage(data: OriginalPixelData, width: width, height: height, rowBytes: rowBytes)
        var forcedbuffer = try! vImage_Buffer(cgImage: forcedOriginalData, format: format)
        var buffer3 = buffer
        var kernelwidth = 9
        var kernelheight = 9
        var A : Float = 1.0
        var simgaX: Float = 0.75
        var sigmaY: Float = 0.75
        
        var kernelArray = kArray(width: kernelwidth, height: kernelheight, sigmaX: simgaX, sigmaY: sigmaY, A: A)
        vImageConvolve_PlanarF(&forcedbuffer, &buffer3, nil, 0, 0, &kernelArray, UInt32(kernelwidth), UInt32(kernelheight), 0, vImage_Flags(kvImageEdgeExtend))

        let BlurredPixelData = (buffer3.data.toArray(to: Float.self, capacity: Int(buffer3.width*buffer3.height)))
        OriginalPixelData = (buffer.data.toArray(to: Float.self, capacity: Int(buffer.width*buffer.height)))
        //Bendvalue of DDP
        
        let bendvalue = bendValue(AdjustedData: BlurredPixelData, lowerPixelLimit: lowerPixelLimit) //return bendvalue as .0, and averagepixeldata as .1

        let ddpPixelData = ddpProcessed(OriginalPixelData: OriginalPixelData, BlurredPixeldata: BlurredPixelData, Bendvalue: bendvalue.0, AveragePixel: bendvalue.1, MinPixel: lowerPixelLimit)
        let DDPScaled = ddpScaled(ddpPixelData: ddpPixelData, MinPixel: lowerPixelLimit)
        let DDPwithScale = returningCGImage(data: DDPScaled, width: width, height: height, rowBytes: rowBytes)
        procssedImage = DDPwithScale
        let originalImage = (try? buffer.createCGImage(format: format))!
        print("called")
        return(histogramBin, originalImage,  DDPwithScale)
        }

}


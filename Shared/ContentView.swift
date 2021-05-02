//
//  ContentView.swift
//  Shared
//
//  Created by anthony lim on 4/20/21.
//

import SwiftUI
import FITS
import FITSKit
import Accelerate
import Accelerate.vImage
import Combine
import CoreGraphics

struct ContentView: View {

    

    var path = "file:///Users/anthonylim/Downloads/2020-12-03_19;56;17.fits"
    let path1 = "file:///Users/anthonylim/Downloads/2020-12-03_19;56;17.fits"
    let path2 = "file:///Users/anthonylim/Downloads/n5194.fits"
    let path3 = "file:///Users/anthonylim/Downloads/HIP115691-ID14333-OC148763-GR7975-LUM.fit"
    let path4 = "file:///Users/anthonylim/Downloads/JtIMAGE_009.fits"
    let path5 = "file:///Users/anthonylim/Downloads/2020-12-03_19_16_43.fits"
    let path6 = "file:///Users/anthonylim/Downloads/moon_BIN_1x1_0.0010s_002.fits"
    let path7 = "file:///Users/anthonylim/Downloads/NGC4438-104275-LUM.fit"
    let path8 = "file:///Users/anthonylim/Downloads/M66-ID10979-OC144423-GR4135-LUM2.fit"
    let path9 = "file:///Users/anthonylim/Downloads/NGC6960-ID14567-OC148925-GR8123-LUM.fit"
    let path10 = "file:///Users/anthonylim/Downloads/globular.fits"
    let histogramcount = 1024
    @State var called = 0
    
    func read() -> ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat){
        var threeData: ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat)?
        var path = URL(string: path2)!
        var read_data = try! FitsFile.read(contentsOf: path)
        let prime = read_data?.prime
        print(prime)
        prime?.v_complete(onError: {_ in
            print("CGImage creation error")
        }) { result in
            threeData = result
        }
        return threeData!
    }
    func read2() -> PrimaryHDU{
        var path = URL(string: path5)!
        var read_data = try! FitsFile.read(contentsOf: path)
        let prime = read_data!.prime
        return prime
    }
    func display() -> (CGImage, [vImagePixelCount], CGImage){
        let threedata = read()
        var data = threedata.0
        //target data
        var redta = threedata.0
        //Buffer from FITS File
        var buffer = threedata.1
        //Grayscale format from FITS file
        let format = threedata.2
        let prime = read2()
        //destination buffer
        var buffer2 = buffer
        var buffer4 = buffer
        var dataMin = data.min()// data type FITSByte_F
        //var dataAvg = data.mean
        
        var dataMaxPixel = Pixel_F(data.max()!)
        var dataMinPixel = Pixel_F(data.min()!)
        var meanPixel = Pixel_F(data.mean)
        var stdevPixel = Pixel_F(data.stdev!)
        print("Pixel mean : ", meanPixel, "Pixel Stdev : ", stdevPixel)
        var histogramBin = [vImagePixelCount](repeating: 0, count: histogramcount)
        let histogramBinPtr = UnsafeMutablePointer<vImagePixelCount>(mutating: histogramBin)
        histogramBin.withUnsafeMutableBufferPointer() { Ptr in
                            let error =
                                vImageHistogramCalculation_PlanarF(&buffer, histogramBinPtr, UInt32(histogramcount), dataMinPixel, dataMaxPixel, vImage_Flags(kvImageNoFlags))
                                guard error == kvImageNoError else {
                                fatalError("Error calculating histogram: \(error)")
                            }
                        }
        print(histogramBin)
        var histogram_optimized = histogramBin
        var histogramMean = histogramBin.mean
        var histogramStdev = histogramBin.stdev
        var histogramStdevp = histogramBin.stdevp
        var histogramAllcount = histogramBin.reduce(0,+)
        print("Mean : ", histogramMean, " Stdev : ", histogramStdev, " Stdevp : ", histogramStdevp, " Total : ", histogramAllcount)
        var histogramMedian = Double( histogramAllcount / 2)
        var meaningfulPixelvalue = 0
        var meaningfulPixelvalue2 = 0
        histogramBin[0] = 0
        for i in 0 ..< histogramcount{
            if histogramBin[i] < 5 {
                histogram_optimized[i] = 0
            }
            else{
                histogram_optimized[i] = histogram_optimized[i]
                meaningfulPixelvalue = i
            }
            
        }
        for i in 10 ..< histogramcount{
            if histogram_optimized[i] == 0{
                meaningfulPixelvalue2 = i
            }
            else{
                break
            }
        }
        print(histogram_optimized, meaningfulPixelvalue, meaningfulPixelvalue2)
        var upperPixelLimit = Pixel_F(Double(meaningfulPixelvalue) / Double(histogramcount))
        var lowerPixelLimt = Pixel_F(Double(meaningfulPixelvalue2) / Double(histogramcount))
        print("Lower Pixel Limit : ", lowerPixelLimt , " Upper Pixel Limit : ", upperPixelLimit)
        var optimized_histogram = histogramBin
        let optimized_histogramBinPtr = UnsafeMutablePointer<vImagePixelCount>(mutating: optimized_histogram)
        histogramBin.withUnsafeMutableBufferPointer() { Ptr in
                            let error =
                                vImageHistogramCalculation_PlanarF(&buffer, optimized_histogramBinPtr, UInt32(histogramcount), lowerPixelLimt, upperPixelLimit, vImage_Flags(kvImageNoFlags))
                                guard error == kvImageNoError else {
                                fatalError("Error calculating histogram: \(error)")
                            }
                        }
        print(optimized_histogram)
        var histogramBin2 = [vImagePixelCount](repeating: 0, count: histogramcount)
        let histogramBinPtr2 = UnsafeMutablePointer<vImagePixelCount>(mutating: histogramBin2)
        histogramBin2.withUnsafeMutableBufferPointer() { Ptr in
                            let error =
                                vImageHistogramCalculation_PlanarF(&buffer4, histogramBinPtr2, UInt32(histogramcount), 0.0, 1.0, vImage_Flags(kvImageNoFlags))
                                guard error == kvImageNoError else {
                                fatalError("Error calculating histogram: \(error)")
                            }
                        }
        print(histogramBin2)
        //vImageEndsInContrastStretch_PlanarF(&buffer, &buffer2, nil, 0, 50, histogramcount, 0.0, 0.1, vImage_Flags(kvImageNoFlags))
        vImageHistogramSpecification_PlanarF(&buffer, &buffer2, nil, optimized_histogram, UInt32(histogramcount), 0.0, 1.0, vImage_Flags(kvImageNoFlags))
        //var buffer3 = buffer2
        //vImageEqualization_PlanarF(&buffer2, &buffer3, nil, histogramcount, lowerPixelLimt, upperPixelLimit, vImage_Flags(kvImageNoFlags))
        //vImageContrastStretch_PlanarF(&buffer2, &buffer3, nil, histogramcount, lowerPixelLimt, upperPixelLimit, vImage_Flags(kvImageNoFlags))
        let gamma: Float = 1.0
        let exponential:[Float] = [1, 0, 0]
    
        var buffer3 = buffer
        vImagePiecewiseGamma_PlanarF(&buffer2, &buffer3, exponential, gamma, [1,0], 0, vImage_Flags(kvImageNoFlags))
        var gammahistogram = [vImagePixelCount](repeating: 0, count: histogramcount)
        let gammahistogramPtr = UnsafeMutablePointer<vImagePixelCount>(mutating: gammahistogram)
        gammahistogram.withUnsafeMutableBufferPointer() { Ptr in
                            let error =
                                vImageHistogramCalculation_PlanarF(&buffer3, gammahistogramPtr, UInt32(histogramcount), 0.0, 1.0, vImage_Flags(kvImageNoFlags))
                                guard error == kvImageNoError else {
                                fatalError("Error calculating histogram: \(error)")
                            }
                        }
        print(gammahistogram)
        vImageHistogramSpecification_PlanarF(&buffer, &buffer2, nil, gammahistogram, UInt32(histogramcount), 0.0, 1.0, vImage_Flags(kvImageNoFlags))
        
        /*for i in 0 ..< kernel2D.count{
            kernel2D[i] = kernel2D[i] / kernel
        }*/
        let kernelwidth = 7
        let kernelheight = 7
        var A : Float = 1.0
        var simgaX: Float = 0.75
        var sigmaY: Float = 0.75
        
        var kernelArray = kArray(width: kernelwidth, height: kernelheight, sigmaX: simgaX, sigmaY: sigmaY, A: A)
        
        print(kernelArray, " " , kernelArray.max())

        vImageConvolve_PlanarF(&buffer, &buffer3, nil, 0, 0, &kernelArray, UInt32(kernelwidth), UInt32(kernelheight), 0, vImage_Flags(kvImageEdgeExtend))
        var histogramBin3 = [vImagePixelCount](repeating: 0, count: histogramcount)
        let histogramBinPtr3 = UnsafeMutablePointer<vImagePixelCount>(mutating: histogramBin3)
        histogramBin3.withUnsafeMutableBufferPointer() { Ptr in
                            let error =
                                vImageHistogramCalculation_PlanarF(&buffer, histogramBinPtr3, UInt32(histogramcount), 0.0, 1.0, vImage_Flags(kvImageNoFlags))
                                guard error == kvImageNoError else {
                                fatalError("Error calculating histogram: \(error)")
                            }
                        }
        print(histogramBin3)
        vImageHistogramSpecification_PlanarF(&buffer, &buffer2, nil, histogramBin3, UInt32(histogramcount), 0.0, 1.0, vImage_Flags(kvImageNoFlags))
    
        var BlurredPixelData = (buffer3.data.toArray(to: Float.self, capacity: Int(buffer3.width*buffer3.height)))
        var OriginalPixelData = (buffer.data.toArray(to: Float.self, capacity: Int(buffer.width*buffer.height)))
        var bendvalue = bendValue(AdjustedData: BlurredPixelData) //return bendvalue as .0, and averagepixeldata as .1
        var ddpPixelData = ddpProcessed(OriginalPixelData: OriginalPixelData, BlurredPixeldata: BlurredPixelData, Bendvalue: bendvalue.0, AveragePixel: bendvalue.1)
        let ddpScaled = ddpScaled(ddpPixelData: ddpPixelData)

        let pixelDataAsData = Data(fromArray: ddpScaled)
        let cfdata = NSData(data: pixelDataAsData) as CFData
        
        let provider = CGDataProvider(data: cfdata)!
        
        let width :Int = Int(buffer3.width)
        let height: Int = Int(buffer3.height)
        let rowBytes :Int = width*4
        
        let bitmapInfo: CGBitmapInfo = [
            .byteOrder32Little,
            .floatComponents]
              
        let pixelCGImage = CGImage(width:  width, height: height, bitsPerComponent: 32, bitsPerPixel: 32, bytesPerRow: rowBytes, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        
        let originalImage = (try? buffer.createCGImage(format: format))!
    
        
        print("called")
        
        return( pixelCGImage!, histogramBin2, originalImage)
    }
    
    
    
    
    func invert(image : CGImage) {
        Image(decorative: image, scale: 1.0)
    }
    func imageView(image: CGImage) -> Image
    {
        Image(decorative: image, scale: 1.0)
    }

    var body: some View {
        let modified = display()
            VStack {
                ScrollView([.horizontal, .vertical]){

                    HSplitView{
                        Image(decorative: modified.0, scale: 1.0)
                    }
                    HSplitView{
                        Image(decorative: modified.2, scale: 1.0)
                    }
                }
                HStack{
                    Spacer()
                    
                    Button("Inverted Optimized", action: {invert(image: modified.0)})
                    Button("Optimized", action: {imageView(image: modified.0)})
                    Button("Original", action: {imageView(image: modified.2)})
                    

                    
                }
            }

        }
    }

    




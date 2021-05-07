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
import UniformTypeIdentifiers

struct ContentView: View {

    let histogramcount = 1024
    
    @State var called = 0
    @State var isImporting: Bool = false
    @State var rawImage: Image?
    @State var processedImage: Image?
    @State var threedata: ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat)?
    
    func display() -> (CGImage, [vImagePixelCount]){
        //let threedata = read()
        var data = threedata!.0
        //target data
        var redta = threedata!.0
        //Buffer from FITS File
        var buffer = threedata!.1
        //Grayscale format from FITS file
        let format = threedata!.2
   //     let prime = read2()
        //destination buffer
        var buffer2 = buffer
        var buffer4 = buffer
        var buffer5 = buffer

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

        var histogram_optimized = histogramBin
        var histogramMean = histogramBin.mean
        var histogramStdev = histogramBin.stdev
        var histogramStdevp = histogramBin.stdevp
        var histogramAllcount = histogramBin.reduce(0,+)
        //print("Mean : ", histogramMean, " Stdev : ", histogramStdev, " Stdevp : ", histogramStdevp, " Total : ", histogramAllcount)
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
     //   print(histogram_optimized, meaningfulPixelvalue, meaningfulPixelvalue2)
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
        //print(optimized_histogram)
        var histogramBin2 = [vImagePixelCount](repeating: 0, count: histogramcount)
        let histogramBinPtr2 = UnsafeMutablePointer<vImagePixelCount>(mutating: histogramBin2)
        histogramBin2.withUnsafeMutableBufferPointer() { Ptr in
                            let error =
                                vImageHistogramCalculation_PlanarF(&buffer4, histogramBinPtr2, UInt32(histogramcount), 0.0, 1.0, vImage_Flags(kvImageNoFlags))
                                guard error == kvImageNoError else {
                                fatalError("Error calculating histogram: \(error)")
                            }
                        }
       // print(histogramBin2)
        //vImageEndsInContrastStretch_PlanarF(&buffer, &buffer2, nil, 0, 50, histogramcount, 0.0, 0.1, vImage_Flags(kvImageNoFlags))
        vImageHistogramSpecification_PlanarF(&buffer, &buffer2, nil, optimized_histogram, UInt32(histogramcount), 0.0, 1.0, vImage_Flags(kvImageNoFlags))
        //var buffer3 = buffer2
        //vImageEqualization_PlanarF(&buffer2, &buffer3, nil, histogramcount, lowerPixelLimt, upperPixelLimit, vImage_Flags(kvImageNoFlags))
        //vImageContrastStretch_PlanarF(&buffer2, &buffer3, nil, histogramcount, lowerPixelLimt, upperPixelLimit, vImage_Flags(kvImageNoFlags))
        let gamma: Float = 0.8
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
        //print(gammahistogram)
        vImageHistogramSpecification_PlanarF(&buffer, &buffer2, nil, gammahistogram, UInt32(histogramcount), 0.0, 1.0, vImage_Flags(kvImageNoFlags))
        
        /*for i in 0 ..< kernel2D.count{
            kernel2D[i] = kernel2D[i] / kernel
        }*/
        let kernelwidth = 3
        let kernelheight = 3
        var kernelArray = [Float]()
        var A : Float = 1.0
        var simgaX: Float = 0.80
        var sigmaY: Float = 0.80
        //var Volume = 2.0 * Float.pi * A * simgaX * sigmaY
        for i in 0 ..< kernelwidth{
            let xposition = Float(i - kernelwidth / 2)
            for j in 0 ..< kernelheight{
            let yposition = Float(j - kernelheight / 2)
                var xponent = -xposition * xposition / (Float(2.0) * simgaX * simgaX)
                var yponent = -yposition * yposition / (Float(2.0) * sigmaY * sigmaY)
                let answer = A * exp (xponent + yponent)
                kernelArray.append(answer)
            }
        }
        var sum = kernelArray.reduce(0, +)
        for i in 0 ..< kernelArray.count{
            kernelArray[i] = kernelArray[i] / sum
        }
        print(kernelArray, " " , kernelArray.max())
       // print(buffer2)
       // print(buffer3)
        vImageConvolve_PlanarF(&buffer2, &buffer3, nil, 0, 0, &kernelArray, UInt32(kernelwidth), UInt32(kernelheight), 0, vImage_Flags(kvImageEdgeExtend))
        var histogramBin3 = [vImagePixelCount](repeating: 0, count: histogramcount)
        let histogramBinPtr3 = UnsafeMutablePointer<vImagePixelCount>(mutating: histogramBin3)
        histogramBin3.withUnsafeMutableBufferPointer() { Ptr in
                            let error =
                                vImageHistogramCalculation_PlanarF(&buffer, histogramBinPtr3, UInt32(histogramcount), 0.0, 1.0, vImage_Flags(kvImageNoFlags))
                                guard error == kvImageNoError else {
                                fatalError("Error calculating histogram: \(error)")
                            }
                        }
        //print(histogramBin3)
        vImageHistogramSpecification_PlanarF(&buffer, &buffer2, nil, histogramBin3, UInt32(histogramcount), 0.0, 1.0, vImage_Flags(kvImageNoFlags))
        
        var imagePixelData = (buffer2.data.toArray(to: Float.self, capacity: Int(buffer2.width*buffer2.height)))
        
        var blurPixelData = (buffer3.data.toArray(to: Float.self, capacity: Int(buffer3.width*buffer3.height)))
        
        
        var myMin:Float = 0.0
        var blackLevel:Float = 0.0
        var minimumLevel:Float = imagePixelData.min()!
        
        if minimumLevel < 0.0 {minimumLevel = 0.0}
        
        if(minimumLevel > myMin.ulp  ){
        
            blackLevel = minimumLevel * 0.75
        }
        else{
            
            blackLevel = 0.0
        }
        
        for i in 0..<imagePixelData.count{
            
            imagePixelData[i] -= blackLevel
            
        }
        
        myMin = 0.0
        blackLevel = 0.0
        
        
        minimumLevel = blurPixelData.min()!
        
        if(minimumLevel > myMin.ulp  ){
        
            blackLevel = minimumLevel * 0.75
        }
        else{
            
            blackLevel = 0.0
        }
        
        
        for i in 0..<blurPixelData.count{
            
            blurPixelData[i] -= blackLevel
            
        }
        
        var average = blurPixelData.mean
        var bendValue :Float  = 0.0
        
        print("average blur = ", average)
        
       // if ((2*average) > 0.5 )
        if ((2*average) > 0.5 )
        {
            bendValue = (1.0 - average) / 2.0 + average
        }
        else
        {
            bendValue = 1.5 * average

        }
        
        print("bendValue =", bendValue)
        print("average = ", average)
        
       // let newBackgroundLevel :Float = 10.0/65535.0
        
        var newBackgroundLevel :Float = 0.0
        
        for i in 0..<imagePixelData.count{
            
            imagePixelData[i] = average * ((imagePixelData[i])/(blurPixelData[i] + bendValue)) + newBackgroundLevel
        }
        
        print(imagePixelData[76])
        
        average = imagePixelData.mean
        print("average = ", average)
        var maximum = imagePixelData.max()!
        var multiplier :Float = 1.0
        
        if (average < 0.5){
            multiplier = abs(0.5/average)
        }
        else{
        
            multiplier = abs(0.5*maximum/average)
            
        }
        
        
        print("muliplier = ", multiplier)
        
        for i in 0..<imagePixelData.count{
            
            imagePixelData[i] = multiplier * imagePixelData[i]
        }
        
        average = imagePixelData.mean
        
        newBackgroundLevel = average / 1.25
        
        for i in 0..<imagePixelData.count{
            
            imagePixelData[i] -= newBackgroundLevel
        }
        
        
        print("average =", average)
        
        
        let pixelDataAsData = Data(fromArray: imagePixelData)
        
        let cfdata = NSData(data: pixelDataAsData) as CFData
        
        let provider = CGDataProvider(data: cfdata)!
        
        let width :Int = Int(buffer2.width)
        let height: Int = Int(buffer2.height)
        let rowBytes :Int = width*4
        
        let bitmapInfo: CGBitmapInfo = [
            .byteOrder32Little,
            .floatComponents]
              
        let pixelCGImage = CGImage(width:  width, height: height, bitsPerComponent: 32, bitsPerPixel: 32, bytesPerRow: rowBytes, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        


 //let result2 = (try? buffer2.createCGImage(format: format))!
        
        
        print("called")
        
        print(width)
        processedImage = Image(pixelCGImage!, scale: CGFloat(Float(width) / 900.0), label: Text("Image"))
        
        let result2 = (try? buffer.createCGImage(format: format))!
               
        rawImage = Image(result2, scale: CGFloat(Float(width) / 900.0), label: Text("Image"))

        //return (result2, histogramBin2)
        
        return( pixelCGImage!, histogramBin2)
    }
    
    
    func histogram () -> [vImagePixelCount]{
        var originalhistogram = display().1
        return originalhistogram
    }

    var body: some View {
        TabView{
            HStack {
                ScrollView([.horizontal, .vertical]){
                    processedImage
                }
            }
                //.padding()
                HStack{
                ScrollView([.horizontal, .vertical]){
                    /*HSplitView{
                        Image(decorative: display().0, scale: 1.0)
                        //.resizable()
                        //.scaledToFit()
                        .padding()
                    }*/
                    rawImage
                }
                }
            }
                //.padding()
                VStack{
                    //Spacer()
                    Divider()
                    
                    Button("Load", action: {
                        isImporting = false
                        
                        //fix broken picker sheet
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isImporting = true
                        }
                    })
                        .padding()

                }
           // .padding()
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.fitDocument],
                allowsMultipleSelection: false
            ) { result in
                do {
                    guard let selectedFile: URL = try result.get().first else { return }
                    
                    print("Selected file is", selectedFile)
                    
                    //trying to get access to url contents
                    if (CFURLStartAccessingSecurityScopedResource(selectedFile as CFURL)) {
                        
                        //guard let message = String(data: try Data(contentsOf: selectedFile), encoding: .utf8) else { return }
                        
                        
                        
                        
                        guard let read_data = try! FitsFile.read(contentsOf: selectedFile) else { return }
                        let prime = read_data.prime
                        
                        prime.v_complete(onError: {_ in
                            print("CGImage creation error")
                        }) { result in
                            
                            threedata = result
                            let _ = self.display()
                           
                        }
                        
                            
                        //done accessing the url
                        CFURLStopAccessingSecurityScopedResource(selectedFile as CFURL)
                        
                        
                    }
                    else {
                        print("Permission error!")
                    }
                } catch {
                    // Handle failure.
                    print(error.localizedDescription)
                }
            }

        }
    }

    


extension UnsafeMutableRawPointer {
    func toArray<T>(to type: T.Type, capacity count: Int) -> [T]{
        let pointer = bindMemory(to: type, capacity: count)
        return Array(UnsafeBufferPointer(start: pointer, count: count))
    }
}


extension Data {

    init<T>(fromArray values: [T]) {
        self = values.withUnsafeBytes { Data($0) }
    }

    func toArray<T>(type: T.Type) -> [T] where T: ExpressibleByIntegerLiteral {
        var array = Array<T>(repeating: 0, count: self.count/MemoryLayout<T>.stride)
        _ = array.withUnsafeMutableBytes { copyBytes(to: $0) }
        return array
    }
}




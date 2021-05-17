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
    
    @State var called = 0
    @State var isImporting: Bool = false
    @State var isExporting: Bool = false
    @State var rawImage: Image?
    @State var processedImage: Image?
    @State var convolvedIamge: Image?
    @State var Val: Bool = false
    @State var displayImage: Image?
    @State var ImageString = "Process Image"
    @State var threeData: ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat)?
    func display(Data: ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat)) {
        let ImageInfo = returnInfo(ThreeData: threeData!)
        rawImage = Image(ImageInfo.1, scale: 2.0, label: Text("Raw"))
        processedImage = Image(ImageInfo.2, scale: 2.0, label: Text("Processed Image"))
        convolvedIamge = Image(ImageInfo.3, scale: 2.0, label: Text("Convolved Image"))
        
    }
    func kArray(width: Int, height: Int, sigmaX: Float, sigmaY: Float, A: Float) -> [Float]
    {
    let kernelwidth = width
    let kernelheight = height
    var kernelArray = [Float]()
    //var Volume = 2.0 * Float.pi * A * simgaX * sigmaY
    for i in 0 ..< kernelwidth{
        let xposition = Float(i - kernelwidth / 2)
        for j in 0 ..< kernelheight{
        let yposition = Float(j - kernelheight / 2)
            var xponent = -xposition * xposition / (Float(2.0) * sigmaX * sigmaX)
            var yponent = -yposition * yposition / (Float(2.0) * sigmaY * sigmaY)
            let answer = A * exp (xponent + yponent)
            kernelArray.append(answer)
        }
    }
    var sum = kernelArray.reduce(0, +)
    for i in 0 ..< kernelArray.count{
        kernelArray[i] = kernelArray[i] / sum
    }
        print(kernelArray)
    return kernelArray
    }

func bendValue(AdjustedData: [Float], lowerPixelLimit: Pixel_F) -> (Float, Float){
    let myMin:Float = 0.0
    var blackLevel:Float = 0.0
    var AdjustedData = AdjustedData
    
    if(AdjustedData.min()! > myMin.ulp  ){
    
        blackLevel = AdjustedData.min()! * 0.75
    }
    else{
        
        blackLevel = 0.1
    }
    
    for i in 0 ..< AdjustedData.count{
        
        AdjustedData[i] = blackLevel
        
    }
    let averagePixelData = AdjustedData.mean
    var bendValue = Float(0.0)
           if averagePixelData * 2.0 > 1.0 {
               bendValue = (1.0 - averagePixelData)/2 + averagePixelData
           }
           else
           {
            bendValue = 1.5 * averagePixelData
           }
    return (bendValue, averagePixelData)
}

func ddpProcessed(OriginalPixelData: [Float], BlurredPixeldata: [Float], Bendvalue : Float, AveragePixel: Float, cutOff: Int, MinPixel : Pixel_F) -> [Float]{
    var ddpPixeldata = [Float]()
        for i in 0 ..< OriginalPixelData.count{
        let answer = AveragePixel * ((OriginalPixelData[i]/(BlurredPixeldata[i] + Bendvalue)))
            ddpPixeldata.append(answer)
        }
    return ddpPixeldata
}
func ddpScaled(ddpPixelData: [Float], MinPixel : Pixel_F) -> [Float]{
    var ddpScaled = [Float]()
    var ddpMax = Float(ddpPixelData.max()!)
    var ddpMin = Float(ddpPixelData.min()!)
    var adjustable = ddpMax - ddpMin
    for i in 0 ..< ddpPixelData.count{
        let answer = (ddpPixelData[i] - ddpMin) / adjustable
        ddpScaled.append(answer)
    }
    return ddpScaled
}
func histogram(dataMaxPixel: Pixel_F, dataMinPixel: Pixel_F, buffer : vImage_Buffer, histogramcount: Int) -> [vImagePixelCount]{
    var buffer = buffer
    var histogramBin = [vImagePixelCount](repeating: 0, count: histogramcount)
    let histogramBinPtr = UnsafeMutablePointer<vImagePixelCount>(mutating: histogramBin)
    histogramBin.withUnsafeMutableBufferPointer() { Ptr in
                        let error =
                            vImageHistogramCalculation_PlanarF(&buffer, histogramBinPtr, UInt32(histogramcount), dataMinPixel, dataMaxPixel, vImage_Flags(kvImageNoFlags))
                            guard error == kvImageNoError else {
                            fatalError("Error calculating histogram: \(error)")
                        }
                    }
    return histogramBin
}

func returningCGImage(data: [Float], width: Int, height: Int, rowBytes: Int) -> CGImage{
    let pixelDataAsData = Data(fromArray: data)
    let cfdata = NSData(data: pixelDataAsData) as CFData
    
    let provider = CGDataProvider(data: cfdata)!
    
    let bitmapInfo: CGBitmapInfo = [
        .byteOrder32Little,
        .floatComponents]
          
    let pixelCGImage = CGImage(width:  width, height: height, bitsPerComponent: 32, bitsPerPixel: 32, bytesPerRow: rowBytes, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    return pixelCGImage
}

func OptValue(histogram_in : [vImagePixelCount], histogramcount : Int) -> (Pixel_F, Pixel_F, Int){
    var MaxPixel = 0
    var MinPixel = 0
    let PixelLimitingCount = Int(Double(histogram_in.reduce(0,+)) * 0.001)
    var minimumCutoff = 1
    for i in 0 ..< histogramcount {
        if histogram_in[i] > PixelLimitingCount{
            MinPixel = i
            break
        }
    }
    if MinPixel > 20 {
        MinPixel = MinPixel - 10
    }
    if MinPixel < 5 {
        MinPixel = 1
        minimumCutoff = 0
    }
    
    for i in 0 ..< histogramcount{
        if histogram_in[i] > 10{
            MaxPixel = i
        }
        
    }
    let difference = MaxPixel - MinPixel
    if difference < 30 {
        MaxPixel = MinPixel + Int(Double(histogramcount) * 0.1)
    }
    let MaxPixel_F = Pixel_F(Float(MaxPixel) / Float(histogramcount))
    let MinPixel_F = Pixel_F(Float(MinPixel) / Float(histogramcount))
    return (MaxPixel_F, MinPixel_F, minimumCutoff)
}
func forcingMeanData(PixelData : [Float], MinimumLimit: Float) -> [Float]{
    var PixelData = PixelData
    for i in 0 ..< PixelData.count{
        if PixelData[i] < MinimumLimit{
            PixelData[i] = MinimumLimit
        }
    }
    return PixelData
}

    func displaySwitch(switchVal: Bool) -> Bool {
        var Val = switchVal
        if Val == false
        {
            ImageString = "Process Image"
            displayImage = processedImage
            Val = true
        }
        if Val == true
        {
            ImageString = "Back to Raw Image"
            displayImage = rawImage
            Val = false
        }
        return Val
    }

func returnInfo(ThreeData : ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat)) -> ([vImagePixelCount], CGImage, CGImage, CGImage){
    let threedata = ThreeData
    //target data
    let data = threedata.0
    //Buffer from FITS File
    let buffer = threedata.1
    //Grayscale format from FITS file
    let format = threedata.2
    //destination buffer
    let width :Int = Int(buffer.width)
    let height: Int = Int(buffer.height)
    let rowBytes :Int = width*4
    let histogramcount = 1024
    let histogramBin = histogram(dataMaxPixel: Pixel_F(data.max()!), dataMinPixel: Pixel_F(data.min()!), buffer: buffer, histogramcount: histogramcount)
    //Return three data, Histogram(0), Maximum Pixel Value(1), Minimum Pixel Value(2), Cutoff?(3) = 0 no, 1 yes
    let OptimizedHistogramContents = OptValue(histogram_in: histogramBin, histogramcount: histogramcount)
    let lowerPixelLimit = OptimizedHistogramContents.1
    let upperPixelLimit = OptimizedHistogramContents.0
    let cutoff = OptimizedHistogramContents.2
    let histogramOpt = histogram(dataMaxPixel: upperPixelLimit, dataMinPixel: lowerPixelLimit, buffer: buffer, histogramcount: histogramcount)
    print(histogramOpt)
    var OriginalPixelData = (buffer.data.toArray(to: Float.self, capacity: Int(buffer.width*buffer.height)))
    OriginalPixelData = forcingMeanData(PixelData: OriginalPixelData, MinimumLimit: lowerPixelLimit)
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

    let ddpPixelData = ddpProcessed(OriginalPixelData: OriginalPixelData, BlurredPixeldata: BlurredPixelData, Bendvalue: bendvalue.0, AveragePixel: bendvalue.1, cutOff: cutoff, MinPixel: lowerPixelLimit)
    let DDPScaled = ddpScaled(ddpPixelData: ddpPixelData, MinPixel: lowerPixelLimit)
    let ConvolveImage = returningCGImage(data: BlurredPixelData, width: width, height: height, rowBytes: rowBytes)
    let DDPwithScale = returningCGImage(data: DDPScaled, width: width, height: height, rowBytes: rowBytes)
    let originalImage = (try? buffer.createCGImage(format: format))!
    
    print("called")
    return(histogramBin, originalImage,  DDPwithScale, ConvolveImage)
    }


    var body: some View {
        TabView{
            HStack{
                rawImage?.resizable().scaledToFit()

            }
            HStack{
                processedImage?.resizable().scaledToFit()

            }
        }

        VStack{
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
                                        
                    
                    guard let read_data = try! FitsFile.read(contentsOf: selectedFile) else { return }
                    let prime = read_data.prime
                    print(prime)
                    prime.v_complete(onError: {_ in
                        print("CGImage creation error")
                    }) { result in
                        threeData = result
                        let _ = self.display(Data: threeData!)
                        
                        
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




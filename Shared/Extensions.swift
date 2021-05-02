//
//  Extensions.swift
//  FitsViewer
//
//  Created by anthony lim on 4/29/21.
//
import Foundation

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
    return kernelArray
}

func bendValue(AdjustedData: [Float]) -> (Float, Float){
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

func ddpProcessed(OriginalPixelData: [Float], BlurredPixeldata: [Float], Bendvalue : Float, AveragePixel: Float) -> [Float]{
    var ddpPixeldata = OriginalPixelData
    for i in 0 ..< OriginalPixelData.count{
        ddpPixeldata[i] = Bendvalue * ((OriginalPixelData[i]/(BlurredPixeldata[i] + AveragePixel)))
    }
    return ddpPixeldata
}
func ddpScaled(ddpPixelData: [Float]) -> [Float]{
    var ddpScaled = ddpPixelData
    var ddpMax = Float(ddpScaled.max()!)
    var ddpMin = Float(ddpScaled.min()!)
    var adjustable = ddpMax - ddpMin
    for i in 0 ..< ddpScaled.count{
        ddpScaled[i] = (ddpScaled[i] - ddpMin) / adjustable
    }
    return ddpScaled
}

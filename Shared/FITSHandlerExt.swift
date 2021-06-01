//
//  FITSHandlerExt.swift
//  FitsViewer
//
//  Created by anthony lim on 5/19/21.
//

import Foundation
import Accelerate
import Accelerate.vImage

extension FITSHandler{
    ///DDP Process functions
    
    func kArray(width: Int, height: Int, sigmaX: Float, sigmaY: Float, A: Float) -> [Float]
    {
    let kernelwidth = width
    let kernelheight = height
    var kernelArray = [Float]()
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

func ddpProcessed(OriginalPixelData: [Float], BlurredPixeldata: [Float], Bendvalue : Float, AveragePixel: Float, MinPixel : Pixel_F) -> [Float]{
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
}

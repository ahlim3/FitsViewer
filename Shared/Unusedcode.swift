        /*
        let kernel1D: [Float] = [0, 45, 136, 181, 136, 45, 0]
        var bendValue = Float(0.0)
        if dataAvg * 2.0 > 1.0 {
            bendValue = (1.0 - dataAvg)/2 + dataAvg
        }
        else
        {
            bendValue = 1.5 * dataAvg
        }
        for i in 0 ..< retdta.count{
            retdta[i] = (dataAvg * (retdta[i] / (data[i] + bendValue)) + 100.0 / 65535.0) * 10.0
        }
        let layerBytes = 510 * 510 * FITSByte_F.bytes
        let rowBytes = 510 * FITSByte_F.bytes
        
        var gray = retdta.withUnsafeMutableBytes{ mptr8 in
            vImage_Buffer(data: mptr8.baseAddress?.advanced(by: layerBytes * 0).bindMemory(to: FITSByte_F.self, capacity: 510 * 510), height: vImagePixelCount(510), width: vImagePixelCount(510), rowBytes: rowBytes)
        }
        func read2() -> PrimaryHDU{
            var path = URL(string: path5)!
            var read_data = try! FitsFile.read(contentsOf: path)
            let prime = read_data!.prime
            return prime
        }

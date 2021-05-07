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
         print(histogramBin3)
         vImageHistogramSpecification_PlanarF(&buffer, &buffer2, nil, histogramBin3, UInt32(histogramcount), 0.0, 1.0, vImage_Flags(kvImageNoFlags))
     */
        /*
                    NavigationView {
                        List {
                            NavigationLink(
                                destination: DestinationPageView()
                            ) {
                                Text("Image 1, Edge Fixed")
                            }
                            NavigationLink(
                                destination: DestinationPageView1()
                            ) {
                                Text("Image 2, Edge Fixed")
                            }
                            NavigationLink(
                                destination: DestinationPageView2()
                            ) {
                                Text("Image 3 Fast")
                            }
                            NavigationLink(
                                destination: DestinationPageView3()
                            ) {
                                Text("Image 4 Fast, Representable")
                            }
                            NavigationLink(
                                destination: DestinationPageView4()
                            ) {
                                Text("Image 5, RGBImage as Mono")
                            }
                            NavigationLink(
                                destination: DestinationPageView5()
                            ) {
                                Text("Image 6 Edge Fixed")
                            }
                            NavigationLink(
                                destination: DestinationPageView6()
                            ) {
                                Text("Image 7 Moon, Representable, Slow")
                            }
                            NavigationLink(
                                destination: DestinationPageView7()
                            ) {
                                Text("Image 8 Edge Fixed")
                            }
                            NavigationLink(
                                destination: DestinationPageView8()
                            ) {
                                Text("Image 9 Edge Problem, Edge is too big")
                            }
                            NavigationLink(
                                destination: DestinationPageView9()
                            ) {
                                Text("Image 10 Edge Fixed")
                            }
                            
                        }
                        Text("Select a Image page from the links.")
                    }*/
        /*
        struct DestinationPageView: View {
            let path = "file:///Users/anthonylim/Downloads/m31_061022_12i60m_L.FIT"
            var body: some View {
                let modified = display(Path: path)
                TabView{
                    HStack{
                Image(decorative: modified.2, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                    }
                HStack{
                Image(decorative: modified.1, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                }
            }
        }
        }
        struct DestinationPageView1: View {
             let path1 = "file:///Users/anthonylim/Downloads/2020-12-03_19;56;17.fits"
            var body: some View {
                let modified = display(Path: path1)
                TabView{
                    HStack{
                Image(decorative: modified.1, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                    }
                HStack{
                Image(decorative: modified.2, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                }
            }
        }
        }
        struct DestinationPageView2: View {
            let path2 = "file:///Users/anthonylim/Downloads/n5194.fits"
            var body: some View {
                let modified = display(Path: path2)
                TabView{
                    HStack{
                Image(decorative: modified.1, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                    }
                HStack{
                Image(decorative: modified.2, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                }
            }
        }
        }
        struct DestinationPageView3: View {
            let path10 = "file:///Users/anthonylim/Downloads/globular.fits"
            var body: some View {
                let modified = display(Path: path10)
                TabView{
                    HStack{
                Image(decorative: modified.1, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                    }
                HStack{
                Image(decorative: modified.2, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                }
            }
        }
        }
        struct DestinationPageView4: View {
             let path4 = "file:///Users/anthonylim/Downloads/UGC3697-104341-LUM.fit"
            var body: some View {
                let modified = display(Path: path4)
                TabView{
                    HStack{
                Image(decorative: modified.1, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                    }
                HStack{
                Image(decorative: modified.2, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                }
            }
        }
        }
        struct DestinationPageView5: View {
             let path5 = "file:///Users/anthonylim/Downloads/BGO-2-KIC8462852-ID06656-OC126425-GR7646-SG.fit"
            var body: some View {
                let modified = display(Path: path5)
                TabView{
                    HStack{
                Image(decorative: modified.1, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                    }
                HStack{
                Image(decorative: modified.2, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                }
            }
        }
        }
        struct DestinationPageView6: View {
             let path6 = "file:///Users/anthonylim/Downloads/moon_BIN_1x1_0.0010s_002.fits"
            var body: some View {
                let modified = display(Path: path6)
                TabView{
                    HStack{
                Image(decorative: modified.1, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                    }
                HStack{
                Image(decorative: modified.2, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                }
            }
        }
        }
        struct DestinationPageView7: View {
             let path7 = "file:///Users/anthonylim/Downloads/NGC4438-104275-LUM.fit"
            var body: some View {
                let modified = display(Path: path7)
                TabView{
                    HStack{
                Image(decorative: modified.1, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                    }
                HStack{
                Image(decorative: modified.2, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                }
            }
        }
        }
        struct DestinationPageView8: View {
             let path8 = "file:///Users/anthonylim/Downloads/M66-ID10979-OC144423-GR4135-LUM2.fit"
             // Work
            var body: some View {
                let modified = display(Path: path8)
                TabView{
                    HStack{
                Image(decorative: modified.1, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                    }
                HStack{
                Image(decorative: modified.2, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                }
            }
        }
        }
        struct DestinationPageView9: View {
             let path9 = "file:///Users/anthonylim/Downloads/NGC6960-ID14567-OC148925-GR8123-LUM.fit"
            var body: some View {
                let modified = display(Path: path9)
                TabView{
                    HStack{
                Image(decorative: modified.1, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                    }
                HStack{
                Image(decorative: modified.2, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                }
            }
        }
        }
        */

        /*
         func read(Path: String) -> ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat){
             var threeData: ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat)?
             var path = URL(string: Path)!
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
         */
        /*
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

        struct ContentView: View {
            @EnvironmentObject var fitDataHandler : FITSDatahandler
            @State var called = 0
            @State var isImporting: Bool = false
            @State var rawImage: Image?
            @State var processedImage: Image?
            @State var threeData: ([FITSByte_F],vImage_Buffer,vImage_CGImageFormat)?
            @State var returnedInfo : ([vImagePixelCount], CGImage, CGImage)?
            
            
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
                                    
                                    threeData = result
                                    returnedInfo = fitDataHandler.returnInfo(ThreeData: result)
                                    rawImage = Image(returnedInfo!.1, scale: 1.0, label: Text("Image"))
                                    processedImage = Image(returnedInfo!.2, scale: 1.0, label: Text("Image"))

                                   
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
        */

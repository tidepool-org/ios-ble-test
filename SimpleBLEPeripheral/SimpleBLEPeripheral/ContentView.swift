//
//  ContentView.swift
//  SimpleBLEPeripheral
//
//  Created by Rick Pasetto on 3/5/20.
//  Copyright © 2020 Rick Pasetto. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    let bluetooth = Bluetooth()
    @State var counter = 0
    var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .center, spacing: 100.0) {
            Text("\(counter)")
                .font(.title)
                .onReceive(timer) { _ in
                    self.counter += 1
                    // HACK
                    self.bluetooth.counter = self.counter
                }
            HStack(spacing: 120.0) {
                Button(action: {
                    self.bluetooth.startAdvertising()
                }) {
                    Text("Start Advertising")
                }
                .disabled(bluetooth.isAdvertising)
                Button(action: {
                    self.bluetooth.stopAdvertising()
                }) {
                    Text("Stop Advertising")
                }
                .disabled(!bluetooth.isAdvertising)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//
//  ContentView.swift
//  SimpleBLECentral
//
//  Created by Rick Pasetto on 3/5/20.
//  Copyright © 2020 Rick Pasetto. All rights reserved.
//

import SwiftUI

struct BLEState: Identifiable {
    var id = UUID()
    var counter = 0
    var connected = false
}

final class ViewModel: ObservableObject {
    @Published var state = BLEState()
    var bluetooth: Bluetooth!
    
    init() {
        bluetooth = Bluetooth(delegate: self)
    }
}

extension ViewModel: BluetoothDelegate {
    func connectedUpdated(value: Bool) {
        state.connected = value
    }
    
    func valueUpdate(value: Int) {
        state.counter = value
    }
}

struct ContentView: View {
    @ObservedObject var viewModel = ViewModel()
    
    static let colors: [Color] = [
        .black, .blue, .gray, .red, .green, .pink, .orange
    ]
    @State var index: Int = UserDefaults.standard.integer(forKey: "SimpleBLECentral.colorIndex") {
        didSet {
            UserDefaults.standard.set(self.index, forKey: "SimpleBLECentral.colorIndex")
        }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 100.0) {
            Text("\(viewModel.state.counter)")
                .font(.title)
                .foregroundColor(ContentView.colors[index])
                .onTapGesture {
                    self.index = (self.index + 1) % ContentView.colors.count
            }
            HStack(spacing: 120.0) {
                Button(action: {
                    self.viewModel.bluetooth.connect()
                }) {
                    Text("Connect")
                }
                .disabled(viewModel.state.connected)
                Button(action: {
                    self.viewModel.bluetooth.disconnect()
                }) {
                    Text("Disconnect")
                }
                .disabled(!viewModel.state.connected)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

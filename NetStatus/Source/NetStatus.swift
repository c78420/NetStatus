//
//  NetStatus.swift
//  NetStatusDemo
//
//  Created by Gabriel Theodoropoulos.
//  Copyright © 2019 Appcoda. All rights reserved.
//

import Foundation
import Network

public class NetStatus {
    static public let shared = NetStatus()
    
    var monitor: NWPathMonitor?
    
    public var isMonitoring = false
    
    public var isConnected: Bool {
        guard let monitor = monitor else { return false }
        return monitor.currentPath.status == .satisfied
    }
    
    public var interfaceType: NWInterface.InterfaceType? {
        guard let monitor = monitor else { return nil }
     
        return monitor.currentPath.availableInterfaces.filter {
            monitor.currentPath.usesInterfaceType($0.type) }.first?.type
    }
    
    public var availableInterfacesTypes: [NWInterface.InterfaceType]? {
        guard let monitor = monitor else { return nil }
        return monitor.currentPath.availableInterfaces.map { $0.type }
    }
    
    public var isExpensive: Bool {
        return monitor?.currentPath.isExpensive ?? false
    }
    
    public var didStartMonitoringHandler: (() -> Void)?
     
    public var didStopMonitoringHandler: (() -> Void)?
     
    public var netStatusChangeHandler: (() -> Void)?

    private init() {
    
    }
    
    deinit {
        stopMonitoring()
    }
    
    public func startMonitoring() {
        guard !isMonitoring else { return }
        
        monitor = NWPathMonitor()
        
        // 觀察網路狀態變化需要在背景執行緒中執行，不可以在主執行緒中執行。
        let queue = DispatchQueue(label: "NetStatus_Monitor")
        monitor?.start(queue: queue)
        
        monitor?.pathUpdateHandler = { _ in
            DispatchQueue.main.async { [unowned self] in
                self.netStatusChangeHandler?()
            }
        }
        
        isMonitoring = true
        didStartMonitoringHandler?()
    }
    
    public func stopMonitoring() {
        guard isMonitoring, let monitor = monitor else { return }
        
        monitor.cancel()
        
        self.monitor = nil
        isMonitoring = false
        
        didStopMonitoringHandler?()
    }
}

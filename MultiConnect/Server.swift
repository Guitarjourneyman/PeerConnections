//
//  Server.swift
//  MultiConnect
//
//  Created by michal on 29/11/2020.
//  Modified by aye on 04/10/2024

import Foundation
import Network
import UIKit

let server = try? Server()

class Server {

    let listener: NWListener
    var connections: [Connection] = []

    init() throws {
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveIdle = 2

        let parameters = NWParameters(tls: nil, tcp: tcpOptions)
        parameters.includePeerToPeer = true
        listener = try NWListener(using: parameters)
        
        listener.service = NWListener.Service(name: "server", type: "_superapp._tcp")
    }

    func start() {
        listener.stateUpdateHandler = { newState in
            log("listener.stateUpdateHandler \(newState)")
        }
        listener.newConnectionHandler = { [weak self] newConnection in
            log("listener.newConnectionHandler \(newConnection)")
            let connection = Connection(connection: newConnection)
            self?.connections += [connection]
        }
        listener.start(queue: .main)
    }

    func send() {
        guard let ipAddress = getLocalIPAddress() else {
            log("Failed to get IP address")
            return
        }
        
        connections.forEach {
            let message = "super message from the server! \(Int(Date().timeIntervalSince1970)) | IP: \(ipAddress)"
            $0.send(message)
        }
    }
    
    // Function to get the local IP address
    func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                let interface = ptr?.pointee
                let addrFamily = interface?.ifa_addr.pointee.sa_family
                
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6),
                   let ifaName = interface?.ifa_name,
                   String(cString: ifaName) == "en0" { // en0 is typically the Wi-Fi interface
                    var addr = interface?.ifa_addr.pointee
                    var hostName = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(&addr!, socklen_t(interface!.ifa_addr.pointee.sa_len),
                                &hostName, socklen_t(hostName.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostName)
                }
            }
            freeifaddrs(ifaddr)
        }
        
        return address
    }
}


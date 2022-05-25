//
//  main.swift
//  VPN-Generator
//
//  Created by Kai Howells on 25/5/2022.
//
//  Version History
//  v1.0 Original version - written in Python.
//  v2.0 A complete re-write in order to port it to Swift.
//

import Foundation
import ArgumentParser

// https://thisdevbrain.com/how-to-trim-a-string-in-swift/
extension String {
    func lowercasedTrimmingAllSpaces(using characterSet: CharacterSet = .whitespacesAndNewlines) -> String {
        return components(separatedBy: characterSet).joined().lowercased()
    }
}

struct VPNGenerator: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A utility to generate VPN Configuration Profiles without needing to use Profile Manager or Apple Configurator.\n(c) 2022 Kai Howells, Automatica <kai@automatica.com.au>",
        version: "2.0.0"
    )
    
    @Option(name: [.short, .customLong("user")], help: "Username for the VPN Server.")
    var username: String

    @Option(name: [.short, .customLong("pass")], help: "Password for the VPN Server.")
    var password: String

    @Option(name: .shortAndLong, help: "Shared secret for the VPN Server.")
    var secret: String

    @Option(name: .shortAndLong, help: "VPN Server hostname or IP address.")
    var address: String

    @Option(name: .shortAndLong, help: "Company name. Used for the name of the configuration profile.")
    var company: String
}

extension VPNGenerator {

    func run() throws {
        let uuidOne = UUID().uuidString.lowercased()
        let uuidTwo = UUID().uuidString.lowercased()

        let payloadIdentifier = "com.apple.mdm." + company.lowercasedTrimmingAllSpaces() + ".private." + uuidOne + ".alacarte"

        // first build the content for the payload.
        // this is done separately so I can wrap it in an array
        // and then stuff it in the main profile.
        
        let thePayloadContent : NSDictionary = [
                "DisconnectOnIdle" : 0,
                "IPSec" : [
                    "AuthenticationMethod" : "SharedSecret",
                    "OnDemandEnabled" : 0,
                    "PromptForVPNPIN" : false,
                    "SharedSecret" : secret
                ],
                "IPV4" : [
                    "OverridePrimary" : false
                ],
                "PPP" : [
                    "AuthName" : username,
                    "AuthPassword" : password,
                    "AuthenticationMethod" : "Passsword",
                    "CommRemoteAddress" : address,
                    "OnDemandEnabled" : 0
                ],
                "PayloadDisplayName" : "VPN (" + company + ")",
                "PayloadEnabled" : true,
                "PayloadIdentifier" : payloadIdentifier + ".vpn." + uuidTwo,
                "PayloadType" : "com.apple.vpn.managed",
                "PayloadUUID" : uuidTwo,
                "PayloadVersion" : 1,
                "Proxies" : [
                    :
                ],
                "UserDefinedName" : company + " VPN",
                "VPNType" : "L2TP",
            ]
        
        // now we wrap the payload in an array
        
        let thePayloadArray : NSArray = [ thePayloadContent ]
        
        // and then we add the array as the payload content in the profile.
        
        let theVPNProfile: NSDictionary = [
            "PayloadContent" : thePayloadArray,
            "PayloadDisplayName" : company + " VPN",
            "PayloadIdentifier" : payloadIdentifier,
            "PayloadOrganization" : company,
            "PayloadRemovalDisallowed" : false,
            "PayloadScope" : "User",
            "PayloadType" : "Configuration",
            "PayloadUUID" : uuidOne,
            "PayloadVersion" : 1
        ]
        
        let theFileName = company + " VPN for " + username
        let thePath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(theFileName).appendingPathExtension("mobileconfig")
        try theVPNProfile.write(to: thePath)
    }
}

struct RuntimeError: Error, CustomStringConvertible {
    var description: String
    
    init(_ description: String) {
        self.description = description
    }
}

VPNGenerator.main()

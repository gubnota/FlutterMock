//
//  FlutterMock.swift
//  FlutterMock
//
//  Created by Vladislav Muravyev on 2025-03-15.
//
//  This module mimics basic Flutter channels (method and event channels)
//  and Flutter plugin registration for debugging purposes in a Swift UIKit project.
//

import Foundation

// MARK: - Flutter Binary Messenger Protocol and Debug Implementation

/// Protocol to mimic Flutter's binary messenger.
public protocol FlutterBinaryMessenger {
    func send(onChannel channel: String, message: Any?, completion: ((Any?) -> Void)?)
}

/// A simple debug implementation that logs outgoing messages.
public class DebugBinaryMessenger: FlutterBinaryMessenger {
    public init() {}
    
    public func send(onChannel channel: String, message: Any?, completion: ((Any?) -> Void)?) {
        print("[DebugBinaryMessenger] Channel: \(channel) | Message: \(String(describing: message))")
        completion?(nil)
    }
}

// MARK: - Flutter Method Channel

/// Represents a Flutter method call.
public struct FlutterMethodCall {
    public let method: String
    public let arguments: Any?
    
    public init(method: String, arguments: Any?) {
        self.method = method
        self.arguments = arguments
    }
}

/// A callback type for returning method results.
public typealias FlutterResult = (Any?) -> Void

/// Protocol for handling incoming method calls.
public protocol FlutterMethodCallHandler: AnyObject {
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult)
}

/// Mimics a Flutter MethodChannel.
public class FlutterMethodChannel {
    public let name: String
    private let messenger: FlutterBinaryMessenger
    private weak var methodCallHandler: FlutterMethodCallHandler?
    
    /// Initializes the channel with a name and a binary messenger.
    public init(name: String, binaryMessenger: FlutterBinaryMessenger) {
        self.name = name
        self.messenger = messenger
    }
    
    /// Sets the handler to process method calls.
    public func setMethodCallHandler(_ handler: FlutterMethodCallHandler?) {
        self.methodCallHandler = handler
    }
    
    /// Simulates invoking a method call (as if coming from Dart).
    public func invokeMethod(_ method: String, arguments: Any?, result: FlutterResult? = nil) {
        print("[FlutterMethodChannel] Invoking method '\(method)' with arguments: \(String(describing: arguments)) on channel '\(name)'")
        let call = FlutterMethodCall(method: method, arguments: arguments)
        if let handler = methodCallHandler {
            handler.handle(call, result: result ?? { _ in })
        } else {
            print("[FlutterMethodChannel] No method call handler registered.")
            result?(nil)
        }
    }
    
    /// Sends a message on the channel (as if from native to Dart).
    public func sendMessage(_ message: Any?, result: FlutterResult? = nil) {
        print("[FlutterMethodChannel] Sending message on channel '\(name)': \(String(describing: message))")
        messenger.send(onChannel: name, message: message, completion: result)
    }
}

// MARK: - Flutter Event Channel

/// Type alias for an event sink callback.
public typealias FlutterEventSink = (Any?) -> Void

/// Protocol to handle stream events.
public protocol FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink)
    func onCancel(withArguments arguments: Any?)
}

/// Mimics a Flutter EventChannel.
public class FlutterEventChannel {
    public let name: String
    private let messenger: FlutterBinaryMessenger
    private var streamHandler: FlutterStreamHandler?
    
    /// Initializes the event channel with a name and a binary messenger.
    public init(name: String, messenger: FlutterBinaryMessenger) {
        self.name = name
        self.messenger = messenger
    }
    
    /// Sets the stream handler to manage event streams.
    public func setStreamHandler(_ handler: FlutterStreamHandler?) {
        self.streamHandler = handler
    }
    
    /// Simulates receiving an event (for debugging purposes).
    public func receiveEvent(withArguments arguments: Any?) {
        print("[FlutterEventChannel] Receiving event on channel '\(name)' with arguments: \(String(describing: arguments))")
        streamHandler?.onListen(withArguments: arguments, eventSink: { event in
            print("[FlutterEventChannel] Event sink received event: \(String(describing: event))")
        })
    }
    
    /// Simulates canceling an event stream.
    public func cancelEvent(withArguments arguments: Any?) {
        print("[FlutterEventChannel] Canceling event on channel '\(name)' with arguments: \(String(describing: arguments))")
        streamHandler?.onCancel(withArguments: arguments)
    }
}

// MARK: - Flutter Plugin Protocols and Registrar

/// Protocol that plugins must implement.
public protocol FlutterPlugin: AnyObject {
    static func register(with registrar: FlutterPluginRegistrar)
}

/// Protocol for Flutter plugin method call delegation (similar to FlutterMethodCallHandler).
public protocol FlutterPluginMethodCallDelegate: AnyObject {
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult)
}

/// Protocol for a Flutter plugin registrar.
public protocol FlutterPluginRegistrar {
    func messenger() -> FlutterBinaryMessenger
    func addMethodCallDelegate(_ delegate: FlutterPluginMethodCallDelegate, channel: FlutterMethodChannel)
}

/// A debug implementation of FlutterPluginRegistrar for UIKit projects.
public class DebugPluginRegistrar: FlutterPluginRegistrar {
    private let binaryMessenger: FlutterBinaryMessenger
    // Optional: store delegate-channel pairs for future use.
    private var delegates: [(delegate: FlutterPluginMethodCallDelegate, channel: FlutterMethodChannel)] = []
    
    public init(binaryMessenger: FlutterBinaryMessenger = DebugBinaryMessenger()) {
         self.binaryMessenger = binaryMessenger
    }
    
    public func messenger() -> FlutterBinaryMessenger {
         return binaryMessenger
    }
    
    public func addMethodCallDelegate(_ delegate: FlutterPluginMethodCallDelegate, channel: FlutterMethodChannel) {
         print("[DebugPluginRegistrar] Registered delegate for channel: \(channel.name)")
         delegates.append((delegate: delegate, channel: channel))
         // Set the method call handler on the channel.
         channel.setMethodCallHandler(delegate as? FlutterMethodCallHandler)
    }
}

// MARK: - Example Plugin Implementation

/// A constant to return when a method is not implemented.
public let FlutterMethodNotImplemented = "FlutterMethodNotImplemented"

/// Example plugin that uses the above definitions.
public class TadaPlugin: NSObject, FlutterPlugin, FlutterPluginMethodCallDelegate, FlutterMethodCallHandler {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        // Note: Use the 'messenger:' parameter label.
        let channel = FlutterMethodChannel(name: "tada", messenger: registrar.messenger())
        let instance = TadaPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("[TadaPlugin] Received method call: \(call.method) with arguments: \(String(describing: call.arguments))")
        if call.method == "logout" {
            // Implement logout logic here.
            result("Logged out successfully")
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    // Conformance for FlutterMethodCallHandler.
    // In this simple example, we simply forward to our own handle(_:,result:).
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.handle(call, result: result)
    }
}

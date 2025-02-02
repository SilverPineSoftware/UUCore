//
//  UULogger.swift
//  UUSwiftCore
//
//  Created by Ryan DeVore on 12/20/24.
//  Copyright © 2024 Silverpine Software. All rights reserved.
//
//  This file is part of UUSwiftCore, distributed under the MIT License.
//  See LICENSE file for details.
//

import Foundation

/// A protocol defining a logging mechanism for structured log output.
/// Types conforming to `UULogger` must implement a method to log messages with
/// varying levels of severity, a descriptive tag, and a formatted message.
open class UULogger
{
    /// The log level threshold for the logger.
    ///
    /// Only messages at or above this level will be logged. Messages with a lower severity will be ignored.
    ///
    /// ### Usage
    /// - Set this property to control the verbosity of the logger.
    /// - For example, if `logLevel` is set to `.info`, only `.info`, `.warn`, `.error`, and `.fatal` messages will be logged.
    ///   Messages with `.verbose` or `.debug` levels will be ignored.
    ///
    /// ### Example
    /// ```swift
    /// var logger: UULogger = SomeLoggerImplementation()
    /// logger.logLevel = .warn
    ///
    /// logger.writeToLog(level: .info, tag: "Example", message: "This will not be logged.")
    /// logger.writeToLog(level: .warn, tag: "Example", message: "This will be logged.")
    /// ```
    ///
    /// - Note: This property allows developers to dynamically control the verbosity of logs during runtime.
    public var logLevel: UULogLevel = .off
    
    /// A list of tags that should be explicitly included in the log output.
    ///
    /// When this property is set with one or more tags, only log messages with matching tags will be logged.
    /// If the list is empty, all tags are included by default unless explicitly excluded by `excludedTags`.
    ///
    /// ### Usage
    /// - Use this property to filter logs based on specific tags of interest.
    /// - Setting this property overrides the default behavior of including all tags.
    ///
    /// ### Example
    /// ```swift
    /// var logger: UULogger = SomeLoggerImplementation()
    /// logger.includedTags = ["Networking", "Database"]
    ///
    /// // Only log messages with "Networking" or "Database" tags will be logged.
    /// logger.writeToLog(level: .info, tag: "Networking", message: "Request started") // Logged
    /// logger.writeToLog(level: .info, tag: "UI", message: "Button clicked") // Ignored
    /// ```
    ///
    /// - Note: The `includedTags` property works in conjunction with `excludedTags`. If a tag is present in both, it will be excluded.
    public var includedTags: [String] = []

    /// A list of tags that should be explicitly excluded from the log output.
    ///
    /// When this property is set with one or more tags, log messages with matching tags will be ignored,
    /// regardless of whether the tags are present in `includedTags`.
    ///
    /// ### Usage
    /// - Use this property to suppress logs from specific tags that are not relevant or needed.
    /// - By default, no tags are excluded.
    ///
    /// ### Example
    /// ```swift
    /// var logger: UULogger = SomeLoggerImplementation()
    /// logger.excludedTags = ["Debug", "Verbose"]
    ///
    /// // Messages with "Debug" or "Verbose" tags will be ignored.
    /// logger.writeToLog(level: .info, tag: "Debug", message: "This will not be logged") // Ignored
    /// logger.writeToLog(level: .info, tag: "Networking", message: "Request started") // Logged
    /// ```
    ///
    /// - Note: The `excludedTags` property has higher priority than `includedTags`. If a tag is in both lists, it will be excluded.
    public var excludedTags: [String] = []
    
    /// The log writer responsible for handling the output of log messages.
    ///
    /// This property allows you to customize how and where log messages are written.
    /// By assigning a custom implementation of `UULogWriter`, you can direct logs to different destinations,
    /// such as a file, console, remote server, or any other logging system.
    ///
    /// ### Usage
    /// - Set this property to a `UULogWriter` implementation that meets your application's needs.
    /// - The logger will delegate the actual log writing to the specified `logWriter`.
    ///
    /// ### Example
    /// ```swift
    /// var logger: UULogger = SomeLoggerImplementation()
    ///
    /// // Use a custom log writer that writes logs to a file.
    /// logger.logWriter = FileLogWriter(filePath: "/path/to/log.txt")
    ///
    /// // Logs will now be written to the specified file.
    /// logger.writeToLog(level: .info, tag: "FileWriter", message: "This message will be saved to the log file.")
    /// ```
    ///
    /// - Note: The `logWriter` must conform to the `UULogWriter` protocol, ensuring compatibility with the logger.
    public var logWriter: UULogWriter
    
    /// Initializes a new instance of the logger with a specified log writer.
    ///
    /// This initializer allows you to configure the logger with a custom implementation of `UULogWriter`,
    /// which determines how and where log messages are written.
    ///
    /// ### Parameters
    /// - logWriter: An object conforming to the `UULogWriter` protocol. This object handles the output of log messages.
    ///
    /// - Note: This initializer ensures that every logger instance is associated with a log writer at creation time.
    public init(_ logWriter: UULogWriter)
    {
        self.logWriter = logWriter
    }
}

///
/// Convenience extensions to log at different levels
///
public extension UULogger
{
    /// Checks whether or not an incoming leg level is at or above the current log level configured for this logger.
    ///
    func shouldLog(level: UULogLevel) -> Bool
    {
        return level.rawValue >= self.logLevel.rawValue
    }
    
    /// Checks whether a given log tag should be writen.
    ///
    /// If a tag is in the excluded list, it is not logged.
    /// If the include list is non empty, the tag is logged only if it is in the list.
    /// If none of the above conditions are true, the tag is logged.
    ///
    /// - Parameters:
    ///   - tag: A `String` identifier that categorizes the log message, such as a component or module name.
    func shouldLog(tag: String) -> Bool
    {
        if (excludedTags.contains(tag))
        {
            return false
        }
        
        if !includedTags.isEmpty
        {
            return includedTags.contains(tag)
        }
        
        return true
    }
    
    /// Writes a log entry with the specified log level, tag, and formatted message.  The log message is only written
    /// if level is >= `currentLogLevel`
    ///
    /// - Parameters:
    ///   - level: The severity level of the log message, represented by the `UULogLevel` enum.
    ///            Common levels include `.verbose`, `.debug`, `.info`, `.warn`, `.error`, and `.fatal`.
    ///
    ///   - tag: A `String` identifier that categorizes the log message, such as a component or module name.
    ///          Useful for filtering logs based on context.
    ///
    ///   - message: A `String` log message.
    func writeToLog(level: UULogLevel, tag: String, message: String)
    {
        guard shouldLog(level: level) else
        {
            return
        }
        
        guard shouldLog(tag: tag) else
        {
            return
        }
        
        logWriter.writeToLog(level: level, tag: tag, message: message)
    }
    
    /// Logs a verbose message.
    ///
    /// - Parameters:
    ///   - tag: A short identifier for the source of the log message.
    ///   - message: The message to be logged.
    func verbose(tag: String, message: String)
    {
        writeToLog(level: .verbose, tag: tag, message: message)
    }

    /// Logs a debug message.
    ///
    /// - Parameters:
    ///   - tag: A short identifier for the source of the log message.
    ///   - message: The message to be logged.
    func debug(tag: String, message: String)
    {
        writeToLog(level: .debug, tag: tag, message: message)
    }

    /// Logs an informational message.
    ///
    /// - Parameters:
    ///   - tag: A short identifier for the source of the log message.
    ///   - message: The message to be logged.
    func info(tag: String, message: String)
    {
        writeToLog(level: .info, tag: tag, message: message)
    }

    /// Logs a warning message.
    ///
    /// - Parameters:
    ///   - tag: A short identifier for the source of the log message.
    ///   - message: The message to be logged.
    func warn(tag: String, message: String)
    {
        writeToLog(level: .warn, tag: tag, message: message)
    }

    /// Logs an error message.
    ///
    /// - Parameters:
    ///   - tag: A short identifier for the source of the log message.
    ///   - message: The message to be logged.
    func error(tag: String, message: String)
    {
        writeToLog(level: .error, tag: tag, message: message)
    }

    /// Logs a fatal message. Use this method for critical errors that may cause the application to crash.
    ///
    /// - Parameters:
    ///   - tag: A short identifier for the source of the log message.
    ///   - message: The message to be logged.
    func fatal(tag: String, message: String)
    {
        writeToLog(level: .fatal, tag: tag, message: message)
    }
}

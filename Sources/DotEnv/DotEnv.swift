import Foundation

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif


public struct DotEnv {
    ///
    /// Load .env file and put all the variables into the environment
    ///
    static public func load(filename: String) {

        let path = getAbsolutePath(relativePath: "/\(filename)", useFallback: false)
        if let path = path, let contents = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) {

            let lines = String(describing: contents).characters.split { $0 == "\n" || $0 == "\r\n" }.map(String.init)
            for line in lines {
                // ignore comments
                if line[line.startIndex] == "#" {
                    continue
                }

                // ignore lines that appear empty 
                if line.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).isEmpty {
                    continue
                }

                // extract key and value which are separated by an equals sign
                let parts = line.characters.split(separator: "=", maxSplits: 1).map(String.init)

                let key = parts[0].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
                var value = parts[1].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)

                // remove surrounding quotes from value & convert remove escape character before any embedded quotes
                if value[value.startIndex] == "\"" && value[value.index(before: value.endIndex)] == "\"" {
                    value.remove(at: value.startIndex)
                    value.remove(at: value.index(before: value.endIndex))
                    value = value.replacingOccurrences(of:"\\\"", with: "\"")
                }
                setenv(key, value, 1)
            }
        }
    }

    ///
    /// Return the value for `name` in the environment, returning the default if not present
    ///
    public static func get(_ name: String) -> String? {
        guard let value = getenv(name) else { 
            return nil
        }
        return String(validatingUTF8: value)
    }

    ///
    /// Return the integer value for `name` in the environment, returning default if not present
    ///
    public static func getAsInt(_ name: String) -> Int? {
        guard let value = get(name) else {
            return nil
        }
        return Int(value)
    }

    ///
    /// Return the boolean value for `name` in the environment, returning default if not present
    ///
    /// Note that the value is lowercaed and must be "true", "yes" or "1" to be considered true.
    ///
    public static func getAsBool(_ name: String) -> Bool? {
        guard let value = get(name) else {
            return nil
        }

        // is it "true"?
        if ["true", "yes", "1"].contains(value.lowercased()) {
            return true
        }

        return false
    }

    // Open
    public static func all() -> [String: String] {
        return ProcessInfo.processInfo.environment
    }

    ///
    /// Determine route path of project. This assumes we're installed via SwiftPM and that
    /// this library is in the Packages subdirectory, so it's a bit fragile!
    ///
    private static func getAbsolutePath(relativePath: String, useFallback: Bool = true) -> String? {
        let thisFile = #file
        let components = thisFile.characters.split(separator: "/").map(String.init)
        let toRootDir = components[0..<components.count - 5]
        var filePath = "/" + toRootDir.joined(separator: "/") + relativePath

        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: filePath) {
            return filePath
        } else if useFallback {
            // Look in the current directory instead
            let currentPath = fileManager.currentDirectoryPath
            filePath = currentPath + relativePath
            if fileManager.fileExists(atPath: filePath) {
                return filePath
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}

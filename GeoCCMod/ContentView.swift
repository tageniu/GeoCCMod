// Icon credit: https://www.vecteezy.com/vector-art/351886-vector-globe-icon

import SwiftUI
import SQLite3

struct ContentView: View {
    @State private var isSimulator: Bool = false
    @State private var showOverrideAlert = false
    @State private var showOpenAlert = false
    @State private var occResult: String = "Loading..."
    @State private var soccResult: String = "Loading..."
    @State private var restorePressCount = 0
    @State private var lastRestorePressTime: Date?
    @State private var showHiddenButton = false
    @State private var hiddenButtonText = ""
    @State private var hiddenButtonAlertText = ""
    @State private var showAlert = false
    @State private var selectedCountryCode: String = "US"
    @State private var countryCodes = ["US", "CN", "JP"]

    // TODO: Check iOS 17 compatibility
    // Set database file location
    let databasePath_sys = ""
    #if targetEnvironment(simulator)
        let databasePath = "/Users/ba/Library/Containers/com.apple.geod/Data/Library/Caches/com.apple.geod/GEOConfigStore.db"
    #else
        let databasePath = "/var/mobile/Library/Caches/com.apple.geod/GEOConfigStore.db"
        init() {
            let databasePath_sys = findGeoPathSys(bundleID: "systemgroup.com.apple.geod") ?? ""
        }
    #endif
    
    var body: some View {
        VStack(spacing: 20) {
            // OCC
            Text(NSLocalizedString("OCC Result:", comment: ""))
                .font(.headline)
            Text(occResult)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            // SOCC
            Text(NSLocalizedString("SOCC Result:", comment: ""))
                .font(.headline)
            Text(soccResult)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            // Override
            HStack (spacing: 20) {
                Picker("Country Code", selection: $selectedCountryCode) {
                    ForEach(countryCodes, id: \.self) {
                        Text($0)
                    }
                }
//                .onAppear(perform: prepareHaptics)
//                .onReceive(Just(selectedCountryCode)) { _ in
//                    self.hapticFeedback()
//                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 150, height: 105)
                .clipped()
//                .border(Color.blue)
            
                Button(action: {
                    overrideAction()
                    if isSimulator {
                        showOverrideAlert = true
                    }
                }) {
                    Text(NSLocalizedString("Override", comment: ""))
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .alert(isPresented: $showOverrideAlert) {
                    Alert(
                        title: Text("Only host setting is overriden from simulator."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            
            // Restore
            Button(action: {
                restoreAction()
            }) {
                Text(NSLocalizedString("Restore", comment: ""))
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .simultaneousGesture(LongPressGesture(minimumDuration: 2.0)
                .onEnded { _ in
                    print("Long press detected!")
                    showHiddenButton = true
                    hiddenButtonText = NSLocalizedString("Show Version", comment: "")
                    hiddenButtonAlertText = NSLocalizedString("Environment version will be shown in the Maps.", comment: "")
                }
            )
            
            HStack (spacing: 20) {
                // Open Maps
                Button(action: {
                    openMaps()
                    if isSimulator {
                        showOpenAlert = true
                    }
                }) {
                    Text(NSLocalizedString("Open Maps", comment: ""))
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .alert(isPresented: $showOpenAlert) {
                    Alert(
                        title: Text("Cannot open host's Maps from simulator."),
                        dismissButton: .default(Text("OK"))
                    )
                }
                
                if showHiddenButton {
                    Button(action: {
                        if hiddenButtonText == "Show Version" {
                            showVersion()
                        } else if hiddenButtonText == "Hide Version" {
                            hideVersion()
                        }
                        showAlert = true
                    }) {
                        Text(hiddenButtonText)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text(hiddenButtonAlertText),
                            dismissButton: .default(Text("OK")) {
                                showHiddenButton = false
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .onAppear {
            #if targetEnvironment(simulator)
                isSimulator = true
            #else
                isSimulator = false
            #endif
            check()
        }
    }

//import Combine
//import CoreHaptics
//    @State private var engine: CHHapticEngine?
//    func prepareHaptics() {
//        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
//        do {
//            self.engine = try CHHapticEngine()
//            try engine?.start()
//        } catch {
//            print("There was an error creating the haptic engine: \(error.localizedDescription)")
//        }
//    }
//
//    func hapticFeedback() {
//        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
//        var events = [CHHapticEvent]()
//
//        // Create one intense, sharp tap.
//        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 10)
//        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 10)
//        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
//        events.append(event)
//
//        // Create a pattern from the events.
//        do {
//            let pattern = try CHHapticPattern(events: events, parameters: [])
//            let player = try engine?.makePlayer(with: pattern)
//            try player?.start(atTime: 0)
//        } catch {
//            print("Failed to play pattern: \(error.localizedDescription)")
//        }
//    }

    func findGeoPathSys(bundleID: String) -> String? {
        let searchPath = "/var/containers/Shared/SystemGroup/"
        let fileManager = FileManager.default
        do {
            let directories = try fileManager.contentsOfDirectory(atPath: searchPath)
            for dir in directories {
                let dirPath = searchPath + dir
                let metadataPath = dirPath + "/.com.apple.mobile_container_manager.metadata.plist"
                if fileManager.fileExists(atPath: metadataPath) {
                    if let plist = NSDictionary(contentsOfFile: metadataPath) as? [String: Any], let identifier = plist["MCMMetadataIdentifier"] as? String, identifier == bundleID {
                        // Found the container, make sure the parent directiry exists
                        let fileManager = FileManager.default
                        do {
                            try fileManager.createDirectory(atPath: dirPath + "/Library/Caches/com.apple.geod/", withIntermediateDirectories: true, attributes: nil)
                        } catch {
                            print("Error: \(error.localizedDescription)")
                        }
                        // Return db path
                        return dirPath + "/Library/Caches/com.apple.geod/GEOSystemConfigStore.db"
                    }
                }
            }
        } catch {
            print("Cannot find bundle path.")
        }
        return nil
    }
    
    // Function to fetch process information using sysctl
    func fetchProcesses() -> [kinfo_proc] {
        var name: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL]
        var length: size_t = 0
        
        // Get the length of the data
        sysctl(&name, u_int(name.count), nil, &length, nil, 0)
        
        // Create an array to hold the process information
        var processInfo = [kinfo_proc](repeating: kinfo_proc(), count: length / MemoryLayout<kinfo_proc>.stride)
        
        // Get the process information
        sysctl(&name, u_int(name.count), &processInfo, &length, nil, 0)
        return processInfo
    }

    // Function to find the PID of `com.apple.geod` for user 501
    func findGeodPID() -> Int32? {
        let processes = fetchProcesses()
        
        #if targetEnvironment(simulator)
            let GEO_process_name = "com.apple.geod"
        #else
            let GEO_process_name = "geod"
        #endif
        
        for var process in processes {
            let uid = process.kp_eproc.e_ucred.cr_uid
            if uid == 501 {
                let command = withUnsafePointer(to: &process.kp_proc.p_comm) {
                    $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXCOMLEN)) {
                        String(cString: $0)
                    }
                }
                if command == GEO_process_name {
                    return Int32(process.kp_proc.p_pid)
                }
            }
        }
        return nil
    }
    
    // Function to ensure both databases are ready to be modified
    func killGeod() {
        repeat {
            let pid = findGeodPID()
            if pid != nil {
                print(pid!)
                kill(pid!, 9)
                print("Attempted 1 kill.")
            }
            usleep(100000) // sleep for 0.1 seconds
        } while !openDatabaseAndClose(path: databasePath) || !openDatabaseAndClose(path: databasePath_sys)
    }
    
    func openDatabaseAndClose(path: String) -> Bool {
        // Return true for empty path string
        if path == "" {
            return true
        }
        
        // Create an empty db if not found
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) {
            var db: OpaquePointer? = nil
            if sqlite3_open(path, &db) == SQLITE_OK {
                print("Successfully created database at \(path)")
                sqlite3_close(db)
            } else {
                print("Unable to create database. Verify that you created the directory described in the Getting Started section.")
                sqlite3_close(db)
            }
        }
        
        // Try to open db
        var db: OpaquePointer? = nil
        let flags = SQLITE_OPEN_READWRITE
        if sqlite3_open_v2(path, &db, flags, nil) != SQLITE_OK {
            print("Database is locked. 1")
            sqlite3_close(db)
            return false
        }
        
        // Try to quick check db by creating table "defaults" if not exist
        var statement: OpaquePointer? = nil
//        let sql = "PRAGMA quick_check;"
        let sql = "CREATE TABLE IF NOT EXISTS defaults ( rowid INTEGER PRIMARY KEY NOT NULL, key TEXT NOT NULL, parent INT REFERENCES defaults(rowid) ON UPDATE CASCADE ON DELETE CASCADE, type TEXT NOT NULL, value TEXT, UNIQUE(key, parent) );"
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
//            if sqlite3_step(statement) == SQLITE_ROW {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Database is ready to be modified.")
                sqlite3_finalize(statement)
                sqlite3_close(db)
                return true
            }
        }
        
        // Return db is locked
        print("Database is locked. 2")
        sqlite3_finalize(statement)
        sqlite3_close(db)
        return false
    }
    
    func openDatabase(path: String) -> OpaquePointer? {
        // Kill geod to unlock databases
        killGeod()
        
        var db: OpaquePointer? = nil
        if sqlite3_open(path, &db) != SQLITE_OK {
            print("Error opening database.")
            return nil
        }
        return db
    }
    
    func query(sql: String, path: String) -> [[String: String]]? {
        guard let db = openDatabase(path: path) else { return nil }
        var queryStatement: OpaquePointer? = nil
        var result: [[String: String]] = []
        
        if sqlite3_prepare_v2(db, sql, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                var row: [String: String] = [:]
                for i in 0..<sqlite3_column_count(queryStatement) {
                    let columnName = String(cString: sqlite3_column_name(queryStatement, i))
                    let columnValue = String(cString: sqlite3_column_text(queryStatement, i))
                    row[columnName] = columnValue
                }
                result.append(row)
            }
        } else {
            print("SELECT statement could not be prepared.")
        }
        sqlite3_finalize(queryStatement)
        sqlite3_close(db)

        return result
    }
    
    func execute(sql: String, path: String) {
        guard let db = openDatabase(path: path) else { return }
        var execStatement: OpaquePointer? = nil

        if sqlite3_prepare_v2(db, sql, -1, &execStatement, nil) == SQLITE_OK {
            if sqlite3_step(execStatement) == SQLITE_DONE {
                print("Successfully executed \(sql)")
            } else {
                print("Could not execute \(sql)")
            }
        } else {
            print("EXEC statement could not be prepared.")
        }
        sqlite3_finalize(execStatement)
        sqlite3_close(db)
    }
    
    func check() {
        // Make sure the parent directiry exists
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(atPath: "/var/mobile/Library/Caches/com.apple.geod/", withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error: \(error.localizedDescription)")
        }
        
        let checkOCC = "SELECT * FROM defaults WHERE key='OverrideCountryCode';"
        let checkSOCC = "SELECT * FROM defaults WHERE key='ShouldOverrideCountryCode';"
        
        if databasePath_sys == "" {
            // Return results from the first database
            if let occResult = query(sql: checkOCC, path: databasePath)?.first {
                self.occResult = occResult.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
            } else {
                self.occResult = NSLocalizedString("OCC NOT found.", comment: "")
            }
            if let soccResult = query(sql: checkSOCC, path: databasePath)?.first {
                self.soccResult = soccResult.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
            } else {
                self.soccResult = NSLocalizedString("SOCC NOT found.", comment: "")
            }
        } else {
            // Return results from the second database
            if let occResult = query(sql: checkOCC, path: databasePath_sys)?.first {
                self.occResult = occResult.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
            } else {
                self.occResult = NSLocalizedString("OCC NOT found.", comment: "")
            }
            if let soccResult = query(sql: checkSOCC, path: databasePath_sys)?.first {
                self.soccResult = soccResult.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
            } else {
                self.soccResult = NSLocalizedString("SOCC NOT found.", comment: "")
            }
        }
    }
    
    func overrideAction() {
        let addOCC = "INSERT INTO defaults (key, parent, type, value) VALUES ('OverrideCountryCode', '0', 'str', '\(selectedCountryCode)');"
        let addSOCC = "INSERT INTO defaults (key, parent, type, value) VALUES ('ShouldOverrideCountryCode', '0', 'int', '1');"
        let updateOCC = "UPDATE defaults SET value='\(selectedCountryCode)' WHERE key='OverrideCountryCode';"
        let updateSOCC = "UPDATE defaults SET value='1' WHERE key='ShouldOverrideCountryCode';"
        
        // Override first db
        if query(sql: "SELECT * FROM defaults WHERE key='OverrideCountryCode';", path: databasePath)?.isEmpty ?? true {
            execute(sql: addOCC, path: databasePath)
        } else {
            execute(sql: updateOCC, path: databasePath)
        }
        if query(sql: "SELECT * FROM defaults WHERE key='ShouldOverrideCountryCode';", path: databasePath)?.isEmpty ?? true {
            execute(sql: addSOCC, path: databasePath)
        } else {
            execute(sql: updateSOCC, path: databasePath)
        }
        
        // Override second db if needed
        if databasePath_sys != "" {
            if query(sql: "SELECT * FROM defaults WHERE key='OverrideCountryCode';", path: databasePath_sys)?.isEmpty ?? true {
                execute(sql: addOCC, path: databasePath_sys)
            } else {
                execute(sql: updateOCC, path: databasePath_sys)
            }
            if query(sql: "SELECT * FROM defaults WHERE key='ShouldOverrideCountryCode';", path: databasePath_sys)?.isEmpty ?? true {
                execute(sql: addSOCC, path: databasePath_sys)
            } else {
                execute(sql: updateSOCC, path: databasePath_sys)
            }
        }
        
        check()
    }
    
    func restoreAction() {
        let now = Date()
        if let lastPressTime = lastRestorePressTime {
            if now.timeIntervalSince(lastPressTime) <= 2 {
                restorePressCount += 1
            } else {
                restorePressCount = 1
            }
        } else {
            restorePressCount = 1
        }
        lastRestorePressTime = now
        if restorePressCount >= 5 {
            print("Five consecutive presses detected!")
            showHiddenButton = true
            hiddenButtonText = NSLocalizedString("Hide Version", comment: "")
            hiddenButtonAlertText = NSLocalizedString("Environment version will be hidden in the Maps.", comment: "")
            restorePressCount = 0
            lastRestorePressTime = nil
        }
        
        let addSOCC = "INSERT INTO defaults (key, parent, type, value) VALUES ('ShouldOverrideCountryCode', '0', 'int', '0');"
        let updateSOCC = "UPDATE defaults SET value='0' WHERE key='ShouldOverrideCountryCode';"
        
        // Restore first db
        if query(sql: "SELECT * FROM defaults WHERE key='ShouldOverrideCountryCode';", path: databasePath)?.isEmpty ?? true {
            execute(sql: addSOCC, path: databasePath)
        } else {
            execute(sql: updateSOCC, path: databasePath)
        }

        // Restore second db if needed
        if databasePath_sys != "" {
            if query(sql: "SELECT * FROM defaults WHERE key='ShouldOverrideCountryCode';", path: databasePath_sys)?.isEmpty ?? true {
                execute(sql: addSOCC, path: databasePath_sys)
            } else {
                execute(sql: updateSOCC, path: databasePath_sys)
            }
        }

        check()
    }
    
    func showVersion() {
        // TODO: Fix not working on iOS 15
        let addSENR = "INSERT INTO defaults (key, parent, type, value) VALUES ('GEOShowEnvironmentNameRule', '0', 'int', '2');"
        let updateSENR = "UPDATE defaults SET value='2' WHERE key='GEOShowEnvironmentNameRule';"
        
        // Change first db
        if query(sql: "SELECT * FROM defaults WHERE key='GEOShowEnvironmentNameRule';", path: databasePath)?.isEmpty ?? true {
            execute(sql: addSENR, path: databasePath)
        } else {
            execute(sql: updateSENR, path: databasePath)
        }
        
        // Change second db if needed
        if query(sql: "SELECT * FROM defaults WHERE key='GEOShowEnvironmentNameRule';", path: databasePath_sys)?.isEmpty ?? true {
            execute(sql: addSENR, path: databasePath_sys)
        } else {
            execute(sql: updateSENR, path: databasePath_sys)
        }
    }
    
    func hideVersion() {
        // TODO: Fix not working on iOS 15
        let addSENR = "INSERT INTO defaults (key, parent, type, value) VALUES ('GEOShowEnvironmentNameRule', '0', 'int', '0');"
        let updateSENR = "UPDATE defaults SET value='0' WHERE key='GEOShowEnvironmentNameRule';"
        
        // Change first db
        if query(sql: "SELECT * FROM defaults WHERE key='GEOShowEnvironmentNameRule';", path: databasePath)?.isEmpty ?? true {
            execute(sql: addSENR, path: databasePath)
        } else {
            execute(sql: updateSENR, path: databasePath)
        }
        
        // Change second db if needed
        if query(sql: "SELECT * FROM defaults WHERE key='GEOShowEnvironmentNameRule';", path: databasePath_sys)?.isEmpty ?? true {
            execute(sql: addSENR, path: databasePath_sys)
        } else {
            execute(sql: updateSENR, path: databasePath_sys)
        }
    }
    
    func openMaps() {
        // Kill Maps if open
        let processes = fetchProcesses()
        let Maps_process_name = "Maps"
        for var process in processes {
            let uid = process.kp_eproc.e_ucred.cr_uid
            if uid == 501 {
                let command = withUnsafePointer(to: &process.kp_proc.p_comm) {
                    $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXCOMLEN)) {
                        String(cString: $0)
                    }
                }
                if command == Maps_process_name {
                    kill(process.kp_proc.p_pid, 9)
                    usleep(100000)
                }
            }
        }
        
        // Open Maps from URL Scheme
        #if !targetEnvironment(simulator)
            if let url = URL(string: "maps://") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        #endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

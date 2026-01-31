//
//  AudioStore.swift
//  Chinese Helper
//
//  Created by Fabian Olczak on 31/01/2026.
//

import Foundation

enum AudioStore {
    static func baseDir() throws -> URL {
        let fm = FileManager.default
        let appSupport = try fm.url(for: .applicationSupportDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: true)
        let dir = appSupport.appendingPathComponent("audio", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func fileURL(for id: UUID, ext: String = "mp3") throws -> URL {
        try baseDir().appendingPathComponent("\(id.uuidString).\(ext)")
    }

    static func relativePath(for id: UUID, ext: String = "mp3") -> String {
        "audio/\(id.uuidString).\(ext)"
    }

    static func resolve(relativePath: String) throws -> URL {
        let fm = FileManager.default
        let appSupport = try fm.url(for: .applicationSupportDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: true)
        return appSupport.appendingPathComponent(relativePath)
    }
}

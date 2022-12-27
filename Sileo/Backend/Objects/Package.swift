//
//  Package.swift
//  Sileo
//
//  Created by CoolStar on 7/3/19.
//  Copyright © 2022 Sileo Team. All rights reserved.
//
import UIKit

final class Package: Hashable, Equatable {
    public var package: String
    public var packageID: String
    public var name: String?
    public var version: String
    public var architecture: String?
    public var author: String?
    public var maintainer: String?
    public var section: String?
    public var rawSection: String?
    public var packageDescription: String?
    public var legacyDepiction: String?
    public var depiction: String?
    public var icon: String?
    public var sourceFile: String?
    public var source: String?
    public var isProvisional: Bool?
    public var sourceFileURL: URL?
    public var rawControl: [String: String] = [:]
    public var rawData: Data?
    public var essential: String?
    public var commercial: Bool = false
    public var installedSize: Int?
    public var tags: PackageTags = .none
    public var nativeDepiction: String?
    
    public var allVersionsInternal = [String: Package]()
    public var allVersions: [Package] {
        [self] + Array(allVersionsInternal.values)
    }
    
    public var fromStatusFile = false
    public var wantInfo: pkgwant = .unknown
    public var eFlag: pkgeflag = .ok
    public var status: pkgstatus = .installed
    public var installDate: Date?
    
    public var filename: String?
    public var size: String?
    public var packageFileURL: URL?
    public var userRead = false
    
    public var defaultIcon: UIImage {
        if let rawSection = rawSection {
            
            // we have to do this because some repos have various Addons sections
            // ie, Addons (activator), Addons (youtube), etc
            if rawSection.lowercased().contains("addons") {
                return UIImage(named: "Category_addons") ?? UIImage(named: "Category_tweak")!
            } else if rawSection.lowercased().contains("themes") {
                // same case for themes
                return UIImage(named: "Category_themes") ?? UIImage(named: "Category_tweak")!
            }
            
            return UIImage(named: "Category_\(rawSection)") ?? UIImage(named: "Category_\(rawSection)s") ?? UIImage(named: "Category_tweak")!
        }
        return UIImage(named: "Category_tweak")!
    }
    
    var sourceRepo: Repo? {
        guard let sourceFileSafe = sourceFile else {
            return nil
        }
        return RepoManager.shared.repo(withSourceFile: sourceFileSafe)
    }
    
    var guid: String {
        String(format: "%@|-|%@", package, version)
    }
    
    init(package: String, version: String) {
        self.package = package
        self.packageID = package
        self.version = version
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(package)
        hasher.combine(version)
    }
    
    public func hasIcon() -> Bool {
        icon?.isEmpty == false
    }

    public func addOld(_ packages: [Package]) {
        for package in packages {
            if package == self { continue }
            allVersionsInternal[package.version] = package
        }
    }
    
    public func addOld(from package: Package) {
        for package in package.allVersions {
            if package == self { continue }
            allVersionsInternal[package.version] = package
        }
    }
    
    public func getVersion(_ version: String) -> Package? {
        if version == self.version { return self }
        return allVersionsInternal[version]
    }
}

func == (lhs: Package, rhs: Package) -> Bool {
    lhs.package == rhs.package && lhs.version == rhs.version
}

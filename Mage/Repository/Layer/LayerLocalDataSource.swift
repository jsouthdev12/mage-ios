//
//  LayerLocalDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 10/4/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct LayerLocalDataSourceProviderKey: InjectionKey {
    static var currentValue: LayerLocalDataSource = LayerLocalCoreDataDataSource()
}

extension InjectedValues {
    var layerLocalDataSource: LayerLocalDataSource {
        get { Self[LayerLocalDataSourceProviderKey.self] }
        set { Self[LayerLocalDataSourceProviderKey.self] = newValue }
    }
}

protocol LayerLocalDataSource: Actor {
    func createLoadedXYZLayer(name: String) async -> Layer?
    func markRemoteLayerNotDownloaded(remoteId: NSNumber) async
    func markRemoteLayerLoaded(remoteId: NSNumber) async
    func createGeoPackageLayer(name: String) async -> Layer?
    func removeOutdatedOfflineMapArchives() async
    func count(eventId: NSNumber, layerId: Int) async -> Int
}

actor LayerLocalCoreDataDataSource: LayerLocalDataSource {
    @Injected(\.nsManagedObjectContext)
    var context: NSManagedObjectContext?
    
    func count(eventId: NSNumber, layerId: Int) async -> Int {
        guard let context = self.context else { return 0 }
        let layerIdNumber = NSNumber(value: layerId)
        
        return await context.perform {
            do {
                return try context.countOfObjects(
                    Layer.self,
                    predicate: NSPredicate(
                        format: "eventId == %@ AND remoteId == %@",
                        eventId,
                        layerIdNumber
                    )
                ) ?? 0
            } catch {
                NSLog("Count error: \(error)")
                return 0
            }
        }
    }
    
    func createLoadedXYZLayer(name: String) async -> Layer? {
        guard let context = self.context else { return nil }
        return await context.perform {
            do {
                let predicate = NSPredicate(
                    format: "eventId == -1 AND (type == %@ OR type == %@) AND name == %@",
                    "GeoPackage", "Local_XYZ", name
                )
                let existing = try context.fetchFirst(
                    Layer.self,
                    sortBy: [NSSortDescriptor(key: "eventId", ascending: true)],
                    predicate: predicate
                )
                if let existing = existing {
                    return existing
                }

                let newLayer = Layer(context: context)
                newLayer.name = name
                newLayer.loaded = NSNumber(floatLiteral: Layer.EXTERNAL_LAYER_LOADED)
                newLayer.type = "Local_XYZ"
                newLayer.eventId = -1
                try context.obtainPermanentIDs(for: [newLayer])
                try context.save()
                return newLayer
            } catch {
                NSLog("Error creating XYZ layer: \(error)")
                return nil
            }
        }
    }
    
    func markRemoteLayerNotDownloaded(remoteId: NSNumber) async {
        guard let context = self.context else { return }
        await context.perform {
            do {
                let layers: [Layer] = try context.fetchObjects(
                    Layer.self,
                    predicate: NSPredicate(format: "remoteId == %@", remoteId)
                ) ?? []
                for layer in layers {
                    layer.loaded = NSNumber(floatLiteral: Layer.OFFLINE_LAYER_NOT_DOWNLOADED)
                    layer.downloading = false
                }
                try context.save()
            } catch {
                NSLog("Error marking not downloaded: \(error)")
            }
        }
    }
    
    func markRemoteLayerLoaded(remoteId: NSNumber) async {
        guard let context = self.context else { return }
        await context.perform {
            do {
                let layers: [Layer] = try context.fetchObjects(
                    Layer.self,
                    predicate: NSPredicate(format: "remoteId == %@", remoteId)
                ) ?? []
                for layer in layers {
                    layer.loaded = NSNumber(floatLiteral: Layer.OFFLINE_LAYER_LOADED)
                    layer.downloading = false
                }
                try context.save()
            } catch {
                NSLog("Error marking loaded: \(error)")
            }
        }
    }
    
    func createGeoPackageLayer(name: String) async -> Layer? {
        guard let context = self.context else { return nil }
        return await context.perform {
            do {
                let layer = Layer(context: context)
                layer.name = name
                layer.loaded = NSNumber(floatLiteral: Layer.EXTERNAL_LAYER_LOADED)
                layer.type = "GeoPackage"
                layer.eventId = -1
                try context.obtainPermanentIDs(for: [layer])
                try context.save()
                return layer
            } catch {
                NSLog("Error creating GeoPackage layer: \(error)")
                return nil
            }
        }
    }

    
    func removeOutdatedOfflineMapArchives() async {
        guard let context = self.context else { return }
        
        let layers: [Layer]? = await context.perform {
            try? context.fetchObjects(
                Layer.self,
                predicate: NSPredicate(
                    format: "eventId == -1 AND (type == %@ OR type == %@)",
                    argumentArray: ["GeoPackage", "Local_XYZ"]
                )
            )
        }
        
        guard let layers else { return }
        
        for layer in layers {
            let overlay = await CacheOverlays.shared.getByCacheName(layer.name)
            
            if overlay == nil || (overlay is GeoPackageCacheOverlay && !FileManager.default.fileExists(atPath: (overlay as! GeoPackageCacheOverlay).filePath)) {
                await context.perform {
                    context.delete(layer)
                }
            }
        }
        
        await context.perform {
            do {
                try context.save()
            } catch {
                NSLog("Error saving after deleting outdated layers: \(error)")
            }
        }
    }
}

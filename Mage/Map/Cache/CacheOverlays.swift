//
//  CacheOverlays.m
//  MAGE
//
//  Created by Brian Osborn on 12/17/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData

protocol CacheOverlayListener: NSObjectProtocol {
    func cacheOverlaysUpdated(_ cacheOverlays: [CacheOverlay]) async
}

actor CacheOverlays {
    static let shared = CacheOverlays()
    
    @Injected(\.layerRepository)
    var layerRepository: LayerRepository
    
    private var overlays: [String: CacheOverlay] = [:]
    private var overlayNames: [String] = []
    private var listeners: [CacheOverlayListener] = []
    private var processing: [String] = []
    
    static func getInstance() -> CacheOverlays {
        shared
    }
    
    func register(_ listener: CacheOverlayListener) async {
        listeners.append(listener)
        await listener.cacheOverlaysUpdated(await getOverlays())
    }
    
    func unregisterListener(_ listener: CacheOverlayListener) {
        listeners.removeAll(where: { $0 === listener })
    }
    
    func setCacheOverlays(overlays: [CacheOverlay]) async {
        self.overlays = [:]
        self.overlayNames = []
        await add(overlays)
    }
    
    func add(_ overlays: [CacheOverlay]) async {
        for overlay in overlays {
            addCacheOverlayHelper(overlay: overlay)
        }
        await notifyListeners()
    }
    
    private func addCacheOverlayHelper(overlay: CacheOverlay) {
        let cacheName = overlay.name
        
        if let existingOverlay = overlays[cacheName] {
            overlay.enabled = existingOverlay.enabled

            if overlay.added {
                overlay.replaced = existingOverlay.replaced ?? existingOverlay
            }
        } else {
            overlayNames.append(cacheName)
        }
        
        overlays[cacheName] = overlay // TODO: !!! CRASHED HERE (Modifying SHARED Mutable state!)
    }
    
    func addCacheOverlay(overlay: CacheOverlay) async {
        addCacheOverlayHelper(overlay: overlay)
        await notifyListeners()
    }
    
    func notifyListeners() async {
        await notifyListenersExceptCaller(caller: nil)
    }
    
    func notifyListenersExceptCaller(caller: CacheOverlayListener?) async {
        let overlays = await getOverlays()
        
        for listener in listeners {
            if caller == nil || listener !== caller {
                await listener.cacheOverlaysUpdated(overlays)
            }
        }
    }
    
    func getOverlays() async -> [CacheOverlay] {
        var overlaysInCurrentEvent: [CacheOverlay] = []
        
        for cacheOverlayName in overlayNames.sorted() {
            guard let cacheOverlay = overlays[cacheOverlayName] else { continue }
            
            if let geopkg = cacheOverlay as? GeoPackageCacheOverlay,
               let layerId = geopkg.layerId,
               let layerIdInt = Int(layerId),
               let currentEventId = Server.currentEventId() {
                let count = await layerRepository.count(eventId: currentEventId, layerId: layerIdInt)
                
                if count != 0 {
                    overlaysInCurrentEvent.append(geopkg)
                }
                
            } else {
                overlaysInCurrentEvent.append(cacheOverlay)
            }
        }
        
        return overlaysInCurrentEvent
    }
    
    func count() -> Int {
        overlayNames.count
    }
    
    func atIndex(index: Int) -> CacheOverlay? {
        overlays[overlayNames[index]]
    }
    
    func getByCacheName(_ cacheName: String?) -> CacheOverlay? {
        guard let cacheName = cacheName else { return nil }
        return overlays[cacheName]
    }
    
    func removeCacheOverlay(overlay: CacheOverlay) async {
        await remove(byCacheName: overlay.cacheName)
    }
    
    func remove(byCacheName: String) async {
        overlays.removeValue(forKey: byCacheName)
        overlayNames.removeAll(where: { $0 == byCacheName })
        await notifyListeners()
    }
    
    func addProcessing(name: String) async {
        self.processing.append(name)
        await notifyListeners()
    }
    
    func addProcessing(from: [String]?) async {
        self.processing.append(contentsOf: from ?? [])
        await notifyListeners()
    }
    
    func removeProcessing(_ name: String) async {
        self.processing.removeAll(where: { $0 == name })
        await notifyListeners()
    }
    
    func getProcessing() -> [String] {
        processing
    }
    
    func removeAll() async {
        for overlay in overlays.values {
            await removeCacheOverlay(overlay: overlay)
        }
    }
}

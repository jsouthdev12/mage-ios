//
//  SettingsDataSource.h
//  MAGE
//
//  Created by William Newman on 1/28/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MaterialComponents/MDCContainerScheme.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, kSettingType) {
    kConnection,
    kLocationServices,
    kObservationServices,
    kDataSynchronization,
    kDataFetching,
    kDataPushing,
    kLocationDisplay,
    kNavigation,
    kTimeDisplay,
    kMediaPhoto,
    kMediaVideo,
    kEventInfo,
    kChangeEvent,
    kMoreEvents,
    kTheme,
    kLogout,
    kChangePassword,
    kAttributions,
    kDisclaimer,
    kContactUs
};

@protocol SettingsDelegate
- (void) settingTapped:(kSettingType) setting info:(id) info;
@end

@interface SettingsDataSource : NSObject<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) id<SettingsDelegate> delegate;
@property (assign, nonatomic) BOOL showDisclosureIndicator;

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme context: (NSManagedObjectContext *) context;
- (void) reloadData;

@end

NS_ASSUME_NONNULL_END

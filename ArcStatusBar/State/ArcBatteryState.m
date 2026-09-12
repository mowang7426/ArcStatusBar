#import "ArcBatteryState.h"
#import <UIKit/UIKit.h>

@implementation ArcBatteryState

+ (float)level {
    UIDevice *device = UIDevice.currentDevice;
    device.batteryMonitoringEnabled = YES;
    return device.batteryLevel;
}

@end

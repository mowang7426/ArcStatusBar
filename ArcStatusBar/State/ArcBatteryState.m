#import "ArcBatteryState.h"
#import <UIKit/UIKit.h>

@implementation ArcBatteryState

+ (NSInteger)percentage {
    UIDevice *device = UIDevice.currentDevice;
    device.batteryMonitoringEnabled = YES;

    if (device.batteryLevel < 0.0) return 0;
    return (NSInteger)lroundf(device.batteryLevel * 100.0f);
}

+ (BOOL)charging {
    UIDeviceBatteryState state = UIDevice.currentDevice.batteryState;
    return state == UIDeviceBatteryStateCharging ||
           state == UIDeviceBatteryStateFull;
}

@end

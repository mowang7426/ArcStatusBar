#import "ArcNetworkState.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

@implementation ArcNetworkState

+ (NSString *)radioLabel {
    CTTelephonyNetworkInfo *info = [CTTelephonyNetworkInfo new];
    NSDictionary *services = info.serviceCurrentRadioAccessTechnology;

    for (NSString *key in services) {
        NSString *tech = services[key];

        if ([tech isEqualToString:CTRadioAccessTechnologyNR] ||
            [tech isEqualToString:CTRadioAccessTechnologyNRNSA]) {
            return @"5G";
        }
    }

    return @"WiFi";
}

+ (NSString *)signalVisual {
    /*
     * Deliberately visual-only in this public-source implementation.
     * The private SpringBoard signal-strength APIs vary between iOS builds.
     */
    return @"▮▮▮▮";
}

@end

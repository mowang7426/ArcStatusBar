#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface ArcStatusBarPrefs : PSListController
@end

@implementation ArcStatusBarPrefs

- (NSArray *)specifiers {
    if (_specifiers) return _specifiers;

    PSSpecifier *header = [PSSpecifier preferenceSpecifierNamed:@"ArcStatusBar 2.1"
                                                          target:nil
                                                             set:nil
                                                             get:nil
                                                          detail:nil
                                                            cell:PSGroupCell
                                                            edit:nil];
    [header setProperty:@"视频风格 Wi-Fi 环形状态栏动画" forKey:@"footerText"];

    PSSpecifier *info = [PSSpecifier preferenceSpecifierNamed:@"动画说明"
                                                        target:nil
                                                           set:nil
                                                           get:nil
                                                        detail:nil
                                                          cell:PSStaticTextCell
                                                          edit:nil];
    [info setProperty:@"蜂窝信号 → 四点；电池胶囊 → 竖线；Wi-Fi 周围弧线展开。" forKey:@"label"];

    _specifiers = @[header, info];
    return _specifiers;
}

@end

//
//  GDPreferences.m
//  Griddy
//
//  Created by Yan Sun on 2014-08-23.
//  Copyright (c) 2014 Sunnay. All rights reserved.
//

#import "GDPreferences.h"
#import "GDAppDelegate.h"



// preference keys
NSString * const GDMainWindowTypeKey = @"GDMainWindowTypeKey";
NSString * const GDMainWindowAbsoluteSizeKey = @"GDMainWindowAbsoluteSizeKey";
NSString * const GDMainWindowRelativeSizeKey = @"GDMainWindowRelativeSizeKey";
NSString * const GDMainWindowBackgroundColorKey = @"GDMainWindowBackgroundColor";
NSString * const GDMainWindowBackgroundTransparencyKey = @"GDMainWindowBackgroundTransparencyKey";
NSString * const GDMainWindowGridColorKey = @"GDMainWindowGridColorKey";
NSString * const GDMainWindowGridTransparencyKey = @"GDMainWindowGridTransparencyKey";
NSString * const GDMainWindowGridUniversalDimensionsKey = @"GDMainWindowGridUniversalDimensionsKey";
NSString * const GDMainWindowRelativeGridSpecificDimensionsKey = @"GDMainWindowRelativeGridSpecificDimensionsKey";
NSString * const GDMainWindowAbsoluteGridSpecificDimensionsKey = @"GDMainWindowAbsoluteGridSpecificDimensionsKey";
NSString * const GDShortcutKey = @"GDShortcutKey";
NSString * const GDStatusItemVisibilityKey = @"GDStatusItemVisibilityKey";
NSString * const GDDockIconVisibilityKey = @"GDDockIconVisibilityKey";
NSString * const GDAutoLaunchOnLoginKey = @"GDAutoLaunchOnLoginKey";



// changes keys
NSString * const GDMainWindowTypeChanged = @"GDMainWindowTypeChanged";
NSString * const GDMainWindowAbsoluteSizeChanged = @"GDMainWindowAbsoluteSizeChanged";
NSString * const GDMainWindowRelativeSizeChanged = @"GDMainWindowRelativeSizeChanged";
NSString * const GDMainWindowGridUniversalDimensionsChanged = @"GDMainWindowGridUniversalDimensionsChanged";
NSString * const GDStatusItemVisibilityChanged = @"GDStatusItemVisibilityChanged";
NSString * const GDDockIconVisibilityChanged = @"GDDockIconVisibilityChanged";
NSString * const GDAutoLaunchOnLoginChanged = @"GDAutoLaunchOnLoginChanged";



@interface GDPreferenceController() {
    GDAppDelegate *_appDelegate;
}

- (NSView *) viewForTag: (NSUInteger) tag;
- (NSRect) getFrameForNewView: (NSView *) view;
@end



@implementation GDPreferenceController



# pragma mark - INIT

- (id) init {
    self = [super initWithWindowNibName:@"Preferences"];
    if (self) {
        _appDelegate = (GDAppDelegate *)[[NSApplication sharedApplication] delegate];
    }
    return self;
}


- (void) awakeFromNib {
    [self.window setContentSize: [appearancesView frame].size];
    [[self.window contentView] setAutoresizesSubviews: NO];
    [[self.window contentView] addSubview: appearancesView];
    [[self.window contentView] setWantsLayer: YES];
}


- (void) windowDidLoad {
    [super windowDidLoad];
    [self listenToNotifications];
    [self setPreferenceUI];
    [self shouldShowMainWindowsByTag: 0];
}


- (void) listenToNotifications {
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(windowTypeChanged:)
                                                 name: GDMainWindowTypeChanged
                                               object: nil];
}




# pragma mark - BASE UI

- (BOOL) isWindowFocused {
    return [self.window isMainWindow] || [self.window isKeyWindow];
}


- (void) preventHideWindow {
    [self.window setCanHide: NO];
}


- (void) enableHideWindow {
    [self.window setCanHide: YES];
}


- (IBAction) switchView: (id)sender {
    NSUInteger tag = [sender tag];
    NSView *view = [self viewForTag: tag];
    NSView *previousView = [self viewForTag: currentViewTag];
    NSRect newFrame = [self getFrameForNewView: view];
    
    // transition
    [NSAnimationContext beginGrouping];
    if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) {
        [[NSAnimationContext currentContext] setDuration: 1.0];
    }
    [[[self.window contentView] animator] replaceSubview: previousView
                                                      with: view];
    [[self.window animator] setFrame: newFrame
                               display: YES];
    [NSAnimationContext endGrouping];
    [self shouldShowMainWindowsByTag: tag];
    currentViewTag = tag;
}


- (void) shouldShowMainWindowsByTag: (NSUInteger) tag {
    if (tag == 0 || tag == 1) {
        [_appDelegate launchWindowsBehindWindowLevel: self.window.level];
    } else {
        [_appDelegate hideWindows];
    }
}


- (NSRect) getFrameForNewView: (NSView *) view {
    NSWindow *prefWindow = self.window;
    NSRect newFrameRect = [prefWindow frameRectForContentRect: [view frame]];
    NSRect oldFrameRect = [prefWindow frame];
    NSSize newSize = newFrameRect.size;
    NSSize oldSize = oldFrameRect.size;
    
    NSRect frame = [prefWindow frame];
    frame.size = newSize;
    frame.origin.y -= (newSize.height - oldSize.height);
    
    return frame;
}


- (NSView *) viewForTag: (NSUInteger) tag {
    NSView *view = nil;
    switch (tag) {
        case 0:
            view = appearancesView;
            break;
        case 1:
            view = functionalityView;
            break;
        case 2:
            view = miscView;
            break;
        default:
            view = appearancesView;
    }
    return view;
}


- (BOOL) validateToolbarItem: (NSToolbarItem *)theItem {
    if ([theItem tag] == currentViewTag) {
        return NO;
    } else {
        return YES;
    }
}



# pragma mark - INTERFACE callbacks

- (void) setPreferenceUI {
    // window tab
    NSUInteger windowType = [[[NSUserDefaults standardUserDefaults] objectForKey: GDMainWindowTypeKey] integerValue];
    [mainWindowSizeChoiceMatrix selectCellWithTag: windowType];
    [self setPreferenceUIWindowSizeWithWindowType: windowType];
    
    // grid tab
    [self setPreferenceUIGridDimensions];
    
    // misc tab
    // NSLog(@"dock icon visibility: %hhd", [[[NSUserDefaults standardUserDefaults] objectForKey: GDDockIconVisibilityKey] boolValue]);
    dockIconCheckBox.state = [[[NSUserDefaults standardUserDefaults] objectForKey: GDDockIconVisibilityKey] boolValue];
    // NSLog(@"status item visibility: %hhd", [[[NSUserDefaults standardUserDefaults] objectForKey: GDStatusItemVisibilityKey] boolValue]);
    statusItemCheckBox.state = [[[NSUserDefaults standardUserDefaults] objectForKey: GDStatusItemVisibilityKey] boolValue];
}

- (void) windowTypeChanged: (NSNotification *) note {
    NSUInteger newWindowType = [[[NSUserDefaults standardUserDefaults] objectForKey: GDMainWindowTypeKey] integerValue];
    [self setPreferenceUIWindowSizeWithWindowType: newWindowType];
}



// window tab callbacks

- (void) setPreferenceUIWindowSizeWithWindowType: (NSUInteger) windowType {
    NSData *sizeData;
    if (windowType == 1) {
        sizeData = [[NSUserDefaults standardUserDefaults] objectForKey: GDMainWindowAbsoluteSizeKey];
    } else {
        sizeData = [[NSUserDefaults standardUserDefaults] objectForKey: GDMainWindowRelativeSizeKey];
    }
    NSSize windowSize = [[NSKeyedUnarchiver unarchiveObjectWithData: sizeData] sizeValue];
    [self setWindowWidthInputBoxValue: windowSize.width
                         asWindowType: windowType];
    [self setWindowHeightInputBoxValue: windowSize.height
                          asWindowType: windowType];
}

- (IBAction) changeMainWindowSizeChoiceMatrix: (id)sender {
    NSUInteger selectedTag = [[sender selectedCell] tag];
    [GDPreferenceController setMainWindowType: selectedTag];
}


- (IBAction) changeWidthInputBox: (id)sender {
	NSUserDefaults *defaultValues = [NSUserDefaults standardUserDefaults];
    NSUInteger windowType = [[defaultValues objectForKey: GDMainWindowTypeKey] integerValue];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle: NSNumberFormatterDecimalStyle];
    [formatter setRoundingMode: NSNumberFormatterRoundUp];
    
    CGFloat widthVal;
    NSSize newSize;
    if (windowType == 1) { // abs
        [formatter setMaximumFractionDigits: 0];
        widthVal = [[formatter numberFromString: widthInputBox.stringValue] integerValue];
        widthVal = floor((ABS(widthVal) / 5) + 0.5) * 5; // round up to nearest 5
        widthVal = MAX(300, MIN(900, widthVal));         // 300 <= widthVal <= 900
        
        // save it
        NSData *data = [defaultValues objectForKey: GDMainWindowAbsoluteSizeKey];
        NSSize oldSize = [[NSKeyedUnarchiver unarchiveObjectWithData: data] sizeValue];
        newSize = NSMakeSize(widthVal, oldSize.height);
        if (NSEqualSizes(newSize, oldSize)) {
            return;
        }
        
        [GDPreferenceController setMainWindowAbsoluteSize: newSize];
        
    } else { // relative
        [formatter setMaximumFractionDigits: 2];
        widthVal = [[formatter numberFromString: widthInputBox.stringValue] floatValue] / 100;
        widthVal = MAX(0.5, MIN(0.7, widthVal));         // 5% <= widthVal <= 70%

        // save it
        NSData *data = [defaultValues objectForKey: GDMainWindowRelativeSizeKey];
        NSSize oldSize = [[NSKeyedUnarchiver unarchiveObjectWithData: data] sizeValue];
        newSize = NSMakeSize(widthVal, oldSize.height);
        if (NSEqualSizes(newSize, oldSize)) {
            return;
        }
        
        [GDPreferenceController setMainWindowRelativeSize: newSize];
    }
    
    [self setWindowWidthInputBoxValue: widthVal
                         asWindowType: windowType];
}


- (IBAction) changeHeightInputBox: (id) sender {
	NSUserDefaults *defaultValues = [NSUserDefaults standardUserDefaults];
    NSUInteger windowType = [[defaultValues objectForKey: GDMainWindowTypeKey] integerValue];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle: NSNumberFormatterDecimalStyle];
    [formatter setRoundingMode: NSNumberFormatterRoundUp];
    
    CGFloat heightVal;
    NSSize newSize;
    if (windowType == 1) { // abs
        [formatter setMaximumFractionDigits: 0];
        heightVal = [[formatter numberFromString: heightInputBox.stringValue] integerValue];
        heightVal = floor((ABS(heightVal) / 5) + 0.5) * 5; // round up to nearest 5
        heightVal = MAX(180, MIN(540, heightVal));         // 180 <= heightVal <= 540

        // save it
        NSData *data = [defaultValues objectForKey: GDMainWindowAbsoluteSizeKey];
        NSSize oldSize = [[NSKeyedUnarchiver unarchiveObjectWithData: data] sizeValue];
        newSize = NSMakeSize(oldSize.width, heightVal);
        if (NSEqualSizes(newSize, oldSize)) {
            return;
        }
        
        [GDPreferenceController setMainWindowAbsoluteSize: newSize];

        
    } else { // relative
        [formatter setMaximumFractionDigits: 2];
        heightVal = [[formatter numberFromString: heightInputBox.stringValue] floatValue] / 100;
        heightVal = MAX(0.5, MIN(0.7, heightVal));         // 5% <= heightVal <= 70%

        // save it
        NSData *data = [defaultValues objectForKey: GDMainWindowRelativeSizeKey];
        NSSize oldSize = [[NSKeyedUnarchiver unarchiveObjectWithData: data] sizeValue];
        newSize = NSMakeSize(oldSize.width, heightVal);
        if (NSEqualSizes(newSize, oldSize)) {
            return;
        }
      
        [GDPreferenceController setMainWindowRelativeSize: newSize];
    }
    
    [self setWindowHeightInputBoxValue: heightVal
                          asWindowType: windowType];
}


- (void) setWindowWidthInputBoxValue: (CGFloat) widthVal
                        asWindowType: (NSUInteger) windowType {
    if (windowType == 1) { // abs
        [widthInputBox setStringValue: [NSString stringWithFormat:@"%lu", (NSInteger)ceilf(widthVal)]];
        [widthInputBoxSuffix setStringValue: @"px"];
    } else {
        [widthInputBox setStringValue: [NSString stringWithFormat:@"%.2f", widthVal * 100]];
        [widthInputBoxSuffix setStringValue: @"%"];
    }
}


- (void) setWindowHeightInputBoxValue: (CGFloat) heightVal
                         asWindowType: (NSUInteger) windowType {
    if (windowType == 1) { // abs
        [heightInputBox setStringValue: [NSString stringWithFormat:@"%lu", (NSInteger)ceilf(heightVal)]];
        [heightInputBoxSuffix setStringValue: @"px"];
    } else {
        [heightInputBox setStringValue: [NSString stringWithFormat:@"%.2f", heightVal * 100]];
        [heightInputBoxSuffix setStringValue: @"%"];
    }
}



// grid tab callbacks

- (void) setPreferenceUIGridDimensions {
    NSData *sizeData = [[NSUserDefaults standardUserDefaults] objectForKey: GDMainWindowGridUniversalDimensionsKey];
    NSSize gridDimensions = [[NSKeyedUnarchiver unarchiveObjectWithData: sizeData] sizeValue];
    [self setGridXInputBoxValue: gridDimensions.width];
    [self setGridYInputBoxValue: gridDimensions.height];
}


- (IBAction) changeGridDimensionsX: (id) sender {
    NSUserDefaults *defaultValues = [NSUserDefaults standardUserDefaults];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle: NSNumberFormatterDecimalStyle];
    [formatter setRoundingMode: NSNumberFormatterRoundUp];
    [formatter setMaximumFractionDigits: 0];
    
    // calculate new dim
    CGFloat newDimX = [[formatter numberFromString: gridDimensionsX.stringValue] integerValue];
    newDimX = MIN(20, MAX(2, newDimX));         // 2 <= widthVal <= 25
    [self setGridXInputBoxValue: newDimX];

    // save it in user defaults
    NSData *data = [defaultValues objectForKey: GDMainWindowGridUniversalDimensionsKey];
    NSSize oldDim = [[NSKeyedUnarchiver unarchiveObjectWithData: data] sizeValue];
    NSSize newDim = NSMakeSize(newDimX, oldDim.height);
    if (NSEqualSizes(newDim, oldDim)) {
        return;
    }
    [GDPreferenceController setGridDimensions: newDim];
}


- (void) setGridXInputBoxValue: (CGFloat) dimX {
    [gridDimensionsX setStringValue: [NSString stringWithFormat:@"%lu", (NSInteger)ceilf(dimX)]];
}


- (IBAction) changeGridDimensionsY: (id) sender {
    NSUserDefaults *defaultValues = [NSUserDefaults standardUserDefaults];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle: NSNumberFormatterDecimalStyle];
    [formatter setRoundingMode: NSNumberFormatterRoundUp];
    [formatter setMaximumFractionDigits: 0];
    
    // calculate new dim
    CGFloat newDimY = [[formatter numberFromString: gridDimensionsY.stringValue] integerValue];
    newDimY = MIN(20, MAX(2, newDimY));         // 2 <= widthVal <= 25
    [self setGridYInputBoxValue: newDimY];
    
    // save it in user defaults
    NSData *data = [defaultValues objectForKey: GDMainWindowGridUniversalDimensionsKey];
    NSSize oldDim = [[NSKeyedUnarchiver unarchiveObjectWithData: data] sizeValue];
    NSSize newDim = NSMakeSize(oldDim.width, newDimY);
    if (NSEqualSizes(newDim, oldDim)) {
        return;
    }
    [GDPreferenceController setGridDimensions: newDim];
}


- (void) setGridYInputBoxValue: (CGFloat) dimY {
    [gridDimensionsY setStringValue: [NSString stringWithFormat:@"%lu", (NSInteger)ceilf(dimY)]];
}



// misc tab callbacks

- (IBAction) changeStatusItemCheckBox: (id)sender {
    NSInteger state = [statusItemCheckBox state];
    [GDPreferenceController setStatusItemVisibility: state];
}


- (IBAction) changeDockIconCheckBox: (id)sender {
    NSInteger state = [dockIconCheckBox state];
    [GDPreferenceController setDockIconVisibility: state];
}




# pragma mark - USER DEFAULTS

+ (void) setUserDefaults {
    // archive necessary data
    NSSize mainWindowAbsSize = NSMakeSize(500, 400);
    NSData *mainWindowAbsSizeData = [NSKeyedArchiver archivedDataWithRootObject: [NSValue valueWithSize: mainWindowAbsSize]];
    NSSize mainWindowRelativeSize = NSMakeSize(0.2, 0.3);
    NSData *mainWindowRelativeSizeData = [NSKeyedArchiver archivedDataWithRootObject: [NSValue valueWithSize: mainWindowRelativeSize]];
    NSSize mainWindowAbsGridUniSize = NSMakeSize(7, 5);
    NSData *mainWindowAbsGridUniSizeData = [NSKeyedArchiver archivedDataWithRootObject: [NSValue valueWithSize: mainWindowAbsGridUniSize]];
    
	// create default dictionary
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	[defaultValues setObject: [NSNumber numberWithInteger: 1] // 0 = relative, 1 = abs
                      forKey: GDMainWindowTypeKey];
	[defaultValues setObject: mainWindowAbsSizeData
                      forKey: GDMainWindowAbsoluteSizeKey];
    [defaultValues setObject: mainWindowRelativeSizeData
                      forKey: GDMainWindowRelativeSizeKey];
    [defaultValues setObject: mainWindowAbsGridUniSizeData
                      forKey: GDMainWindowGridUniversalDimensionsKey];
	[defaultValues setObject: [NSNumber numberWithBool: NO]
                      forKey: GDDockIconVisibilityKey];
	[defaultValues setObject: [NSNumber numberWithBool: YES]
                      forKey: GDStatusItemVisibilityKey];
    
	// Register the dictionary of defaults
	[[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
}


+ (void) setMainWindowType: (NSUInteger) newType {
    // update user defaults
    [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInteger: newType]
                                              forKey: GDMainWindowTypeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // send notification
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName: GDMainWindowTypeChanged
                      object: self
                    userInfo: @{ @"info": [NSNumber numberWithBool: newType] }];
}


+ (void) setStatusItemVisibility: (BOOL) showItem {
    // update user defaults
    [[NSUserDefaults standardUserDefaults] setBool: showItem
                                            forKey: GDStatusItemVisibilityKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // send notification
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName: GDStatusItemVisibilityChanged
                      object: self
                    userInfo: @{ @"info": [NSNumber numberWithBool: showItem] }];
}


+ (void) setDockIconVisibility: (BOOL) showIcon {
    // update user defaults
    [[NSUserDefaults standardUserDefaults] setBool: showIcon
                                            forKey: GDDockIconVisibilityKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // send notification
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName: GDDockIconVisibilityChanged
                      object: self
                    userInfo: @{ @"info": [NSNumber numberWithBool: showIcon] }];
}


+ (void) setMainWindowRelativeSize: (NSSize) newSize {
    // update user defaults
    NSData *newRelativeSizeData = [NSKeyedArchiver archivedDataWithRootObject: [NSValue valueWithSize: newSize]];
    [[NSUserDefaults standardUserDefaults] setObject: newRelativeSizeData
                                              forKey: GDMainWindowRelativeSizeKey];
    
    // send notification
    NSValue *sizeValue = [NSValue valueWithSize: newSize];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName: GDMainWindowRelativeSizeChanged
                      object: self
                    userInfo: @{ @"info": sizeValue }];
}


+ (void) setMainWindowAbsoluteSize: (NSSize) newSize {
    // update user defaults
    NSData *newAbsSizeData = [NSKeyedArchiver archivedDataWithRootObject: [NSValue valueWithSize: newSize]];
    [[NSUserDefaults standardUserDefaults] setObject: newAbsSizeData
                                              forKey: GDMainWindowAbsoluteSizeKey];
    
    // send notification
    NSValue *sizeValue = [NSValue valueWithSize: newSize];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName: GDMainWindowAbsoluteSizeChanged
                      object: self
                    userInfo: @{ @"info": sizeValue }];
}


+ (void) setGridDimensions: (NSSize) newDimensions {
    // update user defaults
    NSData *newGridDimensions = [NSKeyedArchiver archivedDataWithRootObject: [NSValue valueWithSize: newDimensions]];
    [[NSUserDefaults standardUserDefaults] setObject: newGridDimensions
                                              forKey: GDMainWindowGridUniversalDimensionsKey];
    
    // send notification
    NSValue *sizeValue = [NSValue valueWithSize: newDimensions];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName: GDMainWindowGridUniversalDimensionsChanged
                      object: self
                    userInfo: @{ @"info": sizeValue }];
}

@end

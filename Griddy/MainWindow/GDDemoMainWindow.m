//
//  GDDemoMainWindow.m
//  Griddy
//
//  Created by Yan Sun on 2014-09-14.
//  Copyright (c) 2014 Sunnay. All rights reserved.
//

#import "GDDemoMainWindow.h"
#import "GDAppDelegate.h"
#import "GDGrid.h"
#import "GDScreen.h"





// ----------------------------
#pragma mark - GDDemoController
// ----------------------------

@interface GDDemoController () {
    NSMutableArray * _grids;
    NSMutableArray * _windowControllers;
}

@end

@implementation GDDemoController


- (id) init {
    self = [super init];
    if (self) {
        _grids = [self getGrids];
        _windowControllers = [self getWindowControllersFromGrids: _grids];
    }
    return self;
}


- (NSMutableArray *) getGrids {
    GDAppDelegate *appDelegate = (GDAppDelegate *)[[NSApplication sharedApplication] delegate];
    return appDelegate.grids;
}


- (NSMutableArray *) getWindowControllersFromGrids: (NSMutableArray *) grids {
    NSMutableArray * windowControllers = [[NSMutableArray alloc] initWithCapacity:1];
    
    for (int i = 0; i < grids.count; i++) {
        GDGrid *curGrid = [grids objectAtIndex: i];
        GDDemoMainWindowController *curWC = [[GDDemoMainWindowController alloc] initWithGrid: curGrid];
        [windowControllers addObject: curWC];
    }
    return windowControllers;
}




#pragma mark - WINDOW FUNCTIONS

- (void) launchWindows {
    for (NSUInteger i = 0; i < _windowControllers.count; i++) {
        [[_windowControllers objectAtIndex: i] showWindow: nil];
    }
}


- (void) launchWindowsBehindWindowLevel: (NSInteger) windowLevel {
    for (NSUInteger i = 0; i < _windowControllers.count; i++) {
        [[_windowControllers objectAtIndex: i] showWindow: nil BehindWindowLevel: windowLevel];
    }
}


- (void) hideWindows {
    for (NSUInteger i = 0; i < _windowControllers.count; i++) {
        GDDemoMainWindowController *curWC = [_windowControllers objectAtIndex: i];
        [curWC hideWindow];
    }
}

- (void) preventAllWindowHiding {
    for (NSUInteger i = 0; i < _windowControllers.count; i++) {
        [[_windowControllers objectAtIndex: i] preventHideWindow];
    }
}


- (void) enableAllWindowHiding {
    for (NSUInteger i = 0; i < _windowControllers.count; i++) {
        [[_windowControllers objectAtIndex: i] enableHideWindow];
    }
}


@end





// --------------------------------------
#pragma mark - GDDemoMainWindowController
// --------------------------------------

@interface GDDemoMainWindowController ()

@property (strong, nonatomic) GDGrid *grid;

@end



@implementation GDDemoMainWindowController


@synthesize grid = _grid;


#pragma mark - init

- (id) initWithGrid: (GDGrid *) grid {
    _grid = grid;
    
    GDDemoMainWindow *thisWindow = [[GDDemoMainWindow alloc] initWithGrid: grid];
    [thisWindow setWindowController: self];
    self = [super initWithWindow: thisWindow];
    if (self != nil) {
        [self listenToNotifications];
    }
    return self;
}


- (void) reinitWindow: (NSNotification *) note {
    // destroy previous window
    self.window = nil; // release last window
    NSInteger windowLevel = self.window.level;
    
    // make new window
    [_grid setupGridParams];
    GDDemoMainWindow *thisWindow = [[GDDemoMainWindow alloc] initWithGrid: _grid];
    [thisWindow setWindowController: self];
    self.window = thisWindow;
    
    [self showWindow: nil AtWindowLevel: windowLevel];
}



#pragma mark - notifications

- (void) listenToNotifications {
    // register for window events
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
//    [defaultCenter addObserver: self
//                      selector: @selector(windowUnfocused:)
//                          name: NSWindowDidResignMainNotification
//                        object: self.window];
//    [defaultCenter addObserver: self
//                      selector: @selector(reinitWindow:)
//                          name: GDMainWindowTypeChanged
//                        object: nil];
//    
//    [defaultCenter addObserver: self
//                      selector: @selector(reinitWindow:)
//                          name: GDMainWindowAbsoluteSizeChanged
//                        object: nil];
//    
//    [defaultCenter addObserver: self
//                      selector: @selector(reinitWindow:)
//                          name: GDMainWindowRelativeSizeChanged
//                        object: nil];
//    
//    [defaultCenter addObserver: self
//                      selector: @selector(reinitWindow:)
//                          name: GDMainWindowGridUniversalDimensionsChanged
//                        object: nil];
}


- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}


#pragma mark - displaying/hiding windows

- (void) showWindow: (id) sender {
    [super showWindow: sender];
    [self.window orderFront: sender];
    [NSApp activateIgnoringOtherApps: YES];
}


- (void) showWindow: (id) sender
      AtWindowLevel: (NSInteger) prevWindowLevel {
    [self.window setLevel: prevWindowLevel];
    [self.window display];
    [self.window orderFront: sender];
    [NSApp activateIgnoringOtherApps: YES];
}


- (void) showWindow: (id) sender
  BehindWindowLevel: (NSInteger) topWindowLevel {
    [self.window display];
    [self.window orderWindow: NSWindowBelow relativeTo: topWindowLevel];
    [NSApp activateIgnoringOtherApps: YES];
}


- (void) hideWindow {
    [self.window orderOut: nil];
}


- (void) preventHideWindow {
    [self.window setCanHide: NO];
}


- (void) enableHideWindow {
    [self.window setCanHide: YES];
}


@end





// ----------------------------------
#pragma mark - GDDemoMainWindow
// ----------------------------------

@implementation GDDemoMainWindow


- (id) initWithGrid: (GDGrid *)grid {
    NSRect contentFrame = [grid getMainWindowFrame];
    
    self = [super initWithContentRect: contentFrame
                            styleMask: NSBorderlessWindowMask
                              backing: NSBackingStoreBuffered
                                defer: NO];
    if (self != nil) {
        // window setup
        [self setStyleMask: NSBorderlessWindowMask];
        [self setHasShadow: NO];
        [self setOpaque: NO];
        [self setBackgroundColor: [NSColor clearColor]];
        [self setLevel: NSFloatingWindowLevel];
        
        [self setContentView: [[GDDemoMainWindowMainView alloc] initWithGDGrid: grid]];
    }
    
    return self;
}

- (BOOL) canBecomeKeyWindow {
    return NO;
}


- (BOOL) canBecomeMainWindow {
    return NO;
}


@end




// ----------------------------------
#pragma mark - GDMainWindowMainView
// ----------------------------------

@interface GDDemoMainWindowMainView() {
    GDDemoMainWindowAppInfoViewController *_appInfoViewController;
    GDDemoMainWindowCellCollectionView *_cellCollectionView;
}
@end



@implementation GDDemoMainWindowMainView


- (id) initWithGDGrid: (GDGrid *) grid {
    self = [super initWithFrame: [grid getMainWindowFrame]];
    
    if (self != nil) {
        // setup self
        self.wantsLayer = YES;
        self.layer.frame = self.frame;
        self.layer.cornerRadius = 15.0;
        self.layer.masksToBounds = YES;
        
        // setup app info view
        _appInfoViewController = [[GDDemoMainWindowAppInfoViewController alloc] initWithGrid: grid];
        [self addSubview: _appInfoViewController.view];
        
        // setup cell views
        _cellCollectionView = [[GDDemoMainWindowCellCollectionView alloc] initWithGrid: grid];
        [self addSubview: _cellCollectionView];
    }
    
    return self;
}


- (void) drawRect: (NSRect) dirtyRect {
    [[NSColor colorWithCalibratedRed: 0.0
                               green: 0.0
                                blue: 0.0
                               alpha: 0.6] set];
    NSRectFill(dirtyRect);
}


@end





// ----------------------------------
#pragma mark - GDMainWindowAppInfoView
// ----------------------------------

@implementation GDDemoMainWindowAppInfoViewController


- (id) initWithGrid: (GDGrid *) grid {
    self = [super initWithNibName: nil bundle: nil];
    
    if (self != nil) {
        GDDemoMainWindowAppInfoView *appInfoView = [[GDDemoMainWindowAppInfoView alloc] initWithGrid: grid];
        self.view = appInfoView;
    }
    return self;
}


@end



@implementation GDDemoMainWindowAppInfoView


- (id) initWithGrid: (GDGrid *) grid {
    self = [super initWithFrame: [grid getAppInfoFrame]];
    
    if (self != nil) {
        NSImageView *appIconView = [[NSImageView alloc] initWithFrame: [grid getAppIconFrame]];
        appIconView.imageScaling = NSImageScaleAxesIndependently;
        appIconView.image = [NSApp applicationIconImage];
        [self addSubview: appIconView];
        
        NSTextField *appNameView = [[NSTextField alloc] initWithFrame: [grid getAppNameFrame]];
        appNameView.bezeled = NO;
        appNameView.drawsBackground = NO;
        appNameView.editable = NO;
        appNameView.selectable = NO;
        appNameView.textColor = [NSColor whiteColor];
        appNameView.stringValue = @"Demo Application";
        [appNameView sizeToFit];
        [self addSubview: appNameView];
    }
    
    return self;
}

@end





// ----------------------------------
#pragma mark - GDDemoMainWindowCellCollectionView
// ----------------------------------

@implementation GDDemoMainWindowCellCollectionView


#pragma mark - INITIALIZATION

- (id) initWithGrid: (GDGrid *) grid {
    self = [super initWithFrame: [grid getCellCollectionRectFrame]];
    
    if (self != nil) {
        // setup self
        self.wantsLayer = YES;
        self.layer.frame = self.frame;
        self.layer.cornerRadius = 5.0;
        self.layer.masksToBounds = YES;
        
        // setup cells views
        for (NSInteger i = 0; i < (NSUInteger)grid.numCell.width; i++) {
            for (NSInteger j = 0; j < (NSUInteger)grid.numCell.height; j++) {
                NSRect cellFrame = [grid getCellViewFrameForCellX:i Y:j];
                NSView *cellFrameView = [[GDDemoCellView alloc] initWithFrame: cellFrame];
                [self addSubview: cellFrameView];
            }
        }
    }
    
    return self;
}


@end





// ----------------------------------
#pragma mark - GDDemoCellView
// ----------------------------------


@implementation GDDemoCellView


- (id) initWithFrame: (NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // init something
    }
    return self;
}


- (void) drawRect: (NSRect) dirtyRect {
    [[NSColor colorWithCalibratedRed: 0.0
                               green: 0.0
                                blue: 0.0
                               alpha: 0.5] set];
    NSRectFill(dirtyRect);
}

@end



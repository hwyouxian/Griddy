//
//  GDStatusItem.m
//  Griddy
//
//  Created by Yan Sun on 2014-08-19.
//  Copyright (c) 2014 Sunnay. All rights reserved.
//

#import "GDStatusItem.h"
#import "GDStatusPopoverMenuViewController.h"
#import "GDStatusPopoverPreferenceViewController.h"



#define kMinViewWidth 22
NSString * const StatusItemMenuOpened = @"GDStatusItemMenuOpened";
extern NSString * const GDStatusPopoverSettingsButtonSelected;
extern NSString * const GDStatusPopoverBackButtonSelected;





// ----------------------------------
#pragma mark - GDStatusItemController
// ----------------------------------

@implementation GDStatusItemController


@synthesize statusItemView = _statusItemView;
@synthesize curViewController = _curViewController;
@synthesize menuViewController = _menuViewController; // tag = 0
@synthesize preferenceViewController = _preferenceViewController; // tag = 1
@synthesize curViewTag = _curViewTag;


# pragma mark - INIT

- (id) initWithAction: (SEL) action
            andTarget: (id) target {
    self = [super init];
    if (self != nil) {
        [self notificationSetup];
        
        // setup first view controller
        NSViewController *newViewController = [self getMenuViewController];
        
        // setup statusItemView
        _statusItemView = [[GDStatusItemView alloc] initWithViewController: newViewController];
        [_statusItemView setAction: action toTarget: target];
        
    }
    return self;
}



# pragma mark - NOTIFICATIONS

- (void) notificationSetup {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self
           selector: @selector(onStatusItemPreferenceView:)
               name: GDStatusPopoverSettingsButtonSelected
             object: nil];
    [nc addObserver: self
           selector: @selector(onStatusItemMenuView:)
               name: GDStatusPopoverBackButtonSelected
             object: nil];
}


- (void) onStatusItemMenuView: (NSNotification *) note {
    [self changeViewController: 0];
}


- (void) onStatusItemPreferenceView: (NSNotification *) note {
    [self changeViewController: 1];
}



# pragma mark - STATUS ITEM

- (BOOL) isStatusItemMenuOpen {
    return _statusItemView.active;
}


- (void) hideStatusItem {
    [_statusItemView removeStatusItem];
    _statusItemView = nil;
    _menuViewController = nil;
}



# pragma mark - VIEWS

- (void) changeViewController: (NSUInteger) newViewTag {
    if (newViewTag == _curViewTag) {
        return;
    }
    
    NSViewController *newViewController;
    switch (newViewTag) {
        case 0:	{
            newViewController = [self getMenuViewController];
            break;
        }
            
        case 1:	{
            newViewController = [self getPreferenceViewController];
            break;
        }
    }
    [_statusItemView transitionToNewView: newViewController];
}


- (GDStatusPopoverMenuViewController *) getMenuViewController {
    if (_menuViewController == nil) {
        _menuViewController = [[GDStatusPopoverMenuViewController alloc] initWithNibName: @"GDStatusPopoverMenuView"
                                                                                  bundle: nil];
    }
    _curViewController = _menuViewController;
    _curViewTag = 0;
    return _menuViewController;
}


- (GDStatusPopoverPreferenceViewController *) getPreferenceViewController {
    if (_preferenceViewController == nil) {
        _preferenceViewController = [[GDStatusPopoverPreferenceViewController alloc] initWithNibName: @"GDStatusPopoverPreferenceView"
                                                                                              bundle: nil];
        _preferenceViewController.statusItemController = self;
    }
    _curViewController = _preferenceViewController;
    _curViewTag = 1;
    return _preferenceViewController;
}


@end





// ----------------------------------
#pragma mark - GDStatusItemView
// ----------------------------------

@interface GDStatusItemView () {
    NSViewController *_menuViewController;
    NSImageView *_imageView;
    NSImage *_image;
    NSImage *_alternateImage;
    NSStatusItem *_statusItem;
    NSPopover *_popover;
    id _popoverTransiencyMonitor;
    SEL _actionL;
    id _targetL;
}
@end



@implementation GDStatusItemView


@synthesize active = _active;


- (id) initWithViewController: (NSViewController *) controller {
    
    CGFloat height = [NSStatusBar systemStatusBar].thickness;
    
    self = [super initWithFrame:NSMakeRect(0, 0, kMinViewWidth, height)];
    if (self) {
        _menuViewController = controller;
        
        _image = [NSImage imageNamed:@"statusitem-a"];
        _alternateImage = [NSImage imageNamed:@"statusitem-b"];
        
        _imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, kMinViewWidth, height)];
        [self addSubview:_imageView];
        
        _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        _statusItem.view = self;
        self.active = NO;
    }
    return self;
}


- (void) drawRect:(NSRect)dirtyRect {
    // set view background color
    if (_active) {
        [[NSColor selectedMenuItemColor] setFill];
    } else {
        [[NSColor clearColor] setFill];
    }
    NSRectFill(dirtyRect);
    
    // set image
    NSImage *image = (_active ? _alternateImage : _image);
    _imageView.image = image;
}


- (void) setContentSize: (CGSize)size {
    _popover.contentSize = size;
}



#pragma mark - MOUSE EVENTS

- (void) mouseDown: (NSEvent *)theEvent {
    self.active = YES;
}


- (void) mouseUp: (NSEvent *) theEvent {
    self.active = NO;
    if (_popover.isShown) {
        [self hidePopover];
    } else {
        [NSApp sendAction: _actionL to: _targetL from: self];
    }
}


- (void) rightMouseDown: (NSEvent *)theEvent {
    if (_popover.isShown) {
        [self hidePopover];
    } else {
        [self showPopover];
    }
}


- (void) setAction: (SEL) action
           toTarget: (id) target {
    _actionL = action;
    _targetL = target;
}


- (void) setActive: (BOOL)active {
    _active = active;
    [self setNeedsDisplay: YES];
}



#pragma mark - MOUSE EVENTS

- (void) setImage:(NSImage *)image {
    _image = image;
    [self updateViewFrame];
}


- (void) setAlternateImage:(NSImage *)image {
    _alternateImage = image;
    if (!image && _image) {
        _alternateImage = _image;
    }
    [self updateViewFrame];
}


- (void) updateViewFrame {
    CGFloat width = MAX(MAX(kMinViewWidth, _alternateImage.size.width), _image.size.width);
    CGFloat height = [NSStatusBar systemStatusBar].thickness;
    
    NSRect frame = NSMakeRect(0, 0, width, height);
    self.frame = frame;
    _imageView.frame = frame;
    
    [self setNeedsDisplay:YES];
}


- (void) showPopover {
    self.active = YES;
    
    if (!_popover) {
        _popover = [[NSPopover alloc] init];
        _popover.contentViewController = _menuViewController;
    }
    
    if (!_popover.isShown) {
        _popover.animates = YES;
        [_popover showRelativeToRect: self.frame
                              ofView: self
                       preferredEdge: NSMinYEdge];
        _popoverTransiencyMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask: NSLeftMouseDownMask|NSRightMouseDownMask handler:^(NSEvent* event) {
            [self hidePopover];
        }];
        
        // post notification
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName: StatusItemMenuOpened
                          object: self];
    }
}


- (void) hidePopover {
    self.active = NO;
    if (_popover && _popover.isShown) {
        _popover.contentViewController = _menuViewController;
        [_popover close];
		if (_popoverTransiencyMonitor) {
            [NSEvent removeMonitor:_popoverTransiencyMonitor];
            _popoverTransiencyMonitor = nil;
        }
    }
}


- (void) transitionToNewView: (NSViewController *) newViewController {
    _popover.contentViewController = newViewController;
    _popover.contentViewController.view.needsDisplay = YES;
}


- (void) removeStatusItem {
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    [bar removeStatusItem: _statusItem];
    _statusItem = nil;
}


@end

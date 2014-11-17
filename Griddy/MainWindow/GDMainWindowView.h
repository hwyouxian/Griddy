//
//  GDMainWindowView.h
//  Griddy
//
//  Created by Yan Sun on 2014-07-13.
//  Copyright (c) 2014 Sunnay. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class GDGrid;



// ----------------------------------
#pragma mark - GDMainWindowMainView
// ----------------------------------

@interface GDMainWindowMainView : NSVisualEffectView

- ( id ) initWithGDGrid: ( GDGrid * ) grid;

@end



// ----------------------------------
#pragma mark - GDMainWindowAppInfoView
// ----------------------------------
@interface GDMainWindowAppInfoViewController : NSViewController

- ( id ) initWithGDGrid: ( GDGrid * ) grid;

@end


@interface GDMainWindowAppInfoView : NSView

- ( id ) initWithGDGrid: ( GDGrid * ) grid;
- ( void ) newApp: ( NSRunningApplication * ) newApp;

@end



// ----------------------------------
#pragma mark - GDMainWindowCellCollectionView
// ----------------------------------

@interface GDMainWindowCellCollectionView : NSView

- (id) initWithGDGrid: (GDGrid *)grid;

@end



// ----------------------------------
#pragma mark - GDCellView
// ----------------------------------

@interface GDCellView : NSView

@property NSPoint viewPosition;
- (id)initWithFrame: (NSRect)frame
       andPositionX: (NSInteger)x
       andPositionY: (NSInteger)y;
@end

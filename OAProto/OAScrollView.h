//
//  OAScrollView.h
//  OAProto
//
//  Created by Ivan Touzeau on 15/10/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//
//  OAScrollView is the view that displays the scanned page.
//  Annotation thumbnails and shapes are inserted as CALayers.
//
//  Actually the page is resized at 0.25 of its original scale, and the visible portion
//  of the area is drawn upon this view in background using updateHiResView
//
//  To do :
//  - cache the high res zones already computed, to avoid recomputing these zones
//  - optimize the first resize ( actually fixed to 0.25 ) in order to handle bigger images

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class EditViewController;

enum DisplayMode {
    
    kDisplayModeUnknown,
    
    kDisplayModePage,                   // only the page bitmap ( unused )
    
    kDisplayModeNotesThumbnails,        // notes thumbnails
    kDisplayModeNotesShapes,            // all notes shapes  ( unused )
    
    kDisplayModeNote,                   // selected note, display
    
    kDisplayModeEditNote,               // selected note, edit
    kDisplayModeEditRectangle,          // this and below : shpe edit modes.
    kDisplayModeEditEllipse,
    kDisplayModeEditFree,
    kDisplayModeEditPolygon,
    kDisplayModeEditPoint,              // ( unused )
    kDisplayModeBezier,                 // ( unused )
    kDisplayModeBezierQuad,             // ( unused )
    kDisplayModeEditMagicWand
};
typedef enum DisplayMode DisplayMode;

#define IMAGE_MARGIN                80.0f
#define DOUBLETAP_DELAY             0.25f
#define MULTITOUCH_DELAY            0.1f

@interface OAScrollView : UIScrollView <UIScrollViewDelegate> {
    
    CALayer                     * thumbnailsLayer;
    CALayer                     * shapesLayer;
};

- (id) initWithFrame:(CGRect)frame editController:(EditViewController *)controller;

- (void) updateLayers;
- (void) updateHiResView;
- (void) invalidateHiResDeferredUpdates;

@property (nonatomic,retain)    CALayer                     * thumbnailsLayer;
@property (nonatomic,retain)    CALayer                     * shapesLayer;
@property (nonatomic,retain)    CALayer                     * maskLayer;

@end

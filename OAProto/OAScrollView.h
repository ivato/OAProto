/*
 
 
 
 
*/

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

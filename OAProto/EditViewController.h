//
//  EditViewController.h
//  OAProto
//
//  Created by Ivan Touzeau on 15/10/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSTCollectionView.h"
#import "OAScrollView.h"

@class OAScrollView, ZoomView, OpenAnnotation, OAShape, Page;

#define LEFTPANEL_WIDTH             290.0f
#define UPPERPANEL_HEIGHT           270.0f
#define LEFTPANEL_SCROLL_OFFSET      88.0f

#define DISABLED_SHAPE_BUTTONS_ALPHA  0.5f

@protocol EditControllerDelegate <NSObject>

@optional

- (void) onImageResized;

@end

@interface EditViewController : UIViewController <UIPopoverControllerDelegate, UIActionSheetDelegate, PSUICollectionViewDataSource, PSUICollectionViewDelegate> {
    
    id<EditControllerDelegate>                delegate;
    
    OAScrollView                            * editView;
    ZoomView                                * zoomView;
    
    NSMutableArray                          * notes;
    OpenAnnotation                          * selectedNote;
    Page                                    * page;
    UIImage                                 * resizedImage;
    
    DisplayMode                               mode;
    DisplayMode                               previousMode;
    
    UIActivityIndicatorView                 * hiresActivityIndicator;
    
    IBOutlet UIButton                       * shapeRectButton;
    IBOutlet UIButton                       * shapeEllipseButton;
    IBOutlet UIButton                       * shapeFreeButton;
    IBOutlet UIButton                       * shapePolyButton;
    IBOutlet UIButton                       * shapeEndButton;
    IBOutlet UIButton                       * shapeCloseButton;
    IBOutlet UIButton                       * shapeDeleteButton;
    IBOutlet UIButton                       * shapeMWButton;
    
    IBOutlet UILabel                        * mwToleranceLabel;
    IBOutlet UISlider                       * mwToleranceSlider;
    IBOutlet UIActivityIndicatorView        * mwActivityIndicator;
    
    IBOutlet UIButton                       * testButton;
    
    IBOutlet UIToolbar                      * toolbarView;
    IBOutlet UIView                         * panelView;
    IBOutlet UIScrollView                   * panelScrollView;
    IBOutlet UIView                         * pageNavigationView;
    IBOutlet UIView                         * annotationNavigationView;
    
    IBOutlet UIBarButtonItem                * displayToolsItem;
    IBOutlet UIBarButtonItem                * addNoteItem;
    IBOutlet UIBarButtonItem                * thumbnailsNodeItem;
    IBOutlet UIBarButtonItem                * editNoteTextItem;
    IBOutlet UIBarButtonItem                * notesNavigationItem;
    IBOutlet UIBarButtonItem                * deleteNoteItem;
    IBOutlet UIBarButtonItem                * cancelNoteItem;
    IBOutlet UIBarButtonItem                * fs; // flexible space
    
    IBOutlet UIView                         * shapeEditView;
    IBOutlet UIButton                       * editButton;
    IBOutlet UIButton                       * cancelEditButton;
    IBOutlet UIButton                       * saveEditButton;
    
    IBOutlet UITextView                     * titleTextField;
    IBOutlet UITextView                     * contentTextField;
        
}

- (void)        updateNoteTitle:(NSString *)str;
- (void)        updateZoomView;
- (void)        updateZoomComposite;

- (void)        popoverDidSelectNote:(OpenAnnotation *)note;
- (void)        selectNote:(OpenAnnotation *)note;
- (void)        selectShape:(OAShape *)shape;

- (OAShape *)   selectedShape;

- (void)        findShapeAt:(CGPoint)point;

- (void)        setPage:(Page *)page;

- (BOOL)        orientationIsLandscape;

- (void)        dismissKeyboardAndNavigationView;

- (UIImage *)   image;
- (UIImage *)   resizedImage;

@property (nonatomic,retain)            id                                delegate;

@property (nonatomic,retain)            UIImage                         * resizedImage;

@property (nonatomic,retain)            UIActivityIndicatorView         * hiresActivityIndicator;

@property (nonatomic,retain) IBOutlet   UIButton                        * shapeRectButton;
@property (nonatomic,retain) IBOutlet   UIButton                        * shapeEllipseButton;
@property (nonatomic,retain) IBOutlet   UIButton                        * shapeFreeButton;
@property (nonatomic,retain) IBOutlet   UIButton                        * shapePolyButton;
@property (nonatomic,retain) IBOutlet   UIButton                        * shapeEndButton;
@property (nonatomic,retain) IBOutlet   UIButton                        * shapeCloseButton;
@property (nonatomic,retain) IBOutlet   UIButton                        * shapeDeleteButton;
@property (nonatomic,retain) IBOutlet   UIButton                        * shapeMWButton;

@property (nonatomic,retain) IBOutlet   UILabel                         * mwToleranceLabel;
@property (nonatomic,retain) IBOutlet   UISlider                        * mwToleranceSlider;
@property (nonatomic,retain) IBOutlet   UIActivityIndicatorView         * mwActivityIndicator;

@property (nonatomic,retain) IBOutlet   UIBarButtonItem                 * displayToolsItem;
@property (nonatomic,retain) IBOutlet   UIBarButtonItem                 * thumbnailsNodeItem;
@property (nonatomic,retain) IBOutlet   UIBarButtonItem                 * addNoteItem;
@property (nonatomic,retain) IBOutlet   UIBarButtonItem                 * editNoteTextItem;
@property (nonatomic,retain) IBOutlet   UIBarButtonItem                 * notesNavigationItem;
@property (nonatomic,retain) IBOutlet   UIBarButtonItem                 * deleteNoteItem;
@property (nonatomic,retain) IBOutlet   UIBarButtonItem                 * cancelNoteItem;
@property (nonatomic,retain) IBOutlet   UIBarButtonItem                 * fs; // flexible space

@property (nonatomic,retain) IBOutlet   UIView                          * shapeEditView;
@property (nonatomic,retain) IBOutlet   UIButton                        * editButton;
@property (nonatomic,retain) IBOutlet   UIButton                        * cancelEditButton;
@property (nonatomic,retain) IBOutlet   UIButton                        * saveEditButton;
@property (nonatomic,retain) IBOutlet   UIButton                        * deleteEditButton;
@property (nonatomic,retain) IBOutlet   UITextView                      * titleTextField;
@property (nonatomic,retain) IBOutlet   UITextView                      * contentTextField;

@property (nonatomic,retain) IBOutlet   UIButton                        * testButton;
@property (nonatomic,retain) IBOutlet   UIToolbar                       * toolbarView;
@property (nonatomic,retain) IBOutlet   UIView                          * panelView;
@property (nonatomic,retain) IBOutlet   UIScrollView                    * panelScrollView;
@property (nonatomic,retain) IBOutlet   UIView                          * pageNavigationView;
@property (nonatomic,retain) IBOutlet   UIView                          * annotationNavigationView;


@property (nonatomic,retain)            OAScrollView                    * editView;
@property (nonatomic,retain)            ZoomView                        * zoomView;

@property (nonatomic,retain)            NSMutableArray                  * notes;
@property (nonatomic,retain)            OpenAnnotation                  * selectedNote;
@property (nonatomic,retain)            Page                            * page;

@property (nonatomic,assign)            DisplayMode                       mode;
@property (nonatomic,assign)            DisplayMode                       previousMode;

@end

//
//  EditViewController.m
//  OAProto
//

//  Created by Ivan Touzeau on 15/10/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import "OAProtoAppDelegate.h"
#import "PanelsViewController.h"
#import "ZoomView.h"
#import "EditViewController.h"
#import "NotesViewController.h"
#import "OAScrollView.h"
#import "OpenAnnotation.h"
#import "OAShape.h"

#import "PageViewCell.h"

#import "DataWrapper.h"
#import "Book.h"
#import "Page.h"
#import "User.h"
#import "Note.h"

#import "UIImage+Resize.h"

#import <opencv2/imgproc/imgproc_c.h>
#import <opencv2/objdetect/objdetect.hpp>

#define VIEWTAG_PAGESCV         99
#define VIEWTAG_PAGES          100
#define VIEWTAG_BACKALERT      101

@interface EditViewController ()
{
                              // for memory usage comparison
    BOOL                      autoClosePagesOnPageSelect;
    
    BOOL                      noteIsNew;
    UIPopoverController     * notesPopoverController;
    NSArray                 * pagesDataSource;
    PageViewCell            * selectedPageCell;
    
    UIActionSheet           * actionSheet;
    BOOL                      sheetVisible;
    
    UIBarButtonItem         * pagesNavigationItem;
    UIBarButtonItem         * hiresActivityItem;
    
}

@property (nonatomic,retain) UIBarButtonItem                            * hiresActivityItem;
@property (nonatomic,retain) UIImage                                    * image;
@property (nonatomic,retain) UIBarButtonItem                            * toggleDisplayItem;
@property (nonatomic,retain) UIBarButtonItem                            * noteStepperItem;
@property (nonatomic,assign) UIButton                                   * prevShapeButtonClicked;
@property (nonatomic,retain) UIPopoverController                        * notesPopoverController;
@property (nonatomic,retain) NSArray                                    * pagesDataSource;
@property (nonatomic,assign) PageViewCell                               * selectedPageCell;
@property (nonatomic,retain) UIActionSheet                              * actionSheet;
@property (nonatomic,retain) UIBarButtonItem                            * pagesNavigationItem;

@end

@implementation EditViewController

@synthesize delegate;
@synthesize resizedImage;
@synthesize previousMode,mode;

@synthesize notesPopoverController,pagesDataSource,selectedPageCell,actionSheet, pagesNavigationItem;
@synthesize shapeRectButton,shapeEllipseButton,shapeFreeButton,shapePolyButton,shapeEndButton,shapeCloseButton,shapeMoveImageButton,shapeDeleteButton,shapeMWButton;
@synthesize mwToleranceLabel,mwToleranceSlider,mwActivityIndicator;
@synthesize hiresActivityIndicator,hiresActivityItem;

@synthesize displayToolsItem,addNoteItem,thumbnailsNodeItem,noteStepperItem,editNoteTextItem,notesNavigationItem,cancelNoteItem,deleteNoteItem,fs;
@synthesize toggleDisplayItem;

@synthesize testButton;
@synthesize pageNavigationView, annotationNavigationView, toolbarView, panelView, panelScrollView ;

@synthesize editView,zoomView;

@synthesize shapeEditView,editButton,cancelEditButton,saveEditButton,deleteEditButton,titleTextField,contentTextField;

@synthesize image,notes,selectedNote,page;

@synthesize noteIsModified,handToolSelected;

static NSString * cellIdentifier            = @"Page Cell";

static NSString * NSStringFromDisplayMode(DisplayMode m)
{
    switch (m) {
        case kDisplayModeUnknown                : return @"kDisplayModeUnknown";
        case kDisplayModePage                   : return @"kDisplayModePage";
        case kDisplayModeNotesThumbnails        : return @"kDisplayModeNotesThumbnails";
        case kDisplayModeNotesShapes            : return @"kDisplayModeNotesShapes";
        case kDisplayModeNote                   : return @"kDisplayModeNote";
        case kDisplayModeEditNote               : return @"kDisplayModeEditNote";
        case kDisplayModeEditRectangle          : return @"kDisplayModeEditRectangle";
        case kDisplayModeEditEllipse            : return @"kDisplayModeEditEllipse";
        case kDisplayModeEditFree               : return @"kDisplayModeEditFree";
        case kDisplayModeEditPolygon            : return @"kDisplayModeEditPolygon";
        case kDisplayModeEditPoint              : return @"kDisplayModeEditPoint";
        case kDisplayModeBezier                 : return @"kDisplayModeBezier";
        case kDisplayModeEditMagicWand          : return @"kDisplayModeEditMagicWand";
            
        default:return @"DisplayMode value not found";
        
    }
}

- (void) setMode:(DisplayMode)newMode
{
    [self setPreviousMode:self.mode];
    self->mode = newMode;
    
    //
    BOOL forceUpdate = YES;
    
    if ( newMode != self->previousMode || self->previousMode == kDisplayModeUnknown || forceUpdate ){
        
        BOOL editing = !(mode == kDisplayModePage ||
                         mode == kDisplayModeNotesThumbnails ||
                         mode == kDisplayModeNotesShapes ||
                         mode == kDisplayModeNote
                         );
        
        if ( forceUpdate && newMode == self->previousMode ){
            //NSLog(@"sans le forceUpdate, là, il ne se serait rien passé.");
        }
        
        NSArray * array = nil;
        
        [shapeEditView setHidden:NO];
        [UIView beginAnimations:@"shapeview_fade_animation" context:nil];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [addNoteItem setEnabled:!editing];
        [noteStepperItem setEnabled:self.notes.count>1 && !editing];
        
        if ( editing ){
            
            [titleTextField setTextColor:[UIColor blackColor]];
            [titleTextField setBackgroundColor:[UIColor whiteColor]];
            [contentTextField setTextColor:[UIColor blackColor]];
            [contentTextField setBackgroundColor:[UIColor whiteColor]];
            [shapeEditView setAlpha:1.0f];
            
            [saveEditButton setHidden:NO];
            [cancelEditButton setHidden:NO];
            [deleteEditButton setHidden:noteIsNew];
            [editButton setHidden:YES];
            
            self.shapeCloseButton.hidden = newMode != kDisplayModeEditFree && newMode != kDisplayModeEditPolygon;
            self.shapeCloseButton.enabled = NO;
            self.shapeCloseButton.alpha = DISABLED_SHAPE_BUTTONS_ALPHA;
            
            self.shapeEndButton.hidden = newMode != kDisplayModeEditFree && newMode != kDisplayModeEditPolygon;
            self.shapeEndButton.enabled = NO;
            self.shapeEndButton.alpha = DISABLED_SHAPE_BUTTONS_ALPHA;
            
            self.shapeMoveImageButton.hidden = newMode != kDisplayModeEditFree && newMode != kDisplayModeEditPolygon;
            
            self.mwToleranceLabel.hidden = self.mwToleranceSlider.hidden = (newMode!=kDisplayModeEditMagicWand);
            
            array = [NSArray arrayWithObjects:displayToolsItem,fs,hiresActivityItem,fs,nil];
            
            if ( newMode == kDisplayModeEditNote ){
                [displayToolsItem setTitle:@"hide tools"];
                [self toggleShapePanel:1];
            }
            
        } else {
            
            [titleTextField setTextColor:[UIColor whiteColor]];
            [titleTextField setBackgroundColor:[UIColor clearColor]];
            [contentTextField setTextColor:[UIColor whiteColor]];
            [contentTextField setBackgroundColor:[UIColor clearColor]];
            [shapeEditView setAlpha:0.0f];
            [self selectShape:nil];
            
            DataWrapper * wrapper = [(OAProtoAppDelegate *)[[UIApplication sharedApplication] delegate] wrapper];
            [editButton setHidden:![wrapper noteIsEditable:selectedNote]];
            [saveEditButton setHidden:YES];
            [cancelEditButton setHidden:YES];
            [deleteEditButton setHidden:YES];
            
            array = [NSArray arrayWithObjects:displayToolsItem,fs,hiresActivityItem,fs,noteStepperItem,addNoteItem,thumbnailsNodeItem,nil];
            
            if ( newMode == kDisplayModeNotesThumbnails ){
                array = [NSArray arrayWithObjects:fs,hiresActivityItem,fs,addNoteItem,nil];
                [self toggleShapePanel:-1];
                [self.editView zoomToRect:CGRectMake(0, 0, image.size.width, image.size.height) animated:YES];
            }
        }
        
        
        [toolbarView setItems:array animated:YES];
        
        
        if ( newMode == kDisplayModeEditNote ){
            if ( self.prevShapeButtonClicked ){
                [self.prevShapeButtonClicked setHighlighted:NO];
                self.prevShapeButtonClicked = nil;
            }
        }
        [UIView commitAnimations];
        [self.panelScrollView setScrollEnabled:editing];
        [self.titleTextField setEditable:editing];
        [self.contentTextField setEditable:editing];
        
    }
    [editView updateLayers];
    [self.zoomView updateCompositeForNote:self.selectedNote];
    [editView setNeedsLayout];
}

- (UIImage *) image
{
    return image;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( alertView.tag == VIEWTAG_BACKALERT ){
        // if buttonIndex == 0, user clicked on cancel, so don't go back to home.
        if ( buttonIndex > 0 ){
            if ( buttonIndex == 1 ){
                // user has clicked "don't save"
                if ( noteIsNew ){
                    [self deleteNote:self.selectedNote];
                } else {
                    [self.selectedNote revertToSaved];
                }
            }
            else if ( buttonIndex == 2 ){
                // user has clicked "save"
                [self saveNote];
            }
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}


- (void) dismissKeyboardAndNavigationView
{
    [self.panelScrollView endEditing:YES];
    if ( self.pageNavigationView.superview )
        [self togglePagesView];
}

// NOTE you SHOULD cvReleaseImage() for the return value when end of the code.
- (IplImage *)CreateIplImageFromUIImage:(UIImage *)img {
	
    CGImageRef imageRef = img.CGImage;
    
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	IplImage *iplimage = cvCreateImage(cvSize(img.size.width, img.size.height), IPL_DEPTH_8U, 4);
	CGContextRef contextRef = CGBitmapContextCreate(iplimage->imageData, iplimage->width, iplimage->height,
													iplimage->depth, iplimage->widthStep,
													colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault);
	CGContextDrawImage(contextRef, CGRectMake(0, 0, img.size.width, img.size.height), imageRef);
	CGContextRelease(contextRef);
	CGColorSpaceRelease(colorSpace);
    
	IplImage *retval = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
	cvCvtColor(iplimage, retval, CV_RGBA2BGR);
	cvReleaseImage(&iplimage);
    
	return retval;
}

- (void) findShapeAt:(CGPoint)point
{
	
    CGFloat tolerance = self.mwToleranceSlider.value; // -1 > 1
    [[self mwActivityIndicator] startAnimating];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{

        NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
        
        cvSetErrMode(CV_ErrModeParent);        
        UIImage * baseImage;
        CGRect r = CGRectZero;
        
        if ( CGPointEqualToPoint(point, CGPointMake(-1, -1))){
            // tests calibration
            baseImage = [UIImage imageNamed:@"testcolor.png"];
        } else {
            r.origin.x = fmaxf(0,fminf(image.size.width-MW_MAXRECTSIZE,point.x-MW_MAXRECTSIZE/2));
            r.origin.y = fmaxf(0,fminf(image.size.height-MW_MAXRECTSIZE,point.y-MW_MAXRECTSIZE/2));
            r.size.width = fminf(MW_MAXRECTSIZE,image.size.width-r.origin.x);
            r.size.height = fminf(MW_MAXRECTSIZE,image.size.height-r.origin.y);
            baseImage = [image croppedImage:r];
        }
        
        IplImage *img_color = [self CreateIplImageFromUIImage:baseImage];
        
        //cvSmooth(img_color, img_color, CV_GAUSSIAN, 3, 3, 0, 0);
        
        CvSize     size   = cvGetSize(img_color);
        
        CvSize    mSize   = cvSize(size.width+2, size.height+2);
        IplImage * mask   = cvCreateImage( mSize, 8, 1);
        cvZero(mask);
        
        CvPoint mwPoint = cvPoint( (int)(point.x-r.origin.x), (int)(point.y-r.origin.y) );
        CvScalar newVal = CV_RGB(255, 255, 255);
        CvScalar loDiff = cvScalarAll(tolerance);
        CvScalar hiDiff = cvScalarAll(tolerance);
        
        cvFloodFill(img_color, mwPoint, newVal, loDiff, hiDiff, NULL, 4 | 255 << 8, mask);
        cvReleaseImage(&img_color);
        
        // Find each unique contour
        CvSeq * firstContour = NULL;
        CvMemStorage * storage = cvCreateMemStorage(0);
        int contours = cvFindContours(mask, storage, (CvSeq **)&firstContour, sizeof(CvContour), CV_RETR_TREE, CV_CHAIN_APPROX_TC89_KCOS,  cvPoint(0, 0));      // modifies images
        cvReleaseImage(&mask);
        
        uint numElements = 0, numContours = 0;
        CvSeq * firstHole;
        
        if ( contours > 0 ){
            
            if ( CGSizeEqualToSize(CGSizeFromSeqContour(firstContour),CGSizeMake(MW_MAXRECTSIZE, MW_MAXRECTSIZE)) == NO ){
                numElements = firstContour->total+1, numContours = 1;
                firstHole = firstContour->v_next;
                for( CvSeq * c = firstHole; c != NULL; c = c->h_next ){
                    CGSize s = CGSizeFromSeqContour(c);
                    if ( s.width > 10 && s.height > 10 ){
                        numContours++;
                        numElements+=c->total+1;
                    }
                };
            }
        }
        
        OAShape * shape = nil;
        
        if ( numContours>0 && numContours<20 ) {
            
            CGPathElement * elements = malloc(sizeof(CGPathElement)*numElements);
            uint j = 0;
            elements[j++] = CGPathElementCreate(kCGPathElementMoveToPoint, CGPointFromSeqContour(firstContour,0,r.origin));
            for( int i=1; i<firstContour->total; ++i ){
                elements[j++] = CGPathElementCreate(kCGPathElementAddLineToPoint, CGPointFromSeqContour(firstContour,i,r.origin));
            }
            elements[j++] = CGPathElementCreate(kCGPathElementCloseSubpath, CGPointZero);
            firstHole = firstContour->v_next;
            for( CvSeq * c = firstHole; c != NULL; c = c->h_next ){
                CGSize s = CGSizeFromSeqContour(c);
                if ( s.width > 10 && s.height > 10 ){
                    elements[j++] = CGPathElementCreate(kCGPathElementMoveToPoint, CGPointFromSeqContour(c,0,r.origin));
                    for( int i=1; i<c->total; ++i ){
                        elements[j++] = CGPathElementCreate(kCGPathElementAddLineToPoint, CGPointFromSeqContour(c,i,r.origin));
                    }
                    elements[j++] = CGPathElementCreate(kCGPathElementCloseSubpath, CGPointZero);
                }
            };
            
            shape = [[OAShape alloc] initWithType:kShapeTypePath elements:elements length:numElements];
            
            free(elements);
            
        }

        cvReleaseMemStorage(&storage);
        
        [pool release];

        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[self mwActivityIndicator] stopAnimating];
            
            if ( shape ){
                [[self selectedNote] addShape:shape];
                [shape release];
            } else if ( numContours==0 || numContours>20 ){
                
                [self showAlertWithTitle:(numContours==0 ? @"EDIT_ALERT_MV_TITLE_NOFOUND" : @"EDIT_ALERT_MV_TITLE_TOOMUCHFOUND")
                                 message:(numContours==0 ? @"EDIT_ALERT_MV_TEXT_NOFOUND" : @"EDIT_ALERT_MV_TEXT_TOOMUCHFOUND")
                 ];
                
            }
            [self selectShape:nil];
            [self setMode:kDisplayModeEditNote];
        });
    });
}

- (void) showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertView * alert = [[UIAlertView alloc]
                          initWithTitle: NSLocalizedString(title, nil)
                          message: NSLocalizedString(message, nil)
                          delegate: nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

- (void) dealloc
{
    [hiresActivityIndicator release];
    [hiresActivityItem release];
    [pagesNavigationItem release];
    [notesPopoverController release];
    [toolbarView release];
    [panelView release];
    [image release];
    [resizedImage release];
    [selectedNote release];
    [notes release];
    [page release];
    [pagesDataSource release];
    [super dealloc];
}

- (void)doHighlight:(UIButton *)b {
    [b setHighlighted:YES];
}

- (IBAction) onShapeButtonClicked:(id)sender
{
    //uint tag = [(UIView*)sender tag];
    DisplayMode nextMode = kDisplayModeUnknown;
    if ( sender == shapeMoveImageButton ){
        if ( mode == kDisplayModeEditPolygon || mode == kDisplayModeEditFree ){
            handToolSelected = !handToolSelected;
            if ( handToolSelected ){
                [self performSelector:@selector(doHighlight:) withObject:sender afterDelay:0];
            } else {
                [shapeMoveImageButton setHighlighted:NO];
            };
        }
        // exit now to avoid setMode. 
        return;
    }
    else if ( sender == shapeCloseButton ){
        if ( mode == kDisplayModeEditPolygon || mode == kDisplayModeEditFree ){
            [selectedNote.selectedShape closePath];
            [self selectShape:nil];
            nextMode = kDisplayModeEditNote;
        }
    }
    else if ( sender == shapeDeleteButton ){
        OAShape * shapeToDelete = selectedNote.selectedShape;
        if ( shapeToDelete ){
            [self selectShape:nil];
            [selectedNote removeShape:shapeToDelete];
            [editView updateLayers];
            [self.zoomView updateCompositeForNote:selectedNote];
            nextMode = kDisplayModeEditNote;
        };
    } else if ( sender == shapeEndButton ){
        if ( self.prevShapeButtonClicked )
            [self.prevShapeButtonClicked setHighlighted:NO];
        [self selectShape:nil];
        [self setPrevShapeButtonClicked:sender];
        nextMode = kDisplayModeEditNote;
    } else {
        // all other cases ...
        if ( self.prevShapeButtonClicked )
            [self.prevShapeButtonClicked setHighlighted:NO];
        [self performSelector:@selector(doHighlight:) withObject:sender afterDelay:0];
        [self setPrevShapeButtonClicked:sender];
        [self selectShape:nil];
        if ( sender == shapeMWButton ){
            nextMode = kDisplayModeEditMagicWand;
        }
        if ( sender == shapeRectButton ){
            nextMode = kDisplayModeEditRectangle;
        }
        if ( sender == shapeEllipseButton ){
            nextMode = kDisplayModeEditEllipse;
        }
        if ( sender == shapeFreeButton ){
            nextMode = kDisplayModeEditFree;
        }
        if ( sender == shapePolyButton ){
            nextMode = kDisplayModeEditPolygon;
        }
    }
    [self setMode:nextMode];
}

- (void) updateZoomComposite
{
    [self.zoomView updateCompositeForNote:selectedNote];
}

- (void) selectShape:(OAShape *)shape
{
    if ( self.selectedNote ){
        [self.selectedNote setSelectedShape:shape];
        [self.shapeDeleteButton setEnabled:shape!=nil];
    };
    if ( shape == nil ){
        NSArray * shapeButtons = [NSArray arrayWithObjects:shapeRectButton,shapeEllipseButton,shapePolyButton,shapeFreeButton,shapeMWButton,shapeDeleteButton,nil];
        for ( UIButton * button in shapeButtons )
            [button setHighlighted:NO];
        self.prevShapeButtonClicked = nil;
    }
}

- (OAShape *) selectedShape
{
    return selectedNote ? selectedNote.selectedShape : nil;
}

- (void) selectNote:(OpenAnnotation *)note
{
    [self.zoomView updateCompositeForNote:note];
    [self setSelectedNote:note];
    
    DataWrapper * wrapper = [(OAProtoAppDelegate *)[[UIApplication sharedApplication] delegate] wrapper];
    BOOL noteIsEditable = [wrapper noteIsEditable:note];
    [editButton setHidden:!noteIsEditable];
    
    if ( note == nil ){
      
        [titleTextField setText:nil];
        [contentTextField setText:nil];
        [self setMode:kDisplayModeNotesThumbnails];
        
    } else {
        
        [titleTextField setText:[selectedNote title]];
        [contentTextField setText:[selectedNote content]];
        if ( noteIsNew ){
            [self setMode:kDisplayModeEditNote];
        } else {
            [self setMode:kDisplayModeNote];
            [self toggleShapePanel:1];
            CGRect zoomRect = note.boundingBox;
            if ( CGRectEqualToRect(zoomRect, CGRectZero) == NO ){
                [editView zoomToRect:CGRectInset(zoomRect, -200, -300) animated:YES];
            };
        }
        
    }
}

/*
 
 code snippet
 
 customizing & overriding setter
 http://stackoverflow.com/questions/1306897/how-to-provide-additional-custom-implementation-of-accessor-methods-when-using
 
 - (void)setName:(NSString *)aName
 {
    if (name == aName)
    return;
 
    [name release];
    name = [aName retain];
 
    //custom code here
 }
 
 */

- (void) setPage:(Page *)aPage
{
    if ( aPage == page )
        return;
    
    [page release];
    page = [aPage retain];
    
    CGFloat width = [self orientationIsLandscape] ? 1024.0f : 768.0f;
    CGFloat height = width == 1024.0f ? 768.0f : 1024.0f;
    CGRect pframe = panelView.frame;
    CGRect nframe = pageNavigationView.frame;
    
    CGRect eframe = CGRectMake(
                               panelView.superview && panelView.hidden==NO ? pframe.origin.x+pframe.size.width : 0,
                               pageNavigationView.superview && pageNavigationView.hidden==NO ? nframe.origin.y+nframe.size.height : 0,
                               width,
                               height);
    
    [self.notes removeAllObjects];
    for( Note * note in page.notes ){
        OpenAnnotation * oaNote = [[OpenAnnotation alloc] initWithManagedObject:note];
        [self.notes addObject:oaNote];
        [oaNote release];
    };
    
    [self setImage:[DataWrapper imageForPage:page]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
        
        CGSize resizeSize;
        CGFloat maxDimension = 1024.0f * 2;
        if ( image.size.width > image.size.height ){
            resizeSize.width = fminf(maxDimension,image.size.width);
            resizeSize.height = image.size.height / image.size.width * resizeSize.width;
        } else {
            resizeSize.height = fminf(maxDimension,image.size.height);
            resizeSize.width = image.size.width / image.size.height * resizeSize.height;
        }
        UIGraphicsBeginImageContextWithOptions(resizeSize, NO, 0.0);
        [image drawInRect:CGRectMake(0, 0, resizeSize.width, resizeSize.height)];
        UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            [self setResizedImage:img];
            
            if ( editView )
                [editView removeFromSuperview];
            OAScrollView * eView = [[OAScrollView alloc] initWithFrame:eframe editController:self];
            [self setEditView:eView];
            [eView setAlpha:0.0f];
            [[self view] insertSubview:editView belowSubview:toolbarView];
            [eView release];
            
            [UIView animateWithDuration:0.3f animations:^{
                editView.alpha = 1.0f;
            }];
            
            BOOL zoomViewHidden = YES;
            if ( self.zoomView ){
                zoomViewHidden = self.zoomView.hidden;
                [self.zoomView removeFromSuperview];
            }
            ZoomView * zv = [[ZoomView alloc] initWithEditController:self];
            
            zv.hidden = zoomViewHidden;
            zv.alpha = zoomViewHidden ? 0.0f : 1.0f;
            [self setZoomView:zv];
            [self.view addSubview:self.zoomView];
            [zv release];
            
            CGRect panelFrame = self.panelView.frame;
            [self.panelView removeFromSuperview];
            panelFrame.origin.x = -panelFrame.size.width;
            self.panelView.frame = panelFrame;
            
            [self selectNote:nil];
            
            [noteStepperItem setEnabled:self.notes.count>1];
            
            if ( pageNavigationView.superview && autoClosePagesOnPageSelect )
                [self togglePagesView];
            
            [self setTitle:[NSString stringWithFormat:@"%@, %@, %@, %@",page.book.city,page.book.source,page.book.headline,page.name]];
            [[self selectedPageCell] displayLoading:NO];
            [self setSelectedPageCell:nil];
            
            if ( [delegate respondsToSelector:@selector(onImageResized)])
                [delegate onImageResized];
            
            
        });
        
        [pool release];
        
    });

}

- (void) saveNote
{
    if ( self.selectedNote.shapes.count == 0 ){
        [self showAlertWithTitle:@"EDIT_ALERT_SAVENOTE_TITLE" message:@"EDIT_ALERT_SAVENOTE_TEXT"];
    } else {
        [[self page] setNextNoteIndex:[NSNumber numberWithInt:self.page.nextNoteIndex.intValue+1]];
        [self.selectedNote setTitle:titleTextField.text];
        [self.selectedNote setContent:contentTextField.text];
        NSError * saveError = [self.selectedNote cdSave];
        
        if ( saveError == nil ){
            noteIsNew = NO;
            noteIsModified = NO;
            [self setMode:kDisplayModeNote];
        } else {
            [self showAlertWithTitle:NSLocalizedString(@"EDIT_NOTE_SAVEERROR_TITLE", nil) message:NSLocalizedString(@"EDIT_NOTE_SAVEERROR_TEXT", nil)];
        }
    }
}

- (IBAction) onPanelEditButtonClicked:(id)sender
{
    [self dismissKeyboardAndNavigationView];
    
    if ( sender == self.editButton ){
        
        [self setMode:kDisplayModeEditNote];
        
    }
    else if ( sender == self.saveEditButton ){
        
        [self saveNote];

    }
    else if ( sender == self.cancelEditButton ){

        /*
         
            If the note is new, and the user cancels before saving, we must
            delete the note and its managedObject ( note.cdNote )
            cascading model in xcdatamodel deletes note cdShapes.
         
         */
        
        if ( noteIsNew ) {
            
            // deleteNote will set the right mode using setMode
            [self deleteNote:self.selectedNote];
            
        } else {
        
            for ( OAShape * shape in self.selectedNote.shapes )
                [shape.layer removeFromSuperlayer];
            [selectedNote revertToSaved];
            noteIsModified = NO;
            titleTextField.text = self.selectedNote.title;
            contentTextField.text = self.selectedNote.content;
            [self setMode:kDisplayModeNote];
        }
    }
    else if ( sender == self.deleteEditButton ){
        // deleteNote will set the right mode using setMode
        [self deleteNote:self.selectedNote];
    };
}

- (void) deleteNote:(OpenAnnotation *)note
{
    [note cdDelete];
    if ( note.thumbnailLayer.superlayer )
        [note.thumbnailLayer removeFromSuperlayer];
    [self.notes removeObject:note];
    [noteStepperItem setEnabled:self.notes.count>1];
    // selectNote will set the right mode using setMode
    [self selectNote:nil];
    noteIsNew = NO;
}

- (void) updateNoteTitle:(NSString *)str
{
    self.titleTextField.text = str;
}

// option gets 0 to toggle, -1 to force close, 1 to force open.
- (void) toggleShapePanel:(uint)option
{
    CGRect currentPanelFrame = self.panelView.frame, nextPanelFrame;
    CGFloat currPos = self.panelView.frame.origin.x;
    CGFloat nextPos = (currPos==0&&option==0) || option==-1 ? -LEFTPANEL_WIDTH : 0;
    if ([self.panelView superview]==nil && nextPos == 0 ) {
        [[self view] insertSubview:self.panelView belowSubview:self.toolbarView];
        currentPanelFrame.origin.x = -currentPanelFrame.size.width;
        currentPanelFrame.origin.y = fmaxf(44,editView.frame.origin.y);
        currentPanelFrame.size.height = toolbarView.frame.origin.y-currentPanelFrame.origin.y;
        [panelView setFrame:currentPanelFrame];
        CGSize spSize = panelScrollView.frame.size;
        [panelScrollView setFrame:CGRectMake(0,0,spSize.width,currentPanelFrame.size.height-LEFTPANEL_SCROLL_OFFSET)];
    };
    nextPanelFrame = currentPanelFrame;
    nextPanelFrame.origin.x = nextPos;
    CGRect editFrame = editView.frame;
    editFrame.origin.x = nextPos+LEFTPANEL_WIDTH;
    editFrame.size.width = editView.superview.frame.size.width - editFrame.origin.x;
    
    [UIView animateWithDuration:0.25f
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [panelView setFrame:nextPanelFrame];
                         [editView setFrame:editFrame];
                         CGSize spSize = panelScrollView.frame.size;
                         [panelScrollView setFrame:CGRectMake(0,0,spSize.width,nextPanelFrame.size.height-LEFTPANEL_SCROLL_OFFSET)];
                     }
                     completion:^(BOOL finished){
                         if ( panelView.frame.origin.x < 0 ){
                             [displayToolsItem setTitle:NSLocalizedString(@"EDIT_TB_SHOWTOOLS", nil)];
                             [panelView removeFromSuperview];
                         } else {
                             [displayToolsItem setTitle:NSLocalizedString(@"EDIT_TB_HIDETOOLS",nil)];
                             
                         };
                         [editView updateHiResView];
                     }
     ];
    
}

- (void) animationWillStart:(NSString *)animation
{
    if ( [animation isEqualToString:@"panel_fade_animation"] ){
    };
};

- (void) animationDidStop:(NSString *)animation
{
    if ( [animation isEqualToString:@"zoomview_fade_animation"] ) {
        [zoomView setHidden:zoomView.alpha == 0.0f];
    }
    else if ( [animation isEqualToString:@"panel_fade_animation"]){
        if ( panelView.frame.origin.x < 0 ){
            [displayToolsItem setTitle:NSLocalizedString(@"EDIT_TB_SHOWTOOLS", nil)];
            [panelView removeFromSuperview];
        } else {
            [displayToolsItem setTitle:NSLocalizedString(@"EDIT_TB_HIDETOOLS",nil)];
            
        };
    }
    else if ( [animation isEqualToString:@"pagenav_fade_animation"] ){
        if ( pageNavigationView.frame.origin.y < 0 ){
            [pageNavigationView removeFromSuperview];
            [[pageNavigationView viewWithTag:VIEWTAG_PAGESCV] removeFromSuperview];
        };
    }
    else if ( [animation isEqualToString:@"shapeview_fade_animation"] ){
        [shapeEditView setHidden:shapeEditView.alpha==0];
    }
};

- (void) popoverDidSelectNote:(OpenAnnotation *)note
{
    [self selectNote:note];
    [notesPopoverController dismissPopoverAnimated:YES];
}



- (void) onNBNotesButtonClicked:(id)sender
{
    if ( sheetVisible ){
        if ( self.actionSheet )
            [self.actionSheet dismissWithClickedButtonIndex:-1 animated:NO];
            // on évite d'avoir les deux popovers en meme temps à l'écran ...
    }
    
    sheetVisible = YES;
    
    UIPopoverController * pc;
    CGFloat popoverHeight;
    CGSize noNotesFrameSize = CGSizeMake(200,100);
    if ( self.notes.count == 0 ){
        
        UIViewController * smallController = [[UIViewController alloc] init];
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, noNotesFrameSize.width, noNotesFrameSize.height)];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setNumberOfLines:2];
        [label setText:NSLocalizedString(@"EDIT_NOTE_LIST_NONOTES",nil)];
        [label setBackgroundColor:[UIColor clearColor]];
        [label setTextColor:[UIColor whiteColor]];
        [smallController setView:label];
        [label release];
        pc = [[UIPopoverController alloc] initWithContentViewController:smallController];
        [smallController release];
        popoverHeight = label.frame.size.height;
    } else {
        popoverHeight = fmaxf(220,fminf(440, 44 * self.notes.count));
        NotesViewController * nv = [[NotesViewController alloc] initWithEditController:self];
        pc = [[UIPopoverController alloc] initWithContentViewController:nv];
        [nv release];
    }
    [self setNotesPopoverController:pc];
    CGSize cSize = notesPopoverController.popoverContentSize;
    cSize.height = popoverHeight;
    if ( self.notes.count == 0 )
        cSize = noNotesFrameSize;
	[notesPopoverController setPopoverContentSize:cSize];
    [notesPopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    [notesPopoverController setPassthroughViews:[NSMutableArray arrayWithCapacity:0]]; // par défaut il laisse là dedans la footerbar. leuuu CON !
    [pc release];
}

- (void) actionSheet:(UIActionSheet *)aSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    sheetVisible = NO;
    [actionSheet release];
    self->actionSheet = nil;
}

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if ( buttonIndex == -1 )
        return;
    
    NSArray * result = nil;
    if ( buttonIndex == 0 ){
        // pages from the current manuscript
        result = [[self.page.book.pages allObjects] sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            return [[(Page *)a index] compare:[(Page *)b index]];
        }];
    } else {
        // user pages
        User * currentUser = [[self wrapper] currentUser];
        result = [[[self wrapper] pagesWithNotesForUser:currentUser] sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            return [[DataWrapper updateDateForPage:(Page *)a user:currentUser] compare:[DataWrapper updateDateForPage:(Page *)b user:currentUser]];
        }];
    }
    [self setPagesDataSource:result];
    [self togglePagesView];
}

- (void) togglePagesView
{
    [self.editView invalidateHiResDeferredUpdates];
    
    CGFloat pageHeight = pageNavigationView.frame.size.height;
    CGFloat nextPos;
    
    if ( [pageNavigationView superview]==nil ) {
        
        PSTCollectionViewFlowLayout * flowLayout = [[PSTCollectionViewFlowLayout alloc] init];
        [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        [flowLayout setItemSize:CGSizeMake(200, 205)];
        [flowLayout setHeaderReferenceSize:CGSizeZero];
        [flowLayout setFooterReferenceSize:CGSizeZero];
        [flowLayout setMinimumInteritemSpacing:20];
        [flowLayout setMinimumLineSpacing:20];
        [flowLayout setSectionInset:UIEdgeInsetsMake( 0, 10, 0, 10)];
        PSTCollectionView * collectionView = [[PSTCollectionView alloc] initWithFrame:CGRectMake( 0, 0, pageNavigationView.frame.size.width,pageNavigationView.frame.size.height ) collectionViewLayout:flowLayout];
        [collectionView setTag:VIEWTAG_PAGESCV];
        [collectionView setDelegate:self];
        [collectionView setDataSource:self];
        [collectionView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [collectionView setBackgroundColor:[UIColor clearColor]];
        [collectionView registerClass:[PageViewCell class] forCellWithReuseIdentifier:cellIdentifier];
        [pageNavigationView addSubview:collectionView];
        
        [flowLayout release];
        [collectionView release];
        [[self view] addSubview:pageNavigationView];
        nextPos = 0;
        [self.pagesNavigationItem setStyle:UIBarButtonItemStyleDone];
        
        uint pageIndex = [self.pagesDataSource indexOfObject:self.page];
        // PSTCollectionViewScrollPositionCenteredVertically does not want to center so I have to add 1 to index ...
        uint correctedPageIndex = MIN(pageIndex+1,pagesDataSource.count-1);
        [collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:correctedPageIndex inSection:0] atScrollPosition:PSTCollectionViewScrollPositionCenteredVertically animated:NO];
        
    } else {
        [self.pagesNavigationItem setStyle:UIBarButtonItemStylePlain];
        nextPos = -pageHeight;
    };
    
    [UIView animateWithDuration: 0.3f
                          delay: 0
                        options: UIViewAnimationOptionCurveEaseOut
                     animations: ^{
                         [pageNavigationView setFrame:CGRectSetY(pageNavigationView.frame, nextPos)];
                         CGRect editFrame = editView.frame;
                         editFrame.origin.y = nextPos+pageHeight;
                         
                         [editView setFrame:editFrame];
                         CGRect zFrame = self.zoomView.frame;
                         //zFrame.origin.x = editView.frame.size.width-zFrame.size.width;
                         zFrame.origin.x = editView.frame.size.width+editView.frame.origin.x-zFrame.size.width;
                         zFrame.origin.y = fmaxf(44,editView.frame.origin.y);
                         self.zoomView.frame = zFrame;
                         CGRect newPanelFrame = panelView.frame;
                         newPanelFrame.origin.y = nextPos == 0 ? nextPos+pageHeight : 44.0f;
                         newPanelFrame.size.height = toolbarView.frame.origin.y-newPanelFrame.origin.y;
                         [panelView setFrame:newPanelFrame];
                         CGSize spSize = panelView.frame.size;
                         [panelScrollView setFrame:CGRectMake(0,0,spSize.width,spSize.height-LEFTPANEL_SCROLL_OFFSET)];
                     }
                     completion: ^(BOOL finished){
                         if ( pageNavigationView.frame.origin.y < 0 ){
                             [pageNavigationView removeFromSuperview];
                             [[pageNavigationView viewWithTag:VIEWTAG_PAGESCV] removeFromSuperview];
                         }
                         [editView updateHiResView];
                     }
     ];

}

- (void) popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if ( popoverController == self.notesPopoverController ){
        sheetVisible = NO;
        [notesPopoverController release];
        self->notesPopoverController = nil;
    }
}

- (void) onNBPageNavigationButtonClicked:(id)sender
{
    
    if ( [self.view viewWithTag:VIEWTAG_PAGES] ){
        [self togglePagesView];
        return;
    }
    
    // No "my pages" button for those with no pages.
    BOOL userHasPages = [[[[self wrapper] currentUser] notes] count];
    
    if ( userHasPages ){
        if ( sheetVisible ){
            if ( self.notesPopoverController ){
                [self.notesPopoverController dismissPopoverAnimated:NO];
            }
            if ( self.actionSheet ){
                [self.actionSheet dismissWithClickedButtonIndex:-1 animated:YES];
                return;
            }
        }
        sheetVisible = YES;
        
        UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"EDIT_PAGES_BOOK",nil),NSLocalizedString(@"EDIT_PAGES_MYPAGES",nil),nil];
        [self setActionSheet:sheet];
        [self.actionSheet showFromBarButtonItem:sender animated:YES];
        [sheet release];
    } else {
        // tout le livre
        NSArray * bookPages = [[self.page.book.pages allObjects] sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            return [[(Page *)a index] compare:[(Page *)b index]];
        }];
        [self setPagesDataSource:bookPages];
        [self togglePagesView];
        
    }
    
};

- (void) onNBZoomButtonClicked:(id)sender
{
    CGFloat nextAlpha = self.zoomView.alpha == 0.0f ? 1.0f : 0.0f;
    if ( nextAlpha == 1 && self.zoomView.hidden )
        [zoomView setHidden:NO];
    [UIView beginAnimations:@"zoomview_fade_animation" context:nil];
    [UIView setAnimationDelegate:self];
    [self.zoomView setAlpha:nextAlpha];
    [UIView commitAnimations];
}

- (void) onTBNoteNavButtonClicked:(id)sender
{
    int segIndex = [(UISegmentedControl *)sender selectedSegmentIndex];
    int currentNoteIndex = [notes indexOfObject:selectedNote];
    int newNoteIndex = (currentNoteIndex + notes.count + (segIndex==0 ? -1 : 1))%notes.count;
    [self selectNote:[notes objectAtIndex:newNoteIndex]];
}

- (IBAction) onTBThumbnailsButtonClicked:(id)sender
{
    if ( self->mode != kDisplayModeNotesThumbnails )
        [self setMode:kDisplayModeNotesThumbnails];
}

- (IBAction) onTBAddNoteButtonClicked:(id)sender
{
    DataWrapper * wrapper = [(OAProtoAppDelegate *)[[UIApplication sharedApplication] delegate] wrapper];
    Note * note = [wrapper entityForName:@"Note"];
    User * user = [wrapper currentUser];
    note.page = page;
    note.index = note.page.nextNoteIndex;
    note.owner = user;
    [user addNotesObject:note];
    [user addPagesObject:page];
    [user addBooksObject:page.book];
    [page addUsersObject:user];
    [page.book addUsersObject:user];
    OpenAnnotation * newNote = [[OpenAnnotation alloc] initWithManagedObject:note];
    noteIsNew = YES;
    [notes addObject:newNote];
    [newNote release];
    [noteStepperItem setEnabled:self.notes.count>1];
    // selectNote will set the right mode using setMode.
    [self selectNote:newNote];
    
};

- (IBAction)onNBAddPageToMineButtonClicked:(id)sender
{
    
};

- (IBAction) onTBDeleteNoteButtonClicked:(id)sender
{
    
};

- (IBAction) onTBNavigationNoteButtonClicked:(id)sender{
    
};

- (IBAction) onTBNoteEditButtonClicked:(id)sender{
    
};

- (IBAction) onTBShapeToolsButtonClicked:(id)sender
{
    [self toggleShapePanel:0];
};

- (IBAction) onTBCancelNoteButtonClicked:(id)sender
{
    if ( noteIsNew ){
        [[self notes] removeObject:selectedNote];
        [self selectNote:nil];
    } else {
        [self setMode:kDisplayModeNote];
    }
    noteIsNew = NO;
};

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        self->previousMode = kDisplayModeUnknown;
        self->mode = kDisplayModeUnknown;
        [panelScrollView setScrollEnabled:NO];
        
        autoClosePagesOnPageSelect = YES;
        handToolSelected = NO;
        
        UIActivityIndicatorView * hraiv = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        [self setHiresActivityIndicator:hraiv];
        [self.hiresActivityIndicator sizeToFit];
        [self.hiresActivityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
        [self.hiresActivityIndicator setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin)];
        [self.hiresActivityIndicator setHidesWhenStopped:YES];
        [self.hiresActivityIndicator stopAnimating];
        [hraiv release];
        
        UIBarButtonItem * hrai = [[UIBarButtonItem alloc] initWithCustomView:self.hiresActivityIndicator];
        [self setHiresActivityItem:hrai];
        [hrai release];
        
        // Stepper for paging notes of current page
        NSArray * segControlItems = [NSArray arrayWithObjects:[UIImage imageNamed:@"oa_arrow_left_11x11.png"], [UIImage imageNamed:@"oa_arrow_right_11x11.png"], nil];
        UISegmentedControl * segmentControl = [[UISegmentedControl alloc] initWithItems:segControlItems];
        segmentControl.segmentedControlStyle = UISegmentedControlStyleBar;
        segmentControl.momentary = YES;
        CGRect segFrame = segmentControl.frame;
        segFrame.size.width = 80.0f;
        segmentControl.frame = segFrame;
        UIBarButtonItem * nsi = [[UIBarButtonItem alloc] initWithCustomView:segmentControl];
        [segmentControl addTarget:self action:@selector(onTBNoteNavButtonClicked:) forControlEvents:UIControlEventValueChanged];
        [segmentControl release];
        [self setNoteStepperItem:nsi];
        [nsi release];
        
        NSMutableArray * arr = [[NSMutableArray alloc] init];
        [self setNotes:arr];
        [arr release];
        
        noteIsModified = NO;
        
        [self setSelectedNote:nil];
        
    };
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if ( self ){
    }
    return self;
}

- (void) viewWillDisappear:(BOOL)animated
{
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {

        // moved into onNBBackButtonClicked: selector.
    }
    [super viewWillDisappear:animated];
}

- (void) viewWillAppear:(BOOL)animated
{
    
    [pageNavigationView setTag:VIEWTAG_PAGES];
    
    CGFloat width = [self orientationIsLandscape] ? 1024.0f : 768.0f;
    CGFloat height = width == 1024.0f ? 768.0f : 1024.0f;
    CGRect pframe = panelView.frame;
    
    pframe = CGRectSetX(pframe, -pframe.size.width);
    [panelView setFrame:pframe];
    
    [shapeEditView setHidden:YES];
    [shapeEditView setAlpha:0.0f];
    [panelView setFrame:CGRectMake(-LEFTPANEL_WIDTH, 44.0f,LEFTPANEL_WIDTH,height-(44*2))];
    [panelScrollView setFrame:CGRectMake(0,0,LEFTPANEL_WIDTH,height-(44*2)-LEFTPANEL_SCROLL_OFFSET)];
    
    [mwToleranceSlider setMinimumValue:MW_TOLERANCE_MIN];
    [mwToleranceSlider setMaximumValue:MW_TOLERANCE_MAX];
    [mwToleranceSlider setValue:MW_TOLERANCE];
    
    [pageNavigationView setFrame:CGRectMake(0,-UPPERPANEL_HEIGHT,width,UPPERPANEL_HEIGHT)];
    [panelScrollView setContentSize:CGSizeMake(panelView.frame.size.width, shapeEditView.frame.origin.y+shapeEditView.frame.size.height)];
    
}

- (void) updateZoomView
{
    [self.zoomView updateZoomForScrollView:self.editView];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
        
    UIBarButtonItem * p = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"EDIT_NB_PAGES",nil)
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(onNBPageNavigationButtonClicked:)
                           ];
    
    UIBarButtonItem * n = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"EDIT_NB_NOTES",nil)
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(onNBNotesButtonClicked:)
                           ];
    
    UIBarButtonItem * z = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"EDIT_NB_ZOOM",nil)
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(onNBZoomButtonClicked:)
                           ];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:z,n,p,nil];
    
    [self setPagesNavigationItem:p];
    
    [p release];
    [n release];
    [z release];
    
    [titleTextField setTextColor:[UIColor whiteColor]];
    [titleTextField setBackgroundColor:[UIColor clearColor]];
    [contentTextField setTextColor:[UIColor whiteColor]];
    [contentTextField setBackgroundColor:[UIColor clearColor]];
    
    [shapeRectButton setImage:[UIImage imageNamed:@"oa_shape_rect_h_35x31"] forState:UIControlStateHighlighted];    
    [shapeEllipseButton setImage:[UIImage imageNamed:@"oa_shape_ellipse_h_35x31"] forState:UIControlStateHighlighted];
    [shapePolyButton setImage:[UIImage imageNamed:@"oa_shape_poly_h_35x31"] forState:UIControlStateHighlighted];
    [shapeFreeButton setImage:[UIImage imageNamed:@"oa_shape_free_h_35x31"] forState:UIControlStateHighlighted];
    [shapeMWButton setImage:[UIImage imageNamed:@"oa_shape_wand_h_35x31"] forState:UIControlStateHighlighted];
    [shapeMoveImageButton setImage:[UIImage imageNamed:@"oa_shape_move_h_35x31"] forState:UIControlStateHighlighted];
    
    [editButton setHidden:YES];
    [saveEditButton setHidden:YES];
    [cancelEditButton setHidden:YES];
    [deleteEditButton setHidden:YES];
    
    [self.navigationItem setHidesBackButton:YES animated:NO];

    UIButton * backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(0.0f, 0.0f, 96.0f, 32.0f);
    [backButton setBackgroundImage:[UIImage imageNamed:@"nb_backbutton_96x32"] forState:UIControlStateNormal];
    [backButton setBackgroundImage:[UIImage imageNamed:@"nb_backbutton_h_96x32"] forState:UIControlStateHighlighted];
    [backButton addTarget:self action:@selector(onNBBackButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    backButton.titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]];
    [backButton setTitle:NSLocalizedString(@"EDIT_NB_BACK",nil) forState:UIControlStateNormal];
    [backButton setAdjustsImageWhenHighlighted:NO];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:backButton] autorelease];
    
}

- (void) onNBBackButtonClicked:(id)sender
{
    // back button was pressed.  We know this is true because self is no longer
    // in the navigation stack.
    // http://stackoverflow.com/questions/1214965/setting-action-for-back-button-in-navigation-controller/3445994#3445994
    
    // check if the textfields has been modified, adding to noteIsModifed.
    if ( [self.selectedNote.title isEqualToString:titleTextField.text] == NO || [self.selectedNote.content isEqualToString:contentTextField.text] == NO ){
        noteIsModified = YES;
    }
    
    if ( self.selectedNote ) {
        if ( noteIsNew || noteIsModified ){
            
            UIAlertView * alert = [[UIAlertView alloc]
                                   initWithTitle: NSLocalizedString(@"EDIT_NOTE_BACKSAVE_TITLE", nil)
                                   message: NSLocalizedString(@"EDIT_NOTE_BACKSAVE_TEXT", nil)
                                   delegate: self
                                   cancelButtonTitle:NSLocalizedString(@"EDIT_NOTE_BACKSAVE_CANCEL", nil)
                                   otherButtonTitles:NSLocalizedString(@"EDIT_NOTE_BACKSAVE_DONT", nil),NSLocalizedString(@"EDIT_NOTE_BACKSAVE_SAVE", nil),nil];
            [alert setTag:VIEWTAG_BACKALERT];
            [alert show];
            [alert release];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
}

- (void) viewDidDisappear:(BOOL)animated
{
    [editView removeFromSuperview];
    editView = nil;
    [self.zoomView removeFromSuperview];
    
    panelView.frame = CGRectSetX(panelView.frame, 0);
    [panelView removeFromSuperview];
    
    [super viewDidDisappear:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.height;
    CGRect eFrame = editView.frame;
    CGRect pFrame = panelView.frame;
    CGRect nFrame = pageNavigationView.frame;
    CGRect zFrame = self.zoomView.frame;
    [pageNavigationView setFrame:CGRectSetHeight(CGRectSetWidth(nFrame, width),UPPERPANEL_HEIGHT)];
    [editView setFrame:CGRectMake(eFrame.origin.x,nFrame.origin.y+UPPERPANEL_HEIGHT,width-eFrame.origin.x,height)];
    [self.zoomView setFrame:CGRectMake(width-zFrame.size.width,fmaxf(44,nFrame.origin.y+nFrame.size.height),zFrame.size.width,zFrame.size.height)];
    [panelView setFrame:CGRectMake(pFrame.origin.x,pFrame.origin.y,pFrame.size.width,height-(44*2))];
    CGSize spSize = panelScrollView.frame.size;
    [panelScrollView setFrame:CGRectMake(0,0,spSize.width,height-(44*2)-LEFTPANEL_SCROLL_OFFSET)];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    //[editView onDidRotate];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (BOOL) orientationIsLandscape
{
    UIInterfaceOrientation o = [UIApplication sharedApplication].statusBarOrientation;
    return o == UIDeviceOrientationLandscapeLeft || o == UIDeviceOrientationLandscapeRight;
}

#pragma mark -
#pragma mark PSUICollectionView stuff

- (DataWrapper *) wrapper
{
    return [(OAProtoAppDelegate *)[[UIApplication sharedApplication] delegate] wrapper];
}

- (PageViewCell *) cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return (PageViewCell *)[(PSTCollectionView *)[self.pageNavigationView viewWithTag:VIEWTAG_PAGESCV] cellForItemAtIndexPath:indexPath];
}

- (NSInteger)numberOfSectionsInCollectionView:(PSTCollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(PSTCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return pagesDataSource.count;
}

- (void) collectionView:(PSTCollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    PageViewCell * cell = (PageViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    Page * newPage = [pagesDataSource objectAtIndex:indexPath.row];
    if ( newPage == self.page)
        return;
    
    [self.editView setUserInteractionEnabled:NO];
    [self.toolbarView setItems:nil];
    [UIView animateWithDuration:0.3f animations:^{
        [self.editView setAlpha:0.2f];
    }];
    [self setSelectedPageCell:cell];
    [cell displayLoading:YES];
    // delay to let spinner wake up
    float delayInSeconds = 0.01;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self setPage:newPage];
    });
}

- (PSTCollectionViewCell *)collectionView:(PSTCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    PSTCollectionViewCell * cell = (PSTCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    Page * cellPage = [pagesDataSource objectAtIndex:indexPath.row];
    [(PageViewCell *)cell updateForPage:cellPage
                              thumbnail:[DataWrapper thumbnailForPage:cellPage]
     ];
    
    return cell;
}

- (PSTCollectionReusableView *)collectionView:(PSTCollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
	NSString * identifier = nil;
	
	if ([kind isEqualToString:PSTCollectionElementKindSectionHeader]) {
		identifier = @"";
	} else if ([kind isEqualToString:PSTCollectionElementKindSectionFooter]) {
		identifier = @"";
	}
    PSTCollectionReusableView * supplementaryView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:identifier forIndexPath:indexPath];
	
    // TODO Setup view
	
    return supplementaryView;
}

@end

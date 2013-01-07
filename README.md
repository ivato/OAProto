# OAProto

**OpenAnnotation / SharedCanvas iPad prototype application.**

It allows to read, add, edit, share annotations on scanned pages of ancient manuscripts.
Project written for [is&a bloom](http://www.iseabloom.com) on BNF/CNRS demand.

**Work in progress.**

### Dependencies
- OpenCV2 for magic wand feature
- PSTCollectionView from Peter Steinberger, for collection views
- XSWI from Thomas Rørvik Skjølberg, for XML parsing.

### Features

- Simple shapes as ellipses, rectangles,
- Complex pathes and polygons, including open and closed shapes,
- Magic Wand

A simple CoreData layer has been lately added to add data persistence, should be highly improved in the future.

OAProto exports data as OpenAnnotation/SharedCanvas xml files.
Graphic shapes are exported as SVG nodes.

*Code released under GPL v3.0 license. Please read license file for more informations.*

---

Most of the controllers classes are common UX code.
The APIs that handles shapes drawing, database storage, conversion, zooming, transforms, is done in these classes :
###### OpenAnnotation
Represent one annotation.
Stores data for one annotation, author, date, content, and a set of OAShapes that represent the shapes of the annotation.
###### OAShape
Represent one shape for one annotation. Annotations can contain unlimited number of shapes.
Stores graphic path and information for a shape. Includes helpers and methods for conversion from CGPathElement to NSData, used for CoreData, and from CGPathElement to SVG, used in the xml export.
Relies on CAShapeLayer to display shapes.
###### DataWrapper
Includes helpers for initializing the CoreData database, exports and conversions. 
###### OAScrollView ( extends UIScrollView )
Includes main graphic APIs for displaying shapes and annotations.
The scanned page is scaled down at 25%, and the view contains an async API to render the visible area of the page at full resolution.
###### EditViewController
Controller for the OAScrollView. Handles the sliding panels, the small navigation view, and calls to edit APIs.
####### User, Book, Page, Note, Shape 
Simple CoreData wrappers.
###### pages
This file lists the scanned pages of the application. This file is parsed at the first launch of the application.
Full description of the syntax on the header of this file.
You can edit this file to replace the scanned pages with the ones you want.
Each scan must exists in 2 versions, and 3 versions for the cover :

- filename.ext being the original version.
- filename-s.ext being the small version, 200px width.
- filename-s-shad.png being the thumbnail used as cover on the home page if needed.

note : -s and -s-shad files should have a @2x retina version at twice the size for retina support.

**Actually contains file references that are not available on this repo, and the app will not work with the current "pages" file. You can replace the "pages" file content with "pages-demo" file content to run the application.**



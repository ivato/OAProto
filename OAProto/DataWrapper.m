//
//  CDWrapper.m
//  OAProto
//
//  Created by Ivan Touzeau on 07/11/12.
//  Copyright (c) 2012 Ivan Touzeau. All rights reserved.
//

#import "DataWrapper.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>

#import "XMLWriter.h"

#import "Book.h"
#import "Page.h"
#import "Note.h"
#import "User.h"
#import "Shape.h"

#import "OpenAnnotation.h"
#import "OAShape.h"

@interface DataWrapper()
{
}

@property (nonatomic,assign)    NSManagedObjectContext      * moc;
@property (nonatomic,assign)    NSFileManager               * fileManager;
@property (nonatomic,copy)      NSString                    * bundleRoot;

@end

@implementation DataWrapper

@synthesize delegate,currentBook,currentPage,currentUser;

- (void) appendElement:(NSString *)element withContent:(NSString *)content forXML:(XMLWriter *)xml
{
    [xml writeStartElement:element];
    [xml writeCharacters:content];
    [xml writeEndElement];
}

- (NSData *) xmlDataForUser:(User *)user
{
    
    NSArray * userPages = [[self pagesWithNotesForUser:self.currentUser] sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        return [[(Page *)a book].name compare:[(Page *)b book].name];
    }];

    
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    NSString * svgStyleClose = @"fill:red;stroke:none;opacity:0.2";
    NSString * svgStyleOpen = @"fill:none;stroke:black;stroke-width:1";
    
    XMLWriter * xml = [[XMLWriter alloc] init];
    [xml writeStartDocument];
    [xml writeStartElement:@"rdf:RDF"];
    
    [xml writeAttribute:@"xmlns:rdf" value:@"http://www.w3.org/1999/02/22-rdf-syntax-ns#"];
    [xml writeAttribute:@"xmlns:foaf" value:@"http://xmlns.com/foaf/0.1/"];
    [xml writeAttribute:@"xmlns:oac" value:@"http://www.openannotation.org/ns/"];
    [xml writeAttribute:@"xmlns:dc" value:@"http://purl.org/dc/elements/1.1/"];
    [xml writeAttribute:@"xmlns:dcterms" value:@"http://purl.org/dc/terms/"];
    [xml writeAttribute:@"xmlns:cnt" value:@"http://www.w3.org/2008/content"];
    [xml writeAttribute:@"xmlns:sc" value:@"http://www.shared-canvas.org/ns/"];
    
    for ( Page * page in userPages ){
        for ( Note * note in page.notes ){
            [xml writeStartElement:@"oac:Annotation"];
            [xml writeAttribute:@"rdf:about" value:@"http://www.somedomain.com/contentofthisfile.xml"];
            [self appendElement:@"oac:hasTarget" withContent:page.file forXML:xml];
            [xml writeStartElement:@"dc:title"];
            [xml writeAttribute:@"xml:lang" value:@"to_be_defined"];
            [xml writeCData:note.title];
            [xml writeEndElement];
            [xml writeStartElement:@"oac:hasBody"];
            [xml writeCData:note.content];
            [xml writeEndElement];
            
            UIImage * pageImage = [DataWrapper imageForPage:page];
            [xml writeStartElement:@"sc:Canvas"];
            [self appendElement:@"exif:width" withContent:[NSString stringWithFormat:@"%d",(uint)pageImage.size.width] forXML:xml];
            [self appendElement:@"exif:height" withContent:[NSString stringWithFormat:@"%d",(uint)pageImage.size.height] forXML:xml];
            [xml writeStartElement:@"rdfs:label"];
            [xml writeCData:[NSString stringWithFormat:@"%@,%@,%@",page.book.city,page.book.source,page.file]];
            [xml writeEndElement];
            [xml writeEndElement];
            
            [xml writeStartElement:@"oac:SvgConstraint"];
            [self appendElement:@"dc:format" withContent:@"image/svg+xml" forXML:xml];
            [self appendElement:@"cnt:characterEncoding" withContent:@"utf-8" forXML:xml];
            [xml writeStartElement:@"cnt:chars"];
            [xml writeStartElement:@"svg"];
            [xml writeAttribute:@"xmlns" value:@"http://www.w3.org/2000/svg"];
            [xml writeAttribute:@"version" value:@"1.1"];
            
            for ( Shape * shape in note.shapes){
                
                uint shapeType = shape.type.intValue;
                
                CGPathElement * elements = NULL;
                uint len = CGPathElementMakeFromNSData(shape.path, &elements);
                bool shapeClosed = elements[len-1].type == kCGPathElementCloseSubpath;
                
                if ( shapeType == kShapeTypeRectangle){
                    int rectWidth = (abs)((int)elements[0].points[1].x - elements[0].points[0].x);
                    int rectHeight = (abs)((int)elements[0].points[1].y - elements[0].points[0].y);
                    [xml writeStartElement:@"rect"];
                    [xml writeAttribute:@"x" value:[NSString stringWithFormat:@"%i",(abs)((int)elements[0].points[1].x)]];
                    [xml writeAttribute:@"y" value:[NSString stringWithFormat:@"%i",(abs)((int)elements[0].points[1].y)]];
                    [xml writeAttribute:@"width" value:[NSString stringWithFormat:@"%i",rectWidth]];
                    [xml writeAttribute:@"height" value:[NSString stringWithFormat:@"%i",rectHeight]];
                }
                else if ( shapeType == kShapeTypeEllipse){
                    int rx = (abs)((int)(elements[0].points[1].x - elements[0].points[0].x)/2);
                    int ry = (abs)((int)(elements[0].points[1].y - elements[0].points[0].y)/2);
                    int cx = (abs)((int)elements[0].points[1].x + rx);
                    int cy = (abs)((int)elements[0].points[1].y + ry);
                    [xml writeStartElement:@"ellipse"];
                    [xml writeAttribute:@"cx" value:[NSString stringWithFormat:@"%i",cx]];
                    [xml writeAttribute:@"cy" value:[NSString stringWithFormat:@"%i",cy]];
                    [xml writeAttribute:@"rx" value:[NSString stringWithFormat:@"%i",rx]];
                    [xml writeAttribute:@"ry" value:[NSString stringWithFormat:@"%i",ry]];
                }
                else if ( shapeType == kShapeTypePath || shapeType == kShapeTypePolygon ) {
                    
                    [xml writeStartElement:@"path"];
                    NSMutableString * mutableString = [[NSMutableString alloc] init];
                    for ( uint i=0;i<len;i++ ){
                        NSString * command = SVGPathCommandForCGPathElement(elements[i]);
                        if ( elements[i].type == kCGPathElementCloseSubpath){
                            [mutableString appendString:[NSString stringWithFormat:@"%@ ",command]];
                        } else {
                            [mutableString appendString:[NSString stringWithFormat:
                                                         @"%@%d %d ",
                                                         command,
                                                         (abs)((int)elements[i].points[0].x),
                                                         (abs)((int)elements[i].points[0].y)
                                                         ]];
                        };
                    }
                    [xml writeAttribute:@"d" value:mutableString];
                    [mutableString release];
                }
                else {
                    [xml writeStartElement:@"undefined_shape"];
                }
                free(elements);
                [xml writeAttribute:@"style" value:shapeClosed ? svgStyleClose : svgStyleOpen];
                [xml writeEndElement];
            
            }
            
            [xml writeEndElement]; // svg
            [xml writeEndElement]; // cnt:chars
            [xml writeEndElement]; // oac:SvgConstraint
            
            [xml writeStartElement:@"dcterms:creator"];
            [xml writeStartElement:@"foaf:Agent"];
            [xml writeAttribute:@"rdf:about" value:@"author_link"];
            [xml writeStartElement:@"foaf:name"];
            [xml writeCharacters:note.owner.firstName];
            [xml writeCharacters:@" "];
            [xml writeCharacters:note.owner.lastName];
            [xml writeEndElement];
            [xml writeStartElement:@"foaf:mbox"];
            [xml writeAttribute:@"rdf:ressource" value:[NSString stringWithFormat:@"mailto:%@",note.owner.email]];
            [xml writeEndElement];
            [xml writeEndElement];
            [xml writeStartElement:@"dcterms:created"];
            [xml writeCharacters:[dateFormatter stringFromDate:note.creationDate]];
            [xml writeEndElement];
            [xml writeEndElement]; // dcterms:Creator
            
            [xml writeEndElement]; // oac:Annotation
        }
    }
    
    [xml writeEndElement]; // rdf:RDF
    [xml writeEndDocument];
    
    //NSLog(@"%@",[xml toString]);
    NSData * xmlData = [xml toData];
    [xml release];
    [dateFormatter release];
    return xmlData;
}

- (void) dealloc
{
    [super dealloc];
    [currentPage release];
    [currentBook release];
    [currentUser release];
    [delegate release];
}

- (id) initWithContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if ( self ){
        [self setMoc:context];
        [self setFileManager:[NSFileManager defaultManager]];
        self.bundleRoot = [[NSBundle mainBundle] bundlePath];
    }
    return self;
}

#pragma mark -
#pragma mark CoreData helpers

- (NSString *) makeUserUuid
{
    NSString * storedDeviceId = [[NSUserDefaults standardUserDefaults] objectForKey:@"deviceId"];
    if ( storedDeviceId == nil ){
        CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
        storedDeviceId = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
        [[NSUserDefaults standardUserDefaults] setObject:storedDeviceId forKey:@"deviceId"];
        CFRelease(uuidRef);
        [storedDeviceId release];
        return [self makeUserUuid];
    }
    return [NSString stringWithFormat:@"%@-%f",storedDeviceId,CFAbsoluteTimeGetCurrent()];
}

- (BOOL) noteIsEditable:(OpenAnnotation *)note
{
    return [note.authorId isEqualToString:self.currentUser.uuid];
}

- (void) deleteUser:(User *)user
{
    
}

- (void) setCurrentUser:(User *)user
{
    if ( user == currentUser )
        return;
    
    [currentUser release];
    currentUser = [user retain];
    [[NSUserDefaults standardUserDefaults] setObject:user.uuid forKey:@"currentUserUuid"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *) books
{
    return [self entitiesForName:@"Book" sortedWith:@"name"];
}

- (NSArray *) users
{
    return [self entitiesForName:@"User" sortedWith:@"email"];
}

- (NSArray *) pagesWithNotesForUser:(User *)user
{
    NSMutableSet * pages = [NSMutableSet set];
    for ( Note * note in user.notes){
        [pages addObject:note.page];
    }
    return [pages allObjects];
}

- (NSArray *) booksWithNotesForUser:(User *)user
{
    NSMutableSet * books = [NSMutableSet set];
    for ( Note * note in user.notes){
        [books addObject:note.page.book];
    }
    return [books allObjects];
}

- (User *) createUser
{
    User * user = [self entityForName:@"User"];
    user.uuid = [self makeUserUuid];
    user.firstName = @"";
    user.lastName = @"";
    user.organisation = @"";
    user.email = nil;
    return user;
}

- (id) entityForName:(NSString *)entityName
{
    //[NSManagedObject alloc] initWithEntity: insertIntoManagedObjectContext:<#(NSManagedObjectContext *)#>
    return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.moc];
}

- (NSArray *) entitiesForName:(NSString *)entityName sortedWith:(NSString *)key
{
    NSEntityDescription * entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.moc];
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    
    if ( key ){
        NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:NO];
        NSArray * sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        [request setSortDescriptors:sortDescriptors];
        [sortDescriptor release];
    }
    NSError * error = nil;
    NSArray * fetchResults = [self.moc executeFetchRequest:request error:&error];
    if ( !fetchResults || error ) {
        // Handle the error.
        // This is a serious error and should advise the user to restart the application
    }
    [request release];
    return fetchResults;
}

+(BOOL) NSStringIsValidEmail:(NSString *)checkString
{
    // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    BOOL stricterFilter = YES;
    
    NSString * stricterFilterString = @"[A-Za-z0-9._%+-]+@(?:[A-Za-z0-9-]{1,}+\\.)+[A-Za-z]{2,4}";
    NSString * laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
    NSString * emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate * emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    if ( [emailTest evaluateWithObject:checkString] ){
        if ( [checkString hasPrefix:@"." ])
            return NO;
        if ( [checkString componentsSeparatedByString:@".@"].count > 1 )
            return NO;
        if ( [checkString componentsSeparatedByString:@".."].count > 1 )
            return NO;
        return YES;
    } else {
        return NO;
    }
}

- (void) testDatabase
{
}

- (void) logDatabase
{
}

- (BOOL) initDatabase
{
    
    //[self logDatabase];
    
    NSArray * users = [self entitiesForName:@"User" sortedWith:@"email"];
    if ( users.count > 0 ){
        NSString * storedUuid = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserUuid"];
        for ( User * user in users ){
            if ( [user.uuid isEqualToString:storedUuid] ){
                [self setCurrentUser:user];
            }
        }
        return YES;
    }
    
    [self createUser];
    
    // Dic will have one key per title, value will be the set of images pathes.
    // Once we have all titles we can fill the database.
    // NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithCapacity:10];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        

        NSError * err = nil;
        NSString * pageFileContent = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"pages" ofType:nil]
                                                               encoding:NSUTF8StringEncoding
                                                                  error:&err];
        if ( err == nil ){
            NSArray * lines = [pageFileContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            Book * book = nil;
            for ( NSString * line in lines ){
                NSArray * components = [line componentsSeparatedByString:@"|"];
                if ( components.count > 1){
                    NSString * prefix = [components objectAtIndex:0];
                    if ( [prefix isEqualToString:@"#"] == NO ){
                        
                        if ( [prefix isEqualToString:@"book"] ){
                            book = [self entityForName:@"Book"];
                            book.city = [components objectAtIndex:1];
                            book.source = [components objectAtIndex:2];
                            book.headline = [components objectAtIndex:3];
                            book.name = [components objectAtIndex:4];
                            book.author = [components objectAtIndex:5];
                            book.copyright = [components objectAtIndex:6];
                            book.thumbnail = [NSNumber numberWithInt:[(NSString*)[components objectAtIndex:7] intValue]];
                        } else {
                            Page * page = [self entityForName:@"Page"];
                            page.index = [NSNumber numberWithInt:[(NSString*)[components objectAtIndex:0] intValue]];
                            page.name = [components objectAtIndex:1];
                            page.file = [components objectAtIndex:2];
                            page.nextNoteIndex = [NSNumber numberWithInt:1];
                            page.book = book;
                            [book addPagesObject:page];
                        }
                    }
                }
            }
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSError * error = nil;
            [self.moc save:&error];
            [self.moc reset];
            [delegate onSetupComplete];
        });
        
    });
    
    return NO;
    
}

+ (NSDate *) updateDateForPage:(Page *)page user:(User *)user
{
    NSDate * lastDate = [NSDate distantPast];
    for ( Note * note in page.notes ){
        if ( note.owner == user ){
            lastDate = [lastDate laterDate:note.updateDate];
        }
    }
    return lastDate;
}

+ (NSDate *) creationDateForPage:(Page *)page user:(User *)user
{
    NSDate * lastDate = [NSDate distantPast];
    for ( Note * note in page.notes ){
        if ( note.owner == user ){
            lastDate = [lastDate laterDate:note.creationDate];
        }
    }
    return lastDate;
}

#pragma mark -
#pragma mark Image and file helpers

+ (UIImage *) imageForPage:(Page *)page
{
    return [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] bundlePath],page.file]];
}

+ (UIImage *) thumbnailForPage:(Page *)page
{
    NSFileManager * fm = [NSFileManager defaultManager];
    NSString * defaulThumbnailFile = [page.file stringByReplacingOccurrencesOfString:@"." withString:@"-s."];
    NSString * defaultPath = [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] bundlePath],defaulThumbnailFile];
    return [fm fileExistsAtPath:defaultPath] ? [UIImage imageWithContentsOfFile:defaultPath] : [UIImage imageNamed:DEFAULT_PAGE_THUMBNAIL];
}

+ (UIImage *) thumbnailForBook:(Book *)book
{
    NSFileManager * fileManager = [NSFileManager defaultManager];
    Page * selectedPage = book.pages.anyObject;
    for ( Page * page in book.pages ){
        if ( page.index.intValue == book.thumbnail.intValue ){
            selectedPage = page;
        }
    }
    NSString * shadedThumbnailFile = [selectedPage.file stringByReplacingOccurrencesOfString:@".jpg" withString:@"-s-shad.png"];
    NSString * path = [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] bundlePath],shadedThumbnailFile];
    return  [fileManager fileExistsAtPath:path] ? [UIImage imageWithContentsOfFile:path] : [DataWrapper thumbnailForPage:selectedPage];
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage * newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (NSDictionary *) metadataForImageNamed:(NSString *)path
{
    NSURL * myURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] bundlePath],path]];
    CGImageSourceRef mySourceRef = CGImageSourceCreateWithURL((CFURLRef)myURL, NULL);
    NSDictionary * myMetadata = (NSDictionary *) CGImageSourceCopyPropertiesAtIndex(mySourceRef,0,NULL);
    NSMutableDictionary * dic = [NSMutableDictionary dictionary];
    [dic addEntriesFromDictionary:[myMetadata objectForKey:(NSString *)kCGImagePropertyExifDictionary]];
    [dic addEntriesFromDictionary:[myMetadata objectForKey:(NSString *)kCGImagePropertyExifAuxDictionary]];
    [dic addEntriesFromDictionary:[myMetadata objectForKey:(NSString *)kCGImagePropertyTIFFDictionary]];
    [dic addEntriesFromDictionary:[myMetadata objectForKey:(NSString *)kCGImagePropertyDNGDictionary]];
    [dic addEntriesFromDictionary:[myMetadata objectForKey:(NSString *)kCGImagePropertyGPSDictionary]];
    [myMetadata release];
    CFRelease(mySourceRef);
    return dic;
}

- (void) deleteFileAtPath:(NSString *)path
{
    NSString * fullPath = [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] bundlePath],path];
    NSError * error = nil;
    if ( [self.fileManager fileExistsAtPath:fullPath] && [self.fileManager isDeletableFileAtPath:fullPath] ) {
        [self.fileManager removeItemAtPath:fullPath error:&error];
    } else {
        NSLog(@"file not found or not deletable. %@",fullPath);
    }
    if (error != nil)
    {
        NSLog(@"Error: %@", error);
        NSLog(@"Path to file: %@", fullPath);
    }
}

@end

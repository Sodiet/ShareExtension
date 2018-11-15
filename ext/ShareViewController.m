#import "ShareViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>

#define HIDE_POST_DIALOG

@interface ShareViewController ()

@end

@implementation ShareViewController

NSUInteger m_inputItemCount = 0;

NSString * m_invokeArgs = NULL;
NSString * APP_SHARE_GROUP = @"group.com.promultitouch.magazineone.shared";
const NSString * APP_URL_SCHEME = @"flipabit";
CGFloat m_oldAlpha = 1.0;

- (BOOL)isContentValid {
    return YES;
}

- ( void ) didSelectPost
{
#ifdef HIDE_POST_DIALOG
    return;
#endif
    
    [ self passSelectedItemsToApp ];
}
- ( void ) addImageNameToArgumentList: ( NSString * ) imageName
{
    assert( NULL != imageName );
    
    NSLog( @"ImagePath: %@", imageName );
    
    if ( NULL == m_invokeArgs )
        m_invokeArgs = imageName;
    else
        m_invokeArgs = [ NSString stringWithFormat: @"%@,%@", m_invokeArgs, imageName ];
}

- ( NSString * ) saveImageToAppGroupFolder: ( UIImage * ) image fileName: ( NSString* ) fileName
{
    assert( NULL != image );
    
    NSData * jpegData = UIImageJPEGRepresentation( image, 1.0 );

    NSURL * containerURL = [ [ NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier: APP_SHARE_GROUP ];

    NSString * documentsPath = containerURL.path;
    
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    //NSString *documentsPath = [paths objectAtIndex:0];
    
    NSString * filePath = [ documentsPath stringByAppendingPathComponent: fileName ];
    
    [jpegData writeToFile: filePath atomically: YES ];
    
    NSLog(@"saveImage path: %@", filePath);
    NSLog(@"saveImage name: %@", fileName);
    
    return fileName;
}

- ( void ) passSelectedItemsToApp
{
    NSExtensionItem * item = self.extensionContext.inputItems.firstObject;
    
    m_invokeArgs = NULL;
    m_inputItemCount = item.attachments.count;

    for ( NSItemProvider * itemProvider in item.attachments )
    {
        //Check if it is an Image
        if ( [itemProvider hasItemConformingToTypeIdentifier: ( NSString * ) kUTTypeImage] )
        {
            [ itemProvider loadItemForTypeIdentifier: ( NSString * ) kUTTypeImage options: NULL completionHandler: ^ ( UIImage * image, NSError * error )
            {
                 static int itemIdx = 0;
                
                 if ( NULL != error )
                 {
                     NSLog( @"There was an error retrieving the attachments: %@", error );
                     return;
                 }
                
                 NSString * filePath = [ self saveImageToAppGroupFolder: image fileName:  [[NSUUID new] UUIDString ]];
                
                 NSLog(@"PassSelectedItems: %@", filePath);
                
                 [self addImageNameToArgumentList: filePath ];
                
                 if ( ++itemIdx >= m_inputItemCount )
                     [ self invokeApp: m_invokeArgs ];
             } ];
        }
    }
}
- ( void ) invokeApp: ( NSString * ) invokeArgs
{

    NSString * urlString = [ NSString stringWithFormat: @"%@://%@", APP_URL_SCHEME, ( NULL == invokeArgs ? @"" : invokeArgs ) ];

    UIResponder* responder = self;
    
    while ((responder = [responder nextResponder]) != nil)
    {
        if([responder respondsToSelector:@selector(openURL:)] == YES)
            [responder performSelector:@selector(openURL:) withObject:[NSURL URLWithString:urlString]];
    }
    
    [ super didSelectPost ];
}

#ifdef HIDE_POST_DIALOG
- ( NSArray * ) configurationItems
{
    [ self passSelectedItemsToApp ];

    return @[];
}

- ( void ) willMoveToParentViewController: ( UIViewController * ) parent
{
    m_oldAlpha = [ self.view alpha ];
    [ self.view setAlpha: 0.0 ];
}

- ( void ) didMoveToParentViewController: ( UIViewController * ) parent
{
    [ self.view setAlpha: m_oldAlpha ];
}

- ( id ) init
{
    if ( self = [ super init ] )
        [ [ NSNotificationCenter defaultCenter ] addObserver: self selector: @selector( keyboardWillShow: ) name: UIKeyboardWillShowNotification    object: nil ];
    
    return self;
}

- ( void ) keyboardWillShow: ( NSNotification * ) note
{
    [ self.view endEditing: true ];
}
#endif

@end

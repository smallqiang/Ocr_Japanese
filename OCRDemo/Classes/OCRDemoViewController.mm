//
//  OCRDemoViewController.m
//  OCRDemo
//
//  Created by Nolan Brown on 12/30/09.
//

#import "OCRDemoViewController.h"
#import "baseapi.h"
#import "JSON.h"
#include <math.h>
static inline double radians (double degrees) {return degrees * M_PI/180;}

@implementation OCRDemoViewController

@synthesize iv,alert;
@synthesize ocrTextView=_ocrTextView;
@synthesize textView=_textView;
@synthesize responseData=_responseData;

@synthesize translateButton=_translateButton;

@synthesize contentString=_contentString;

// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization

    }
    return self;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad {
	[super viewDidLoad];
    
    [self startTesseract];
}

- (void)dealloc {
    tess->End();
    
    [imagePickerController release];
    imagePickerController=nil;
    
	[iv release];
	iv = nil;
    
    [alert release];
    
    [_ocrTextView release];
    _ocrTextView=nil;
    
    [_textView release];
    _textView=nil;
    
    [_responseData release];
    _responseData=nil;
    
    [_translateButton release];
    _translateButton=nil;
    
    [_contentString release];
    _contentString=nil;
    
    [super dealloc];

}


#pragma mark -
#pragma mark IBAction
- (IBAction) takePhoto:(id) sender
{
    [_ocrTextView resignFirstResponder];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.delegate = self;
        imagePickerController.sourceType =  UIImagePickerControllerSourceTypeCamera;
        [imagePickerController setAllowsEditing:YES];
        
        [self presentModalViewController:imagePickerController animated:YES];
        
        [imagePickerController release];
    }
}
- (IBAction) findPhoto:(id) sender
{ 
    [_ocrTextView resignFirstResponder];
    imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
    [imagePickerController setAllowsEditing:YES];
	
	[self presentModalViewController:imagePickerController animated:YES];
    
    [imagePickerController release];
}

#pragma mark -

- (NSString *) applicationDocumentsDirectory
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
	NSString *documentsDirectoryPath = [paths objectAtIndex:0];
	return documentsDirectoryPath;
}

#pragma mark -
#pragma mark Image Processsing
- (void) startTesseract
{
	//code from http://robertcarlsen.net/2009/12/06/ocr-on-iphone-demo-1043

	NSString *dataPath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"tessdata"];
	/*
	 Set up the data in the docs dir
	 want to copy the data to the documents folder if it doesn't already exist
	 */
	NSFileManager *fileManager = [NSFileManager defaultManager];
	// If the expected store doesn't exist, copy the default store.
	if (![fileManager fileExistsAtPath:dataPath]) {
		// get the path to the app bundle (with the tessdata dir)
		NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
		NSString *tessdataPath = [bundlePath stringByAppendingPathComponent:@"tessdata"];
		if (tessdataPath) {
			[fileManager copyItemAtPath:tessdataPath toPath:dataPath error:NULL];
		}
	}
	
	NSString *dataPathWithSlash = [[self applicationDocumentsDirectory] stringByAppendingString:@"/"];
	setenv("TESSDATA_PREFIX", [dataPathWithSlash UTF8String], 1);
	
	// init the tesseract engine.
	tess = new tesseract::TessBaseAPI();
	
	tess->Init([dataPath cStringUsingEncoding:NSUTF8StringEncoding],    // Path to tessdata-no ending /.
               "jpn"                                                    // ISO 639-3 string or NULL.
               );
}

- (NSString *) ocrImage: (UIImage *) uiImage
{
	// <MARCELO>

	CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *          bitmapData;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
    int             bitsPerComponent = 8;
	int width;
	int height;
	
	
	CGImageRef image = uiImage.CGImage;
	
	int numberOfComponents = 4;
	
	width = CGImageGetWidth(image);
	height = CGImageGetHeight(image);
	CGRect imageRect = {{0,0},{width, height}};
	// Declare the number of bytes per row. Each pixel in the bitmap in this example is represented by 4 bytes; 8 bits each of red, green, blue, and  alpha.
	bitmapBytesPerRow   = (width * numberOfComponents);
	bitmapByteCount     = (bitmapBytesPerRow * height);
	
	// Allocate memory for image data. This is the destination in memory
	// where any drawing to the bitmap context will be rendered.
	bitmapData = malloc( bitmapByteCount );
	if (bitmapData == NULL) {
		CGColorSpaceRelease( colorSpace );
		return @"";
	}
	
	context = CGBitmapContextCreate (bitmapData, width, height, 
									 bitsPerComponent, bitmapBytesPerRow, colorSpace,
									 kCGImageAlphaPremultipliedFirst);//kCGImageAlphaNoneSkipFirst);//kCGImageAlphaNone);//
	if (context == NULL)  {
		free (bitmapData);
		CGColorSpaceRelease( colorSpace );
		return @"";
	}
	
	CGContextDrawImage(context, imageRect, image);
	CGColorSpaceRelease( colorSpace );
	void * buf = CGBitmapContextGetData (context);	

	char* text = tess->TesseractRect((unsigned char*)buf, 4, bitmapBytesPerRow, 0, 0, width, height);
	
	free( buf );
    
	if(text==nil)
    {
        return nil;
    }
    else
    {
	return [NSString stringWithCString:text encoding:NSUTF8StringEncoding];
    }
}

-(UIImage *)resizeImage:(UIImage *)image {
	
	CGImageRef imageRef = [image CGImage];
	CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
	CGColorSpaceRef colorSpaceInfo = CGColorSpaceCreateDeviceRGB();
	
	if (alphaInfo == kCGImageAlphaNone)
		alphaInfo = kCGImageAlphaNoneSkipLast;
	
	int width, height;
	
	width = 640;//[image size].width;
	height = 640;//[image size].height;
	
	CGContextRef bitmap;
	
	if (image.imageOrientation == UIImageOrientationUp | image.imageOrientation == UIImageOrientationDown) {
		bitmap = CGBitmapContextCreate(NULL, width, height, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, alphaInfo);
		
	} else {
		bitmap = CGBitmapContextCreate(NULL, height, width, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, alphaInfo);
		
	}
	
	if (image.imageOrientation == UIImageOrientationLeft) {
		NSLog(@"image orientation left");
		CGContextRotateCTM (bitmap, radians(90));
		CGContextTranslateCTM (bitmap, 0, -height);
		
	} else if (image.imageOrientation == UIImageOrientationRight) {
		NSLog(@"image orientation right");
		CGContextRotateCTM (bitmap, radians(-90));
		CGContextTranslateCTM (bitmap, -width, 0);
		
	} else if (image.imageOrientation == UIImageOrientationUp) {
		NSLog(@"image orientation up");	
		
	} else if (image.imageOrientation == UIImageOrientationDown) {
		NSLog(@"image orientation down");	
		CGContextTranslateCTM (bitmap, width,height);
		CGContextRotateCTM (bitmap, radians(-180.));
		
	}
	
	CGContextDrawImage(bitmap, CGRectMake(0, 0, width, height), imageRef);
	CGImageRef ref = CGBitmapContextCreateImage(bitmap);
	UIImage *result = [UIImage imageWithCGImage:ref];
	
	CGContextRelease(bitmap);
	CGImageRelease(ref);
	
	return result;	
}

// <MARCELO>
-(void)doOCR:(UIImage*)image
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *textString = [self ocrImage:image];
	
    [self performSelectorOnMainThread:@selector(reloadTextView:) withObject:textString waitUntilDone:NO];
    
	[pool release];
	
	[alert dismissWithClickedButtonIndex:0 animated:YES];
    [alert release];
}

-(void)reloadTextView:(NSString *)textString
{
    _ocrTextView.text=textString;
}
// </MARCELO>

#pragma mark -
#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker 
		didFinishPickingImage:(UIImage *)image
				  editingInfo:(NSDictionary *)editingInfo
{
    _ocrTextView.text=nil;
    _textView.hidden=YES;
    iv.hidden=NO;
    
    iv.image=image;
    
	alert = [[UIAlertView alloc] initWithTitle:nil message:@"识别中..." delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
	[alert show];
	
	[picker dismissModalViewControllerAnimated:YES];
	
	[NSThread detachNewThreadSelector:@selector(doOCR:) toTarget:self withObject:image];
	// </MARCELO>
}

-(IBAction)translate:(id)sender
{
    [_ocrTextView resignFirstResponder];
    
    if ([_ocrTextView.text length]==0) {
        alert = [[UIAlertView alloc] initWithTitle:nil message:@"请输入翻译内容！" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    }
    else
    {
    _textView.text=nil;
    _textView.hidden=NO;
    iv.hidden=YES;    
        
    alert = [[UIAlertView alloc] initWithTitle:nil message:@"翻译中..." delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    [alert show];    
    
    [self performTranslation];
    }
}

-(void)performTranslation
{
    _responseData = [[NSMutableData data] retain];
    
    NSString *langString = @"ja|zh-CN";
    
    NSString *textString=_ocrTextView.text;
    
    NSArray *array=[textString componentsSeparatedByString:@"\n"];
    
    _contentString=[[NSString alloc]init];
    
    for (int i=0; i<[array count]; i++) {
        if ([[array objectAtIndex:i] length]!=0) {
            _contentString=[_contentString stringByAppendingString:[NSString stringWithFormat:@"&q=%@",[array objectAtIndex:i]]];
        }
    }
    
    NSString *langtextString = [_contentString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *langStringEscaped = [langString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *url =[NSString stringWithFormat:@"http://ajax.googleapis.com/ajax/services/language/translate?v=1.0%@&langpair=%@",langtextString,langStringEscaped];
    
    //NSString *url=[NSString stringWithFormat:@"https://www.googleapis.com/language/translate/v2?source=ja&target=zh-CN&q=%@",langtextString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [[NSURLConnection alloc] initWithRequest:request delegate:self];

}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
     [_responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [connection release];
    
    NSString *responseString = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
    
    [_responseData release];
    
    NSMutableDictionary *luckyNumbers = [responseString JSONValue];
    [responseString release];
    if (luckyNumbers != nil) {
        
        NSDecimalNumber * responseStatus = [luckyNumbers objectForKey:@"responseStatus"];
        if ([responseStatus intValue] != 200) {
            return;
        }
        
        NSMutableArray *responseDataArray = (NSMutableArray *)[luckyNumbers objectForKey:@"responseData"];
        if (responseDataArray != nil) {
            NSString *stringText=[[NSString alloc]init];
            
            if ([responseDataArray count]==1) {
                NSString *translatedText = [(NSDictionary *)responseDataArray objectForKey:@"translatedText"];
                _textView.text=translatedText;
            }
            
            else
            {
            for (int i=0; i<[responseDataArray count]; i++) {
                stringText=[stringText stringByAppendingFormat:@"%@\n",[[(NSDictionary *)[responseDataArray objectAtIndex:i] objectForKey:@"responseData"] objectForKey:@"translatedText"]];
            }
            _textView.text=stringText;
            }
        }
    }
    
    [alert dismissWithClickedButtonIndex:0 animated:YES];
    [alert release];
}

@end

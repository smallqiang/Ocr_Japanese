//
//  OCRDemoViewController.h
//  OCRDemo
//
//  Created by Nolan Brown on 12/30/09.

//

#import <UIKit/UIKit.h>
#import "baseapi.h"

@interface OCRDemoViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>{
	//UIImagePickerController *imagePickerController;
    tesseract::TessBaseAPI *tess;
	UIImageView *iv;
	UIAlertView *alert;
    
    UITextView *_ocrTextView;
    UITextView *_textView;
    
    UIButton *_translateButton;

    NSMutableData *_responseData;
    
    NSString *_contentString;
    
    UIImagePickerController *imagePickerController;
}
@property (nonatomic, retain) IBOutlet UIImageView *iv;
@property (nonatomic, retain) UIAlertView *alert;

@property (nonatomic, retain) IBOutlet UITextView *ocrTextView;
@property (nonatomic, retain) IBOutlet UITextView *textView;

@property (nonatomic, retain) NSMutableData *responseData;

@property (nonatomic, retain) IBOutlet UIButton *translateButton;

@property (nonatomic, retain) NSString *contentString;

- (IBAction) findPhoto:(id) sender;
- (IBAction) takePhoto:(id) sender;

-(IBAction)translate:(id)sender;
-(IBAction)performTranslation;

- (void) startTesseract;
- (NSString *) applicationDocumentsDirectory;
- (NSString *) ocrImage: (UIImage *) uiImage;
-(UIImage *)resizeImage:(UIImage *)image;

@end

//
//  OCRDemoViewController.h
//  OCRDemo
//
//  Created by Nolan Brown on 12/30/09.

//

#import <UIKit/UIKit.h>
#import "baseapi.h"

@interface OCRDemoViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>{
	UIImagePickerController *imagePickerController;
    tesseract::TessBaseAPI *tess;
	UIImageView *iv;
	UILabel *label;
	UIAlertView *alert;

}
@property (nonatomic, retain) IBOutlet UIImageView *iv;
@property (nonatomic, retain) IBOutlet UILabel *label;


- (IBAction) findPhoto:(id) sender;
- (IBAction) takePhoto:(id) sender;

- (void) startTesseract;
- (NSString *) applicationDocumentsDirectory;
- (NSString *) ocrImage: (UIImage *) uiImage;
-(UIImage *)resizeImage:(UIImage *)image;

@end

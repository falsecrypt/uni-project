//
//  ChangeAccountImageViewController.m
//  uni-project
//
//  Created by Pavel Ermolin on 13.05.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import "ChangeAccountImageVC.h"
#import "User.h"
#import "EMNetworkManager.h"
#import "AFHTTPRequestOperation.h"

@interface ChangeAccountImageVC ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *existingFotoButton;
@property (strong, nonatomic) UIPopoverController *popover;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (strong, nonatomic) UIImagePickerController *imagePicker;
@property (strong, nonatomic) User *me;

@end

@implementation ChangeAccountImageVC

static bool _newMedia;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.delegate = self;
    // show controls for moving & scaling pictures:
    self.imagePicker.allowsEditing = YES;
    self.me = [User findFirstByAttribute:@"sensorid" withValue:@(MySensorID)];
    NSData *imgData = self.me.profileimage;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([imgData length] > 0) {
            UIImage *profileImg = [[UIImage alloc]initWithData: imgData];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.imageView setImage:profileImg];
            });
        }
        
    });
    
    self.imageView.layer.cornerRadius = 10.0;
    self.imageView.clipsToBounds = YES;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)useCameraRoll:(UIButton *)sender {
    
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    if (self.popover != nil) {
        [self.popover dismissPopoverAnimated:YES];
        self.popover=nil;
    }
    
    self.popover = [[UIPopoverController alloc] initWithContentViewController:self.imagePicker];
    CGRect popoverRect = [self.view convertRect:[self.existingFotoButton frame]
                                       fromView:[self.existingFotoButton superview]];
    
    popoverRect.size.width = MIN(popoverRect.size.width, 100) ;
    popoverRect.origin.x = popoverRect.origin.x;
    
    [self.popover
     presentPopoverFromRect:popoverRect
     inView:self.view
     permittedArrowDirections:UIPopoverArrowDirectionAny
     animated:YES];
    
    _newMedia = NO;
}

- (IBAction)useCamera:(id)sender {
    // the simulator has no camera ;-)
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                              message:@"Device has no camera"
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles: nil];
        [myAlertView show];
        
    }
    
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        // Default Prop. value for mediaTypes is 'kUTTypeImage'
        [self presentViewController:self.imagePicker animated:YES completion:NULL];
        _newMedia = YES;
  
    }
}

////////////////////////////////////////////////
// Delegate Methods of UIImagePickerController
///////////////////////////////////////////////

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    

    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    self.imageView.image = chosenImage;
    NSData *imgData = UIImageJPEGRepresentation(chosenImage, 0.5);
    NSString *imgType = [self contentTypeForImageData:imgData]; // jpeg or png?
    DLog(@"imgType %@ ", imgType);
    if (![imgType isEqualToString:@"image/jpeg"]) {
        UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                              message:@"Nur JPG-Bilder sind erlaubt"
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles: nil];
        [myAlertView show];
        return;
    }
    if (_newMedia) {
        // Save the new image (original or edited) to the Camera Roll
        UIImageWriteToSavedPhotosAlbum(chosenImage, self, @selector(image:finishedSavingWithError:contextInfo:), nil);
    }
    
    if (self.popover.isPopoverVisible) {
        [self.popover dismissPopoverAnimated:true];
    }
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    CGSize size = chosenImage.size;
    DLog(@"saving new image with size: height: %f width: %f ", size.height, size.width);
    DLog(@"storing image data with size: %@ ", [NSByteCountFormatter stringFromByteCount:imgData.length countStyle:NSByteCountFormatterCountStyleFile]);
    // Now save the image in the DB

    self.me = [User findFirstByAttribute:@"sensorid" withValue:@(MySensorID)];
    self.me.profileimage = imgData;
    
    [[NSManagedObjectContext defaultContext]  saveInBackgroundCompletion:^{
        User *me = [User findFirstByAttribute:@"sensorid" withValue:@(MySensorID)];
        DLog(@"NEW USER SAVED! me: %@", me);
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:NewAccountImageAvailable
                                                                object:self];
        });
        [self sendNewImageToServer:imgData];
    }];
    
}
// user canceled the operation
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    if (self.popover.isPopoverVisible) {
        [self.popover dismissPopoverAnimated:true];
    }
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}
// something went wrong
-(void)image:(UIImage *)image finishedSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle: @"Save failed"
                              message: @"Failed to save image"
                              delegate: nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)sendNewImageToServer:(NSData *)imgData {
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:@"put" forKey:@"action"];
    [parameters setObject:@(1) forKey:@"avatar"];
    [parameters setObject:@(MySensorID) forKey:@"userID"];
    
    NSMutableURLRequest *request = [[EMNetworkManager sharedClient] multipartFormRequestWithMethod:@"POST"
                                                                                              path:@"rpc.php"
                                                                                        parameters:parameters
                                                                         constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
        [formData appendPartWithFileData:imgData name:@"image" fileName:@"avatar.jpg" mimeType:@"image/jpeg"];
    }];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = [operation responseString];
        DLog(@"response: [%@], responseObj: %@",response, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if([operation.response statusCode] == 403){
            DLog(@"Upload Failed");
            return;
        }
        DLog(@"error: %@", [operation error]);
    }];
    
    [operation start];
}

// H3lp method
- (NSString *)contentTypeForImageData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
            return @"image/jpeg";
        case 0x89:
            return @"image/png";
        case 0x47:
            return @"image/gif";
        case 0x49:
        case 0x4D:
            return @"image/tiff";
    }
    return nil;
}
@end

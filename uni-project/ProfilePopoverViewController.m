//
//  ProfilePopoverViewController.m
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import "ProfilePopoverViewController.h"
#import "KeychainItemWrapper.h"
#import "User.h"
#import "Participant.h"

@interface ProfilePopoverViewController ()
@property (strong, nonatomic) UIImageView *imageView;
@end

@implementation ProfilePopoverViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    KeychainItemWrapper *keychain =
    [[KeychainItemWrapper alloc] initWithIdentifier:@"EcoMeterAccountData" accessGroup:nil];
    if ([[keychain objectForKey:(__bridge id)(kSecAttrLabel)] isEqualToString:@"LOGGEDIN"]) { //kSecAttrIsInvisible = NO
        self.userName.text = [keychain objectForKey:(__bridge id)kSecAttrAccount];
    }
    else {
        self.userName.text = @"User is not logged in";
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.contentSizeForViewInPopover = CGSizeMake(150.0, 180.0);
    UIView* popoverView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 140, 180)];
    popoverView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];

    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(updateAccountImage)
     name:NewAccountImageAvailable
     object:nil];
    
    // width, height = 100
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 100, 100)];
    self.imageView.layer.cornerRadius = 10.0;
    self.imageView.clipsToBounds = YES;
    User *me = [User findFirstByAttribute:@"sensorid" withValue:@(MySensorID)];
    Participant *participantObj = [Participant findFirstByAttribute:@"sensorid" withValue:@(MySensorID)];
    NSData *imgData = me.profileimage;
    NSLog(@"getting image data with size: %@ ", [NSByteCountFormatter stringFromByteCount:imgData.length countStyle:NSByteCountFormatterCountStyleFile]);
    NSLog(@"getting image data with size: %@ ", [NSByteCountFormatter stringFromByteCount:participantObj.profileimage.length countStyle:NSByteCountFormatterCountStyleFile]);
    if ([imgData length] > 0) {
        UIImage *profileImg = [[UIImage alloc]initWithData: imgData];
        [self.imageView setImage:profileImg];
    }
    else if ([participantObj.profileimage length] > 0){
        UIImage *profileImg = [[UIImage alloc]initWithData: participantObj.profileimage];
        [self.imageView setImage:profileImg];
    }
    else {
        UIImage *img = [UIImage imageNamed:@"defaultAvatar.png"];
        [self.imageView setImage:img];
    }

    self.userName = [[UILabel alloc] initWithFrame:CGRectMake(10,110,120,20)];
    self.userName.backgroundColor = [UIColor clearColor];
    self.userName.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];

    KeychainItemWrapper *keychain =
    [[KeychainItemWrapper alloc] initWithIdentifier:@"EcoMeterAccountData" accessGroup:nil];
    if ([[keychain objectForKey:(__bridge id)(kSecAttrLabel)] isEqualToString:@"LOGGEDIN" ]) {
        self.userName.text = [keychain objectForKey:(__bridge id)kSecAttrAccount];
    }
    else {
        self.userName.text = @"User is not logged in";
    }
    
    CGRect logOffButtonFrame = CGRectMake( 10, 140, 100, 30 );
    //UIButton *logOffButton = [[UIButton alloc] initWithFrame: buttonFrame];
    UIButton *logOffButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    logOffButton.frame = logOffButtonFrame;
    [logOffButton setTitle: @"Abmelden" forState: UIControlStateNormal];
    [logOffButton addTarget:self action:@selector(didSelectLogOff:) forControlEvents:UIControlEventTouchUpInside];
    [logOffButton setTitleColor: [UIColor lightGrayColor] forState: UIControlStateNormal];
    //[logOffButton setBackgroundColor: [UIColor lightGrayColor]];
    
    [popoverView addSubview:self.imageView];
    [popoverView addSubview:self.userName];
    [popoverView addSubview:logOffButton];
    
    self.view = popoverView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didSelectLogOff:(id)sender {
    
    KeychainItemWrapper *keychain =
    [[KeychainItemWrapper alloc] initWithIdentifier:@"EcoMeterAccountData" accessGroup:nil];
    // Log off user
    [keychain setObject:@"LOGGEDOFF" forKey:(__bridge id)(kSecAttrLabel)];
    NSString *notificationName = @"UserLoggedOffNotification";
    [[NSNotificationCenter defaultCenter]
     postNotificationName:notificationName
     object:nil];
    
}

- (void)updateAccountImage {
    User *me = [User findFirstByAttribute:@"sensorid" withValue:@(MySensorID)];
    NSData *imgData = me.profileimage;
    UIImage *profileImg = [[UIImage alloc]initWithData: imgData];
    [self.imageView setImage:profileImg];
}


/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"CellIdentifier";
    
    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    [cell.textLabel setFont:[UIFont fontWithName:@"Bold" size:20]];
    
    // Configure the cell.
    cell.textLabel.text = @"test";
    return cell;
} */

@end

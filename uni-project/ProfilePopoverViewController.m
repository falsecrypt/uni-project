//
//  ProfilePopoverViewController.m
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import "ProfilePopoverViewController.h"
#import "KeychainItemWrapper.h"

@interface ProfilePopoverViewController ()

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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    KeychainItemWrapper *keychain =
    [[KeychainItemWrapper alloc] initWithIdentifier:@"EcoMeterAccountData" accessGroup:nil];
    if ([defaults boolForKey:@"userLoggedIn"]) {
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
    
    self.contentSizeForViewInPopover = CGSizeMake(140.0, 150.0);
    UIView* popoverView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 140, 150)];
    popoverView.backgroundColor = [UIColor whiteColor];
    /*UITableView *table = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, 150, 140) style:UITableViewStylePlain];
    table.backgroundColor=[UIColor whiteColor];
    [table setDataSource:self];
    [table setDelegate:self];
    [table setRowHeight:80];
    [self.view addSubview:table];
    [popoverView addSubview:table];*/
    
    // width, height = 100
    UIImageView *profilePic = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 100, 100)];
    UIImage *img = [UIImage imageNamed:@"defaultAvatar.png"];
    [profilePic setImage:img];
    
    self.userName = [[UILabel alloc] initWithFrame:CGRectMake(10,110,120,20)];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    KeychainItemWrapper *keychain =
    [[KeychainItemWrapper alloc] initWithIdentifier:@"EcoMeterAccountData" accessGroup:nil];
    if ([defaults boolForKey:@"userLoggedIn"]) {
        self.userName.text = [keychain objectForKey:(__bridge id)kSecAttrAccount];
    }
    else {
        self.userName.text = @"User is not logged in";
    }
    
    
    [popoverView addSubview:profilePic];
    [popoverView addSubview:self.userName];
    
    self.view = popoverView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

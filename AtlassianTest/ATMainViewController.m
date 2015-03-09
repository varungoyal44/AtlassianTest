//
//  ATMainViewController.m
//  AtlassianTest
//
//  Created by Varun Goyal on 3/6/15.
//  Copyright (c) 2015 CrazyKarma. All rights reserved.
//

#import "ATMainViewController.h"
#import "ATMessageMapper.h"

@interface ATMainViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *labelOutput;
@property (weak, nonatomic) IBOutlet UITextField *textFieldInput;
@property (weak, nonatomic) IBOutlet UIButton *buttonTest;
@property (strong, nonatomic) ATMessageMapper *message;
@end



@implementation ATMainViewController
#pragma mark- Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}





#pragma mark- Action
- (IBAction)buttonTestWasPressed:(id)sender {
    if(self.textFieldInput.text.length > 0){
        self.message = [[ATMessageMapper alloc] initWithMessage:self.textFieldInput.text];
    }
}


- (IBAction)textFieldInputDidEndEditing:(id)sender{
    [self buttonTestWasPressed:sender];
}






@end

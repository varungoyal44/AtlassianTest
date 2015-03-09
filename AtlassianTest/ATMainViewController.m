//
//  ATMainViewController.m
//  AtlassianTest
//
//  Created by Varun Goyal on 3/6/15.
//  Copyright (c) 2015 CrazyKarma. All rights reserved.
//

#import "ATMainViewController.h"
#import "ATMessageMapper.h"

@interface ATMainViewController () <ATMessageMapperDelegate>
@property BOOL isKeyboardDisplayed;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UITextField *textFieldInput;
@property (weak, nonatomic) IBOutlet UIButton *buttonSend;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@end



@implementation ATMainViewController
#pragma mark- Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [self.activityIndicator stopAnimating];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}


#pragma mark- Action
/**
 * This method will instantiate the class to handle the message sent by the user.
 * Even though most of the heavy lifing is carried out in a background thread,
 * still the app waits for the result to be returned (by the delegate method),
 * all the while not letting the user to input more messages, hence conceptually
 * blocking the UI.
 *
 * Depending upon the requirement such a behaviour could be changed.
 */
- (IBAction)buttonSendWasPressed:(id)sender {
    if(self.textFieldInput.text.length > 0){
        ATMessageMapper *message = [[ATMessageMapper alloc] initWithMessage:self.textFieldInput.text];
        message.delegate = self;
        
        [self.textFieldInput resignFirstResponder];
        [self.buttonSend setEnabled:NO]; // so that multiple requests cannot be sent...
        [self.activityIndicator startAnimating];
    }
}

#pragma mark- ATMessageMapperDelegate method
/**
 * This delegate method will be returned once all the data has been parsed to extract
 * the required data from the message entered by the user and then converted into a JSON object.
 */
- (void) messageMapper:(ATMessageMapper *) messageMapper
         didCreateJSON:(NSString *) returnString
{
    [self.textFieldInput setText:@""];
    [self.buttonSend setEnabled:YES];
    [self.activityIndicator stopAnimating];
    
    NSString *text = [NSString stringWithFormat:@"Message: %@\n\nReturn (string):\n%@", messageMapper.originalString, returnString];
    [self.textView setText:text];
    
}


#pragma mark- keyboard
- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary* userInfo = [notification userInfo];
    
    // get the size of the keyboard.
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // resize the view.
    CGRect viewFrame = self.view.frame;
    viewFrame.size.height += (keyboardSize.height);
    
    // animate the resize with keyboard.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [self.view setFrame:viewFrame];
    [UIView commitAnimations];
    self.isKeyboardDisplayed = NO;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary* userInfo = [notification userInfo];
    
    // get the size of the keyboard.
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // resize the view.
    CGRect viewFrame = self.view.frame;
    viewFrame.size.height = viewFrame.size.height - keyboardSize.height;
    
    // animate the resize with keyboard.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [self.view setFrame:viewFrame];
    [UIView commitAnimations];
    self.isKeyboardDisplayed = YES;
}



@end

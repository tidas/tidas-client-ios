//
//  ViewController.m
//  tidas_objc_prototype
//
//  Created by ryan on 7/1/15.
//  Copyright © 2015 trailofbits. All rights reserved.
//

#import "ViewController.h"
#import "Tidas.h"

@interface ViewController ()
@property (nonatomic, strong) UITextView *textToSign;
@property (nonatomic, strong) UITextView *console;
@end

@implementation ViewController

@synthesize textToSign, console;

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	UIButton *enrollButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	enrollButton.frame = CGRectMake(5,22,300,44);
  enrollButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
	[enrollButton addTarget:self action:@selector(enroll) forControlEvents:UIControlEventTouchUpInside];
  [enrollButton setTitle:@"Generate Enrollment Request TidasBlob" forState:UIControlStateNormal];
	[self.view addSubview:enrollButton];
  
  UIButton *signButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  signButton.frame = CGRectMake(5,66,300,44);
  signButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
  [signButton addTarget:self action:@selector(validate) forControlEvents:UIControlEventTouchUpInside];
  [signButton setTitle:@"Generate Validation Request TidasBlob" forState:UIControlStateNormal];
  [self.view addSubview:signButton];

  UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  resetButton.frame = CGRectMake(5,110,120,44);
  resetButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
  [resetButton addTarget:self action:@selector(reset) forControlEvents:UIControlEventTouchUpInside];
  [resetButton setTitle:@"Reset Keychain" forState:UIControlStateNormal];
  [self.view addSubview:resetButton];

  UILabel *inputLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 160, 300, 22)];
  inputLabel.font = [UIFont systemFontOfSize:12];
  inputLabel.text = @"Text Input";
  [self.view addSubview:inputLabel];
  textToSign = [[UITextView alloc] initWithFrame:CGRectMake(5, 187, 300, 87)];
  textToSign.layer.borderWidth = 1;
  textToSign.layer.borderColor = [[UIColor colorWithWhite:0.7 alpha:1] CGColor];
  [self.view addSubview:textToSign];
  
  UILabel *consoleLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 326, 300, 22)];
  consoleLabel.font = [UIFont systemFontOfSize:12];
  consoleLabel.text = @"Output Console";
  [self.view addSubview:consoleLabel];

  console = [[UITextView alloc] initWithFrame:CGRectMake(5, 351, 300, 150)];
  console.layer.borderWidth = 1;
  console.layer.borderColor = [[UIColor colorWithWhite:0.7 alpha:1] CGColor];
  console.layer.backgroundColor = [[UIColor colorWithWhite:0.95 alpha:1] CGColor];

  UIView *dummyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
  console.inputView = dummyView;
  [self.view addSubview:console];
  
  UITapGestureRecognizer *tgr = [UITapGestureRecognizer new];
  [tgr addTarget:self action:@selector(hideKeyboard)];
  [self.view addGestureRecognizer:tgr];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  for (UIButton *button in self.view.subviews) {
    if ([button class] != [UIButton class]){
      continue;
    }
    [button addTarget:self action:@selector(hideKeyboard) forControlEvents:UIControlEventTouchUpInside];
  }
}

- (void)hideKeyboard {
  [self.view endEditing:true];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


- (void)enroll {
  Tidas *ti = [Tidas sharedInstance];
  __block NSString *enrollmentData;
  [ti generateEnrollmentRequestWithCompletion:^(NSString *string, NSError *err) {
    if (string) {
      enrollmentData = string;
      [console setText: [NSString stringWithFormat:@"Enrollment request data: %@\n", enrollmentData]];
    }
    else{
      [console setText: [NSString stringWithFormat:@"Error: %@", err] ];
    }
  }];
  
}

- (void)validate {
  Tidas *ti = [Tidas sharedInstance];
  NSString *inputString = textToSign.text;
  __block NSString *validationData;
  NSData *stringData = [NSData dataWithBytes:[inputString UTF8String] length:[inputString length]];
  [ti generateValidationRequestForData:stringData withCompletion:^(NSString *string, NSError *err) {
    if (string){
      validationData = string;
      [console setText: [NSString stringWithFormat:@"Validation request data: %@\n", validationData]];
    }
    else {
      [console setText: [NSString stringWithFormat:@"Error: %@", err] ];
    }
  }];
}

- (void)reset {
  [[Tidas sharedInstance] resetKeychain];
}

@end

//
//  RegisterViewController.m
//  ZFUB
//
//  Created by 徐宝桥 on 15/2/10.
//  Copyright (c) 2015年 ___MyCompanyName___. All rights reserved.
//

#import "RegisterViewController.h"
#import "MobileRegisterController.h"
#import "EmailRegisterController.h"
#import "RegularFormat.h"
#import "NetworkInterface.h"

@interface RegisterViewController ()<UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UITextField *inputField;

@property (nonatomic, strong) UIButton *sendButton;

@property (nonatomic, assign) BOOL isMobile;

@end

@implementation RegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"注册";
    [self initAndLayoutUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI

- (void)initAndLayoutUI {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.backgroundColor = kColor(244, 243, 243, 1);
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self setHeaderAndFooterView];
    [self.view addSubview:_tableView];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_tableView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_tableView
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1.0
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_tableView
                                                          attribute:NSLayoutAttributeRight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1.0
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_tableView
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0
                                                           constant:0]];
    
    _inputField = [[UITextField alloc] init];
    _inputField.delegate = self;
    _inputField.placeholder = @"输入手机/邮箱";
    _inputField.font = [UIFont systemFontOfSize:15.f];
    _inputField.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _sendButton.titleLabel.font = [UIFont systemFontOfSize:12.f];
    _sendButton.layer.cornerRadius = 4.f;
    _sendButton.layer.masksToBounds = YES;
    [_sendButton setBackgroundImage:kImageName(@"light_red.png") forState:UIControlStateNormal];
    [_sendButton addTarget:self action:@selector(sendInfo:) forControlEvents:UIControlEventTouchUpInside];
    [_sendButton setTitle:@"发送验证码" forState:UIControlStateNormal];
}

- (void)setHeaderAndFooterView {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 20)];
    headerView.backgroundColor = [UIColor clearColor];
    _tableView.tableHeaderView = headerView;
    
    UIView *footerView = [[UIView alloc] init];
    footerView.backgroundColor = [UIColor clearColor];
    _tableView.tableFooterView = footerView;
}

- (void)setIsMobile:(BOOL)isMobile {
    _isMobile = isMobile;
    if (_isMobile) {
        _sendButton.hidden = NO;
    }
    else {
        _sendButton.hidden = YES;
    }
}

- (void)registerWithEmail {
    if ([RegularFormat isCorrectEmail:_inputField.text]) {
        EmailRegisterController *emailC = [[EmailRegisterController alloc] init];
        emailC.email = _inputField.text;
        [self.navigationController pushViewController:emailC animated:YES];
    }
    else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        hud.customView = [[UIImageView alloc] init];
        hud.mode = MBProgressHUDModeCustomView;
        [hud hide:YES afterDelay:1.f];
        hud.labelText = @"请输入正确的邮箱号";
    }
}

#pragma mark - Action

- (IBAction)sendInfo:(id)sender {
    [_inputField resignFirstResponder];
    if ([RegularFormat isMobileNumber:_inputField.text]) {
        [self sendMobileValidate];
    }
    else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        hud.customView = [[UIImageView alloc] init];
        hud.mode = MBProgressHUDModeCustomView;
        [hud hide:YES afterDelay:1.f];
        hud.labelText = @"请输入正确的手机号";
    }
}

#pragma mark - Data

//发送验证码
- (void)sendMobileValidate {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.labelText = @"正在发送...";
    [NetworkInterface getRegisterValidateCodeWithMobileNumber:_inputField.text finished:^(BOOL success, NSData *response) {
        hud.customView = [[UIImageView alloc] init];
        hud.mode = MBProgressHUDModeCustomView;
        [hud hide:YES afterDelay:0.3f];
        if (success) {
            id object = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingMutableLeaves error:nil];
            if ([object isKindOfClass:[NSDictionary class]]) {
                if ([[object objectForKey:@"code"] intValue] == RequestSuccess) {
                    [hud setHidden:YES];
                    NSString *validate = [object objectForKey:@"result"];
                    MobileRegisterController *mobileC = [[MobileRegisterController alloc] init];
                    mobileC.validate = validate;
                    mobileC.phoneNumber = _inputField.text;
                    [self.navigationController pushViewController:mobileC animated:YES];
                }
                else {
                    hud.labelText = [NSString stringWithFormat:@"错误代码:%@",[object objectForKey:@"code"]];
                }
            }
            else {
                hud.labelText = kServiceReturnWrong;
            }
        }
        else {
            hud.labelText = kNetworkFailed;
        }
    }];
}


#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    CGFloat buttonWidth = 100;
    CGFloat space = 10.f;
    _inputField.frame = CGRectMake(10, (cell.frame.size.height - 30) / 2, kScreenWidth - buttonWidth - 3 * space, 30);
    _sendButton.frame = CGRectMake(kScreenWidth - 110, (cell.frame.size.height - 30) / 2, 100, 30);
    [cell.contentView addSubview:_inputField];
    [cell.contentView addSubview:_sendButton];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [_inputField becomeFirstResponder];
}

#pragma mark - UITextField

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@""]) {
        //删除
        if ([textField.text length] > 0 && [[textField.text substringToIndex:[textField.text length] - 1] containsString:@"@"]) {
            self.isMobile = NO;
        }
        else {
            self.isMobile = YES;
        }
    }
    else if ([textField.text containsString:@"@"] || [string containsString:@"@"]) {
        self.isMobile = NO;
    }
    else {
        self.isMobile = YES;
    }
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    self.isMobile = YES;
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if (!_isMobile) {
        [self registerWithEmail];
    }
    return YES;
}

@end
//
//  ViewController.m
//  broadcast-chat
//
//  Created by Alexander Sukharev on 21.11.15.
//  Copyright © 2015 Alexander Sukharev. All rights reserved.
//

#import "ViewController.h"
#include "chat.h"

#include <ifaddrs.h>
#include <arpa/inet.h>

static NSString * broadcastAddress() {
    NSString * broadcastAddr= @"Error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    
    if (success == 0)
    {
        temp_addr = interfaces;
        
        while(temp_addr != NULL)
        {
            // check if interface is en0 which is the wifi connection on the iPhone
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
                {
                    broadcastAddr = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_dstaddr)->sin_addr)];
                    
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    return broadcastAddr;
}

void trigger_callback(char data[], int size) {
    ViewController *controller = [ViewController sharedInstance];
    NSData *objdata = [NSData dataWithBytes:data length:size];
    NSString *str = [[NSString alloc] initWithData:objdata encoding:NSUTF8StringEncoding];
    [controller performSelectorOnMainThread:@selector(addMessage:) withObject:str waitUntilDone:NO];
}

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) NSMutableArray *messages;
@end

@implementation ViewController

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    
    self.messages = [NSMutableArray new];
//    for (NSUInteger i = 0; i < 50; i++) {
//        [self.messages addObject:[NSNumber numberWithInt:i].stringValue];
//    }
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];
    
    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.sendButton setTitle:NSLocalizedString(@"Send", "") forState:UIControlStateNormal];
    [self.sendButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.sendButton addTarget:self action:@selector(sendAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.sendButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.messages.count > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messages.count-1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect topFrame = CGRectZero;
    CGRect bottomFrame = CGRectZero;
    CGRectDivide(self.view.frame, &bottomFrame, &topFrame, 44.0f, CGRectMaxYEdge);
    
    self.tableView.frame = topFrame;
    self.sendButton.frame = bottomFrame;
}

#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    NSString *text = self.messages[indexPath.row];
    cell.textLabel.text = text;
    return cell;
}

#pragma mark -

- (void)addMessage:(NSString *)message {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messages.count inSection:0];
    [self.messages addObject:message];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    if (self.messages.count > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messages.count-1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (void)sendAction:(id)sender {
    char data[] = "hello";
    
    NSString *broadcastAddressString = broadcastAddress();
    NSData *broadcastAddressData = [broadcastAddressString dataUsingEncoding:NSUTF8StringEncoding];
    
    send_data(data, sizeof(data), broadcastAddressData.bytes, broadcastAddressString.length);
}

@end

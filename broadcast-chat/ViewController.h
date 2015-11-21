//
//  ViewController.h
//  broadcast-chat
//
//  Created by Alexander Sukharev on 21.11.15.
//  Copyright © 2015 Alexander Sukharev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
+ (instancetype)sharedInstance;
- (void)addMessage:(NSString *)message;
@end


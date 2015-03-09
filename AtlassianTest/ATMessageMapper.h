//
//  ATMessageMapper.h
//  AtlassianTest
//
//  Created by Varun Goyal on 3/6/15.
//  Copyright (c) 2015 CrazyKarma. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void (^JsonifyCompletionHandler)(NSData *json, NSError* error);


@interface ATMessageMapper : NSObject
-(id) initWithMessage:(NSString *) message;

@end

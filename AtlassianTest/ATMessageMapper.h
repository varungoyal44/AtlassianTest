//
//  ATMessageMapper.h
//  AtlassianTest
//
//  Created by Varun Goyal on 3/6/15.
//  Copyright (c) 2015 CrazyKarma. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol ATMessageMapperDelegate;


@interface ATMessageMapper : NSObject
@property (nonatomic, readonly) NSString *originalString;
@property (nonatomic, weak) id<ATMessageMapperDelegate> delegate;

-(id) initWithMessage:(NSString *) message;
@end


@protocol ATMessageMapperDelegate <NSObject>
/**
 * This delegate method will be returned once all the data has been parsed to extract
 * the required data from the message entered by the user and then converted into a JSON object.
 */
- (void) messageMapper:(ATMessageMapper *) messageMapper
         didCreateJSON:(NSString *) returnString;
@end


//
//  ATMessageMapper.m
//  AtlassianTest
//
//  Created by Varun Goyal on 3/6/15.
//  Copyright (c) 2015 CrazyKarma. All rights reserved.
//

#import "ATMessageMapper.h"

@interface ATMessageMapper()
@property (nonatomic, strong) NSString *originalString;
@property (nonatomic, strong) NSArray *mentions;
@property (nonatomic, strong) NSMutableArray *emoticons;
@property (nonatomic, strong) NSMutableDictionary *links; // Key is the url and value is the title of page

@property BOOL fetchedLinks;
@end

@implementation ATMessageMapper

-(id) initWithMessage:(NSString *) message{
    if(self = [super init]){
        _originalString = message;
        _fetchedLinks = NO;
        [self extractMentions];
        [self extractEmoticons];
        [self extractLinks];
        [self JSONify];
    }
    return self;
}

-(void) extractMentions{
    if(self.originalString.length == 0){
        return;
    }
    if(!self.mentions){
        NSString *regEx = @"(?<=@)\\w+";
        self.mentions = [NSArray arrayWithArray:[self arrayOfSubStringsForRegEx:regEx]];
    }
}

-(void) extractEmoticons{
    if(self.originalString.length == 0){
        return;
    }
    if(!self.emoticons){
        NSString *regEx = @"\\(.{1,15}\\)";
        NSArray *emoticonWithBrackets = [NSArray arrayWithArray:[self arrayOfSubStringsForRegEx:regEx]];
        
        // To extract just the text contained within brackets.
        // Cannot do this in one regex as, the prev regex checks for everything in the string contained within round brackets with 1 to 15 characters. on creating a single regex, the comparator will extract those strings which may be longer than 15 characters too.
        self.emoticons = [NSMutableArray arrayWithCapacity:emoticonWithBrackets.count];
        for(NSString *thisEmoticon in emoticonWithBrackets)
        {
            NSString *regEx = @"(?<=\\()(.*)(?=\\))";
            NSRange range = [thisEmoticon rangeOfString:regEx options:NSRegularExpressionSearch];
            [self.emoticons addObject:[thisEmoticon substringWithRange:range]];
        }
    }
}

-(void) extractLinks{
    if(self.originalString.length == 0){
        return;
    }
    
    if(!self.links){
        self.fetchedLinks = NO;
        
        // This will grab all the links provided in the message
        NSDataDetector* detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
        NSArray *linkCheckingResults = [detector matchesInString:self.originalString options:0 range:NSMakeRange(0, [self.originalString length])];
        self.links = [NSMutableDictionary dictionaryWithCapacity:linkCheckingResults.count];
        
        if(linkCheckingResults.count == 0)
        {
            self.fetchedLinks = YES;
        }
        
        /*
         This will get the individual links from the list of links.
         Note: I am adding the links to the NSDictionary as a Key and its value will be the title of the webPage (if there is one).
         
         This will serve a hidden purpose: There will only be one unique copy of a link (which might have been repeated in the message), thus lesser number of network calls.
         
         This will also mean that the JSON created in the end will notify that the user mentioned the url only once, which might not be true. (Even though the message may have multiple copies of the same url) thus data discrepency.
         
         If such a data discrepency is needs to be handled then, the logic could be updated to manage a count of such copies and thus return that count in the JSON object.
         */
        
        for(id result in linkCheckingResults)
        {
            NSURL *thisLink = [result URL];
            if(![self.links objectForKey:thisLink])
            {
                [self.links setObject:@"" forKey:thisLink];
            }
        }
        
        /*
         This will chain all the network calls made to the found URLs.
         This part of the code does not consider the case if user looses connectivity (enters a long tunnel or elevator), do we hold off the network calls? In such-a-case, a network layer could be setup which would hold off (and cache) all the network calls going out of the system until the connectivity returns.
         */
        
        __block void (^handler)(NSURLResponse *response, NSData *data, NSError *error);
        __weak __block void (^weakHandler)(NSURLResponse *response, NSData *data, NSError *error);
        __block NSInteger currentRequestIndex = 0;
        __block NSArray *allURLs = self.links.allKeys;
        
        
        handler = ^(NSURLResponse *response, NSData *data, NSError *error){
            if(data)
            {
                [self.links setObject:data forKey:[allURLs objectAtIndex:currentRequestIndex]];
            }
            
            currentRequestIndex++;
            if (currentRequestIndex < [allURLs count]) {
                [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[allURLs objectAtIndex:currentRequestIndex]]
                                                   queue:[NSOperationQueue mainQueue]
                                       completionHandler:handler];
            } else {
                [self extractPageTitles];
            }
        };
        
        [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[allURLs objectAtIndex:0]]
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:handler];
        
        
    }
}

-(void) extractPageTitles
{
    for(NSURL *thisURL in self.links.allKeys)
    {
        NSData *data = (NSData *)[self.links objectForKey:thisURL];
        if(data != nil)
        {
            NSString *returnedHTML = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (returnedHTML.length > 0){
                NSString *regEx = @"(?<=>)(.*)(?=</title>)";
                NSRange range = [returnedHTML rangeOfString:regEx options:NSRegularExpressionSearch];
                NSString *title = [returnedHTML substringWithRange:range];
                [self.links setObject:title forKey:thisURL];
            }
        }
    }
    
    self.fetchedLinks = YES;
    [self JSONify];
    
}


-(NSMutableArray *) arrayOfSubStringsForRegEx:(NSString *) regEx{
    
    NSRange lookWithIn = NSMakeRange(0, [self.originalString length]);
    NSString *stringToLookInto = self.originalString;
    NSMutableArray *foundSubStrings = [NSMutableArray array];
    
    do{
        stringToLookInto = [stringToLookInto substringWithRange:lookWithIn];
        NSRange foundRange = [stringToLookInto rangeOfString:regEx options:NSRegularExpressionSearch];
        if(foundRange.location != NSNotFound){
            [foundSubStrings addObject:[stringToLookInto substringWithRange:foundRange]];
            NSUInteger foundLength = (foundRange.location + foundRange.length);
            lookWithIn = NSMakeRange(foundLength, stringToLookInto.length - foundLength);
        }
        else{
            break;
        }
    }while(lookWithIn.length != 0);
    
    return foundSubStrings;
}


-(void) JSONify
{
    if(self.fetchedLinks)
    {
        NSMutableArray *objects = [NSMutableArray array];
        NSMutableArray *keys = [NSMutableArray array];
        if(self.mentions)
        {
            [objects addObject:self.mentions];
            [keys addObject:@"mentions"];
        }
        if(self.emoticons)
        {
            [objects addObject:self.emoticons];
            [keys addObject:@"emoticons"];
        }
        
        if(self.links)
        {
            NSMutableArray *linksArray = [NSMutableArray arrayWithCapacity:self.links.allKeys.count];
            for(NSURL *thisLink in self.links.allKeys)
            {
                NSDictionary *thisDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [thisLink absoluteString], @"url",
                                                [self.links objectForKey:thisLink], @"title",
                                                nil];
                [linksArray addObject:thisDictionary];
            }
            
            [objects addObject:linksArray];
            [keys addObject:@"links"];
        }
        
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        
        
        
        
        NSLog(@"%@", [NSJSONSerialization JSONObjectWithData:jsonData
                                                     options:NSJSONReadingMutableLeaves
                                                       error:&error]);
        
        
        
    }
    
}


@end

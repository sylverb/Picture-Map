//
//  ALAssetAdditions.m
//  PictureMap
//
//  Created by Sylver Bruneau.
//  Copyright 2011 Sylver Bruneau. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "ALAssetAdditions.h"
#import "URLParser.h"

@implementation ALAsset (PMAdditions)

// code from http://stackoverflow.com/questions/5048640/retrieving-a-filename-for-an-alasset
- (NSString*)fileName {
    ALAssetRepresentation *assetRepresentation = [self defaultRepresentation];
    NSURL *url = [assetRepresentation url];
    if([url.scheme isEqualToString:@"assets-library"]) {
        NSRange range = [url.absoluteString rangeOfString:@"?"];
        if(range.location != NSNotFound) {
            URLParser *parser = [[[URLParser alloc] initWithURLString:url.absoluteString] autorelease];
            
            NSString* extention = [[parser valueForVariable:@"ext"] lowercaseString];
            NSString* identifier = [parser valueForVariable:@"id"];
            
            if(extention != NULL && identifier != NULL) {
                return [NSString stringWithFormat:@"%@.%@", identifier, extention];
            }
        }
    }
    return NULL;
}

@end

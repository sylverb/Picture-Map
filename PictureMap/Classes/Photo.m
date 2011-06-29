//
//  Photo.m
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

#import "Photo.h"

@implementation Photo
@synthesize alAsset = _alAsset;
@synthesize caption = _caption;
@synthesize urlLarge = _urlLarge;
@synthesize urlSmall = _urlSmall;
@synthesize urlThumb = _urlThumb;
@synthesize photoSource = _photoSource;
@synthesize size = _size;
@synthesize index = _index;

- (id)initWithalAsset:(ALAsset *)alAsset {
    if ((self = [super init])) {
        self.caption = nil;
        self.alAsset = alAsset;
        self.urlLarge = nil;
        self.urlSmall = nil;
        self.urlThumb = nil;
        self.size = CGSizeMake(-1, -1);
        self.index = NSIntegerMax;
        self.photoSource = nil;
    }
    return self;
}

- (void) dealloc {
    self.caption = nil;
    self.urlLarge = nil;
    self.urlSmall = nil;
    self.urlThumb = nil;  
    self.alAsset = nil;
    [super dealloc];
}

#pragma mark TTPhoto

- (NSString*)URLForVersion:(TTPhotoVersion)version {
    switch (version) {
        case TTPhotoVersionLarge:
            return _urlLarge;
        case TTPhotoVersionMedium:
            return _urlLarge;
        case TTPhotoVersionSmall:
            return _urlSmall;
        case TTPhotoVersionThumbnail:
            return _urlThumb;
        default:
            return nil;
    }
}

- (CGSize)size {
    if (_size.height == -1) {
        NSDictionary *dict = [[_alAsset defaultRepresentation] metadata];
        float width = [[dict objectForKey:@"PixelWidth"] floatValue];
        float height = [[dict objectForKey:@"PixelHeight"] floatValue];
        _size = CGSizeMake(width, height);
    }
    return _size;
}

- (NSString *)caption {
    if (!_caption) {
        NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
		[outputFormatter setDateStyle:NSDateFormatterFullStyle];
		[outputFormatter setTimeStyle:NSDateFormatterMediumStyle];
        
        NSString *caption = [NSString stringWithFormat:NSLocalizedString(@"Date: %@", nil),
                             [outputFormatter stringFromDate:[self.alAsset valueForProperty:@"ALAssetPropertyDate"]]];
        self.caption = caption;
        
		[outputFormatter release];
    }
    return _caption;
}

@end
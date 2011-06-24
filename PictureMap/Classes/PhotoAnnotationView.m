//
//  PhotoAnnotationView.m
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

#import "PhotoAnnotationView.h"
#import "AssetClusterAnnotation.h"
#import "UIImageAdditions.h"

@implementation PhotoAnnotationView

#define kHeight (57)
#define kWidth  (57)

- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
	if(self) {
		countView = nil;
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void)setAnnotation:(id <MKAnnotation>)annotation {
	[super setAnnotation: annotation];
    
	if([annotation isMemberOfClass:[AssetClusterAnnotation class]]) {
		AssetClusterAnnotation *assetClusterAnnotation = (AssetClusterAnnotation *)annotation;
		self.frame = CGRectMake(0, 0, kWidth, kHeight);
		self.backgroundColor = [UIColor clearColor];

        UIImage *imageFromFile = [[assetClusterAnnotation.thumbnail makeRoundCornerImage:15 :15] imageScaledToSize:CGSizeMake(kWidth, kHeight)];
        
        self.image = imageFromFile;

        /* Remove previous CountView if needed */
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:[CountView class]]) {
                [subview removeFromSuperview];
                break;
            }
        }
        
        if (([assetClusterAnnotation totalMarkers] > 1) || ([assetClusterAnnotation totalVideoMarkers])) {
			countView = [[CountView alloc] initWithFrame:CGRectZero];
			countView.pictureCount = [assetClusterAnnotation totalPhotoMarkers];
			countView.movieCount = [assetClusterAnnotation totalVideoMarkers];
			
			CGRect frame = countView.frame;
			frame.size = [countView sizeThatFits:countView.bounds.size];
			frame.origin.y += 2;
			frame.origin.x += 2;
			
			countView.frame = frame;
			
			[self addSubview:countView];
			[countView release];
		}
	} else {
		self.frame = CGRectMake(0,0,0,0);
	}
	
}

- (void)dealloc {
	[countView release], countView = nil;
	[super dealloc];
}

@end

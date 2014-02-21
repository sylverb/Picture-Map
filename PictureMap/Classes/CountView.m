//
//  CountView.m
//  PictureMap
//
//  Created by Sylver Bruneau.
//  Based on Colloquy source code.
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

#import "CountView.h"

@implementation CountView
- (id) initWithFrame:(CGRect) frame {
	if (!(self = [super initWithFrame:frame]))
		return nil;
	self.opaque = NO;
	return self;
}

@synthesize pictureCount = _pictureCount;

- (void) setPictureCount:(NSUInteger) count {
	if (_pictureCount == count)
		return;
	_pictureCount = count;
	[self setNeedsDisplay];
}

@synthesize movieCount = _movieCount;

- (void) setMovieCount:(NSUInteger) movieCount {
	if (_movieCount == movieCount)
		return;
	_movieCount = movieCount;
	[self setNeedsDisplay];
}

- (CGSize) sizeThatFits:(CGSize) size {
	if (!_movieCount && !_pictureCount)
		return CGSizeZero;
	
	UIFont *font = [UIFont boldSystemFontOfSize:16.];
	NSString *numberString = [NSString stringWithFormat:@"%lu", (unsigned long)(_pictureCount ? _pictureCount : _movieCount)];
	CGSize textSize = [numberString sizeWithFont:font];
	
	CGFloat radius = 10.;
	CGRect enclosingRect = CGRectMake(0., 0., MAX(textSize.width + radius + (_pictureCount && _movieCount ? radius * 1.2 : 0.), radius * 2.), radius * 2.);
	
	if (((NSUInteger)enclosingRect.size.width % 2) == 0 && ((NSUInteger)textSize.width % 2) != 0)
		enclosingRect.size.width += 1.;
	
	if (_movieCount && _pictureCount) {
		CGSize previousTextSize = textSize;
		
		numberString = [NSString stringWithFormat:@"%lu", (unsigned long)_movieCount];
		textSize = [numberString sizeWithFont:font];
		
		enclosingRect = CGRectMake(previousTextSize.width + (radius * 1.2), 0., MAX(textSize.width + radius, radius * 2.), radius * 2.);
		
		if (((NSUInteger)enclosingRect.size.width % 2) == 0 && ((NSUInteger)textSize.width % 2) != 0)
			enclosingRect.size.width += 1.;
	}
	
	return CGSizeMake(CGRectGetMaxX(enclosingRect), enclosingRect.size.height);
}

- (void) drawRect:(CGRect) rect {
	if (!_movieCount && !_pictureCount)
		return;
	
	UIFont *font = [UIFont boldSystemFontOfSize:16.];
	NSString *numberString = [NSString stringWithFormat:@"%lu", (unsigned long)(_pictureCount ? _pictureCount : _movieCount)];
	CGSize textSize = [numberString sizeWithFont:font];
	
	CGFloat radius = 10.;
	CGRect enclosingRect = CGRectMake(0., 0., MAX(textSize.width + radius + (_pictureCount && _movieCount ? radius * 1.2 : 0.), radius * 2.), radius * 2.);
	if (((NSUInteger)enclosingRect.size.width % 2) == 0 && ((NSUInteger)textSize.width % 2) != 0)
		enclosingRect.size.width += 1.;
	CGRect pathCornersRect = CGRectInset(enclosingRect, radius, radius);
	
	CGMutablePathRef path = CGPathCreateMutable();
	
	CGPathAddArc(path, NULL, CGRectGetMinX(pathCornersRect), CGRectGetMinY(pathCornersRect), radius, M_PI, (M_PI + M_PI_2), 1);
	CGPathAddArc(path, NULL, CGRectGetMaxX(pathCornersRect), CGRectGetMinY(pathCornersRect), radius, (M_PI + M_PI_2), (M_PI + M_PI), 1);
	CGPathAddArc(path, NULL, CGRectGetMaxX(pathCornersRect), CGRectGetMaxY(pathCornersRect), radius, 0., M_PI_2, 1);
	CGPathAddArc(path, NULL, CGRectGetMinX(pathCornersRect), CGRectGetMaxY(pathCornersRect), radius, M_PI_2, M_PI, 1);
	
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	if (_pictureCount)
        CGContextSetRGBFillColor(ctx, (220. / 255.), (20. / 255.), (20. / 255.), 1.);
	else
        CGContextSetRGBFillColor(ctx, (131. / 255.), (152. / 255.), (180. / 255.), 1.);

	CGContextAddPath(ctx, path);
	CGContextFillPath(ctx);

	CGPathRelease(path);

	CGContextSetBlendMode(ctx, kCGBlendModeLighten);

	CGContextSetRGBFillColor(ctx, (255. / 255.), (255. / 255.), (255. / 255.), 1.);

	CGPoint textPoint = enclosingRect.origin;
	textPoint.x += round(((enclosingRect.size.width - (_pictureCount && _movieCount ? radius * .8 : 0.)) / 2.) - (textSize.width / 2.));
	textPoint.y += round((enclosingRect.size.height / 2.) - (textSize.height / 2.));
	
	[numberString drawAtPoint:textPoint withFont:font];
	
	if (_movieCount && _pictureCount) {
		CGSize previousTextSize = textSize;
		
		numberString = [NSString stringWithFormat:@"%lu", (unsigned long)_movieCount];
		textSize = [numberString sizeWithFont:font];
		
		enclosingRect = CGRectMake(previousTextSize.width + (radius * 1.2), 0., MAX(textSize.width + radius, radius * 2.), radius * 2.);
		if (((NSUInteger)enclosingRect.size.width % 2) == 0 && ((NSUInteger)textSize.width % 2) != 0)
			enclosingRect.size.width += 1.;
		pathCornersRect = CGRectInset(enclosingRect, radius, radius);
		
		path = CGPathCreateMutable();
		
		CGPathAddArc(path, NULL, CGRectGetMinX(pathCornersRect), CGRectGetMinY(pathCornersRect), radius, M_PI, (M_PI + M_PI_2), 1);
		CGPathAddArc(path, NULL, CGRectGetMaxX(pathCornersRect), CGRectGetMinY(pathCornersRect), radius, (M_PI + M_PI_2), (M_PI + M_PI), 1);
		CGPathAddArc(path, NULL, CGRectGetMaxX(pathCornersRect), CGRectGetMaxY(pathCornersRect), radius, 0., M_PI_2, 1);
		CGPathAddArc(path, NULL, CGRectGetMinX(pathCornersRect), CGRectGetMaxY(pathCornersRect), radius, M_PI_2, M_PI, 1);
		
		CGContextSetGrayFillColor(ctx, 0., 1.);
		CGContextSetGrayStrokeColor(ctx, 0., 1.);
		CGContextSetBlendMode(ctx, kCGBlendModeClear);
		CGContextSetLineWidth(ctx, 4.);
		
		CGContextAddPath(ctx, path);
		CGContextStrokePath(ctx);
		
		CGContextAddPath(ctx, path);
		CGContextFillPath(ctx);
		
		CGContextSetRGBFillColor(ctx, (131. / 255.), (152. / 255.), (180. / 255.), 1.);
		
		CGContextSetBlendMode(ctx, kCGBlendModeNormal);
		
		CGContextAddPath(ctx, path);
		CGContextFillPath(ctx);
		
		CGPathRelease(path);
		
		CGContextSetBlendMode(ctx, kCGBlendModeLighten);
		
		CGContextSetRGBFillColor(ctx, (255. / 255.), (255. / 255.), (255. / 255.), 1.);
		
		textPoint = enclosingRect.origin;
		textPoint.x += round((enclosingRect.size.width / 2.) - (textSize.width / 2.));
		textPoint.y += round((enclosingRect.size.height / 2.) - (textSize.height / 2.));
		
		[numberString drawAtPoint:textPoint withFont:font];
	}
}
@end

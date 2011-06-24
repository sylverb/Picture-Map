//
//  AssetClusterAnnotation.m
//  PictureMap
//
//  Created by Sylver Bruneau
//  Based on MapClusteringPrototypeiPhone by Vlado Grancaric
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

#import "AssetClusterAnnotation.h"
#import "AssetAnnotation.h"

@implementation AssetClusterAnnotation

@synthesize clusterer,annotations, centerLongitude, centerLatitude, mapView, thumbnail;

- (id)initWithAnnotationClusterer:(AnnotationClusterer*) clusterManager {
  
  if ((self = [super init])) {
    // Custom initialization
    annotations = [NSMutableArray new];
    self.clusterer = clusterManager;
    self.mapView = clusterManager.mapView;
    centerLatitude = 0.0f;
    centerLongitude = 0.0f;
    
  }
  
  return self;
}

- (CLLocationCoordinate2D)coordinate {
  CLLocationCoordinate2D theCoordinate;
  theCoordinate.latitude = self.centerLatitude;
  theCoordinate.longitude = self.centerLongitude;
  return theCoordinate; 
}

- (NSString*) title {
    NSMutableString *annotationTitle = [NSMutableString string];
    if ([self totalMarkers] == 1) {
		[annotationTitle setString:[[annotations objectAtIndex:0] title]];
	} else {
        NSInteger totalPhotos = [self totalPhotoMarkers];
        NSInteger totalvideos = [self totalVideoMarkers];
        if ([self totalPhotoMarkers] !=0) {
            [annotationTitle appendFormat:@"%d photo%@ ", totalPhotos, (totalPhotos == 1)?@"":@"s"];
        }
        if (([self totalPhotoMarkers] !=0) && ([self totalVideoMarkers] !=0)) {
            [annotationTitle appendString:@", "];
        }
        if ([self totalVideoMarkers] !=0) {
            [annotationTitle appendFormat:@"%d video%@", totalvideos, (totalvideos == 1)?@"":@"s"];
        }
    }
	return annotationTitle;
}

- (NSString*) subtitle {
	NSString *result = nil;
	if ([annotations count] == 1) {
        AssetAnnotation *assetAnnotation = (AssetAnnotation *)[annotations objectAtIndex:0];
        
		NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
		[outputFormatter setDateStyle:NSDateFormatterFullStyle];
		[outputFormatter setTimeStyle:NSDateFormatterMediumStyle];
        
		result = [outputFormatter stringFromDate:[assetAnnotation.alAsset valueForProperty:@"ALAssetPropertyDate"]];
		[outputFormatter release];
	} else {
        AssetAnnotation *oldestAssetAnnotation = (AssetAnnotation *)[annotations objectAtIndex:0];
        AssetAnnotation *latestAssetAnnotation = (AssetAnnotation *)[annotations lastObject];

        NSDate *oldestDate = [oldestAssetAnnotation.alAsset valueForProperty:@"ALAssetPropertyDate"];
        NSDate *latestDate = [latestAssetAnnotation.alAsset valueForProperty:@"ALAssetPropertyDate"];
		NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
		if ((oldestDate) && (latestDate)) {
			[outputFormatter setDateStyle:NSDateFormatterMediumStyle];
			result = [NSString stringWithFormat:@"%@ - %@", [outputFormatter stringFromDate:oldestDate],
                      [outputFormatter stringFromDate:latestDate]];
		} else if (oldestDate != nil) {
			[outputFormatter setDateStyle:NSDateFormatterFullStyle];
			result = [outputFormatter stringFromDate:oldestDate];
		} else if (latestDate != nil) {
			[outputFormatter setDateStyle:NSDateFormatterFullStyle];
			result = [outputFormatter stringFromDate:latestDate];
		}
		[outputFormatter release];
	}
	return result;
}

-(void) addAnnotation: (id <MKAnnotation>) annotation {
  if(centerLatitude == 0.0 && centerLongitude == 0.0) {
    centerLatitude = annotation.coordinate.latitude;
    centerLongitude = annotation.coordinate.longitude;
  }
  [annotations addObject:annotation];
}

-(UIImage *) thumbnail {
    if (thumbnail == nil) {
        AssetAnnotation *assetAnnotation = (AssetAnnotation *)[annotations lastObject];
        self.thumbnail = [UIImage imageWithCGImage:[assetAnnotation.alAsset thumbnail]];
    }
    return thumbnail;
}

-(BOOL) removeAnnotation:(id <MKAnnotation>) annotation {
  for (id <MKAnnotation> anno in annotations) {
    if([annotation isEqual:anno]) {
      if([[mapView annotations] containsObject:annotation]) {
        [mapView removeAnnotation:annotation];
        return YES;
      }
      
      [annotations removeObject:annotation];
      return YES;
    }
  }
  return NO;
}

-(int) totalMarkers {
	return [annotations count];
}

-(int) totalPhotoMarkers {
    int photoCount = 0;
    for (AssetAnnotation *assetAnnotation in annotations) {
        if ([assetAnnotation.alAsset valueForProperty:@"ALAssetPropertyType"] == ALAssetTypePhoto) {
            photoCount++;
        }
    }
    return photoCount;
}

-(int) totalVideoMarkers {
    int videoCount = 0;
    for (AssetAnnotation *assetAnnotation in annotations) {
        if ([assetAnnotation.alAsset valueForProperty:@"ALAssetPropertyType"] == ALAssetTypeVideo) {
            videoCount++;
        }
    }
    return videoCount;
}


-(void) dealloc {
	[mapView release];
	[clusterer release];
	[annotations release];
    [thumbnail release];
	[super dealloc];
}
@end

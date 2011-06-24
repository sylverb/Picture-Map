//
//  AnnotationClusterer.m
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

#import <MapKit/MapKit.h>
#import "AnnotationClusterer.h"
#import "AssetClusterAnnotation.h"

@interface AnnotationClusterer(Private)

@end


@implementation AnnotationClusterer

@synthesize clusters,mapView;

- (id)initWithMapAndAnnotations:(MKMapView *)paramMapView {
  
  if ((self = [super init])) {
    // Custom initialization
    gridSize = 57; //size of the annotation in pixels on the map
    clusters = [NSMutableArray new];
    self.mapView = paramMapView;
  }
  
  return self;

}

-(void) addAnnotation:(id<MKAnnotation>)annotation {
    // Add the annotation if it is in the visible area
    if (MKMapRectContainsPoint(self.mapView.visibleMapRect, MKMapPointForCoordinate(annotation.coordinate))) {
        CGPoint point = [self.mapView convertCoordinate:annotation.coordinate toPointToView:self.mapView];
        
        AssetClusterAnnotation *cluster = nil;
        
        for(AssetClusterAnnotation *arrayCluster in clusters) {
            if(arrayCluster.centerLatitude != 0.0 && arrayCluster.centerLongitude != 0.0) {
                CGPoint clusterCenterPoint = [self.mapView convertCoordinate:arrayCluster.coordinate toPointToView:self.mapView];
                
                // Found a cluster which contains the marker.
                if (point.x >= clusterCenterPoint.x - gridSize && point.x <= clusterCenterPoint.x + gridSize &&
                    point.y >= clusterCenterPoint.y - gridSize && point.y <= clusterCenterPoint.y + gridSize) {
                    
                    [arrayCluster addAnnotation:annotation];
                    
                    return;
                }      
            } else {
                continue;
            }
        }
        
        // No cluster contain the marker, create a new cluster.
        cluster = [[AssetClusterAnnotation alloc] initWithAnnotationClusterer:self];
        [cluster addAnnotation:annotation];
        
        // Add this cluster both in clusters provided and clusters_
        [clusters addObject:cluster];
        [cluster release];
    }
}

-(void) addAnnotations:(NSArray*) newAnnotations {
  for(id <MKAnnotation> anno in newAnnotations) {
    [self addAnnotation:anno];
  }
}

-(void) removeAnnotations {  
  [clusters removeAllObjects];
}

-(int) totalClusters {
  return [clusters count];
}

-(int) totalAnnotations {
  int result = 0;
  
  for(AssetClusterAnnotation *arrayCluster in clusters) {
    result += [arrayCluster totalMarkers];
  }
  
  return result;
}

- (void)dealloc {
  [clusters release];
  [mapView release];
  [super dealloc];
}

@end

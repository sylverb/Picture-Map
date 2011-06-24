//
//  AnnotationClusterer.h
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
#import <Foundation/Foundation.h>


@interface AnnotationClusterer : NSObject {
  NSMutableArray *clusters; //Annotations in a cluster.
  MKMapView *mapView;
  int gridSize; //size of the annotation cluster in pixels on the map.
}

@property(nonatomic,retain) MKMapView *mapView;
@property(nonatomic,retain) NSMutableArray *clusters;

- (id)initWithMapAndAnnotations:(MKMapView *)mapView;

-(void) addAnnotation:(id<MKAnnotation>)annotation;

// Add |annotations| to the map and clusterer
-(void) addAnnotations:(NSArray*) annotations;

// Remove all annotations from the clusterer
-(void) removeAnnotations;

// Total number of clusters that exist.
-(int) totalClusters;

// Total number annotations
-(int) totalAnnotations;

@end

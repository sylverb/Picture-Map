//
//  AssetClusterAnnotation.h
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

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "AnnotationClusterer.h"

// This represents a cluster of annotations in a built up area.
@interface AssetClusterAnnotation : NSObject <MKAnnotation> {
  double centerLatitude;
  double centerLongitude;  
  
  AnnotationClusterer *clusterer; //The annotations in the cluster
  MKMapView *mapView; // The mapview the cluster is appearing on.
  
  NSMutableArray *annotations;
  UIImage *thumbnail;
}

@property (nonatomic, retain) AnnotationClusterer *clusterer;
@property (nonatomic, retain) MKMapView *mapView;
@property (nonatomic, retain) NSMutableArray *annotations;
@property (nonatomic, retain) UIImage *thumbnail;
@property double centerLatitude;
@property double centerLongitude;

-(id) initWithAnnotationClusterer:(AnnotationClusterer*) clusterer;
-(void) addAnnotation: (id <MKAnnotation>) annotation;
-(BOOL) removeAnnotation:(id <MKAnnotation>) annotation;
-(int) totalMarkers;
-(int) totalPhotoMarkers;
-(int) totalVideoMarkers;
@end

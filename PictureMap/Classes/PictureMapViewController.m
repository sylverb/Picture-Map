//
//	PictureMapViewController.m
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


#import "PictureMapViewController.h"
#import "SettingsViewController.h"
#import "AssetClusterAnnotation.h"
#import "AssetAnnotation.h"
#import "AnnotationClusterer.h"
#import "AssetController.h"
#import "PhotoAnnotationView.h"

#import "Photo.h"
#import "PhotoViewController.h"
#import "ThumbsViewController.h"


@interface PictureMapViewController ()
@property (nonatomic, retain) AnnotationClusterer *annotationClusterer;


- (void)updateAssetsOnRegion:(NSValue *)value;
@end


@implementation PictureMapViewController


#pragma mark -
#pragma mark Synthesize Properties
@synthesize annotationClusterer;
@synthesize mapView = _mapView;
@synthesize assetController = _assetController;
@synthesize locationManager = _locationManager;

#pragma mark -
#pragma mark NSObject Methods
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"assetsParsingEnded"
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"refreshMap"
                                                  object:nil];
	[self setAnnotationClusterer:nil];
	[self setMapView:nil];
    [self setAssetController:nil];
    [self setLocationManager:nil];
	[super dealloc];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

#pragma mark -
#pragma mark UIViewController Methods
- (void)viewDidLoad {
	[super viewDidLoad];

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

    _mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    _mapView.delegate = self;
    

    if ([prefs objectForKey:@"CenterPointLatitude"]) {
        CLLocationCoordinate2D centerPoint = {[prefs floatForKey:@"CenterPointLatitude"], [prefs floatForKey:@"CenterPointLongitude"]};
        MKCoordinateSpan coordinateSpan = MKCoordinateSpanMake([prefs floatForKey:@"SpanDeltaLatitude"], [prefs floatForKey:@"SpanDeltaLongitude"]);
        MKCoordinateRegion coordinateRegion = MKCoordinateRegionMake(centerPoint, coordinateSpan);
        
        [_mapView setRegion:coordinateRegion animated: FALSE];
        [_mapView regionThatFits:coordinateRegion];
    }
    
    _mapView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [self.view addSubview:_mapView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNotification:)
                                                 name:@"assetsParsingEnded"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNotification:)
                                                 name:@"refreshMap"
                                               object:nil];
    
    _assetController = [[AssetController alloc] init];

    self.navigationController.toolbarHidden = NO;

    // Set map type
    if ([prefs objectForKey:@"MapType"]) {
        _mapView.mapType = [prefs integerForKey:@"MapType"];
    } else {
        _mapView.mapType = MKMapTypeStandard;
    }
    
    // Parse assets
    [_assetController parseAssets];

    NSArray* toolbarItems = [NSArray arrayWithObjects:
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                                                                           target:nil
                                                                           action:nil],
                             [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"locate"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(showUserLocation:)],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                                                                           target:nil
                                                                           action:nil],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
                                                                           target:self
                                                                           action:@selector(refreshAnnotations:)],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                                                                           target:nil
                                                                           action:nil],
                             [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(settings:)],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                                                                           target:nil
                                                                           action:nil],
                             nil];
    self.toolbarItems = toolbarItems;
    [toolbarItems makeObjectsPerformSelector:@selector(release)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    [self.navigationController setToolbarHidden:NO animated:animated];

    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
    [super viewWillDisappear:animated];
}

#pragma mark -
#pragma mark NSNotification Handling
- (void)handleNotification:(NSNotification *)pNotification {
	if ([pNotification.name isEqualToString:@"assetsParsingEnded"]) {
        NSArray *annotationsArray = [_mapView annotations];
        [_mapView removeAnnotations:annotationsArray];
        
        if ([_assetController.assetItems count] == 0) {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning",nil)
                                                             message:NSLocalizedString(@"There are not geotagged photos available in the selection, please change your selection or add geotagged photos on your device",nil)
                                                            delegate:nil
                                                   cancelButtonTitle:@"Ok"
                                                   otherButtonTitles:nil];
            [alert show];
            [alert release];
        }
        MKCoordinateRegion currentRegion = [_mapView region];
        NSValue *regionAsValue = [NSValue valueWithBytes:&currentRegion objCType:@encode(MKCoordinateRegion)];
        
        [self performSelectorOnMainThread:@selector(updateAssetsOnRegion:) withObject:regionAsValue waitUntilDone:YES];
    } else 	if ([pNotification.name isEqualToString:@"refreshMap"]) {
        // Set map type
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        if ([prefs objectForKey:@"MapType"]) {
            _mapView.mapType = [prefs integerForKey:@"MapType"];
        } else {
            _mapView.mapType = MKMapTypeStandard;
        }
        
        // Parse assets
        [_assetController parseAssets];
    }
}

#pragma mark -
#pragma mark MKMapViewDelegate Methods
- (void)mapView:(MKMapView *)aMapView regionDidChangeAnimated:(BOOL)animated {
	NSArray *annotationsArray = [aMapView annotations];
	[aMapView removeAnnotations:annotationsArray];

	MKCoordinateRegion currentRegion = [aMapView region];
	NSValue *regionAsValue = [NSValue valueWithBytes:&currentRegion objCType:@encode(MKCoordinateRegion)];

    [self performSelectorOnMainThread:@selector(updateAssetsOnRegion:) withObject:regionAsValue waitUntilDone:YES];
    
    // Save location
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setFloat: currentRegion.center.latitude forKey: @"CenterPointLatitude"];
    [prefs setFloat: currentRegion.center.longitude forKey: @"CenterPointLongitude"];
    [prefs setDouble: currentRegion.span.latitudeDelta forKey: @"SpanDeltaLatitude"];
    [prefs setDouble: currentRegion.span.longitudeDelta forKey: @"SpanDeltaLongitude"];
}


- (MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(id<MKAnnotation>)annotation {
	static NSString *kAnnotationViewIdentifier = @"MKPhotoAnnotationViewID";

	if (![annotation isKindOfClass:[AssetClusterAnnotation class]])
	{
		return nil;
	}

    AssetClusterAnnotation *assetClusterAnnotation = (AssetClusterAnnotation *)annotation;
    
    // See if we can reduce, reuse, recycle
    PhotoAnnotationView *photoAnnotationView = (PhotoAnnotationView *)[aMapView dequeueReusableAnnotationViewWithIdentifier:kAnnotationViewIdentifier];
    
    // If we have to, create a new view
    if (photoAnnotationView == nil) {
        photoAnnotationView = [[[PhotoAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kAnnotationViewIdentifier] autorelease];
    }
    
    // Set up the Right callout
    [photoAnnotationView setCanShowCallout:YES];
    
    // Set a bunch of other stuff
    photoAnnotationView.annotation = annotation;
    [photoAnnotationView setEnabled:YES];

    // Set the right callout if needed
    if ([assetClusterAnnotation totalPhotoMarkers] == 0) {
		[photoAnnotationView setRightCalloutAccessoryView:nil];
    } else if (photoAnnotationView.rightCalloutAccessoryView == nil) {
        // add disclosur button if needed
        UIButton *detailDisclosureButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		[detailDisclosureButton setTag:1];
		[photoAnnotationView setRightCalloutAccessoryView:detailDisclosureButton];
    }

    return photoAnnotationView;
}


- (void)mapView:(MKMapView *)aMapView annotationView:(MKAnnotationView *)anAnnotationView calloutAccessoryControlTapped:(UIControl *)aControl {
	if ([[anAnnotationView annotation] isKindOfClass:[AssetClusterAnnotation class]])
	{
        AssetClusterAnnotation *assetClusterAnnotation = [anAnnotationView annotation];

        NSMutableArray *photos = [[NSMutableArray alloc] init];
        for (AssetAnnotation *annotation in [assetClusterAnnotation annotations]) {
            if ([[annotation.alAsset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
                Photo *photo = [[Photo alloc] initWithalAsset:annotation.alAsset];
                
                [photos addObject:photo];
                [photo release];
            }
        }

        if ([photos count] > 1) {
            ThumbsViewController *photoViewController = [[ThumbsViewController alloc] initwithPhotos:photos];
            [self.navigationController pushViewController:photoViewController animated:YES];
            [photoViewController release];
        } else {
            PhotoViewController *photoViewController = [[PhotoViewController alloc] initwithPhotos:photos];
            [self.navigationController pushViewController:photoViewController animated:YES];
            [photoViewController release];
        }
	}
}
#pragma mark -
#pragma mark CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    //zoom to user's location
    if (CLLocationCoordinate2DIsValid(newLocation.coordinate)) {
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 500, 500);
        [_mapView setRegion:region animated:YES];

        // Location found, stop updating it
        [_locationManager stopUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
}

#pragma mark -
#pragma mark UIBarButtonItems actions
- (void)refreshAnnotations:(UIBarButtonItem *)button {
    [_assetController parseAssets];
}

- (void)settings:(UIBarButtonItem *)button {
    if (popoverController) {
        [popoverController dismissPopoverAnimated:YES];
        popoverController = nil;
        return;
    }

    SettingsViewController *settingsViewController = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
        navController.title = NSLocalizedString(@"Settings", nil);
        popoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
        popoverController.delegate = self;
        popoverController.popoverContentSize = CGSizeMake(320.0f, 500.0f);
        [popoverController presentPopoverFromBarButtonItem:button
                                  permittedArrowDirections:UIPopoverArrowDirectionDown|UIPopoverArrowDirectionUp
                                                  animated:YES];
        [navController release];
    } else {
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    [SettingsViewController release];

}

- (void)showUserLocation:(UIBarButtonItem *)button {
    if (_locationManager == nil) {
        _locationManager=[[CLLocationManager alloc] init];
        _locationManager.delegate=self;
        _locationManager.desiredAccuracy=kCLLocationAccuracyHundredMeters;
    }
    [_locationManager startUpdatingLocation];
}


#pragma mark -
#pragma mark UIPopoverControllerDelegate
- (void) popoverControllerDidDismissPopover:(UIPopoverController *)apopoverController {
    if (apopoverController == popoverController) {
        [popoverController release], popoverController = nil;
    }
}

#pragma mark -
#pragma mark Private Instance Methods
- (void)updateAssetsOnRegion:(NSValue *)value {
	NSMutableArray *assetItemsArray = [_assetController getAssetsByCoordinateRegion:value];

	if (![self annotationClusterer])
	{
		AnnotationClusterer *anAnnotationClusterer = [[AnnotationClusterer alloc] initWithMapAndAnnotations:_mapView];
		[self setAnnotationClusterer:anAnnotationClusterer];
		[anAnnotationClusterer release], anAnnotationClusterer = nil;
	}
	else
	{
		[[self annotationClusterer] removeAnnotations];
	}

	[[self annotationClusterer] addAnnotations:assetItemsArray];
	[_mapView addAnnotations:[[self annotationClusterer] clusters]];
}
@end


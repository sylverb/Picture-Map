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

#ifdef ADMOB
#import "AdId.h"
#endif

@interface PictureMapViewController ()
@property (nonatomic, strong) AnnotationClusterer *annotationClusterer;


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
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"zoomToLocation"
                                                  object:nil];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

#ifdef ADMOB
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    bannerView_.frame = CGRectMake((self.view.frame.size.width - bannerView_.frame.size.width)/2,
                                  self.view.frame.size.height -
                                  self.navigationController.toolbar.viewForBaselineLayout.frame.size.height -
                                  bannerView_.frame.size.height,
                                  bannerView_.frame.size.width,
                                  bannerView_.frame.size.height);
    CGRect frame = self.view.bounds;
    frame.size.height -= self.navigationController.toolbar.viewForBaselineLayout.frame.size.height + bannerView_.frame.size.height;
    _mapView.frame = frame;
}
#endif

#pragma mark -
#pragma mark UIViewController Methods
- (void)viewDidLoad {
	[super viewDidLoad];

    needsToReloadClusterer = NO;
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

    _mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    _mapView.delegate = self;
    

    if ([prefs objectForKey:@"CenterPointLatitude"]) {
        CLLocationCoordinate2D centerPoint = {[prefs floatForKey:@"CenterPointLatitude"], [prefs floatForKey:@"CenterPointLongitude"]};
        MKCoordinateSpan coordinateSpan = MKCoordinateSpanMake([prefs floatForKey:@"SpanDeltaLatitude"], [prefs floatForKey:@"SpanDeltaLongitude"]);
        MKCoordinateRegion coordinateRegion = MKCoordinateRegionMake(centerPoint, coordinateSpan);
        
        if ((!isnan(coordinateRegion.center.latitude)) &&
            (!isnan(coordinateRegion.center.longitude)) &&
            (!isnan(coordinateRegion.span.latitudeDelta)) &&
            (!isnan(coordinateRegion.span.longitudeDelta))
            )
        {
            [_mapView setRegion:coordinateRegion animated: FALSE];
            [_mapView regionThatFits:coordinateRegion];
        }
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNotification:)
                                                 name:@"zoomToLocation"
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

    NSArray* toolbarItems = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
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
                                                                           action:nil]];
    self.toolbarItems = toolbarItems;
//    [toolbarItems makeObjectsPerformSelector:@selector(release)];

#ifdef ADMOB
    bannerView_ = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
    bannerView_.adUnitID = PICTUREMAP_BANNER_ID;
    bannerView_.rootViewController = self;
    [bannerView_ setDelegate:self];
    bannerView_.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

    [self.view addSubview:bannerView_];
    
    GADRequest *request = [GADRequest request];
    request.testDevices = [NSArray arrayWithObjects:GAD_SIMULATOR_ID, IPHONE5S_ID, nil];
    
    [bannerView_ loadRequest:request];
#endif
}

#ifdef ADMOB
- (void)adViewDidReceiveAd:(GADBannerView *)bannerView
{
    NSLog(@"Received ad successfully");
    bannerView.frame = CGRectMake((self.view.frame.size.width - bannerView.frame.size.width)/2,
                                  self.view.frame.size.height -
                                  self.navigationController.toolbar.viewForBaselineLayout.frame.size.height -
                                  bannerView.frame.size.height,
                                  bannerView.frame.size.width,
                                  bannerView.frame.size.height);
    CGRect frame = self.view.bounds;
    frame.size.height -= self.navigationController.toolbar.viewForBaselineLayout.frame.size.height + bannerView.frame.size.height;
    _mapView.frame = frame;
}

- (void)adView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(GADRequestError *)error {
    NSLog(@"Failed to receive ad with error: %@", [error localizedFailureReason]);
}
#endif

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
        }
        MKCoordinateRegion currentRegion = [_mapView region];
        NSValue *regionAsValue = [NSValue valueWithBytes:&currentRegion objCType:@encode(MKCoordinateRegion)];
        
        [self performSelectorOnMainThread:@selector(updateAssetsOnRegion:) withObject:regionAsValue waitUntilDone:YES];
    } else if ([pNotification.name isEqualToString:@"refreshMap"]) {
        // Set map type
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        if ([prefs objectForKey:@"MapType"]) {
            _mapView.mapType = [prefs integerForKey:@"MapType"];
        } else {
            _mapView.mapType = MKMapTypeStandard;
        }
        
        // Parse assets
        [_assetController parseAssets];
    } else if ([pNotification.name isEqualToString:@"zoomToLocation"]) {
        CLLocation *location = (pNotification.userInfo)[@"location"];
        if (CLLocationCoordinate2DIsValid(location.coordinate)) {
            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location.coordinate, 500, 500);
            [_mapView setRegion:region animated:YES];
        }
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
	static NSString *kPhotoAnnotationViewIdentifier = @"MKPhotoAnnotationViewID";
	static NSString *kPinAnnotationViewIdentifier = @"MKPinAnnotationViewID";

    MKAnnotationView *annotationView = nil;
    AssetClusterAnnotation *assetClusterAnnotation = (AssetClusterAnnotation *)annotation;
    if ([annotation isKindOfClass:[AssetClusterAnnotation class]]) {
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        if ([prefs integerForKey:@"MarkType"] == 0) { // Thumbnails
            // See if we can reduce, reuse, recycle
            PhotoAnnotationView *photoAnnotationView = (PhotoAnnotationView *)[aMapView dequeueReusableAnnotationViewWithIdentifier:kPhotoAnnotationViewIdentifier];
            
            // If we have to, create a new view
            if (photoAnnotationView == nil) {
                photoAnnotationView = [[PhotoAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kPhotoAnnotationViewIdentifier];
            } else {
                annotationView.annotation = annotation;
            }
            
            annotationView.enabled = YES;
            
            // Set up the Right callout
            [photoAnnotationView setCanShowCallout:YES];
            
            // Set a bunch of other stuff
            photoAnnotationView.annotation = annotation;
            [photoAnnotationView setEnabled:YES];
            
            // Set the right callout if needed
            if ([assetClusterAnnotation totalPhotoMarkers] == 0) {
                [photoAnnotationView setRightCalloutAccessoryView:nil];
            } else if (photoAnnotationView.rightCalloutAccessoryView == nil) {
                // add disclosure button if needed
                UIButton *detailDisclosureButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
                [detailDisclosureButton setTag:1];
                [photoAnnotationView setRightCalloutAccessoryView:detailDisclosureButton];
            }
            annotationView = photoAnnotationView;
        }
        else if ([prefs integerForKey:@"MarkType"] == 1) { // Pins
            // See if we can reduce, reuse, recycle
            MKPinAnnotationView *pinAnnotationView = (MKPinAnnotationView *)[aMapView dequeueReusableAnnotationViewWithIdentifier:kPinAnnotationViewIdentifier];
            
            // If we have to, create a new view
            if (pinAnnotationView == nil) {
                pinAnnotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kPinAnnotationViewIdentifier];
            } else {
                pinAnnotationView.annotation = annotation;
            }

            pinAnnotationView.enabled = YES;
            pinAnnotationView.canShowCallout = YES;

            // Set the right callout if needed
            if ([assetClusterAnnotation totalPhotoMarkers] == 0) {
                [pinAnnotationView setRightCalloutAccessoryView:nil];
            } else if (annotationView.rightCalloutAccessoryView == nil) {
                // add disclosure button if needed
                [pinAnnotationView setRightCalloutAccessoryView:[UIButton buttonWithType:UIButtonTypeDetailDisclosure]];
            }
            if ([assetClusterAnnotation totalPhotoMarkers] == 1) {
                pinAnnotationView.pinColor = MKPinAnnotationColorRed;
            } else {
                pinAnnotationView.pinColor = MKPinAnnotationColorGreen;
            }
            
            annotationView = pinAnnotationView;
        }
	}

    return annotationView;
}

- (void)mapView:(MKMapView *)aMapView annotationView:(MKAnnotationView *)anAnnotationView calloutAccessoryControlTapped:(UIControl *)aControl {
	if ([[anAnnotationView annotation] isKindOfClass:[AssetClusterAnnotation class]])
	{
        AssetClusterAnnotation *assetClusterAnnotation = [anAnnotationView annotation];
        NSMutableArray *photos = [[NSMutableArray alloc] init];
        NSMutableArray *thumbs = [[NSMutableArray alloc] init];
        
        for (AssetAnnotation *annotation in [assetClusterAnnotation annotations]) {
            [photos addObject:[MWPhoto photoWithURL:annotation.alAsset.defaultRepresentation.url]];
            [thumbs addObject:[MWPhoto photoWithImage:[UIImage imageWithCGImage:annotation.alAsset.thumbnail]]];
        }

        self.photos = photos;
        self.thumbs = thumbs;
        
        // Create browser
        MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
        browser.displayActionButton = YES;
        browser.displayNavArrows = YES;
        browser.displaySelectionButtons = NO;
        browser.alwaysShowControls = YES;
        browser.zoomPhotosToFill = YES;
        if ([photos count] > 1) {
            browser.enableGrid = YES;
            browser.startOnGrid = YES;
        }
        else {
            browser.enableGrid = NO;
            browser.startOnGrid = NO;
        }
        [browser setCurrentPhotoIndex:0];

        [self.navigationController pushViewController:browser animated:YES];
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

    needsToReloadClusterer = YES;

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
    } else {
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }

}

- (void)showUserLocation:(UIBarButtonItem *)button {
    if (_locationManager == nil) {
        _locationManager=[[CLLocationManager alloc] init];
        _locationManager.delegate=self;
        _locationManager.desiredAccuracy=kCLLocationAccuracyHundredMeters;
    }
    [_locationManager startUpdatingLocation];
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count)
        return _photos[index];
    return nil;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    if (index < _thumbs.count)
        return _thumbs[index];
    return nil;
}

#pragma mark -
#pragma mark UIPopoverControllerDelegate
- (void) popoverControllerDidDismissPopover:(UIPopoverController *)apopoverController {
    if (apopoverController == popoverController) {
        popoverController = nil;
    }
}

#pragma mark -
#pragma mark Private Instance Methods
- (void)updateAssetsOnRegion:(NSValue *)value {
	NSMutableArray *assetItemsArray = [_assetController getAssetsByCoordinateRegion:value];

	if ((![self annotationClusterer]) || needsToReloadClusterer)
	{
		[self setAnnotationClusterer:[[AnnotationClusterer alloc] initWithMapAndAnnotations:_mapView]];
        needsToReloadClusterer = NO;
	}
	else
	{
		[[self annotationClusterer] removeAnnotations];
	}

	[[self annotationClusterer] addAnnotations:assetItemsArray];
	[_mapView addAnnotations:[[self annotationClusterer] clusters]];
}
@end


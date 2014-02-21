//
//  AssetController.m
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
#import <AssetsLibrary/AssetsLibrary.h>
#import "AssetController.h"
#import "AssetAnnotation.h"

@implementation AssetController
@synthesize assetItems;

- (id)init {
    self = [super init];
    if (self) {
        assetItems = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void) parseAssets {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

    // Get parsing parameters
    BOOL parsePhotos = YES;
    if ([prefs objectForKey:@"SyncPhotos"]) {
        parsePhotos = [prefs boolForKey:@"SyncPhotos"];
    }
    
    BOOL parseVideos =  NO;
    if ([prefs objectForKey:@"SyncVideos"]) {
        parseVideos = [prefs boolForKey:@"SyncVideos"];
    }
    
    NSMutableDictionary *dict = nil;
    BOOL allAlbumsSelected = YES;
    if ([prefs objectForKey:@"AllAlbumsSelected"]) {
        allAlbumsSelected = [prefs boolForKey:@"AllAlbumsSelected"];
    }
    
    if ((!allAlbumsSelected) &&
        ([prefs objectForKey:@"SelectedAlbumsDict"])) {
        dict = [NSMutableDictionary dictionaryWithDictionary:[prefs objectForKey:@"SelectedAlbumsDict"]];
    } else {
        dict = [NSMutableDictionary dictionary];
    }

    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       @autoreleasepool {
                       
                           NSMutableArray *groupsArray = [NSMutableArray array];
                           NSMutableDictionary *assetUrlDict = [NSMutableDictionary dictionary];
                           __block NSInteger parsedArrayCount = 0;
                           
                           // Remove previous objects
                           [assetItems removeAllObjects];
                           
                           // Asset enumerator Block
                           void (^assetEnumerator)(ALAsset *, NSUInteger, BOOL *) = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
                               if(result != nil) {
                                   CLLocation *location = [result valueForProperty:@"ALAssetPropertyLocation"];
                                   if ((location != nil) && (CLLocationCoordinate2DIsValid(location.coordinate))) {
                                       NSString *type = [result valueForProperty:@"ALAssetPropertyType"];
                                       if (((type == ALAssetTypePhoto) && (parsePhotos)) ||
                                           ((type == ALAssetTypeVideo) && (parseVideos))) {
                                           NSString *url = [[[result defaultRepresentation] url] absoluteString];
                                           // If no element with this URL already exists, add it
                                           if (!assetUrlDict[url]) {
                                               AssetAnnotation *anno = [[AssetAnnotation alloc] init];		
                                               [anno setTitle:[result fileName]];
                                               [anno setLatitude:location.coordinate.latitude];
                                               [anno setLongitude:location.coordinate.longitude];
                                               [anno setAlAsset:result];
                                               [assetItems addObject:anno];
                                               // Add the URL in the list of added elements
                                               assetUrlDict[url] = @"foo";
                                           }
                                       }
                                   }
                                   return;
                               } else {
                                   parsedArrayCount ++;
                                   // If last group parsed, send a notification to main controller
                                   if (parsedArrayCount == [groupsArray count]) {
                                       [[NSNotificationCenter defaultCenter] postNotificationName:@"assetsParsingEnded"
                                                                                           object:self
                                                                                         userInfo:nil];
                                   }
                               }
                           };
                           
                           // Group enumerator Block
                           void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) {
                               if (group != nil) {
                                   // Check if we want to parse this album
                                   if (dict[[group valueForProperty:ALAssetsGroupPropertyPersistentID]]) {
                                       if ([dict[[group valueForProperty:ALAssetsGroupPropertyPersistentID]] boolValue]) {
                                           [groupsArray addObject:group];
                                       }
                                   } else {
                                       [groupsArray addObject:group];
                                   }
                               } else {
                                   // Last group parsed, now parse ALAssets of each group
                                   for (ALAssetsGroup *assetGroups in groupsArray) {
                                       [assetGroups enumerateAssetsUsingBlock:assetEnumerator];
                                   }
                               }
                           };
                           
                           // Group Enumerator Failure Block
                           void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error) {
                               
                               UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Album Error: %@", [error description]] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                               [alert show];
                               
                               NSLog(@"A problem occured %@", [error description]);
                           };	
                           
                           // Enumerate Albums
                           ALAssetsLibrary *library = [ALAssetsLibrary defaultAssetsLibrary];        
                           [library enumerateGroupsWithTypes:ALAssetsGroupAll
                                                  usingBlock:assetGroupEnumerator 
                                                failureBlock:assetGroupEnumberatorFailure];
                       
                       }
                   });
}

- (NSMutableArray *) getAssetsByCoordinateRegion: (NSValue*) region {
	return assetItems;
}

@end

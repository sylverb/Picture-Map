//
//  SettingsViewController.m
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

#import "SettingsViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation SettingsViewController

@synthesize assetGroups;
@synthesize assets;

#define TAG_SWITCH_PHOTOS 1
#define TAG_SWITCH_VIDEOS 2
#define TAG_SLIDER_SIZE         1
#define TAG_SLIDER_TRANSPARENCY 2

- (void)viewDidLoad {
    [super viewDidLoad];
    
	self.navigationItem.title = NSLocalizedString(@"Settings", nil);
    
    // Set if all albums are selected or not
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if ([prefs objectForKey:@"AllAlbumsSelected"]) {
        allAlbumsSelected = [prefs boolForKey:@"AllAlbumsSelected"];
    } else {
        allAlbumsSelected = YES;
    }
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
	self.assetGroups = tempArray;
    [tempArray release];
    
    // Load Albums into assetGroups
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                       
                       // Group enumerator Block
                       void (^assetGroupEnumerator)(ALAssetsGroup *group, BOOL *stop) = ^(ALAssetsGroup *group, BOOL *stop) {
                           if (group != nil) {
                               [self.assetGroups addObject:group];
                               
                               // Keep this line!  w/o it the asset count is broken for some reason.  Makes no sense
                               //                               NSLog(@"count: %d", [group numberOfAssets]);
                               
                               // Reload albums
                               [self performSelectorOnMainThread:@selector(reloadTableView) withObject:nil waitUntilDone:YES];
                           }
                           
                       };
                       
                       // Group Enumerator Failure Block
                       void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error) {
                           
                           UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Album Error: %@", [error description]] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                           [alert show];
                           [alert release];
                           
                           NSLog(@"A problem occured %@", [error description]);
                       };	
                       
                       // Enumerate Albums
                       ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];        
                       [library enumerateGroupsWithTypes:ALAssetsGroupAll
                                              usingBlock:assetGroupEnumerator 
                                            failureBlock:assetGroupEnumberatorFailure];
                       
                       
                       [library release];
                       [pool release];
                   });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMap"
                                                        object:self
                                                      userInfo:nil];
	[super viewDidDisappear:animated];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

-(void)reloadTableView {
	
	[self.tableView reloadData];
    
    // Load Albums into assetGroups
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                       
                       // Group enumerator Block
                       void (^assetEnumerator)(ALAsset *result, NSUInteger index, BOOL *stop) = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
                           if(result != nil) {
                               return;
                           }
                       };
                       
                       if ([assetGroups count])
                           [[assetGroups objectAtIndex:0] enumerateAssetsUsingBlock:assetEnumerator];
                       
                       [pool release];
                   });    
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    NSInteger rows = 0;
    switch (section) {
        case 0 :
            rows = 1;
            break;
        case 1 :
            rows = 1;
            break;
        case 2 :
            rows = 2;
            break;
        case 3 :
            if (allAlbumsSelected) {
                rows = 1;
            } else {
                rows = [assetGroups count] + 1;
            }
            break;
        default:
            break;
    }
    return rows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString * title = @"";
	switch (section) {
		case 0:
			title = NSLocalizedString(@"Thumbnails on map",nil);
			break;
		case 1:
			title = NSLocalizedString(@"Map settings",nil);
			break;
		case 2:
			title = NSLocalizedString(@"Files to show on map",nil);
			break;
		case 3:
			title = NSLocalizedString(@"Albums to show on map",nil);
			break;
	}
	return title;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * CellIdentifier = @"Cell";
    static NSString * PhotoCellIdentifier = @"PhotoCell";
    static NSString * SegCtrlCellIdentifier = @"SegCtrlCell";
    static NSString * SliderCellIdentifier = @"SliderCell";
    
    UITableViewCell *cell = nil;
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

    switch (indexPath.section) {
        case 0:
        {
            switch (indexPath.row) {
                case 0:
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:SliderCellIdentifier];
                    if (cell == nil) {
                        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SliderCellIdentifier] autorelease];
                    }
                    
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
                    cell.textLabel.text = NSLocalizedString(@"Transparency",nil);
                    
                    // UISlider setup
                    NSArray *cellSubViews = [[cell.textLabel superview] subviews];
                    for (id item in cellSubViews) {
                        if ([item isKindOfClass:[UISlider class]]) {
                            UISlider *oldSlider = (UISlider *)item;
                            [oldSlider removeFromSuperview];
                            break;
                        }
                    }
                    
                    CGRect frame = CGRectMake(130, 0, 160, 44);
                    UISlider *slider = [[[UISlider alloc] init] autorelease];
                    slider.frame = frame;
                    float annotationAlpha = 1.0;
                    if ([prefs objectForKey:@"AnnotationAlpha"]) {
                        annotationAlpha = [prefs floatForKey:@"AnnotationAlpha"];
                    }
                    slider.value = annotationAlpha;
                    [slider addTarget:self
                               action:@selector(sliderValueChanged:)
                     forControlEvents:UIControlEventValueChanged];
                    slider.tag = TAG_SLIDER_TRANSPARENCY;
                    [[cell.textLabel superview] addSubview:slider];
                    break;
                }
            }
            break;
        }
        case 1:
        {
            switch (indexPath.row) {
                case 0:
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:SegCtrlCellIdentifier];
                    if (cell == nil) {
                        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SegCtrlCellIdentifier] autorelease];
                        
                        // Make transparent background
                        UIView *backView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
                        backView.backgroundColor = [UIColor clearColor];
                        cell.backgroundView = backView;
                    }
                    
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
                    
                    // UISegmentedControl setup
                    NSArray *cellSubViews = [[cell.textLabel superview] subviews];
                    for (id item in cellSubViews) {
                        if ([item isKindOfClass:[UISegmentedControl class]]) {
                            UISegmentedControl *oldSegCtrl = (UISegmentedControl *)item;
                            [oldSegCtrl removeFromSuperview];
                            break;
                        }
                    }
                    
                    NSArray *text = [NSArray arrayWithObjects:
                                     NSLocalizedString(@"Standard", nil),
                                     NSLocalizedString(@"Satellite", nil),
                                     NSLocalizedString(@"Hybrid", nil),
                                     nil];
                    CGRect frame = CGRectMake(5, 7, 290, 44);
                    UISegmentedControl *segCtrl = [[[UISegmentedControl alloc] initWithItems:text] autorelease];
                    segCtrl.frame = frame;
                    if ([prefs objectForKey:@"MapType"]) {
                        switch ([prefs integerForKey:@"MapType"]) {
                            case MKMapTypeStandard:
                                segCtrl.selectedSegmentIndex = 0;
                                break;
                            case MKMapTypeSatellite:
                                segCtrl.selectedSegmentIndex = 1;
                                break;
                            case MKMapTypeHybrid:
                                segCtrl.selectedSegmentIndex = 2;
                                break;
                        }
                    } else {
                        segCtrl.selectedSegmentIndex = 0;
                    }
                    [segCtrl addTarget:self
                                action:@selector(segCtrlValueChanged:)
                      forControlEvents:UIControlEventValueChanged];
                    segCtrl.tag = 0;
                    [[cell.textLabel superview] addSubview:segCtrl];
                    break;
                }
            }
            break;
        }
        case 2:
        { 
            switch (indexPath.row) {
                case 0:
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                    if (cell == nil) {
                        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
                    }
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    cell.textLabel.text = NSLocalizedString(@"Photos",nil);
                    
                    // UISwitch setup
                    NSArray *cellSubViews = [[cell.textLabel superview] subviews];
                    for (id item in cellSubViews) {
                        if ([item isKindOfClass:[UISwitch class]]) {
                            UISwitch *oldSwitch = (UISwitch *)item;
                            [oldSwitch removeFromSuperview];
                            break;
                        }
                    }
                    
                    UISwitch *aswitch = [[[UISwitch alloc] initWithFrame:CGRectMake(cell.contentView.frame.size.width - 110,
                                                                                    7,
                                                                                    100,
                                                                                    30)] autorelease];
                    aswitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

                    BOOL parsePhotos = [prefs objectForKey:@"SyncPhotos"]?[prefs boolForKey:@"SyncPhotos"]:YES;
 
                    [aswitch setOn:parsePhotos animated:NO];
                    
                    [aswitch addTarget:self
                                action:@selector(switchValueChanged:)
                      forControlEvents:UIControlEventValueChanged];
                    aswitch.tag = TAG_SWITCH_PHOTOS;
                    [[cell.textLabel superview] addSubview:aswitch];
                    break;
                }
                case 1:
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                    if (cell == nil) {
                        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
                    }
                    
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    cell.textLabel.text = NSLocalizedString(@"Videos",nil);
                    
                    // UISwitch setup
                    NSArray *cellSubViews = [[cell.textLabel superview] subviews];
                    for (id item in cellSubViews) {
                        if ([item isKindOfClass:[UISwitch class]]) {
                            UISwitch *oldSwitch = (UISwitch *)item;
                            [oldSwitch removeFromSuperview];
                            break;
                        }
                    }
                    
                    UISwitch *aswitch = [[[UISwitch alloc] initWithFrame:CGRectMake(cell.contentView.frame.size.width - 110,
                                                                                    7,
                                                                                    100,
                                                                                    30)] autorelease];
                    aswitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

                    BOOL parseVideos = [prefs objectForKey:@"SyncVideos"]?[prefs boolForKey:@"SyncVideos"]:NO;

                    [aswitch setOn:parseVideos animated:NO];
                    
                    [aswitch addTarget:self
                                action:@selector(switchValueChanged:)
                      forControlEvents:UIControlEventValueChanged];
                    aswitch.tag = TAG_SWITCH_VIDEOS;
                    [[cell.textLabel superview] addSubview:aswitch];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 3:
        {
            switch (indexPath.row) {
                case 0:
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                    if (cell == nil) {
                        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
                    }
                    
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    cell.textLabel.text = NSLocalizedString(@"All albums",nil);
                    
                    // UISwitch setup
                    NSArray *cellSubViews = [[cell.textLabel superview] subviews];
                    for (id item in cellSubViews) {
                        if ([item isKindOfClass:[UISwitch class]]) {
                            UISwitch *oldSwitch = (UISwitch *)item;
                            [oldSwitch removeFromSuperview];
                            break;
                        }
                    }
                    
                    UISwitch *aswitch = [[[UISwitch alloc] initWithFrame:CGRectMake(cell.contentView.frame.size.width - 110,
                                                                                    7,
                                                                                    100,
                                                                                    30)] autorelease];
                    aswitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

                    [aswitch setOn:allAlbumsSelected animated:NO];
                    
                    [aswitch addTarget:self
                                action:@selector(switchAllAlbumValueChanged:)
                      forControlEvents:UIControlEventValueChanged];
                    aswitch.tag = 0;
                    [[cell.textLabel superview] addSubview:aswitch];
                    break;
                }
                default:
                {                    
                    cell = [tableView dequeueReusableCellWithIdentifier:PhotoCellIdentifier];
                    if (cell == nil) {
                        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:PhotoCellIdentifier] autorelease];
                    }
                    
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.textLabel.font = [UIFont systemFontOfSize:13];
                    
                    // Get count
                    ALAssetsGroup *g = (ALAssetsGroup*)[assetGroups objectAtIndex:indexPath.row - 1];
                    
                    cell.textLabel.text = [g valueForProperty:ALAssetsGroupPropertyName];
                    [cell.imageView setImage:[UIImage imageWithCGImage:[(ALAssetsGroup*)[assetGroups objectAtIndex:indexPath.row - 1] posterImage]]];
                    
                    // UISwitch setup
                    NSArray *cellSubViews = [[cell.textLabel superview] subviews];
                    for (id item in cellSubViews) {
                        if ([item isKindOfClass:[UISwitch class]]) {
                            UISwitch *oldSwitch = (UISwitch *)item;
                            [oldSwitch removeFromSuperview];
                            break;
                        }
                    }

                    UISwitch *aswitch = [[[UISwitch alloc] initWithFrame:CGRectMake(cell.contentView.frame.size.width - 110,
                                                                                    7,
                                                                                    100,
                                                                                    30)] autorelease];
                    aswitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

                    if ([prefs objectForKey:@"SelectedAlbumsDict"]) {
                        NSMutableDictionary *dict = [prefs objectForKey:@"SelectedAlbumsDict"];
                        if ([dict objectForKey:[g valueForProperty:ALAssetsGroupPropertyPersistentID]]) {
                            [aswitch setOn:[[dict objectForKey:[g valueForProperty:ALAssetsGroupPropertyPersistentID]] boolValue]
                                  animated:NO];
                        } else {
                            [aswitch setOn:YES
                                  animated:NO];
                        }
                    } else {
                        [aswitch setOn:YES
                              animated:NO];
                    }
                    [aswitch addTarget:self
                                action:@selector(switchAlbumValueChanged:)
                      forControlEvents:UIControlEventValueChanged];
                    aswitch.tag = indexPath.row - 1;
                    [[cell.textLabel superview] addSubview:aswitch];
                    break;
                }
            }
        }
        default:
            break;
    }
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}


- (void)switchValueChanged:(id)sender {
	int tag = ((UISwitch *)sender).tag;
    switch (tag) {
        case TAG_SWITCH_PHOTOS:
        {
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setBool:[sender isOn] forKey:@"SyncPhotos"];
            break;
        }
        case TAG_SWITCH_VIDEOS:
        {
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setBool:[sender isOn] forKey:@"SyncVideos"];
            break;
        }
    }
}

- (void)segCtrlValueChanged:(UISegmentedControl *)segCtrl {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSInteger mapType = 0;
	if(segCtrl.selectedSegmentIndex == 0) {
		mapType = MKMapTypeStandard;
	} else if (segCtrl.selectedSegmentIndex == 1) {
		mapType = MKMapTypeSatellite;
	} else if (segCtrl.selectedSegmentIndex == 2) {
		mapType = MKMapTypeHybrid;
	}
    [prefs setInteger:mapType forKey:@"MapType"];
}

- (void)switchAllAlbumValueChanged:(id)sender {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setBool:[sender isOn] forKey:@"AllAlbumsSelected"];
    
    allAlbumsSelected = [sender isOn];
	[self.tableView reloadData];
}

- (void)switchAlbumValueChanged:(id)sender {
	int tag = ((UISwitch *)sender).tag;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    ALAssetsGroup *g = (ALAssetsGroup*)[assetGroups objectAtIndex:tag];
    
    NSMutableDictionary *dict = nil;
    if ([prefs objectForKey:@"SelectedAlbumsDict"]) {
        dict = [NSMutableDictionary dictionaryWithDictionary:[prefs objectForKey:@"SelectedAlbumsDict"]];
    } else {
        dict = [NSMutableDictionary dictionary];
    }
    [dict setObject:[NSNumber numberWithBool:[sender isOn]] forKey:[g valueForProperty:ALAssetsGroupPropertyPersistentID]];

    [prefs setObject:dict forKey:@"SelectedAlbumsDict"];
}

- (void)sliderValueChanged:(id)sender {
    UISlider *slider = (UISlider *)sender;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    switch (((UISwitch *)sender).tag) {
        case TAG_SLIDER_SIZE:
            [prefs setFloat:slider.value forKey:@"AnnotationRatio"];    
            break;
        case TAG_SLIDER_TRANSPARENCY:
            [prefs setFloat:slider.value forKey:@"AnnotationAlpha"];    
            break;
            
        default:
            break;
    }
}


- (void)dealloc {
    [super dealloc];
}

@end

//
//  topPlacesTableViewController.m
//  topPlaces
//
//  Created by Wang Tom on 2018-01-28.
//  Copyright © 2018 Wang Tom. All rights reserved.
//

#import "topPlacesTableViewController.h"
#import "FlickrFetcher.h"
#import "photosInSelectedPlaceTableViewController.h"
#import "mapViewController.h"
#import "mapAnnotation.h"

@interface topPlacesTableViewController () <mapViewControllerDelegate>
@property (nonatomic, strong)NSArray *topPlaces;
@end

@implementation topPlacesTableViewController
@synthesize topPlaces = _topPlaces;

- (void)viewDidLoad {
    NSLog(@"view did load");
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"view will appear");
    [super viewWillAppear:YES];
    [self refresh:self.navigationItem.leftBarButtonItem];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)refresh:(UIBarButtonItem *)sender {
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [spinner startAnimating];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("download places data", NULL);
    dispatch_async(downloadQueue, ^{
        NSArray *topPlacesArray = [NSArray array];
        topPlacesArray = [FlickrFetcher topPlaces];
        dispatch_async(dispatch_get_main_queue(), ^{
            [sender setEnabled:false];
            [sender setEnabled:true];
            self.navigationItem.leftBarButtonItem = sender;
            self.topPlaces = topPlacesArray;
        });
    });
}

- (void)setTopPlaces:(NSArray *)topPlaces {
    _topPlaces = topPlaces;
    [self updateDetailVC];
    [self.tableView reloadData];
}

- (NSArray *)topPlaces {
    if (!_topPlaces) {
        _topPlaces = [NSArray array];
    }
    return _topPlaces;
}

- (NSArray *)mapAnnotations {
    NSMutableArray *annotations = [[NSMutableArray alloc] initWithCapacity:[self.topPlaces count]];
    for (NSDictionary *place in self.topPlaces) {
        [annotations addObject:[mapAnnotation annotationForPlaceAndPhoto:place]];
    }
    return annotations;
}

- (UIImage *)mapViewController:(mapViewController *)mapVC imageForAnnotation:(id<MKAnnotation>)annotation {
    mapAnnotation *anno = (mapAnnotation *) annotation;
    NSURL *url = [FlickrFetcher urlForPhoto:anno.data format:FlickrPhotoFormatSquare];
    NSData *imgData = [NSData dataWithContentsOfURL:url];
    return imgData ? [UIImage imageWithData:imgData] : nil;
}

- (void)updateDetailVC {
    id navigationVC = [[self.splitViewController viewControllers] lastObject];
    if ([navigationVC isKindOfClass:[UINavigationController class]]) {
        NSLog(@"navigation vc");
        id mapVC = [navigationVC topViewController];
        if ([mapVC isKindOfClass:[mapViewController class]]) {
            NSLog(@"map vc");
            ((mapViewController *)mapVC).delegate = self;
            [(mapViewController *)mapVC setAnnotations:[self mapAnnotations]];
        }
    }
}

- (BOOL)segueFromPlace {
    return YES;
}

- (BOOL)segueFromPhotos {
    return NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.topPlaces count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"topPlacesCell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSDictionary *place = [self.topPlaces objectAtIndex:[indexPath row]];
    [cell.textLabel setText:[place objectForKey:FLICKR_CITYNAME]];
    [cell.detailTextLabel setText:[place objectForKey:FLICKR_PLACE_NAME]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger selectedRow = [indexPath row];
    NSDictionary *place = [self.topPlaces objectAtIndex:selectedRow];
    [self performSegueWithIdentifier:@"showPhotosInSelectedPlace" sender:place];
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"showPhotosInSelectedPlace"]) {
        if ([sender isKindOfClass:[NSDictionary class]]) {
            NSDictionary *place = sender;
            [segue.destinationViewController setPlace:place];
            [segue.destinationViewController setTitle:[place objectForKey:FLICKR_CITYNAME]];
        }
    }
    else if ([segue.identifier isEqualToString:@"showMap"]) {
        [segue.destinationViewController setDelegate: self];
        [segue.destinationViewController setAnnotations:[self mapAnnotations]];
    }
}

@end



//
//  AssetTablePicker.m
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetTablePicker.h"
#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "ELCAlbumPickerController.h"

@implementation ELCAssetTablePicker

@synthesize parent;
@synthesize selectedAssetsLabel;
@synthesize assetGroup, elcAssets;

-(void)viewDidLoad {
        
	[self.tableView setSeparatorColor:[UIColor clearColor]];
	[self.tableView setAllowsSelection:NO];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    self.elcAssets = tempArray;
    [tempArray release];
	
	UIBarButtonItem *doneButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)] autorelease];
	[self.navigationItem setRightBarButtonItem:doneButtonItem];
	[self.navigationItem setTitle:@"Loading..."];

    backgroundThread = [[NSThread alloc] initWithTarget: self selector: @selector(preparePhotos) object: NULL];
    if(backgroundThread)
    {
        [backgroundThread start];
    }

    createdCells = [[NSMutableArray alloc] initWithCapacity: 2048];
}

// if the assets already have superviews (i.e. they are already an official part of a 
// currently-displayed table cell) there's no sense redrawing them...
-(BOOL)okayToRedraw: (NSUInteger) rowNumber {

    NSUInteger startOfRange = (rowNumber * 4);
    NSUInteger length = [self.elcAssets count] - 1;
    
    if(length - startOfRange > 3)
    {
        length = 3;
    }
    
    if(length > 0)
    {
        NSRange subarrayRange = NSMakeRange(startOfRange, length);
        NSArray * elcAssetSubarray = NULL;
        @try {
            elcAssetSubarray = [self.elcAssets subarrayWithRange:subarrayRange];
        }
        @catch( NSException * exception )
        {
            NSLog( @"exception raised in okayToRedraw - location %d length %d %@ %@", 
                  startOfRange, length, [exception name], [exception reason] );
        }
        @finally {
            for(ELCAsset * elcAsset in elcAssetSubarray)
            {
                if([elcAsset superview] != NULL)
                    return NO;
            }
        }
    }
    return YES;
}

-(void)preparePhotos {
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    pthread_setname_np("preparePhotos Thread"); // <- oh how I wish this actually named the thread in xcode 4's debugger

    //NSLog(@"enumerating photos");
    [self.assetGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) 
    {         
         if(result == nil) 
         {
             return;
         }

         // ELCAsset *elcAsset = [[[ELCAsset alloc] initWithAsset:result] autorelease];
         ELCAsset *elcAsset = [[ELCAsset alloc] initWithAsset:result];
         [elcAsset setParent:self];
         if(backgroundThread.isCancelled)
         {
             *stop = YES;
             [elcAsset release];
             return;
         } else {
             NSArray * visibleCells = [self.tableView indexPathsForVisibleRows];
             elcAsset.tag = index;
             [self.elcAssets addObject:elcAsset];
             [elcAsset release];

             // check to see if this newly created asset is on a row that is currently visible in the table view
             if(visibleCells)
             {
                 NSMutableArray * visibleCellsPlusOneMoreRow = [[NSMutableArray alloc] initWithCapacity: [visibleCells count] + 1];
                 if(visibleCellsPlusOneMoreRow)
                 {
                     NSIndexPath * lastIndexPath = [visibleCells lastObject];
                     NSIndexPath * extraIndexPath = [NSIndexPath indexPathForRow: lastIndexPath.row+1 inSection: lastIndexPath.section];

                     [visibleCellsPlusOneMoreRow addObjectsFromArray: visibleCells];
                     [visibleCellsPlusOneMoreRow addObject: extraIndexPath];
                     
                     for(NSIndexPath * anIndexPath in visibleCellsPlusOneMoreRow)
                     {
                         if(anIndexPath.row > 0)
                         {
                             NSUInteger firstAssetOnThisRow = (anIndexPath.row * 4);
                             NSUInteger lastAssetOnThisRow = firstAssetOnThisRow + 3;
                             
                             if((index >= firstAssetOnThisRow) && (index <= lastAssetOnThisRow))
                             {
                                 if((index % 4) == 0)
                                 {
                                     NSUInteger rowToReload = anIndexPath.row - 1;

                                     if([self okayToRedraw: rowToReload])
                                     {
#if ELCDEBUG
                                         NSLog( @"forcing a reload of row %d (out of %f rows) which contains assets %d through %d; triggered by index %d", anIndexPath.row, ceil(index / 4.0), firstAssetOnThisRow, lastAssetOnThisRow, index );
#endif
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             if(rowToReload < ceil([self.assetGroup numberOfAssets] / 4.0))
                                             {
                                                 NSIndexPath * newIndexPath = [NSIndexPath indexPathForRow: rowToReload inSection: anIndexPath.section];
                                                 
                                                 [self.tableView reloadRowsAtIndexPaths: [NSArray arrayWithObject: newIndexPath] withRowAnimation: UITableViewRowAnimationFade];
                                             }
                                         });
                                     }
                                 }
                             }
                         }
                     }
                     [visibleCellsPlusOneMoreRow release];
                 }
             }
         }
     }];
    //NSLog(@"done enumerating photos");
	
    if(backgroundThread.isCancelled == NO)
    {
        [self.tableView reloadData];
        [self.navigationItem setTitle:@"Pick Items"];
    }
    
    [backgroundThread release];
    backgroundThread = NULL;
    [pool release];
}

- (void) doneAction:(id)sender {
	
	NSMutableArray *selectedAssetsImages = [[NSMutableArray alloc] initWithCapacity:24];
    if(backgroundThread)
    {
        //NSLog( @"calling cancel on background thread" );
        [backgroundThread cancel];
    } else {
        //NSLog( @"no background thread to call cancel on");
    }

	for(ELCAsset *elcAsset in self.elcAssets) 
    {		
		if([elcAsset selected]) {
			
			[selectedAssetsImages addObject:[elcAsset asset]];
		}
	}
        
    [(ELCAlbumPickerController*)self.parent selectedAssets:selectedAssetsImages];
    
    [selectedAssetsImages release];
}

#pragma mark UITableViewDataSource Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ceil([self.assetGroup numberOfAssets] / 4.0);
}

// ugly
-(NSArray*)assetsForIndexPath:(NSIndexPath*)_indexPath {
    
	int index = (_indexPath.row*4);
	int maxIndex = (_indexPath.row*4+3);

    // ugly
	if(maxIndex < [self.elcAssets count]) {
        
		return [NSArray arrayWithObjects:[self.elcAssets objectAtIndex:index],
				[self.elcAssets objectAtIndex:index+1],
				[self.elcAssets objectAtIndex:index+2],
				[self.elcAssets objectAtIndex:index+3],
				nil];
	}
    
	else if(maxIndex-1 < [self.elcAssets count]) {
        
		return [NSArray arrayWithObjects:[self.elcAssets objectAtIndex:index],
				[self.elcAssets objectAtIndex:index+1],
				[self.elcAssets objectAtIndex:index+2],
				nil];
	}
    
	else if(maxIndex-2 < [self.elcAssets count]) {
        
		return [NSArray arrayWithObjects:[self.elcAssets objectAtIndex:index],
				[self.elcAssets objectAtIndex:index+1],
				nil];
	}
    
	else if(maxIndex-3 < [self.elcAssets count]) {
        
		return [NSArray arrayWithObject:[self.elcAssets objectAtIndex:index]];
	}
    
	return nil;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
        
    ELCAssetCell *cell = (ELCAssetCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) 
    {
        cell = [[ELCAssetCell alloc] initWithAssets:[self assetsForIndexPath:indexPath] reuseIdentifier:CellIdentifier];

#if ELCDEBUG
        NSLog( @"ROW %d brand new cell %p", indexPath.row, cell );
#endif
        [createdCells addObject: cell];
        [cell release];
        cell.tag = indexPath.row;
    }	
	else
    {
#if ELCDEBUG
        NSLog( @"ROW %d reycling cell %p", indexPath.row, cell );
#endif
		[cell setAssets:[self assetsForIndexPath:indexPath]];
        cell.tag = indexPath.row;
	}

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	return 79;
}

- (int)totalSelectedAssets {
    
    int count = 0;
    
    for(ELCAsset *asset in self.elcAssets) 
    {
		if([asset selected]) 
        {            
            count++;	
		}
	}
    
    return count;
}

- (void)dealloc 
{
    [createdCells release];
    [elcAssets release];
    
    [selectedAssetsLabel release];
    [super dealloc];    
}

@end

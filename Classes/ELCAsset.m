//
//  Asset.m
//
//  Created by Matt Tuzzolo on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAsset.h"
#import "ELCAssetTablePicker.h"
#import "UIImage+Resize.h"

@implementation ELCAsset

@synthesize asset;
@synthesize parent;

-(id)initWithAsset:(ALAsset*)_asset {
	
	if (self = [super initWithFrame:CGRectMake(0, 0, 75, 75)]) {
		
		self.asset = _asset;
		
		CGRect viewFrames = CGRectMake(0, 0, 75, 75);
		UIImage * bigThumb = [[UIImage alloc] initWithCGImage: [self.asset thumbnail]];
        UIImage * littleThumb = [bigThumb resizedImage: viewFrames.size interpolationQuality: kCGInterpolationLow];
		UIImageView *assetImageView = [[UIImageView alloc] initWithFrame:viewFrames];
		[assetImageView setContentMode:UIViewContentModeScaleToFill];
		[assetImageView setImage:littleThumb];
        [bigThumb release];
		[self addSubview:assetImageView];
		[assetImageView release];
		
		overlayView = [[UIImageView alloc] initWithFrame:viewFrames];
		[overlayView setImage:[UIImage imageNamed:@"Overlay.png"]];
		[overlayView setHidden:YES];
		[self addSubview:overlayView];

        UITapGestureRecognizer * recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleSelection)];
        [self addGestureRecognizer:recognizer];
        [recognizer release];

    }
    
	return self;	
}

-(void)toggleSelection {
	overlayView.hidden = !overlayView.hidden;
    
//    if([(ELCAssetTablePicker*)self.parent totalSelectedAssets] >= 10) {
//        
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Maximum Reached" message:@"" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
//		[alert show];
//		[alert release];	
//
//        [(ELCAssetTablePicker*)self.parent doneAction:nil];
//    }
}

-(BOOL)selected {
	return !overlayView.hidden;
}

-(void)setSelected:(BOOL)_selected {
	[overlayView setHidden:!_selected];
}

- (void)dealloc 
{    
    UIGestureRecognizer * recognizer = [self.gestureRecognizers objectAtIndex: 0];
    [self removeGestureRecognizer: recognizer];

    [self removeFromSuperview];
    self.asset = nil;
	[overlayView release];
    [super dealloc];
}

@end


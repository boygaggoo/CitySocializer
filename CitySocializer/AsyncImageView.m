//
//  AsyncImageView.m
//  RealMadrid
//
//  Created by macbook on 7/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AsyncImageView.h"

@implementation AsyncImageView

@synthesize data,connection;

- (void)loadImageFromURL:(NSURL*)url {
    UIImageView* imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"loading.png"]];
    
    imageView.contentMode = UIViewContentModeScaleToFill;
    imageView.autoresizingMask = ( UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight );
    
    [self addSubview:imageView];
    imageView.frame = self.bounds;
    [imageView setNeedsLayout];
    [self setNeedsLayout];
    NSURLRequest* request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:60.0];
    connection = [[NSURLConnection alloc]
                  initWithRequest:request delegate:self];
    //TODO error handling, what if connection is nil?
}

- (void)connection:(NSURLConnection *)theConnection
    didReceiveData:(NSData *)incrementalData {
    if (data==nil) {
        data =
        [[NSMutableData alloc] initWithCapacity:2048];
    }
    [data appendData:incrementalData];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)theConnection {
    
    connection=nil;
    
    if ([[self subviews] count]>0) {
        [[[self subviews] objectAtIndex:0] removeFromSuperview];
    }
    
    UIImageView* imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:data]];
    
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.autoresizingMask = ( UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight );
    
    [self addSubview:imageView];
    imageView.frame = self.bounds;
    [imageView setNeedsLayout];
    [self setNeedsLayout];
    data=nil;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = FALSE;
}

- (UIImage*) image {
    UIImageView* iv = [[self subviews] objectAtIndex:0];
    return [iv image];
}

- (void)dealloc {
    [connection cancel];
}

@end

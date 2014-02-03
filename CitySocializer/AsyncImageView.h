//
//  AsyncImageView.h
//  RealMadrid
//
//  Created by macbook on 7/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AsyncImageView : UIView

@property(nonatomic,strong)NSURLConnection* connection;
@property(nonatomic,strong)NSMutableData* data;
- (void)loadImageFromURL:(NSURL*)url;
- (UIImage*) image;
@end

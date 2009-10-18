//
//  EtherTeXAppDelegate.m
//  EtherTeX
//
//  Created by Uwe Dauernheim on 11.10.09.
//  Copyright 2009 KTH. All rights reserved.
//

#import "EtherTeXAppDelegate.h"

@implementation EtherTeXAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
}

- (void) awakeFromNib
{
	NSString *urlText = [NSString stringWithString:@"http://kreisquadratur.etherpad.com/SA3"];
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlText]]];	
	
    NSString *pdfPath = [[NSBundle mainBundle] pathForResource: @"Test" ofType: @"pdf"];
	PDFDocument *pdfDoc = [[[PDFDocument alloc] initWithURL: [NSURL fileURLWithPath: pdfPath]] autorelease];
	[pdfView setDocument: pdfDoc];
}

@end

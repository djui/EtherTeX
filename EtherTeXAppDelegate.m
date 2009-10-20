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
@synthesize webView;
@synthesize pdfView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
}

- (void)awakeFromNib {
	// Hide the window's toolbar
	[window toggleToolbarShown:self];
	
	// Get web address
	//	NSString *urlText = [NSString stringWithString:@"http://kreisquadratur.etherpad.com/SA3"];
	NSString *protocol = [NSString stringWithString:@"http://"];
	NSString *userId = [NSString stringWithString:@"kreisquadratur"];
	NSString *domain = [NSString stringWithString:@"etherpad.com"];
	NSString *padId = [NSString stringWithString:@"SA3"];
	NSString *urlText = [NSString stringWithFormat:@"%@%@.%@/%@", protocol, userId, domain, padId];
	NSURL *url = [NSURL URLWithString:urlText];

	// Display web site
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
	
	// Set main window's caption text
//	[window setRepresentedURL:url];
	// [window setTitleWithRepresentedFilename:urlText];
	
	// Set main window's icon
	NSString *imageName = [[NSBundle mainBundle] pathForResource:@"appl" ofType:@"icns"];
//	[[window standardWindowButton:NSWindowDocumentIconButton] setImage:[[NSImage alloc] initWithContentsOfFile:imageName]];
		
	// Set main window as edited
	[window setDocumentEdited:YES];
	
    // Get PDF address
	NSString *pdfPath = [[NSBundle mainBundle] pathForResource:@"Test" ofType:@"pdf"];

	// Display PDF
	PDFDocument *pdfDoc = [[[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:pdfPath]] autorelease];
	[pdfView setDocument:pdfDoc];

	// Start repetition background worker
	// TODO
}

- (BOOL)window:(NSWindow *)sender shouldPopUpDocumentPathMenu:(NSMenu *)titleMenu {
	return NO;
}

- (BOOL)window:(NSWindow *)window shouldDragDocumentWithEvent:(NSEvent *)event from:(NSPoint)dragImageLocation withPasteboard:(NSPasteboard *)pasteboard {
	return NO;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
	return YES;
}

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
	// TODO Not working/responding yet
    if (frame == [sender mainFrame]) {
        NSString *urlText = [[[[frame provisionalDataSource] request] URL] absoluteString];
		NSURL *url = [NSURL URLWithString:urlText];
		[window setRepresentedURL:url];
    }
}

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame {
    if (frame == [sender mainFrame]) {
        [[sender window] setTitle:title];
    }
}

- (void)webView:(WebView *)sender didReceiveIcon:(NSImage *)image forFrame:(WebFrame *)frame {
    if (frame == [sender mainFrame]) {
		[[[sender window] standardWindowButton:NSWindowDocumentIconButton] setImage:image];
    }
}

@end

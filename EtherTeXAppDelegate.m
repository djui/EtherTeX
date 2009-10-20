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
	// TODO Save everything in UserDefaults
	
	// TODO Check for internet connection
	NSURL *connectivityUrl = [NSURL URLWithString:@"http://www.etherpad.com"];
	CFNetDiagnosticRef diag = CFNetDiagnosticCreateWithURL(NULL, (CFURLRef)connectivityUrl);
	CFNetDiagnosticStatus status = CFNetDiagnosticCopyNetworkStatusPassively(diag, NULL);
	CFRelease(diag);
	
	if (status != kCFNetDiagnosticConnectionUp) {
		NSLog (@"Connection is down");
		NSAlert* alert = [[NSAlert alloc] init];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert setMessageText: @"No internet connection"];
		[alert setInformativeText: @"There is no internet connection available. Please establish an internet connection and restart the application."];
		[alert setIcon: [NSImage imageNamed:@"DisconnectedIcon"]];
		[alert setShowsSuppressionButton:YES];
		[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];		
		[alert release];
	}
	
	// TODO Check if there is a pdflatex file somewhere
	NSArray *pdfLatexPaths = [NSArray arrayWithObjects: 
							  @"/usr/texbin/pdflatex", 
							  @"/usr/local/texlive/2008/bin/universal-darwin/pdflatex",
							  nil];
	
	NSString *pdfLatexPath = nil;
	for (int i = 0; i < [pdfLatexPaths count]; i++) {
		if ([[NSFileManager defaultManager] fileExistsAtPath:[pdfLatexPaths objectAtIndex:i]]) {
			pdfLatexPath = [pdfLatexPaths objectAtIndex:i];
			NSLog(@"FOUND at %@\n", pdfLatexPath);
		}
	}
	if (pdfLatexPath == nil) {	
		// TODO Only show the "no pdflatex available" warning if net already seen
		if (YES) {
			NSAlert* alert = [[NSAlert alloc] init];
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert setMessageText: @"No pdflatex found"];
			[alert setInformativeText: @"No pdflatex installation available, so no PDF previews can be generated. Please install a TeX distribution.\n(http://www.tug.org/mactex/)"];
			[alert setIcon: [NSImage imageNamed:@"AlertCautionIcon"]];
			[alert setShowsSuppressionButton:YES];
			[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];		
			[alert release];
		}
	}
}

/*
 - (void)applicationWillFinishLaunching:(NSNotification *)aNotification {}
 */

- (void)awakeFromNib {
	[webView setFrameLoadDelegate:self];
    [webView setUIDelegate:self];
    [webView setResourceLoadDelegate:self];
	
	// TODO Hide everything until we have at least or web site completely finished loaded
	
	// Hide the window's toolbar
	[window toggleToolbarShown:self];
	
	// Get web address
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
	NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(tick:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)tick:(NSTimer *)theTimer {
	// TODO Download the text file content
	// Better use: http://developer.apple.com/mac/library/documentation/Cocoa/Conceptual/URLLoadingSystem/Tasks/UsingNSURLDownload.html#//apple_ref/doc/uid/20001839 or http://developer.apple.com/mac/library/documentation/Cocoa/Conceptual/URLLoadingSystem/Tasks/UsingNSURLConnection.html
	NSString *protocol = [NSString stringWithString:@"http://"];
	NSString *userId = [NSString stringWithString:@"kreisquadratur"];
	NSString *domain = [NSString stringWithString:@"etherpad.com"];
	NSString *padId = [NSString stringWithString:@"SA3"];
	NSString *urlText = [NSString stringWithFormat:@"%@%@.%@/ep/pad/export/%@/latest?format=txt", protocol, userId, domain, padId];
	NSURL *url = [NSURL URLWithString:urlText];

	NSData *content = [NSData dataWithContentsOfURL: url];
	
	// TODO Store it in a file (maybe optional due to direct stdin input?)
	NSString *tempFileTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ethertextfile.tex"];
	const char *tempFileTemplateCString = [tempFileTemplate fileSystemRepresentation];
	char *tempFileNameCString = (char *)malloc(strlen(tempFileTemplateCString) + 1);
	strcpy(tempFileNameCString, tempFileTemplateCString);
	int fileDescriptor = mkstemp(tempFileNameCString);
	
	NSString *tempFileName = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempFileNameCString length:strlen(tempFileNameCString)];
	free(tempFileNameCString);
		
	[content writeToFile:tempFileName atomically:YES];
	
	NSLog(@"%@:\n", tempFileName);
	NSLog(@"%d\n", content);
	
	// TODO Run "pdflatex"
	// @"pdflatex -version" -> "pdfTeX 3.1415926-1.40.9-2.2 (Web2C 7.5.7)\n..."
	NSString *pdfLatexPath = [NSString stringWithString: @"/usr/texbin/pdflatex"];
	NSTask *task = [[NSTask alloc] init];
	NSArray *arguments = [NSArray arrayWithObjects: @"-version", nil];
	NSPipe *pipe = [NSPipe pipe];
	NSFileHandle *file = [pipe fileHandleForReading];
	
	[task setLaunchPath: pdfLatexPath];
	// [task setCurrentDirectoryPath: @""];
	[task setArguments: arguments];	
	[task setStandardOutput: pipe];
	[task launch];
	
	NSData *data = [file readDataToEndOfFile];
	NSString *string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];	
	
	// TODO Check if no errors
	
	// TODO Check if file exists
	// if ([fileManager fileExistsAtPath:filePath]) {}
	
	// TODO Update either gray screen or new PDF
	
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void*)contextInfo {
	if ([[alert suppressionButton] state] == NSOnState) {
		// TODO Add a note to the configuration, that this popup should not be shown again
	}	
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

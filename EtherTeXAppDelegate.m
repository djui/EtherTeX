//
// EtherTeXAppDelegate.m
// EtherTeX
//
// Created by Uwe Dauernheim on 11.10.09.
// Copyright 2009 Kreisquadratur. All rights reserved.
//

#import "EtherTeXAppDelegate.h"
#import "PreferencesDelegate.h"

@implementation EtherTeXAppDelegate

@synthesize mainWindow;
@synthesize preferenceWindow;

@synthesize webView;
@synthesize pdfView;
@synthesize parserIndicator;

@synthesize tempfilePath;
@synthesize	defaults;

/*
 unsigned bytesReceived;
 unsigned expectedContentLength = 10000;
*/

- (id)init {
	if ((self = [super init])) {
		defaults = [NSUserDefaults standardUserDefaults];
		[defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
																@"60", @"download_interval",
																@"etherpad.com", @"domain",
																@"kreisquadratur", @"teamsite_id",
																@"SA3", @"pad_id",
																@"", @"pdflatex_path",
																@"NO", @"ignore_no_pdflatex",
																nil]];
		
		preferenceWindow = [[PreferenceWindow alloc] init];
	}

	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {	
	[self checkForConnectivity];
	
	if ([defaults stringForKey:@"pdflatex_path"] == @"") {
		[self searchForAndSetPDFLatexPath];
	}
	
  if ([defaults stringForKey:@"pdflatex_path"] == @"") {
		if (![defaults boolForKey:@"ignore_no_pdflatex"]) {
			[self warnNoPDFLatexAvailable];
		}
	}

	[self startDownloadingURL];

	[NSTimer scheduledTimerWithTimeInterval:[defaults integerForKey:@"download_interval"] 
																target:self selector:@selector(tick:) 
																userInfo:nil repeats:NO];
	
	[NSBundle loadNibNamed:@"Preferences" owner:preferenceWindow];
}

- (void)awakeFromNib {
	[webView setFrameLoadDelegate:self];
	[webView setUIDelegate:self];
	[webView setResourceLoadDelegate:self];
	//[webView setWantsLayer:YES];
	
	// Hide everything until we have at least or web site completely finished loaded
	[webView setHidden:YES];
	[pdfView setHidden:YES];
	
	// Hide the window's toolbar
	[mainWindow toggleToolbarShown:self];
	
	// Get web address
	NSString *TeamsiteId = [defaults stringForKey:@"teamsite_id"];
	NSString *domain = [defaults stringForKey:@"domain"];
	NSString *padId = [defaults stringForKey:@"pad_id"];
	NSString *urlText = [NSString stringWithFormat:@"http://%@.%@/%@", TeamsiteId, domain, padId];
	NSURL *url = [NSURL URLWithString:urlText];
	
	// Display web site
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
	
	// Set main window's caption text
	[mainWindow setRepresentedURL:url];
	
	// Set main window's icon
	NSString *imageName = [[NSBundle mainBundle] pathForResource:@"app" ofType:@"icns"];
	NSImage *windowIcon = [[NSImage alloc] initWithContentsOfFile:imageName];
	[[mainWindow standardWindowButton:NSWindowDocumentIconButton] setImage:windowIcon];
	
	// Set main window as edited
	[mainWindow setDocumentEdited:YES];
}

- (void)checkForConnectivity {
	NSString *domain = [defaults stringForKey:@"domain"];
	NSString *urlText = [NSString stringWithFormat:@"http://www.%@/", domain];	
	NSURL *connectivityUrl = [NSURL URLWithString:urlText];
	CFNetDiagnosticRef diag = CFNetDiagnosticCreateWithURL(NULL, (CFURLRef)connectivityUrl);
	CFNetDiagnosticStatus status = CFNetDiagnosticCopyNetworkStatusPassively(diag, NULL);
	CFRelease(diag);
	
	if (status != kCFNetDiagnosticConnectionUp) {
		NSLog(@"Connection is down");
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert setMessageText:NSLocalizedString(@"No Connectivity", nil)];
		[alert setInformativeText:NSLocalizedString(@"There is no internet connection available. Please establish an internet connection and restart the application.", nil)];
		[alert setIcon: [NSImage imageNamed:@"DisconnectedIcon"]];
		[alert beginSheetModalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(noConnectivityAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
		[alert release];
	}
}

- (void)noConnectivityAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void*)contextInfo {
	// Quit the application because no connectivity means there is no use of etherpad
	[mainWindow close];
}

- (void)searchForAndSetPDFLatexPath {
	// Check if there is a pdflatex file somewhere
	NSArray *pdfLatexSearchPaths = [NSArray arrayWithObjects: 
																	@"/usr/texbin/pdflatex", 
																	@"/usr/local/texlive/2008/bin/universal-darwin/pdflatex",
																	nil];
		
	for (NSString *pdfLatexSearchPath in pdfLatexSearchPaths) {
		NSLog(@"Check for existance: %@", pdfLatexSearchPath);
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:pdfLatexSearchPath]) {
			[defaults setObject:pdfLatexSearchPath forKey:@"pdflatex_path"];
			NSLog(@"Found pdflatex at %@", pdfLatexSearchPath);
			break;
		}
	}
}

- (void)warnNoPDFLatexAvailable {
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert setMessageText:NSLocalizedString(@"No pdflatex found", nil)];
	[alert setInformativeText:NSLocalizedString(@"No pdflatex installation available, so no PDF previews can be generated. Please install a TeX distribution.(http://www.tug.org/mactex/)", nil)];
	[alert setIcon:[NSImage imageNamed:@"AlertCautionIcon"]];
	[alert setShowsSuppressionButton:YES];
	[alert beginSheetModalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(noPDFLatexAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];		
	[alert release];
}

- (void)noPDFLatexAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void*)contextInfo {
	if ([[alert suppressionButton] state] == NSOnState) {
		[defaults setBool:YES forKey:@"ignore_no_pdflatex"];
	}
}

// Set background worker
/*
 [parserIndicator setMinValue:0.0];
 [parserIndicator setMaxValue:100];
 [parserIndicator incrementBy:10.0];
 [parserIndicator setDoubleValue:2.0];
 [parserIndicator startAnimation:self];
 NSTimer *timer = [[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(checkThem:) userInfo:nil repeats:YES] retain];
 [progressBar startAnimation: self];
 }
 
 -(void)checkThem:(NSTimer *)aTimer
 {
 count++;
 if(count > 100)
 {
 count = 0;
 [timer invalidate];
 [timer release];
 timer = NULL;
 [progressBar setDoubleValue:0.0];
 [progressBar stopAnimation: self];
 }
 else
 {
 [progressBar setDoubleValue:(100.0 * count) / 100;
 }
 }
 */	

- (void)tick:(NSTimer *)theTimer {
	// Download the text file content
	[self startDownloadingURL];
}

- (void)startDownloadingURL {
	NSString *TeamsiteId = [defaults stringForKey:@"teamsite_id"];
	NSString *domain = [defaults stringForKey:@"domain"];
	NSString *padId = [defaults stringForKey:@"pad_id"];
	NSString *urlText = [NSString stringWithFormat:@"http://%@.%@/ep/pad/export/%@/latest?format=txt", TeamsiteId, domain, padId];

	NSLog(@"Downloading url: %@", urlText);
	
	// Create the request
	NSURL *url = [NSURL URLWithString:urlText];
	NSURLRequest *theRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:DOWNLOAD_TIMEOUT];

	// Create the temporary file for the download content
	NSString *tempfileName = [NSString stringWithFormat: @"ethertex_%@_%@.tex", TeamsiteId, padId];
	[self setTempfilePath:[NSTemporaryDirectory() stringByAppendingPathComponent:tempfileName]];

	// Create the connection with the request and start loading the data
	NSURLDownload *theDownload = [[NSURLDownload alloc] initWithRequest:theRequest delegate:self];
	[theDownload setDestination:[self tempfilePath] allowOverwrite:YES];	
}

-(void)download:(NSURLDownload *)download didCreateDestination:(NSString *)path {
	NSLog(@"Final file destination: %@", path);
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error {
	[download release];	
	NSLog(@"Download failed! Error - %@ %@", [error localizedDescription], [error userInfo]);
	// Set background worker
	[NSTimer scheduledTimerWithTimeInterval:[defaults integerForKey:@"download_interval"] target:self selector:@selector(tick:) userInfo:nil repeats:NO];
}

- (void)downloadDidFinish:(NSURLDownload *)download {
	[download release];
	NSLog(@"Download did finish.");
	[self parseTeXFile];
}

- (BOOL)checkParserResult:(int)resultStatus outputText:(NSString *)outputText {
	NSLog(@"texParserTask status: %d", resultStatus);
	
	// Check if no errors
	if (resultStatus == PDFLATEX_STATUS_SUCCESS) {
		
		NSLog(@"texParserTask succeeded.");
	} else { // PDFLATEX_STATUS_FAILURE
		NSLog(@"texParserTask possibly failed.");

		if ([outputText rangeOfString:@"Output written on "].location == NSNotFound) {
			NSLog(@"texParserTask failed.");
			return NO;
		} else {
			NSLog(@"texParserTask succeeded. (tex file had errors)");
		}
	}
		
	// Check if file exists
	NSString *pdfFile = [[[self tempfilePath] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:pdfFile]) {
		NSLog(@"Can't find PDF file. TexParserTask failed after all?");		
		return NO;
	}
	
	return YES;
}

- (void)parseTeXFile {
	NSLog(@"texParserTask: Parsing downloaded tex file...");

	NSString *workingDirectory = [[self tempfilePath] stringByDeletingLastPathComponent];
	NSString *texFile = [[self tempfilePath] lastPathComponent];
	
	// Run "pdflatex" : @"pdflatex -version" -> "pdfTeX 3.1415926-1.40.9-2.2 (Web2C 7.5.7)..."
	NSTask *texParserTask = [[NSTask alloc] init];
	NSArray *arguments = [NSArray arrayWithObjects:@"-interaction=nonstopmode", texFile, nil];
	NSPipe *pipe = [NSPipe pipe];
	NSFileHandle *outputHandle = [pipe fileHandleForReading];
	
	[texParserTask setLaunchPath:[defaults stringForKey:@"pdflatex_path"]];
	[texParserTask setCurrentDirectoryPath:workingDirectory];
	[texParserTask setArguments:arguments];	
	[texParserTask setStandardOutput:pipe];
	[texParserTask setStandardError:[NSFileHandle fileHandleWithNullDevice]];
	NSLog(@"texParserTask: Launching...");
	[texParserTask launch];
	NSLog(@"texParserTask: Launched");
	[texParserTask waitUntilExit];
	NSLog(@"texParserTask: Exit");
	
	NSData *data = [outputHandle readDataToEndOfFile];
	NSString *outputText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	BOOL success = [self checkParserResult:[texParserTask terminationStatus] outputText:outputText];
	if (success) {
		// Store all current and needed PDF view settings (scrollbar position, zoom level, etc.)
		// PDFDestination *currentPosition = [pdfView currentDestination];
		
		// Display PDF
		NSString *pdfFile = [[[self tempfilePath] stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
		PDFDocument *pdfDoc = [[[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:pdfFile]] autorelease];
		[pdfView setDocument:pdfDoc];
		[pdfView setHidden:NO];
		
		// Restore all old values
		// TODO CRASHES: maybe split in page and point?
		//[pdfView goToDestination: currentPosition];
		
		NSArray *filters = nil;
		CIFilter *filter = [CIFilter filterWithName:@"CIMaximumComponent"];
		[filter setDefaults];
		filters = [NSArray arrayWithObject:filter];
		 
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:1.5];
		[[[[self mainWindow] contentView] animator] setContentFilters:filters];
		[NSAnimationContext endGrouping];
	} else {
		// Gray out the PDF view
		/*
		 NSArray *filters = nil;
		 CIFilter *filter = [CIFilter filterWithName:@"CIPointillize"];
		 [filter setDefaults];
		 [filter setValue:[NSNumber numberWithFloat:4.0] forKey:@"inputRadius"];
		 filters = [NSArray arrayWithObject:filter];
		 
		 [NSAnimationContext beginGrouping];
		 [[NSAnimationContext currentContext] setDuration:1.5];
		 // [[[[self window] contentView] animator] replaceSubview:previousView with:view];
		 // [[[self window] animator] setFrame:newFrame display:YES];
		 [[webView animator] setContentFilters:filters];
		 [NSAnimationContext endGrouping];		
		 */
	}
	
	// Set background worker
	[NSTimer scheduledTimerWithTimeInterval:[defaults integerForKey:@"download_interval"] target:self selector:@selector(tick:) userInfo:nil repeats:NO];
}

/*
- (void)setDownloadResponse:(NSURLResponse *)aDownloadResponse {
 [aDownloadResponse retain];
 [downloadResponse release];
 downloadResponse = aDownloadResponse;
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response {
 bytesReceived=0;
	
 [self setDownloadResponse:response];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(unsigned)length {
 long long expectedLength=[[self downloadResponse] expectedContentLength];
	
 bytesReceived=bytesReceived+length;
	
 if (expectedLength != NSURLResponseUnknownLength) {
 float percentComplete=(bytesReceived/(float)expectedLength)*100.0;
 NSLog(@"Percent complete - %f",percentComplete);
 } else {
 NSLog(@"Bytes received - %d",bytesReceived);
 }
}
*/

- (BOOL)window:(NSWindow *)sender shouldPopUpDocumentPathMenu:(NSMenu *)titleMenu {
	return NO;
}

- (BOOL)window:(NSWindow *)window shouldDragDocumentWithEvent:(NSEvent *)event from:(NSPoint)dragImageLocation withPasteboard:(NSPasteboard *)pasteboard {
	return NO;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
	return YES;
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
	if (frame == [sender mainFrame]) {
		NSString *errorText = [NSString stringWithFormat:@"%@\n(%@)", 
													 [error localizedDescription],
													 [[[[frame provisionalDataSource] initialRequest] URL] absoluteString]]; 
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert setMessageText:NSLocalizedString(@"Error loading page", nil)];
		[alert setInformativeText:errorText];
		[alert setIcon:[NSImage imageNamed:@"AlertCautionIcon"]];
		[alert beginSheetModalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(PageLoadErrorAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];		
		[alert release];
	}
}

- (void)PageLoadErrorAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void*)contextInfo {
	// TODO Reload?
}

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
	if (frame == [sender mainFrame]) {
		NSString *urlText = [[[[frame provisionalDataSource] request] URL] absoluteString];
		NSURL *url = [NSURL URLWithString:urlText];
		[mainWindow setRepresentedURL:url];
	}
}

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame {
	if (frame == [sender mainFrame]) {
		[mainWindow setTitle:title];
	}
}

- (void)webView:(WebView *)sender didReceiveIcon:(NSImage *)image forFrame:(WebFrame *)frame {
	if (frame == [sender mainFrame]) {
		[[mainWindow standardWindowButton:NSWindowDocumentIconButton] setImage:image];
	}
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	if (frame == [sender mainFrame]) {
		[webView performSelector:@selector(setHidden:) withObject:NO afterDelay:1];
	}
}
	
@end

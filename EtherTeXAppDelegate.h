//
//  EtherTeXAppDelegate.h
//  EtherTeX
//
//  Created by Uwe Dauernheim on 11.10.09.
//  Copyright 2009 KTH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <Quartz/Quartz.h>

#include <SystemConfiguration/SystemConfiguration.h>

@interface EtherTeXAppDelegate : NSObject <NSApplicationDelegate> {
	NSWindow *mainWindow;
	IBOutlet WebView *webView;
	IBOutlet PDFView *pdfView;
	IBOutlet NSProgressIndicator *parserIndicator;
	
	NSString *tempfilePath;
	NSString *pdflatexPath;
	NSNumber *downloadInterval;
}

int DOWNLOAD_INTERVAL = 10;
int DOWNLOAD_TIMEOUT = 60;
int PDFLATEX_STATUS_SUCCESS = 0;
int PDFLATEX_STATUS_FAILURE = 1;

@property (assign) IBOutlet NSWindow *mainWindow;
@property (assign) IBOutlet WebView *webView;
@property (assign) IBOutlet PDFView *pdfView;
@property (assign) IBOutlet NSProgressIndicator *parserIndicator;

@property (copy) NSString *tempfilePath;
@property (copy) NSString *pdflatexPath;
@property (assign) NSNumber *downloadInterval;

- (void)startDownloadingURL;
- (void)parseTeXFile;
- (BOOL)checkParserResult:(int)resultStatus outputText:(NSString *)outputText;

@end

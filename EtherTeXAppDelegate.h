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

@interface EtherTeXAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
	IBOutlet WebView *webView;
	IBOutlet PDFView *pdfView;
}

@property (assign) IBOutlet NSWindow *window;

@end

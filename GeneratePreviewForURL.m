
#include <Cocoa/Cocoa.h>
#include <CoreFoundation/CoreFoundation.h>
#include <QuickLook/QuickLook.h>


OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSData *data = [NSData dataWithContentsOfURL:(NSURL*)url];
	NSImage *image = [[NSImage alloc] initWithData:data];
	if ([[image representations] count] == 0)
	{
		// Assume crippled iPhone png
		NSPipe *inputPipe = [NSPipe pipe];
		NSPipe *outputPipe = [NSPipe pipe];
		
		NSTask *ipin = [[NSTask alloc] init];
		[ipin setLaunchPath:@"/usr/bin/python"];
		[ipin setArguments:[NSArray arrayWithObject:[[NSBundle bundleWithIdentifier:@"ch.pitaya.qlgenerator.crippng"] pathForResource:@"ipin" ofType:@"py"]]];
		[ipin setStandardInput:inputPipe];
		[ipin setStandardOutput:outputPipe];
		
		@try
		{
			[ipin launch];
			[[inputPipe fileHandleForWriting] writeData:data];
			[[inputPipe fileHandleForWriting] closeFile];
			data = [[outputPipe fileHandleForReading] readDataToEndOfFile];
			[image release];
			image = [[NSImage alloc] initWithData:data];
		}
		@catch (NSException *exception)
		{
			data = [NSData data];
		}
		@finally
		{
			[ipin release];
		}
	}
	
	NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:roundf([image size].width)], kQLPreviewPropertyWidthKey, [NSNumber numberWithFloat:roundf([image size].height)], kQLPreviewPropertyHeightKey, nil];
	[image release];
	
	QLPreviewRequestSetDataRepresentation(preview, (CFDataRef)data, contentTypeUTI, (CFDictionaryRef)properties);
	
	[pool drain];
	return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
	// implement only if supported
}

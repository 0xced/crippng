
#include <Cocoa/Cocoa.h>
#include <CoreFoundation/CoreFoundation.h>
#include <QuickLook/QuickLook.h>


// takes a png buffer and a file descriptor where the valid png will be written
bool fix_png(const unsigned char *png, int fd);

NSString *uuid()
{
	CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
	CFStringRef uuidCFStr = CFUUIDCreateString(kCFAllocatorDefault, uuid);
	CFRelease(uuid);
	NSString *uuidNSStr = [NSString stringWithString:(NSString*)uuidCFStr];
	CFRelease(uuidCFStr);
	return uuidNSStr;
}

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSData *data = [NSData dataWithContentsOfURL:(NSURL*)url];
	NSImage *image = [[NSImage alloc] initWithData:data];
	if ([[image representations] count] == 0)
	{
		// Assume crippled iPhone png
		NSString *tempPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:uuid()] stringByAppendingPathExtension:@"png"];
		[[NSFileManager defaultManager] createFileAtPath:tempPath contents:[NSData data] attributes:nil];
		BOOL ok = fix_png([data bytes], [[NSFileHandle fileHandleForWritingAtPath:tempPath] fileDescriptor]);
		if (ok)
		{
			data = [NSData dataWithContentsOfFile:tempPath];
			[image release];
			image = [[NSImage alloc] initWithData:data];
		}
		[[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
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

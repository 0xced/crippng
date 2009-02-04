
#include <Cocoa/Cocoa.h>
#include <CoreFoundation/CoreFoundation.h>
#include <QuickLook/QuickLook.h>


// takes a png buffer and a file descriptor where the valid png will be written
bool fix_png(const unsigned char *png, int fd);

bool flip_channels(int inputFd, int outputFd);

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
		NSString *tempPathFixed = [[NSTemporaryDirectory() stringByAppendingPathComponent:uuid()] stringByAppendingPathExtension:@"png"];
		NSString *tempPathFlipped = [[NSTemporaryDirectory() stringByAppendingPathComponent:uuid()] stringByAppendingPathExtension:@"png"];
		[[NSFileManager defaultManager] createFileAtPath:tempPathFixed contents:[NSData data] attributes:nil];
		[[NSFileManager defaultManager] createFileAtPath:tempPathFlipped contents:[NSData data] attributes:nil];
		BOOL fixOK = fix_png([data bytes], [[NSFileHandle fileHandleForWritingAtPath:tempPathFixed] fileDescriptor]);
		if (fixOK)
		{
			data = [NSData dataWithContentsOfFile:tempPathFixed];
			BOOL flipOK = flip_channels([[NSFileHandle fileHandleForReadingAtPath:tempPathFixed] fileDescriptor], [[NSFileHandle fileHandleForWritingAtPath:tempPathFlipped] fileDescriptor]);
			if (flipOK)
			{
				data = [NSData dataWithContentsOfFile:tempPathFlipped];
				[image release];
				image = [[NSImage alloc] initWithData:data];
			}
		}
		[[NSFileManager defaultManager] removeItemAtPath:tempPathFixed error:nil];
		[[NSFileManager defaultManager] removeItemAtPath:tempPathFlipped error:nil];
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

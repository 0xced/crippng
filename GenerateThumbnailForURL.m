
#include <Cocoa/Cocoa.h>
#include <CoreFoundation/CoreFoundation.h>
#include <QuickLook/QuickLook.h>


OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
	return noErr;
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
	// implement only if supported
}

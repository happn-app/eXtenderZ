/*
Copyright 2021 happn

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

#import "HPNObjectExtender.h"

@import happnLogger;

@import eXtenderZ.HelptenderUtils;



#define DEFAULT_BUFFER_LENGTH (256) /* Bytes */

@implementation HPNObjectHelptender

+ (void)load
{
	[self hpn_registerClass:self asHelptenderForProtocol:@protocol(HPNObjectExtender)];
}

+ (void)hpn_helptenderHasBeenAdded:(NSObject <HPNHelptender> *)helptender
{
#pragma unused(helptender)
	/* Nothing do to here */
}

+ (void)hpn_helptenderWillBeRemoved:(NSObject <HPNHelptender> *)helptender
{
#pragma unused(helptender)
	/* Nothing do to here */
}

#pragma mark - Weird Stuff (Utils)

static SEL transformedSelectorFrom(SEL aSelector) {
	const char *selStringOri = sel_getName(aSelector);
	size_t n = strlen(selStringOri);
	if (n < 2) return NULL;
	
	BOOL selHasParams = (selStringOri[n-1] == ':');
	
	char staticBuffer[DEFAULT_BUFFER_LENGTH];
	char *selString = staticBuffer;
	BOOL hasMalloced = NO;
	
	size_t l = (n + 7/* strlen("object") + strlen(":") */ + 1/* NULL-char ending */);
	if (l > DEFAULT_BUFFER_LENGTH) {
		selString = malloc(l * sizeof(char));
		if (selString == NULL) return NULL;
		hasMalloced = YES;
	}
	selString[l-1] = '\0';
	strcpy(selString, "object:");
	strcpy(selString + 6/* strlen("object") */ + (selHasParams? 1: 0), selStringOri);
	
	if (!selHasParams) {
		selString[6/* strlen("object") */] = toupper(selString[6]);
		selString[n + 7/* strlen("object") + strlen(":") */ - 1] = ':';
	}
	
	SEL ret = sel_registerName(selString);
	if (hasMalloced) free(selString);
	return ret;
}

/* An initial buffer size lower than (startDelta + space + 1) is not accepted */
static char *typesInRangeFromMethodSignatureWithDelta(NSInteger startIdx, NSInteger endIdx, NSMethodSignature *ms,
																		char *buffer, size_t *bufferLength,
																		size_t startDelta, size_t guaranteedSpace,
																		BOOL *hadToMalloc) {
	STATIC_ASSERT(sizeof(char) == 1, sizeof_char_is_1);
	NSCParameterAssert(startIdx <= endIdx);
	NSCParameterAssert(endIdx < ms.numberOfArguments);
	
	size_t curPos = startDelta;
	size_t retLength = startDelta;
	
	for (NSInteger i = startIdx; i <= endIdx; ++i) {
		const char *curType = (i<0? [ms methodReturnType]: [ms getArgumentTypeAtIndex:i]);
		size_t l = strlen(curType);
		size_t d = l + 1 + guaranteedSpace;
		
		if (retLength + d > *bufferLength) {
			if (!*hadToMalloc) {
				/* First malloc */
				void *tempBuf = malloc(*bufferLength + d + DEFAULT_BUFFER_LENGTH);
				memcpy(tempBuf, buffer, retLength);
				buffer = tempBuf;
			} else {
				/* We already malloc'd. We have to re-alloc */
				buffer = realloc(buffer, *bufferLength + d + DEFAULT_BUFFER_LENGTH);
			}
			*bufferLength += d + DEFAULT_BUFFER_LENGTH;
			*hadToMalloc = YES;
		}
		
		memcpy(buffer + curPos, curType, l);
		curPos += l;
		retLength += l;
	}
	
	buffer[retLength] = '\0';
	return buffer;
}

#pragma mark - Weird Stuff

- (BOOL)respondsToSelector:(SEL)aSelector
{
	if (((BOOL (*)(id, SEL, SEL))HPN_HELPTENDER_CALL_SUPER(HPNObjectHelptender, aSelector)))
		return YES;
	
	NSArray *extendersConformingToProtocol = [self hpn_extendersConformingToProtocol:@protocol(HPNObjectExtender)];
	if (extendersConformingToProtocol.count == 0) return NO;
	
	aSelector = transformedSelectorFrom(aSelector);
	if (aSelector == NULL) return NO;
	
	for (id <HPNObjectExtender> extender in extendersConformingToProtocol)
		if ([extender respondsToSelector:aSelector])
			return YES;
	
	return NO;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	if (((BOOL (*)(id, SEL, SEL))HPN_HELPTENDER_CALL_SUPER_WITH_SEL_NAME(HPNObjectHelptender, respondsToSelector:, aSelector)))
		return ((NSMethodSignature *(*)(id, SEL, SEL))HPN_HELPTENDER_CALL_SUPER(HPNObjectHelptender, aSelector));
	
	NSArray *extendersConformingToProtocol = [self hpn_extendersConformingToProtocol:@protocol(HPNObjectExtender)];
	if (extendersConformingToProtocol.count == 0) return nil;
	
	aSelector = transformedSelectorFrom(aSelector);
	if (aSelector == NULL) return nil;
	
	for (NSObject <HPNObjectExtender> *extender in extendersConformingToProtocol) {
		if ([extender respondsToSelector:aSelector]) {
			NSMethodSignature *methodSignature = [extender methodSignatureForSelector:aSelector];
			
			char *types = NULL;
			BOOL hasMalloced = NO;
			size_t bufferLength = DEFAULT_BUFFER_LENGTH;
			char typesBuffer[DEFAULT_BUFFER_LENGTH] = {'\0'};
			types = typesInRangeFromMethodSignatureWithDelta(-1, 1, methodSignature, typesBuffer, &bufferLength, 0, 0, &hasMalloced);
			if (methodSignature.numberOfArguments > 3)
				types = typesInRangeFromMethodSignatureWithDelta(3, methodSignature.numberOfArguments-1, methodSignature, types, &bufferLength, strlen(types), 0, &hasMalloced);
			NSMethodSignature *transformedBackMethodSignature = [NSMethodSignature signatureWithObjCTypes:types];
			if (hasMalloced) free(types);
			
			return transformedBackMethodSignature;
		}
	}
	
	return nil;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	/* We could forward the invocation to all the extenders that respond to it
	 * (doc says so), but I think it's clearer to only forward to the first one
	 * that responds to the invocation's selector (how would we "merge" return
	 * values for methods returning something, etc.) */
	
	char *types = NULL;
	BOOL hasMalloced = NO;
	size_t idTypeLength = sizeof(@encode(id));
	size_t bufferLength = DEFAULT_BUFFER_LENGTH;
	char typesBuffer[DEFAULT_BUFFER_LENGTH] = {'\0'};
	types = typesInRangeFromMethodSignatureWithDelta(-1, 1, anInvocation.methodSignature, typesBuffer, &bufferLength, 0, idTypeLength, &hasMalloced);
	memcpy(types + strlen(types), @encode(id), idTypeLength);
	if (anInvocation.methodSignature.numberOfArguments > 2)
		types = typesInRangeFromMethodSignatureWithDelta(2, anInvocation.methodSignature.numberOfArguments - 1, anInvocation.methodSignature, types, &bufferLength, strlen(types), 0, &hasMalloced);
	NSInvocation *transformedInvocation = [NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:types]];
	transformedInvocation.selector = transformedSelectorFrom(anInvocation.selector);
	if (hasMalloced) free(types);
	
	void *dynamicBuffer = NULL;
	char staticBuffer[DEFAULT_BUFFER_LENGTH];
	
	void *curArgLoc = &staticBuffer;
	if (MAX(anInvocation.methodSignature.frameLength, anInvocation.methodSignature.methodReturnLength) > DEFAULT_BUFFER_LENGTH) {
		HPNLogD(@"Frame length (%"NSUINT_FMT") is greater than static buffer length (%"NSUINT_FMT"). Allocating a dynamic buffer.", anInvocation.methodSignature.frameLength, (NSUInteger)DEFAULT_BUFFER_LENGTH);
		dynamicBuffer = malloc(MAX(anInvocation.methodSignature.frameLength, anInvocation.methodSignature.methodReturnLength));
		curArgLoc = dynamicBuffer;
	}
	
	for (NSUInteger i = anInvocation.methodSignature.numberOfArguments; i > 2; --i) {
		[anInvocation          getArgument:curArgLoc atIndex:i-1];
		[transformedInvocation setArgument:curArgLoc atIndex:i];
	}
	void *nonARCedSelf = (__bridge void *)self;
	[transformedInvocation setArgument:&nonARCedSelf atIndex:2];
	
	for (id <HPNObjectExtender> extender in [self hpn_extendersConformingToProtocol:@protocol(HPNObjectExtender)]) {
		if ([extender respondsToSelector:transformedInvocation.selector]) {
			[transformedInvocation invokeWithTarget:extender];
			goto end;
		}
	}
	
	((void (*)(id, SEL, NSInvocation *))HPN_HELPTENDER_CALL_SUPER(HPNObjectHelptender, anInvocation));
	
end:
	if (anInvocation.methodSignature.methodReturnLength > 0) {
		[transformedInvocation getReturnValue:curArgLoc];
		[anInvocation          setReturnValue:curArgLoc];
	}
	if (dynamicBuffer != NULL) free(dynamicBuffer);
}

@end

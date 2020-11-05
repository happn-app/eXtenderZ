/*
Copyright 2020 happn

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

#import "HPNExtenderConfig.h"



@implementation HPNExtenderConfig

static os_log_t oslog = nil;

+ (os_log_t)oslog
{
	return oslog;
}

+ (void)setOslog:(os_log_t)newOslog
{
	oslog = newOslog;
}

- (instancetype)init
{
	[super doesNotRecognizeSelector:_cmd];
	return nil;
}

@end

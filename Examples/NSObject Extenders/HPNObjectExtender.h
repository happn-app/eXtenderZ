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

@import Foundation;

@import eXtenderZ;



@protocol HPNObjectExtender <HPNExtender>

@end



/* When an object extended with an extender conforming the the HPNObjectExtender
 * protocol receives a message to which it cannot respond, it will try asking
 * its extenders which conform to protocol HPNObjectExtender if they can respond
 * for him to the message. The first extender which can do it will be forwarded
 * a slightly modified message to. The original message will be modified so the
 * extended object which forwarded the message be included in the new message.
 *
 *
 * Let's see an example:
 * The object obj is sent a message
 *    doThis
 * without arguments. obj does not know how to doThis. Thus it will search its
 * extenders for an extender that can doThis. The first extender that can doThis
 * will be sent the message:
 *    objectDoThis:
 * with argument obj.
 * The original message is modified so it contains the original sender.
 *
 * Let's see what happens if the original message have an argument:
 *    doThisDuring:
 * The extender will receive the message:
 *    object:doThisDuring:
 *
 * When searching for extenders responding to the modified selector, the search
 * is done in the order the extenders were added to the object.
 */
@interface HPNObjectHelptender : NSObject <HPNHelptender>

@end

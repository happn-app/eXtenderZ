/*
 * HCObjectExtender.h
 * eXtenderZ
 *
 * Created by François LAMBOLEY on 29/04/14.
 * Copyright (c) 2014 FTW & Co. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "NSObject+Extender.h"



@protocol HCObjectExtender <HCExtender>

@end



/* When an object extended with an extender conforming the the HCObjectExtender
 * protocol receives a message to which it cannot respond, it will try asking
 * its extenders which conform to protocol HCObjectExtender if they can respond
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
@interface HCObjectHelptender : NSObject <HCHelptender>

@end

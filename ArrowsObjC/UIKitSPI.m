//
//  UIKitSPI.m
//  ArrowsObjC
//
//  Created by rd on 12/2/18.
//  Copyright © 2018 rd. All rights reserved.
//

#import "UIKitSPI.h"
#import <objc/runtime.h>
@import WebKit;
@import CoreGraphics;

typedef enum {
    WebEventMouseDown,
    WebEventMouseUp,
    WebEventMouseMoved,
    
    WebEventScrollWheel,
    
    WebEventKeyDown,
    WebEventKeyUp,
    
    WebEventTouchBegin,
    WebEventTouchChange,
    WebEventTouchEnd,
    WebEventTouchCancel
} WebEventType;

// These enum values are copied directly from GSEvent for compatibility.
typedef enum {
    WebEventFlagMaskAlphaShift = 0x00010000,
    WebEventFlagMaskShift      = 0x00020000,
    WebEventFlagMaskControl    = 0x00040000,
    WebEventFlagMaskAlternate  = 0x00080000,
    WebEventFlagMaskCommand    = 0x00100000,
} WebEventFlagValues;
typedef unsigned WebEventFlags;

// These enum values are copied directly from GSEvent for compatibility.
typedef enum {
    WebEventCharacterSetASCII           = 0,
    WebEventCharacterSetSymbol          = 1,
    WebEventCharacterSetDingbats        = 2,
    WebEventCharacterSetUnicode         = 253,
    WebEventCharacterSetFunctionKeys    = 254,
} WebEventCharacterSet;

NSString* WebEventInitStr() {
    return @"initWithKeyEventType:timeStamp:characters:charactersIgnoringModifiers:modifiers:isRepeating:withFlags:keyCode:isTabKey:characterSet:";
}

static IMP _original_WebEventInit_Imp;
void _replacement__WebEventInit(id self,
                                SEL _cmd,
                                WebEventType type,
                                CFTimeInterval timeStamp,
                                NSString* characters,
                                NSString* charactersIgnoringModifiers,
                                WebEventFlags modifiers,
                                BOOL repeating,
                                NSUInteger flags,
                                uint16_t keyCode,
                                BOOL tabKey,
                                WebEventCharacterSet characterSet
                                )
{
    NSLog(@"WebEventInit:");
    assert([NSStringFromSelector(_cmd) isEqualToString:WebEventInitStr()]);
    
    if(charactersIgnoringModifiers != nil) {
        NSString* keyName = [[UIKitSPI keyMapping] objectForKey:charactersIgnoringModifiers];
        if (keyName != nil) {
            characters = keyName;
            charactersIgnoringModifiers = characters;
        }
    }
    
    ((id(*)(
            id,
            SEL,
            WebEventType,
            CFTimeInterval,
            NSString*,
            NSString*,
            WebEventFlags,
            BOOL,
            NSUInteger,
            uint16_t,
            BOOL,
            WebEventCharacterSet
            ))_original_WebEventInit_Imp)
    (self,
     _cmd,
     type,
     timeStamp,
     characters,
     charactersIgnoringModifiers,
     modifiers,
     repeating,
     flags,
     keyCode,
     tabKey,
     characterSet
     );
}


static IMP _original__handleKeyUIEvent_Imp;
void _replacement__handleKeyUIEvent(id self, SEL _cmd,UIEvent* event)
{
    assert([NSStringFromSelector(_cmd) isEqualToString:@"_handleKeyUIEvent:"]);
    
    if (event._unmodifiedInput != nil && [[UIKitSPI keyMapping] objectForKey:event._unmodifiedInput] != nil) {
        
        NSLog(@"_handleKeyUIEvent: %@ %@", NSStringFromSelector(_cmd), event);
        
        IMP imp = method_getImplementation(class_getInstanceMethod(NSClassFromString(@"WKContentView"),
                                                                   NSSelectorFromString(@"handleKeyEvent:")));
        
        ((int(*)(id,SEL,UIEvent*))imp)(self, _cmd, event);
    } else {
        ((int(*)(id,SEL,UIEvent*))_original__handleKeyUIEvent_Imp)(self, _cmd, event);
    }
    
}


@implementation UIKitSPI

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzle];
    });
}

+ (NSDictionary*)keyMapping {
    
    static NSDictionary<NSString*, NSString*>* remap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        remap = @{
                  UIKeyInputUpArrow: [NSString stringWithFormat:@"%C", (unichar)NSUpArrowFunctionKey],
                  UIKeyInputDownArrow: [NSString stringWithFormat:@"%C", (unichar)NSDownArrowFunctionKey],
                  UIKeyInputLeftArrow: [NSString stringWithFormat:@"%C", (unichar)NSLeftArrowFunctionKey],
                  UIKeyInputRightArrow: [NSString stringWithFormat:@"%C", (unichar)NSRightArrowFunctionKey],
                  UIKeyInputEscape: [NSString stringWithFormat:@"%C", (unichar)0x1B],
                  };
    });
    return remap;
}

+ (void) swizzle
{
    _original_WebEventInit_Imp = method_setImplementation(class_getInstanceMethod(NSClassFromString(@"WebEvent"),
                                                                                  NSSelectorFromString(WebEventInitStr())),
                                                          (IMP)_replacement__WebEventInit);
    
    _original__handleKeyUIEvent_Imp = method_setImplementation(class_getInstanceMethod(NSClassFromString(@"WKContentView"),
                                                                                       NSSelectorFromString(@"_handleKeyUIEvent:")),
                                                               (IMP)_replacement__handleKeyUIEvent);
}
@end



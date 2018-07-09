//
//  Student.m
//  RuntimeDemo
//
//  Created by 张诗健 on 2018/7/9.
//  Copyright © 2018年 张诗健. All rights reserved.
//

#import "Student.h"
#import "AudioPlayer.h"

@implementation Student


+ (BOOL)resolveInstanceMethod:(SEL)sel
{
    NSLog(@"resolveInstanceMethod");
    
    return [super resolveInstanceMethod:sel];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSLog(@"methodSignatureForSelector");
    
    if (aSelector == @selector(playMusic))
    {
        return [NSMethodSignature signatureWithObjCTypes:"v@:"];
    }
    
    return [super methodSignatureForSelector:aSelector];
}


- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    NSLog(@"forwardInvocation");
    
    if (anInvocation.selector == @selector(playMusic))
    {
        [anInvocation invokeWithTarget:[[AudioPlayer alloc] init]];
    }else
    {
        [super forwardInvocation:anInvocation];
    }
}

@end

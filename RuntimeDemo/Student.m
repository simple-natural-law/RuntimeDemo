//
//  Student.m
//  RuntimeDemo
//
//  Created by 张诗健 on 2018/7/9.
//  Copyright © 2018年 张诗健. All rights reserved.
//

#import "Student.h"
#import "AudioPlayer.h"
#import <objc/runtime.h>

@implementation Student

// 如果动态方法解析不成功，则启动消息转发机制。
+ (BOOL)resolveInstanceMethod:(SEL)sel
{
    NSLog(@"%@ --> resolveInstanceMethod",[self class]);
    
    return [super resolveInstanceMethod:sel];
}


- (id)forwardingTargetForSelector:(SEL)aSelector
{
    NSLog(@"%@ --> forwardingTargetForSelector",[self class]);
    
    if (aSelector == @selector(playMusic))
    {
        return [[AudioPlayer alloc] init];
    }
    
    return [super forwardingTargetForSelector:aSelector];
}


- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSLog(@"%@ --> methodSignatureForSelector",[self class]);
    
    if (aSelector == @selector(pause))
    {
        NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:"v@:"];
        
        return methodSignature;
    }
    
    return [super methodSignatureForSelector:aSelector];
}


- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    NSLog(@"%@ --> forwardInvocation",[self class]);
    
    if (anInvocation.selector == @selector(pause))
    {
        [anInvocation invokeWithTarget:[[AudioPlayer alloc] init]];
    }else
    {
        [super forwardInvocation:anInvocation];
    }
}

@end

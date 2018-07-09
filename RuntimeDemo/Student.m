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

#pragma -mark 消息转发机制流程

// 首先，运行时系统调用`forwardingTargetForSelector:`方法询问是否存在该消息的后备接收者。如果存在，则将消息发送给这个后备接收者，消息转发完成。如果不存在，运行时系统会调用`methodSignatureForSelector:`方法获取该方法的签名并将其封装成一个`NSInvocation`对象，然后调用`forwardInvocation:`方法并将`NSInvocation`对象传递给它，在`forwardInvocation:`方法实现中将这个消息发送给合适的对象，消息转发机制完成。


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

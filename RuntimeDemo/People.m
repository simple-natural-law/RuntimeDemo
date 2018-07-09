//
//  People.m
//  RuntimeDemo
//
//  Created by 张诗健 on 2018/7/9.
//  Copyright © 2018年 张诗健. All rights reserved.
//

#import "People.h"
#import <objc/runtime.h>

@implementation People


- (void)eatApple
{
    NSLog(@"people eats an apple. ");
}

- (void)say:(NSString *)string
{
    NSLog(@"people says : %@",string);
}


void writeCode (id target, SEL selector)
{
    NSLog(@"write code.");
}


+ (BOOL)resolveInstanceMethod:(SEL)sel
{
    if (sel == @selector(doSomeThings))
    {
        class_addMethod([self class], sel, (IMP)writeCode, "v@:");

        return YES;
    }

    return [super resolveClassMethod:sel];
}


@end

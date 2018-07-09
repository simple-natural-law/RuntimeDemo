//
//  ViewController.m
//  RuntimeDemo
//
//  Created by 张诗健 on 2018/7/7.
//  Copyright © 2018年 张诗健. All rights reserved.
//

#import "ViewController.h"
#import <objc/objc.h>
#import "People.h"


@interface ViewController ()

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    People *people = [[People alloc] init];
    
    // 向people对象发送一个eatApple消息.
    // `people`对象包含一个指向其类结构体的指针实例变量`isa`。编译器为每个类和对象构建的结构体中都包括两个基本要素：一个指向父类的指针和一个类调度表。类调度表中包含将方法选择器和方法选择器所标识的特定于类的方法的地址。编译器将此消息表达式转换为`objc_msgSend`函数的调用，并向该函数传递`people`对象和`eatApple`方法选择器这两个参数。`objc_msgSend`函数跟随`people`对象的`isa`指针找到`People`类结构中的类调度表，并在该表中查找`eatApple`方法选择器。如果没有找到该方法选择器，`objc_msgSend`函数会跟随类结构中指向其父类的指针到父类的类调度表中查找方法选择器。`objc_msgSend`函数会沿着类层次结构一直查找，直到到达`NSObject`类。一旦找到方法选择器，`objc_msgSend`函数就会调用与该方法选择器关联的方法，并将`people`对象的数据结构传递给它。
    [people eatApple];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

//
//  ViewController.m
//  RuntimeDemo
//
//  Created by 张诗健 on 2018/7/7.
//  Copyright © 2018年 张诗健. All rights reserved.
//

#import "ViewController.h"
#import "People.h"
#import "Student.h"

@interface ViewController ()

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    People *people = [[People alloc] init];
    
/********************************* 消息发送 ***********************************/
    
    // 向people对象发送一个eatApple消息.
    
    // `people`对象包含一个指向其类结构体的指针实例变量`isa`。编译器为每个类和对象构建的结构体中都包括两个基本要素：一个指向父类的指针和一个类调度表。类调度表中包含将方法选择器和方法选择器所标识的特定于类的方法的地址。编译器将此消息表达式转换为`objc_msgSend`函数的调用，并向该函数传递`people`对象和`eatApple`方法选择器这两个参数。在运行时，`objc_msgSend`函数跟随`people`对象的`isa`指针找到`People`类结构中的类调度表，并在该表中查找`eatApple`方法选择器。如果没有找到该方法选择器，`objc_msgSend`函数会跟随类结构中指向其父类的指针到父类的类调度表中查找方法选择器。`objc_msgSend`函数会沿着类层次结构一直查找，直到到达`NSObject`类。一旦找到方法选择器，`objc_msgSend`函数就会调用与该方法选择器关联的方法，并将`people`对象的数据结构传递给它。这就是在运行时动态地将方法实现绑定到消息的过程。
    
    // 为了加快消息发送的速度，每个类都有一个独立的缓存用来记录已经使用过一次的方法的选择器和地址。在检索调度表之前，`objc_msgSend`函数会首先检索消息接收对象类的缓存。如果有对应的方法，则会直接调用该方法。如果没有，才会到类调度表中去查找。
    
    [people eatApple];
    
    // 绕过动态绑定的唯一方法是获取方法的地址并直接调用它。这可能适用于极少数情况，例如，当一个特定方法将连续多次执行并且希望每次执行该方法时都避免消息发送的开销时，使用methodForSelector:方法绕过动态绑定可以节省消息发送所需的大部分时间。
    
    void (*peopleSay) (id, SEL, NSString *);
    
    peopleSay = (void (*) (id, SEL, NSString *))[people methodForSelector:@selector(say:)];
    
    for (int i = 0; i < 1000; i++)
    {
        peopleSay(people, @selector(say:), @"talk is cheap, show you my code.");
    }

/********************************* 动态方法解析 ***********************************/
    
    // 在某些情况下，可能想要动态提供方法的实现。当某个类声明了一个方法却没有实现该方法时，调用这个类的该方法。此时，在消息发送过程中，在类调度表中无法找到与该方法选择器对应的方法。这时运行时系统就会调用该类的`resolveInstanceMethod:`或者`resolveClassMethod:`，这就提供了一个机会来让我们动态提供方法的实现。
    
    [people doSomeThings];


/********************************* 消息转发 ***********************************/
    
    Student *student = [[Student alloc] init];
    
    [student playMusic];
    
    [student pause];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

# Objective-C Runtime 编程指南


## 引言

Objective-C语言从编译时间和链接时间到运行时推迟了尽可能多的决策。只要有可能，它就会动态地执行任务。这意味着该语言不仅需要编译器，还需要运行时系统来执行编译的代码。运行时系统充当Objective-C语言的一种操作系统，是语言工作的基础。


## 与运行时交互

Objective-C程序在三个不同的级别与运行时系统交互：通过Objective-C源代码，通过Foundation框架中的`NSObject`类中定义的方法，通过直接运行时函数。


### Objective-C源代码

在大多数情况下，运行时系统会在后台自动运行。我们只需要编写和编译Objective-C源代码即可使用它。

当编译包含Objective-C类和方法的代码时，编译器会创建实现该语言动态特性的数据结构和函数调用。数据结构捕获在类和类别定义中以及在协议声明中找到的信息，它们包括在[The Objective-C Programming Language](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjectiveC/Introduction/introObjectiveC.html#//apple_ref/doc/uid/TP30001163)中[Defining a Class](#turn)和[Protocols](#turn)讨论的类和协议对象，以及方法选择器，实例变量模版和从源代码中提取的其他信息。主要的运行时函数是发送消息的函数，如[发送消息](#turn)所述。它由源代码消息表达式调用。

### NSObject方法

Cocoa中的大多数对象都是`NSObject`类的子类，因此大多数对象都继承了它定义的方法。

# Objective-C Runtime 编程指南


## 引言

Objective-C语言从编译时间和链接时间到运行时推迟了尽可能多的决策。只要有可能，它就会动态地执行任务。这意味着该语言不仅需要编译器，还需要运行时系统来执行编译的代码。运行时系统充当Objective-C语言的一种操作系统，是语言工作的基础。


## 与运行时交互

Objective-C程序在三个不同的级别与运行时系统交互：通过Objective-C源代码，通过Foundation框架中的`NSObject`类中定义的方法，通过直接调用运行时函数。


### Objective-C源代码

在大多数情况下，运行时系统会在后台自动运行。我们只需要编写和编译Objective-C源代码即可使用它。

当编译包含Objective-C类和方法的代码时，编译器会创建实现该语言动态特性的数据结构和函数调用。数据结构捕获在类和类别定义中以及在协议声明中找到的信息，它们包括在[The Objective-C Programming Language](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjectiveC/Introduction/introObjectiveC.html#//apple_ref/doc/uid/TP30001163)中[Defining a Class](#turn)和[Protocols](#turn)讨论的类和协议对象，以及方法选择器，实例变量模板和从源代码中提取的其他信息。主要的运行时函数是发送消息的函数，如[发送消息](#turn)所述。它由源代码消息表达式调用。

### NSObject方法

Cocoa中的大多数对象都是`NSObject`类的子类，因此大多数对象都继承了它定义的方法。（值得注意的例外是`NSProxy`类，有关更多信息请参看[消息转发](#turn)。）因此，它的方法建立了每个实例和每个类对象固有的行为。然而，在少数情况下，`NSObject`类只定义了应该如何完成某事的模板，它本身并不提供所有必要的代码。

例如，`NSObject`类定义了一个`description`实例方法，该方法返回描述类内容的字符串。其主要用于调试——GDB的`print-object`命令打印此方法返回的字符串。`NSObject`的此方法的实现不知道该类包含什么，因此它返回一个包含对象名称和地址的字符串。`NSObject`的子类可以实现此方法以返回更多详细信息。例如，Foundation框架中的`NSArray`类的此方法返回它包含的对象的描述列表。

一些`NSObject`方法只是查询运行时系统的信息，这些方法允许对象执行内省（内省是指计算机程序在运行时检查对象类型的一种能力，通常也可以称作运行时类型检查）。这些方法的例子是`class`方法，它请求对象标识它的类；`isKindOfClass:`和`isMemberOfClass:`方法检验对象在继承层次结构中的位置；`respondsToSelector:`方法指示对象是否可以接收特定消息；`conformsToProtocol:`方法指示对象是否声明实现特定协议中定义的方法；`methodForSelector:`方法提供方法实现的地址。

### 运行时函数

运行时系统是一个具有公共接口的动态共享库，其公共接口由位于`/usr/include/objc`目录中的头文件中的一组函数和数据结构组成。其中许多函数允许我们使用纯C语言来复制当我们编写Objective-C代码时编译器所执行的操作，另一些函数构成了通过`NSObject`类的方法输出的功能的基础。这些函数使得开发运行时系统的其它接口成为可能，并创作了增强开发环境的工具。在Objective-C中编程时不需要它们，但是，在编写Objective-C程序时，一些运行时函数有时可能会有用。所有这些功能都记录在[Objective-C Runtime Reference](https://developer.apple.com/documentation/objectivec/objective_c_runtime?language=objc)中。


## 发送消息



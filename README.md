# Objective-C Runtime


## 引言

Objective-C语言从编译时间和链接时间到运行时推迟了尽可能多的决策。只要有可能，它就会动态地执行任务。这意味着该语言不仅需要编译器，还需要运行时系统来执行编译的代码。运行时系统充当Objective-C语言的一种操作系统，是语言工作的基础。


## 与运行时交互

Objective-C程序在三个不同的级别与运行时系统交互：通过Objective-C源代码，通过Foundation框架中的`NSObject`类中定义的方法，通过直接调用运行时函数。

### Objective-C源代码

在大多数情况下，运行时系统会在后台自动运行。我们只需要编写和编译Objective-C源代码即可使用它。

当编译包含Objective-C类和方法的代码时，编译器会创建实现该语言动态特性的数据结构和函数调用。数据结构捕获在类和类别定义中以及在协议声明中找到的信息，它们包括在[The Objective-C Programming Language](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjectiveC/Introduction/introObjectiveC.html#//apple_ref/doc/uid/TP30001163)中[Defining a Class](#turn)和[Protocols](#turn)讨论的类和协议对象，以及方法选择器，实例变量模板和从源代码中提取的其他信息。主要的运行时函数是发送消息的函数，如[消息发送](#turn)所述。它由源代码消息表达式调用。

### NSObject方法

Cocoa中的大多数对象都是`NSObject`类的子类，因此大多数对象都继承了它定义的方法。（值得注意的例外是`NSProxy`类，有关更多信息请参看[消息转发](#turn)。）因此，它的方法建立了每个实例和每个类对象固有的行为。然而，在少数情况下，`NSObject`类只定义了应该如何完成某事的模板，它本身并不提供所有必要的代码。

例如，`NSObject`类定义了一个`description`实例方法，该方法返回描述类内容的字符串。其主要用于调试——GDB的`print-object`命令打印此方法返回的字符串。`NSObject`的此方法的实现不知道该类包含什么，因此它返回一个包含对象名称和地址的字符串。`NSObject`的子类可以实现此方法以返回更多详细信息。例如，Foundation框架中的`NSArray`类的此方法返回它包含的对象的描述列表。

一些`NSObject`方法只是查询运行时系统的信息，这些方法允许对象执行内省（内省是指计算机程序在运行时检查对象类型的一种能力，通常也可以称作运行时类型检查）。这些方法的例子是`class`方法，它请求对象标识它的类；`isKindOfClass:`和`isMemberOfClass:`方法检验对象在继承层次结构中的位置；`respondsToSelector:`方法指示对象是否可以接收特定消息；`conformsToProtocol:`方法指示对象是否声明实现特定协议中定义的方法；`methodForSelector:`方法提供方法实现的地址。

### 运行时函数

运行时系统是一个具有公共接口的动态共享库，其公共接口由位于`/usr/include/objc`目录中的头文件中的一组函数和数据结构组成。其中许多函数允许我们使用纯C语言来复制当我们编写Objective-C代码时编译器所执行的操作，另一些函数构成了通过`NSObject`类的方法输出的功能的基础。这些函数使得开发运行时系统的其它接口成为可能，并生成了增强开发环境的工具。在Objective-C中编程时不需要它们，但是，在编写Objective-C程序时，一些运行时函数有时可能会有用。所有这些功能都记录在[Objective-C Runtime Reference](https://developer.apple.com/documentation/objectivec/objective_c_runtime?language=objc)中。


## 消息发送

本节介绍如何将消息表达式转换为`objc_msgSend`函数调用，以及如何按名称引用方法。然后，还解释了如何使用`objc_msgSend`以及如何绕过动态绑定。

### objc_msgSend函数

在Objective-C中，消息在运行时之前不会被绑定到方法实现，编译器将消息表达式
```
[receiver message]
```
转换为`objc_msgSend`消息发送函数的调用。此函数将接收者和消息中提到的方法的名称（即方法选择器）作为其两个主要参数：
```
objc_msgSend(receiver, selector)
```
消息中传递的任何参数也会传递给`objc_msgSend`：
```
objc_msgSend(receiver, selector, arg1, arg2, ...)
```
消息发送函数会为动态绑定去做必要的任何事情：
- 它首先找到选择器所引用的程序（即方法实现）。由于同样的方法能够被单独的类以不同的方式实现，所以它找到的精确程序取决于接收者的类。
- 然后它调用该程序，将接收对象（指向其数据的指针）以及为该方法指定的任何参数传递给它。
- 最后，它将程序的返回值作为其自身的返回值传递。

消息发送的关键在于编译器为每个类和对象构建的结构。每个类结构都包括以下两个基本要素：
- 一个指向父类的指针。
- 一个类调度表。此表含有将方法选择器与这些方法选择器所标识方法的特定于类的地址相关联的条目。`setOrigin::`方法的选择器与`setOrigin::`（方法实现程序）的地址相关联，`display`方法的选择器与`display`的地址相关联，依此类推。

当一个新对象被创建时，将为其分配内存，并初始化其实例变量。对象的第一个变量是指向其类结构的指针。这个名为`isa`的指针使得对象能够访问它的类，并通过该类访问它继承的所有类。

类结构和对象结构的这些元素如下图所示：

![图2-1 消息发送框架.png](https://upload-images.jianshu.io/upload_images/4906302-015c526213f01b63.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

当一个消息被发送给对象时，`objc_msgSend`函数跟随对象的`isa`指针到类结构的类调度表中查找方法选择器。如果没有找到方法选择器，`objc_msgSend`函数会跟随指向父类的指针到父类的类调度表中查找方法选择器。`objc_msgSend`函数会顺着类层次结构一直查找，直到到达`NSObject`类。一旦找到方法选择器，该函数就会调用类调度表中的方法并将接收对象的数据结构传递给它。

这是在运行时选择方法实现的的方式——或者，在面向对象编程的术语中，方法动态地绑定到消息。

为了加快消息发送过程的速度，运行时系统会缓存使用过的方法的选择器和地址。每个类都有一个独立的缓存，它可以包含继承的方法以及该类中定义的方法的选择器。在检索调度表之前，消息发送函数首先检查接收对象类的缓存（理论上使用过一次的方法可能会再次使用）。如果缓存中存在方法选择器，则消息发送仅比函数调用稍慢一点。一旦程序运行了足够长的时间来“预热”其缓存，它发送的几乎所有消息都能找到一个缓存的方法。

### 使用隐藏参数

当`objc_msgSend`找到实现一个方法的程序时，它会调用该程序并将消息中的所有参数传递给该程序。它还传递了两个隐藏参数：
- 接收对象。
- 方法的选择器。

这些参数为每个方法实现提供与调用该方法实现的消息表达式有关的明确信息，它们之所以被称为隐藏参数是因为它们未在定义方法的源代码中声明。当代码被编译时，它们才会被插入到方法实现中。

虽然这些参数没有显示声明，但源代码仍然可以引用它们（就像它可以引用接收对象的实例变量一样）。方法将接收对象引用为`self`，并将其自身的选择器称为`_cmd`。在下面的示例中，`_cmd`引用为`strange`方法的选择器，`self`引用为接收`strange`消息的对象。
```
- strange
{
    id  target = getTheReceiver();
    SEL method = getTheMethod();

    if ( target == self || method == _cmd )
        return nil;
        
    return [target performSelector:method];
}
```
`self`是两个参数中更加有用的一个。实际上，它是接收对象的实例变量可用于方法定义的一种方式。


### 获取方法地址

绕过动态绑定的唯一方法是获取方法的地址并直接调用它。这可能适用于极少数情况，例如，当一个特定方法将连续多次执行并且希望每次执行该方法时都避免消息发送的开销。

使用`NSObject`类中定义的`methodForSelector:`方法可以请求一个指向实现了一个方法的程序的指针，然后使用该指针调用方法实现程序。`methodForSelector:`方法返回的指针必须小心地转换为正确的函数类型。返回值和参数类型都应包含在强制转换中。

以下示例显示了实现了`setFilled:`方法的程序是如何被调用的：
```
void (*setter)(id, SEL, BOOL);
int i;

setter = (void (*)(id, SEL, BOOL))[target methodForSelector:@selector(setFilled:)];

for ( i = 0 ; i < 1000 ; i++ )
    setter(targetList[i], @selector(setFilled:), YES);
```
传递给程序的前两个参数是接收对象（self）和方法选择器（_cmd）。这些参数隐藏在方法语法中，但在将方法作为函数调用时必须使其显式化。

使用`methodForSelector:`方法绕过动态绑定可以节省消息发送所需的大部分时间。但是，只有在特定消息重复多次的情况下，节省才会明显，例如上面所示的for循环。

注意，`methodForSelector`方法是由Cocoa运行时系统提供的，它不是Objective-C语言本身的一个特性。


## 动态方法解析

本节介绍如何动态提供方法的实现。

### 动态方法解析

在某些情况下，我们可能希望动态提供方法的实现。例如，Objective-C声明属性特性（参看[Objective-C Programming Language](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjectiveC/Introduction/introObjectiveC.html#//apple_ref/doc/uid/TP30001163)中的[Declared Properties](#turn)）包含`@dynamic`指令：
```
@dynamic propertyName;
```
它告诉编译器将动态提供与属性关联的方法。

我们可以实现`resolveInstanceMethod:`方法和`resolveClassMethod:`方法来分别为实例方法和类方法的给定选择器提供一个实现。

一个Objective-C方法在根本上是一个至少需要两个参数（self和_cmd）的C函数，可以使用`class_addMethod`函数将函数作为方法添加到类中。因此，给出以下函数：
```
void dynamicMethodIMP(id self, SEL _cmd) {
    // implementation ....
}
```
我们可以使用`resolveInstanceMethod:`方法动态地将上面的函数作为方法（方法名为`resolveThisMethodDynamically`）添加到一个类中：
```
@implementation MyClass
+ (BOOL)resolveInstanceMethod:(SEL)aSEL
{
    if (aSEL == @selector(resolveThisMethodDynamically)) {
        class_addMethod([self class], aSEL, (IMP) dynamicMethodIMP, "v@:");
        return YES;
    }
    return [super resolveInstanceMethod:aSEL];
}
@end
```





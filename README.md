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
转换为`objc_msgSend`消息发送函数的调用。此函数将接收者和消息中提到的方法名称（即方法选择器）作为其两个主要参数：
```
objc_msgSend(receiver, selector)
```
消息中传递的任何参数也会传递给`objc_msgSend`：
```
objc_msgSend(receiver, selector, arg1, arg2, ...)
```
消息发送函数会为动态绑定去做任何必要的事情：
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

可以实现`resolveInstanceMethod:`方法和`resolveClassMethod:`方法来分别为实例方法和类方法的给定选择器提供一个实现。

一个Objective-C方法在根本上是一个至少需要两个参数（self和_cmd）的C函数，可以使用`class_addMethod`函数将函数作为方法添加到类中。因此，给出以下函数：
```
void dynamicMethodIMP(id self, SEL _cmd) {
    // implementation ....
}
```
使用`resolveInstanceMethod:`方法动态地将上面的函数作为方法（方法名为`resolveThisMethodDynamically`）添加到一个类中：
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
转发方法（如[消息转发](#turn)中所述）和动态方法解析在很大程度上是正交的，类可以在转发机制启动之前动态解析方法。如果调用`respondsToSelector:`方法或者`instancesRespondToSelector:`方法，则动态方法解析器有机会首先为选择器提供`IMP`。如果实现了`resolveInstanceMethod:`方法，但是希望特定的选择器实际上是通过消息转发机制转发的，则为这些选择器返回`NO`。


### 动态加载

Objective-C程序可以在运行时加载和链接新类和类别。新代码被合并到程序中，并且与最开始加载的类和类别进行相同的处理。

动态加载可以用来做很多不同的事情。例如， System Preferences应用程序（系统偏好设置）中的各种模块就是动态加载的。

在Cocoa环境中，通常使用动态加载来允许自定义应用程序。其他人可以编写程序在运行时加载的模块——就像Interface Builder中加载自定义调色板和OS X System Preferences应用程序加载自定义偏好设置模块一样，可加载模块扩展了应用程序的功能，他们以我们允许但是无法由我们自己预测和定义的方式为其做出贡献。我们提供框架，但是其他人提供提供代码。

虽然有一个运行时函数可以在Mach-O文件中执行Objective-C模块的动态加载（`objc_loadModules`，在objc/objc-load.h中定义），但是Cocoa的`NSBundle`类为动态加载提供了一个非常方便的接口。有关`NSBundle`类及其用法的信息，请参看[NSBundle](https://developer.apple.com/documentation/foundation/nsbundle?language=occ)。



## 消息转发

将消息发送给一个不能处理该消息的对象会引发错误。但是，在宣布错误之前，运行时系统给接收对象提供了第二次机会去处理该消息。


### 转发

如果发送一个消息给不能处理该消息的对象，则在宣布错误之前，运行时系统会向该对象发送一个`forwardInvocation:`消息，该消息唯一的参数是一个`NSInvocation`对象——`NSInvocation`对象封装了原始的消息和该消息传递的参数。

可以实现`forwardInvocation:`方法来为消息提供默认的响应，或者以其他方式来避免错误。顾名思义，`forwardInvocation:`方法通常用于将消息转发给另一个对象。

为了明白转发的范围和目的，请设想以下情景：首先，假设我们正在设计一个能够响应名为`negotiate`的消息的对象，并且希望其响应中包含另一种对象对该消息的响应。可以通过在`negotiate`方法实现主体中的某个位置将`negotiate`消息传递给另一个对象来轻松完成此操作。

更进一步，假设我们希望对象对`negotiate`消息的响应完全是在另一个类中实现的响应。实现此目的的一种方法是让类从其他类继承该方法。然而，可能无法以这种方式安排事情，因为我们的类和实现了`negotiate`方法的类可能位于继承层次结构的不同分支中。

即使类不能继承`negotiate`方法，我们仍然可以通过实现一个简单地将该消息传递给另一个类的实例的方法来借用它：
```
- (id)negotiate
{
    if ( [someOtherObject respondsTo:@selector(negotiate)] )
        return [someOtherObject negotiate];
        
    return self;
}
```
这种方式可能会有点麻烦，特别是如果有许多需要对象传递给另一个对象的消息。我们必须实现一种方法来覆盖每个想要从其他类借用的方法。而且，这样可能无法处理那些我们不知道的情况。在编写代码时，我们可能无法确定想要转发的完整消息集。该集合可能取决于运行时的事件，并且可能会在未来实现新的方法和类时发生改变。

`forwardInvocation:`消息提供的第二次机会为这个问题提供了一个解决方案，其是动态的而不是静态的。它的工作方式为：当一个对象无法响应消息是因为它没有与该消息中的选择器相匹配的方法时，运行时系统会通过向该对象发送一个`forwardInvocation:`消息来告知它。每个对象都从`NSObject`类继承了一个`forwardInvocation:`方法。但是，在`NSObject`类的此方法实现中只是调用了`doesNotRecognizeSelector:`方法。通过重写该方法来覆盖`NSObject`类的实现，我们可以使用`forwardInvocation:`消息提供的机会将消息转发给其他对象。

要转发一个消息，`forwardInvocation:`方法需要做以下事情：
- 确定消息的去向。
- 使用原始的参数发送它。

可以使用`invokeWithTarget:`方法发送消息：
```
- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    if ([someOtherObject respondsToSelector:[anInvocation selector]])
    
        [anInvocation invokeWithTarget:someOtherObject];
    else
        [super forwardInvocation:anInvocation];
}
```
转发的消息的返回值会返回给原始的消息接受者。可以将所有类型的返回值传递给接收者，包括`id`类型对象，结构体和双精度浮点数。

`forwardInvocation:`方法可以充当无法识别的消息的分发中心，将它们分发给不同的接收者。或者它可以是转移站，将所有消息发送到同一个目的地。它可以将一条消息翻译成另一条消息，或者只是“吞下”一些消息，这样就没有响应也没有错误。`forwardInvocation:`方法还可以将多个消息合并到一个响应中，该方法做什么事情取决于实现者。

> **注意**：`forwardInvocation:`方法只有在对象调用一个其没有实现的方法时才会处理消息。例如，如果希望对象将`negotiate`消息转发给另一个对象，则该对象不能拥有自己的`negotiate`方法。否则，运行时系统永远都不会发送`forwardInvocation:`消息给该对象。

有关转发和调用的更多信息，请参看[NSInvocation](https://developer.apple.com/documentation/foundation/nsinvocation?language=occ)。


### 转发和多重继承

转发模仿了继承，并可用于向Objective-C程序提供多重继承的一些效果。如下图所示，一个通过转发消息来响应消息的对象好像借用或者“继承”了另一个类中定义的方法实现。

![图4-1 转发.png](https://upload-images.jianshu.io/upload_images/4906302-8ee262349375767e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

转发消息的对象因此从继承层次结构的两个分支“继承”方法——它自己所在的分支和响应消息的对象所在的分支。在上面的例子中，似乎`Warrior`类继承自`Diplomat`类以及它自己的父类。

转发提供了我们通常想要从多重继承中获得的大多数特性，但是两者之间有一个重要的区别。多重继承在单个对象中组合了不同的能力，它倾向于大型、多方面的对象。另一方面，转发是将单独的责任分配给完全不同的对象，它将问题分解为较小的对象，但以对消息发送者透明的方式来关联这些对象。


### 代理对象

转发不仅模仿多重继承，它还可以开发出代表或者“代替”有更多实质的对象的轻量级对象。代理代表另一个对象，并向该对象发送消息。

在[The Objective-C Programming Language](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjectiveC/Introduction/introObjectiveC.html#//apple_ref/doc/uid/TP30001163)中[Remote Messaging](#turn)中讨论的代理就是这样的代理。代理处理将消息转发到远程接收者的管理细节，确保在连接过程中复制和检索参数值，等等。但它并没有尝试做太多其他事情，它不会复制远程对象的功能，而只是给远程对象一个本地地址——一个可以在另一个应用程序中接收消息的地方。

其他类型的替代对象也是可能的。例如，假设有一个操纵大量数据的对象，也许它会创建一个复杂的图像或者读取磁盘上文件的内容。由于设置此对象可能会非常耗时，所以可以懒惰地执行此操作——在确实需要时或者系统资源暂时空闲时才执行此操作。同时，至少需要该对象的一个占位符才能使应用程序中的其他对象正常运行。

在这种情况下，可以初始创建一个不完整的对象，它只是一个轻量级的代理。这个对象可以自己做一些事情，比如回应和数据有关的问题，但大多数情况下，它只是为较大型的对象保留一个位置，并在时间到来时，转发消息给它。当代理的`forwardInvocation:`方法首次接收到发往另一个对象的消息时，它将确保该对象存在并且如果不存在则创建它。大型对象的所有消息都会通过代理，所以，就程序其余部分而言代理和大型对象是相同的。


### 转发和继承

虽然转发模仿了继承，但`NSObject`类从来不会混淆两者。像`respondsToSelector:`和`isKindOfClass:`这样的方法只查看继承层次结构，永远不会查看转发链。例如，如果询问`Warrior`对象是否响应`negotiate`消息：
```
if ( [aWarrior respondsToSelector:@selector(negotiate)] )
    ...
```
返回值是`NO`，尽管它可以毫无错误地接收`negotiate`消息，并且从某种意义上来说，通过转发该消息给`Diplomat`对象来回应该消息。（请看[图4-1 转发.png](#turn)）

在许多情况下，`NO`是正确答案，但某些情况下可能不是。如果使用转发来设置一个代理对象或者扩展类的功能，则转发机制可能应该像继承一样透明。如果希望对象的行为就像它们真正继承了它们转发消息的对象的行为一样，那么需要重新实现`respondsToSelector:`方法和`isKindOfClass:`方法来包含我们的转发算法：
```
- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ( [super respondsToSelector:aSelector] )
        return YES;
    else {
        /* Here, test whether the aSelector message can     *
        * be forwarded to another object and whether that  *
        * object can respond to it. Return YES if it can.  */
    }
    return NO;
}
```
除了`respondsToSelector:`和`isKindOfClass:`方法之外，`instancesRespondToSelector:`方法还应该反映转发算法。如果使用了协议，则同意应将`conformsToProtocol:`方法加入到列表中。类似的，如果一个对象转发它收到的任何远程消息，它应该重新实现`methodSignatureForSelector:`方法来返回最终响应转发消息的方法的准确描述。例如，如果一个对象能够将消息转发给它的代理，那么实现`methodSignatureForSelector:`方法如下：
```
- (NSMethodSignature*)methodSignatureForSelector:(SEL)selector
{
    NSMethodSignature* signature = [super methodSignatureForSelector:selector];
    if (!signature) {
        signature = [surrogate methodSignatureForSelector:selector];
    }
    return signature;
}
```
可以考虑将转发算法放在私有代码中的某个位置，并使用所有这些方法（包括`forwardInvocation:`）来调用它。

> **注意**：这是一项高级技术，仅适用于无法提供其他解决方案的情况。它不是作为继承的替代。如果必须使用此技术，请确保完全了解执行转发的类和转发对象类的行为。


## 类型编码

为了协助运行时系统，编译器会将每个方法的返回值和参数的类型编码为字符串，并将此字符串与方法选择器相关联。它使用的编码方案在其他上下文中也很有用，所以可以公开使用`@encode()`编译器指令。当给定一个类型规范时，`@encode()`返回编码该类型的字符串。类型可以是基本类型，例如`int`，指针，标记结构或联合，或者类名——实际上，任何类型都可以用作C运算符`sizeof()`的参数。
```
char *buf1 = @encode(int **);
char *buf2 = @encode(struct key);
char *buf3 = @encode(Rectangle);
```
下表列出了类型代码。注意，它们中的许多与编码对象时用于存档和分发的代码重叠。但是，此处列出的代码在编写编码器时是无法使用的，并且在编写不是由`@encode()`生成的编码器时可能需要使用代码。

| Code | Meaning |
|--------|-----------|
| c | A `Char` |
| i | An `int` |
| s | A `short` |
| l | A `long` <br> l is treated as a 32-bit quantity on 64-bit programs. |
| q | A `long long` |
| C | An `unsigned char` |
| I | An `unsigned int` |
| S | An `unsigned short` |
| L | An `unsigned long` |
| Q | An `unsigned long long` |
| f | An `float` |
| d | A `double` |
| B | A C++ `bool` or a C99 `_Bool` |
| v | A `void` |
| * | A character string (`char *`) |
| @ | An object (whether statically typed or typed `id`) |
| # | A class object (`Class`) |
| : | A method selector (`SEL`) |
| [array type] | An array |
| {name=type...} | A structure |
| (name=type...) | A union |
| bnum | A bit field of num bits |
| ^type | A pointer to type |
| ^type | A pointer to type |
| ? | An unknown type (among other things, this code is used for function pointers |

> **重要**：Objective-C不支持`long double`类型。 `@encode(long double)`返回`d`，这与`double`的编码相同。


数组的类型代码使用方括号括起来，数组中元素的数量是在数组类型前面的开括号后面立即指定的。例如，一个包含12个`float`指针的数字将被编码为：
```
[12^f]
```
结构体在括号内指定。首先列出结构体标签，然后是等号，并按顺序列出结构体字段的代码。例如，结构体
```
typedef struct example {
    id   anObject;
    char *aString;
    int  anInt;
} Example;
```
会被编码成这样：
```
{example=@*i}
```
结构体指针的编码与结构体的字段有关的相同数量的信息：
```
^{example=@*i}
```
但是，指向结构体指针的指针的编码间接删除内部类型规范：
```
^^{example}
```
对象被视为结构体。例如，将`NSObject`类名传递给`@encode()`会产生以下编码：
```
{NSObject=#}
```
`NSObject`类只声明一个类型为`Class`的实例变量`isa`。

注意，尽管`@encode()`指令不返回下表中列出的其他编码，但是当它们用于在协议中声明方法时，运行时系统使用它们来表示类型限定符。

| Code | Meaning |
|--------|-----------|
| r | const |
| n | in |
| N | inout |
| o | out |
| O | bycopy |
| R | byref |
| V | oneway |





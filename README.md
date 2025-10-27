# GLFW for Swift

A Swift library that adds a more Swift-like interface to [GLFW](https://github.com/glfw/glfw). ~~So far, it's only been tested on macOS, but it should compile and run on Windows and Linux with little difficulty~~. As of pull request #5, cross-platform *should* be working now.

This package is based on [CGLFW3](https://github.com/thepotatoking55/CGLFW3), which is just the pure C bindings.

## Setting Up

Adding this to your project is pretty standard for a Swift Package.

```swift
import PackageDescription

let package = Package(
    name: "GLFWSample",
    products: [
        .executable(name: "GLFW Sample", targets: ["GLFWSample"])
    ],
    dependencies: [
        .package(url: "https://github.com/thepotatoking55/SwiftGLFW.git", .upToNextMajor(from: "4.2.0"))
        ...
    ],
    targets: [
        .executableTarget(
            name: "GLFWSample",
            // Silence deprecation warnings on Apple platforms if you're using OpenGL
            cSettings: [
                .define("GL_SILENCE_DEPRECATION",
                    .when(platforms: [.macOS])),
                .define("GLES_SILENCE_DEPRECATION",
                    .when(platforms: [.iOS, .tvOS])),
            ],
            dependencies: [
                .product(name: "SwiftGLFW", package: "SwiftGLFW"),
                ...
            ]
        )
    ]
)
```

## Usage
### Documentation

There's a [work in progress adaptation of GLFW's C documentation on this repo](https://github.com/thepotatoking55/swiftglfw/wiki), which should help show the differences (or serve as an introduction if you're new to GLFW). In-code documentation is also being worked on.

### Example Code

GLFW's [Hello Window example](https://www.glfw.org/documentation.html#example-code), except in a much more Swift-idiomatic way:

```swift
import GLFW
import OpenGL // Or whatever other library you use

@MainActor
func main() {
    do {
        try GLFWSession.initialize()
        
        /* macOS's OpenGL implementation requires some extra tweaking */
        GLFWWindow.hints.contextVersion = (4, 1)
        GLFWWindow.hints.openGLProfile = .core
        GLFWWindow.hints.openGLCompatibility = .forward
        
        /* Create a windowed mode window and its OpenGL context */
        let window = try GLFWWindow(width: 640, height: 480, title: "Hello World")
        
        /* Make the window's context current */
        window.context.makeCurrent()
        
        /* Loop until the user closes the window */
        while !window.shouldClose {
            /* Render here */
            glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
            someRenderFunctionDefinedElsewhere()
            
            /* Swap front and back buffers */
            window.swapBuffers()
            
            /* Poll for and process events */
            GLFWSession.pollInputEvents()
        }
    } catch let error as GLFWError {
        print(error.description ?? "Unknown error")
    } catch {
        print(error)
    }
}
```

### Error Handling

Since they're fundamental to GLFW, `GLFWSession.initialize` and `GLFWWindow.init` can both throw errors. However, if you're expecting potential errors in other places, you can also call

```swift
try GLFWSession.checkForError()
```

Or, you can assign an error handler to catch them as soon as they come up:

```swift
GLFWSession.onReceiveError = { error in
    /* do something with it here */
}
```

### Wrapping things up

Like Swift, this package is built with readability and strong type-checking in mind. Rather than passing `Int32`s and `OpaquePointer`s around, variables are represented with enums and so on.
    
```swift
import GLFW

try! GLFWSession.initialize()

guard let window = try? GLFWWindow(width: 640, height: 480, title: "Hello World") else {
    GLFWSession.terminate()
    return
}

window.resizable = false
window.maximize()

window.mouse.useRawMotionInput = true
window.mouse.cursorMode = .disabled
window.scrollInputHandler = { window, x, y in
    ...
}

let monitor = GLFWMonitor.primary
monitor.setGamma(1.0)
```

Is equivalent to this:

```c
#include <GLFW/glfw3.h>

GLFWwindow* window;

if !(glfwInit()) {
    return -1;
}

window = glfwCreateWindow(640, 480, "Hello World", NULL, NULL);
if !(window) {
    glfwTerminate();
    return -1;
}

glfwSetWindowAttrib(window, GLFW_RESIZABLE, GLFW_FALSE);
glfwMaximizeWindow(window);

if (glfwRawMouseMotionSupported())
    glfwSetInputMode(window, GLFW_RAW_MOUSE_MOTION, GLFW_TRUE);
    
glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
void scroll_callback(GLFWwindow* window, double xoffset, double yoffset) {
    ...
}

glfwSetScrollCallback(window, scroll_callback);

GLFWmonitor* monitor = glfwGetPrimaryMonitor();
glfwSetGamma(monitor, 1.0);
```

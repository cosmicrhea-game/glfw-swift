import CGLFW3

public struct Gamepad: Hashable, Equatable {
    public let id: Int
    
    private var joystickID: Int32 {
        id.int32 + .gamepad1
    }
    
    nonisolated init(id: Int) {
        self.id = id
    }
    
    nonisolated init(jid: Int32) {
        self.id = (jid - .gamepad1).int
    }
    
    @MainActor
    public init?(_ id: Int) {
        self.id = id
        guard isPresent else {
            return nil
        }
    }
    
    /// Returns whether the joystick is present (connected)
    @MainActor
    public var isPresent: Bool {
        glfwJoystickPresent(joystickID) == .true
    }
    
    /// Returns whether the joystick has a gamepad mapping
    @MainActor
    public var isGamepad: Bool {
        glfwJoystickIsGamepad(joystickID) == .true
    }
    
    /// The connection status of the joystick
    @MainActor
    public var status: Status {
        if isPresent {
            return isGamepad ? .gamepad : .joystick
        } else {
            return .disconnected
        }
    }
    
    /// The human-readable name of the joystick (raw joystick name)
    @MainActor
    public var joystickName: String? {
        glfwGetJoystickName(joystickID).map(String.init(cString:))
    }
    
    /// The SDL-compatible GUID of the joystick
    @MainActor
    public var guid: String? {
        glfwGetJoystickGUID(joystickID).map(String.init(cString:))
    }
    
    /// The human-readable name of the gamepad (from gamepad mapping)
    @MainActor
    public var gamepadName: String? {
        guard isGamepad else { return nil }
        return glfwGetGamepadName(joystickID).map(String.init(cString:))
    }
    
    /// The name property - returns gamepad name if available, otherwise joystick name
    @MainActor
    public var name: String? {
        gamepadName ?? joystickName
    }
    
    /// User-defined pointer associated with this joystick
    @MainActor
    public var userPointer: UnsafeMutableRawPointer? {
        get {
            glfwGetJoystickUserPointer(joystickID)
        }
        set {
            glfwSetJoystickUserPointer(joystickID, newValue)
        }
    }
    
    // MARK: - Gamepad State (mapped)
    
    @MainActor
    static var states = Array(repeating: GLFWgamepadstate(), count: 16)
    
    /// Get the state of a gamepad button (mapped)
    @MainActor
    public func state(of button: Button) -> ButtonState {
        guard isGamepad else { return .released }
        return withUnsafePointer(to: Gamepad.states[id].buttons) { ptr in
            ptr.withMemoryRebound(to: UInt8.self, capacity: 15) { buttons in
                ButtonState(Int32(buttons[button.rawValue]))
            }
        }
    }
    
    /// Get the state of a gamepad axis (mapped)
    @MainActor
    public func state(of axis: Axis) -> Float {
        guard isGamepad else { return 0.0 }
        return withUnsafePointer(to: Gamepad.states[id].axes) { ptr in
            ptr.withMemoryRebound(to: Float.self, capacity: 6) { axes in
                axes[axis.rawValue]
            }
        }
    }
    
    // MARK: - Raw Joystick State
    
    /// Get all raw joystick axes (values between -1.0 and 1.0)
    @MainActor
    public var axes: [Float] {
        var count: Int32 = 0
        guard let axesPtr = glfwGetJoystickAxes(joystickID, &count) else {
            return []
        }
        return Array(UnsafeBufferPointer(start: axesPtr, count: count.int))
    }
    
    /// Get all raw joystick button states
    @MainActor
    public var buttons: [ButtonState] {
        var count: Int32 = 0
        guard let buttonsPtr = glfwGetJoystickButtons(joystickID, &count) else {
            return []
        }
        return Array(UnsafeBufferPointer(start: buttonsPtr, count: count.int)).map { ButtonState(Int32($0)) }
    }
    
    /// Get all raw joystick hat states
    @MainActor
    public var hats: [HatState] {
        var count: Int32 = 0
        guard let hatsPtr = glfwGetJoystickHats(joystickID, &count) else {
            return []
        }
        return Array(UnsafeBufferPointer(start: hatsPtr, count: count.int)).map { HatState(rawValue: $0) }
    }
    
    // MARK: - Types
    
    public enum Status: Sendable {
        case disconnected
        case joystick  // Present but no gamepad mapping
        case gamepad   // Present and has gamepad mapping
    }
    
    public enum Button: Int, Sendable {
        case a, b, x, y
        case leftBumper, rightBumper
        case back, start, guide
        case leftThumb, rightThumb
        case dpadUp, dpadRight, dpadDown, dpadLeft
        
        public static let cross = a
        public static let circle = b
        public static let square = x
        public static let triangle = y
    }
    
    public enum Axis: Int, Sendable {
        case leftX, leftY
        case rightX, rightY
        case leftTrigger, rightTrigger
    }
    
    /// Represents the state of a joystick hat (d-pad)
    public struct HatState: OptionSet, Sendable, Hashable {
        public let rawValue: UInt8
        
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
        
        public static let centered = HatState(rawValue: UInt8(GLFW_HAT_CENTERED))
        public static let up = HatState(rawValue: UInt8(GLFW_HAT_UP))
        public static let right = HatState(rawValue: UInt8(GLFW_HAT_RIGHT))
        public static let down = HatState(rawValue: UInt8(GLFW_HAT_DOWN))
        public static let left = HatState(rawValue: UInt8(GLFW_HAT_LEFT))
        public static let rightUp = HatState(rawValue: UInt8(GLFW_HAT_RIGHT_UP))
        public static let rightDown = HatState(rawValue: UInt8(GLFW_HAT_RIGHT_DOWN))
        public static let leftUp = HatState(rawValue: UInt8(GLFW_HAT_LEFT_UP))
        public static let leftDown = HatState(rawValue: UInt8(GLFW_HAT_LEFT_DOWN))
    }
    
    // MARK: - Callback
    
    @MainActor
    static var callback: ((Gamepad, Status) -> Void)?
    
    @MainActor
    public static func setCallback(_ callback: ((Gamepad, Status) -> Void)?) {
        Gamepad.callback = callback
        if callback != nil {
            glfwSetJoystickCallback { jid, event in
                let gamepad = Gamepad(jid: jid)
                let status: Status = event == .connected 
                    ? (glfwJoystickIsGamepad(jid) == .true ? .gamepad : .joystick)
                    : .disconnected
                Gamepad.callback?(gamepad, status)
            }
        } else {
            glfwSetJoystickCallback(nil)
        }
    }
}

extension Gamepad {
    /// All connected gamepads (joysticks with gamepad mappings)
    @MainActor
    public static var allGamepads: [Gamepad] {
        return (0..<16).compactMap { id in
            let gamepad = Gamepad(id: id)
            return gamepad.isGamepad ? gamepad : nil
        }
    }
    
    /// All connected joysticks (including those without gamepad mappings)
    @MainActor
    public static var allConnected: [Gamepad] {
        return (0..<16).compactMap { id in
            let gamepad = Gamepad(id: id)
            return gamepad.isPresent ? gamepad : nil
        }
    }
}

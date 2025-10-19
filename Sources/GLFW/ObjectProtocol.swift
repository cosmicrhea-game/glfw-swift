import CGLFW3

@MainActor public protocol GLFWObject: Equatable {
  nonisolated var pointer: OpaquePointer? { get }
}

extension GLFWObject {
  nonisolated public static func == (lhs: Self, rhs: some GLFWObject) -> Bool {
    lhs.pointer == rhs.pointer
  }
}

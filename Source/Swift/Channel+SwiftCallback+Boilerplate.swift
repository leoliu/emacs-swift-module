//
// Channel+SwiftCallback+Boilerplate.swift
// Copyright (C) 2022 Valeriy Savchenko
//
// This file is part of EmacsSwiftModule.
//
// EmacsSwiftModule is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
//
// EmacsSwiftModule is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
// or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License along with
// EmacsSwiftModule. If not, see <https://www.gnu.org/licenses/>.
//
class LazySwiftCallback0: AnyLazyCallback {
  let function: (Environment) throws -> Void
  init(function: @escaping (Environment) throws -> Void) {
    self.function = function
  }
  func call(_ env: Environment, with args: Any) throws {
    try function(env)
  }
}

class LazySwiftCallback1<T>: AnyLazyCallback {
  let function: (Environment, T) throws -> Void
  init(function: @escaping (Environment, T) throws -> Void) {
    self.function = function
  }
  func call(_ env: Environment, with args: Any) throws {
    if let arg = args as? T {
      try function(env, arg)
    }
  }
}

class LazySwiftCallback2<T1, T2>: AnyLazyCallback {
  let function: (Environment, T1, T2) throws -> Void
  init(function: @escaping (Environment, T1, T2) throws -> Void) {
    self.function = function
  }
  func call(_ env: Environment, with args: Any) throws {
    if let arg = args as? (T1, T2) {
      try function(env, arg.0, arg.1)
    }
  }
}

class LazySwiftCallback3<T1, T2, T3>: AnyLazyCallback {
  let function: (Environment, T1, T2, T3) throws -> Void
  init(function: @escaping (Environment, T1, T2, T3) throws -> Void) {
    self.function = function
  }
  func call(_ env: Environment, with args: Any) throws {
    if let arg = args as? (T1, T2, T3) {
      try function(env, arg.0, arg.1, arg.2)
    }
  }
}

class LazySwiftCallback4<T1, T2, T3, T4>: AnyLazyCallback {
  let function: (Environment, T1, T2, T3, T4) throws -> Void
  init(function: @escaping (Environment, T1, T2, T3, T4) throws -> Void) {
    self.function = function
  }
  func call(_ env: Environment, with args: Any) throws {
    if let arg = args as? (T1, T2, T3, T4) {
      try function(env, arg.0, arg.1, arg.2, arg.3)
    }
  }
}

class LazySwiftCallback5<T1, T2, T3, T4, T5>: AnyLazyCallback {
  let function: (Environment, T1, T2, T3, T4, T5) throws -> Void
  init(function: @escaping (Environment, T1, T2, T3, T4, T5) throws -> Void) {
    self.function = function
  }
  func call(_ env: Environment, with args: Any) throws {
    if let arg = args as? (T1, T2, T3, T4, T5) {
      try function(env, arg.0, arg.1, arg.2, arg.3, arg.4)
    }
  }
}

extension Channel {
  /// Make a callback that doesn't require the environment from a closure that does.
  ///
  /// This allows us to contact Emacs as part of asynchronous callbacks from Swift APIs.
  /// Please, see <doc:AsyncCallbacks> for more details on that.
  ///
  /// - Parameter function: a function to turn into a callback.
  /// - Returns: a callback that if called, will eventually call the given function.
  public func callback(function: @escaping (Environment) throws -> Void)
    -> () -> Void
  {
    return { [self] in
      register(
        callback: LazySwiftCallback0(function: function), args: ())
    }
  }
  /// Make a callback that doesn't require the environment from a closure that does.
  ///
  /// This allows us to contact Emacs as part of asynchronous callbacks from Swift APIs.
  /// Please, see <doc:AsyncCallbacks> for more details on that.
  ///
  /// - Parameter function: a function to turn into a callback.
  /// - Returns: a callback that if called, will eventually call the given function.
  public func callback<T>(function: @escaping (Environment, T) throws -> Void)
    -> (T) -> Void
  {
    return { [self] arg in
      register(
        callback: LazySwiftCallback1(function: function), args: arg)
    }
  }
  /// Make a callback that doesn't require the environment from a closure that does.
  ///
  /// This allows us to contact Emacs as part of asynchronous callbacks from Swift APIs.
  /// Please, see <doc:AsyncCallbacks> for more details on that.
  ///
  /// - Parameter function: a function to turn into a callback.
  /// - Returns: a callback that if called, will eventually call the given function.
  public func callback<T1, T2>(
    function: @escaping (Environment, T1, T2) throws -> Void
  ) -> (T1, T2) -> Void {
    return { [self] (arg1, arg2) in
      register(
        callback: LazySwiftCallback2(function: function), args: (arg1, arg2))
    }
  }
  /// Make a callback that doesn't require the environment from a closure that does.
  ///
  /// This allows us to contact Emacs as part of asynchronous callbacks from Swift APIs.
  /// Please, see <doc:AsyncCallbacks> for more details on that.
  ///
  /// - Parameter function: a function to turn into a callback.
  /// - Returns: a callback that if called, will eventually call the given function.
  public func callback<T1, T2, T3>(
    function: @escaping (Environment, T1, T2, T3) throws -> Void
  ) -> (T1, T2, T3) -> Void {
    return { [self] (arg1, arg2, arg3) in
      register(
        callback: LazySwiftCallback3(function: function),
        args: (arg1, arg2, arg3))
    }
  }
  /// Make a callback that doesn't require the environment from a closure that does.
  ///
  /// This allows us to contact Emacs as part of asynchronous callbacks from Swift APIs.
  /// Please, see <doc:AsyncCallbacks> for more details on that.
  ///
  /// - Parameter function: a function to turn into a callback.
  /// - Returns: a callback that if called, will eventually call the given function.
  public func callback<T1, T2, T3, T4>(
    function: @escaping (Environment, T1, T2, T3, T4) throws -> Void
  ) -> (T1, T2, T3, T4) -> Void {
    return { [self] (arg1, arg2, arg3, arg4) in
      register(
        callback: LazySwiftCallback4(function: function),
        args: (arg1, arg2, arg3, arg4))
    }
  }
  /// Make a callback that doesn't require the environment from a closure that does.
  ///
  /// This allows us to contact Emacs as part of asynchronous callbacks from Swift APIs.
  /// Please, see <doc:AsyncCallbacks> for more details on that.
  ///
  /// - Parameter function: a function to turn into a callback.
  /// - Returns: a callback that if called, will eventually call the given function.
  public func callback<T1, T2, T3, T4, T5>(
    function: @escaping (Environment, T1, T2, T3, T4, T5) throws -> Void
  ) -> (T1, T2, T3, T4, T5) -> Void {
    return { [self] (arg1, arg2, arg3, arg4, arg5) in
      register(
        callback: LazySwiftCallback5(function: function),
        args: (arg1, arg2, arg3, arg4, arg5))
    }
  }

  /// Execute the given closure with Emacs environment.
  ///
  /// This function allows us to asynchronously use environment
  /// to execute code on the Emacs side whenever we have any
  /// updates.
  ///
  /// - Parameter function: a callback to execute with Emacs environment
  public func withEnvironment(
    _ function: @escaping (Environment) throws -> Void
  ) {
    register(callback: LazySwiftCallback0(function: function), args: ())
  }

  /// Execute the given closure with Emacs environment and return its result.
  ///
  /// This function allows us to asynchronously use environment to request
  /// information from the Emacs side and wait for it using Swift async/await
  /// mechanisms.
  ///
  /// - Parameter function: a code calculating some value with Emacs environment
  public func withAsyncEnvironment<R: EmacsConvertible>(
    _ function: @escaping (Environment) throws -> R
  ) async throws -> R {
    try await withCheckedThrowingContinuation {
      continuation in
      withEnvironment {
        env in
        do {
          continuation.resume(returning: try function(env))
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }
}

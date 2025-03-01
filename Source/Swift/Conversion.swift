//
// Conversion.swift
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
import EmacsModule

/// The main protocol for value conversions between Emacs Lisp and Swift.
///
/// This protocol allows us to create a seamless integration between the two
/// worlds and bring strongly typed signatures into the mix.
///
/// See <doc:TypeConversions> for more detail.
public protocol EmacsConvertible {
  /// Convert current Swift value into `EmacsValue` within the given environment.
  ///
  /// - Parameter env: Emacs environment to convert the value in.
  /// - Returns: an opaque Emacs value representing this object.
  /// - Throws: any kind of excpetion if something during the conversion process went wrong.
  func convert(within env: Environment) throws -> EmacsValue
  /// Convert given EmacsValue value into the value of the current type within the given environment.
  ///
  /// - Parameters:
  ///   - from: an opaque Emacs value to convert.
  ///   - env: Emacs environment to convert the value in.
  /// - Returns: an object of the current type.
  /// - Throws: an `EmacsError` excpetion if something during the conversion process went wrong.
  static func convert(from: EmacsValue, within env: Environment) throws -> Self
}

/// We should be able to use Emacs value itself whenever we expect something
/// convertible to an Emacs value.
extension EmacsValue: EmacsConvertible {
  public func convert(within env: Environment) -> EmacsValue {
    return self
  }

  public static func convert(from: EmacsValue, within env: Environment) throws
    -> Self
  {
    return try Self(from: from, within: env)
  }
}

/// String conversions to and from Emacs values.
///
/// Emacs Lisp has a built-in string type, so this one is a 1-to-1 conversion.
/// Strings are immutable, changing them on the Swift side won't affect the
/// corresponding string on the Lisp side and vice versa.
extension String: EmacsConvertible {
  public func convert(within env: Environment) throws -> EmacsValue {
    return try env.make(self)
  }

  public static func convert(from: EmacsValue, within env: Environment) throws
    -> Self
  {
    return try env.toString(from)
  }
}

/// Bool conversions to and from Emacs values.
///
/// Emacs Lisp doesn't have a dedicated boolean type, but it is a common thing
/// there to assume that everything is "true" that is not "nil". That's what
/// we are going to do as well when converting to Swift Bool type. Because of that
/// `convert(within:)` and `convert(from:within:)` functions don't ever throw.
/// As for the true value, we chose `t`, which is a common Emacs Lisp practice.
extension Bool: EmacsConvertible {
  public func convert(within env: Environment) -> EmacsValue {
    return self ? env.t : env.Nil
  }

  public static func convert(from value: EmacsValue, within env: Environment)
    throws -> Bool
  {
    return try env.isNotNil(value)
  }
}

/// Integer conversions to and from Emacs values.
///
/// Emacs Lisp has a built-in integer type, so this one is a 1-to-1 conversion.
extension Int: EmacsConvertible {
  public func convert(within env: Environment) throws -> EmacsValue {
    // TODO: handle bigger integers
    return try env.make(self)
  }

  public static func convert(from value: EmacsValue, within env: Environment)
    throws -> Int
  {
    // TODO: handle bigger integers
    return try env.toInt(value)
  }
}

/// Double conversions to and from Emacs values.
///
/// Emacs Lisp has a built-in floating point type, so this one is a 1-to-1 conversion.
extension Double: EmacsConvertible {
  public func convert(within env: Environment) throws -> EmacsValue {
    return try env.make(self)
  }

  public static func convert(from value: EmacsValue, within env: Environment)
    throws -> Double
  {
    return try env.toDouble(value)
  }
}

/// Array conversions to and from Emacs values.
///
/// First things first, of course, it only works for arrays of `EmacsConvertible`
/// objects. The second important note is that, at the moment, arrays are converted
/// to and from Emacs Lisp vectors, not lists. It is a more appropriate container
/// to convert Swift arrays to, but we still might consider adding Emacs Lisp
/// lists conversions to Swift arrays later on.
extension Array: EmacsConvertible where Element: EmacsConvertible {
  public func convert(within env: Environment) throws -> EmacsValue {
    return try env.make(self.map { try $0.convert(within: env) })
  }

  public static func convert(from value: EmacsValue, within env: Environment)
    throws -> [Element]
  {
    // TODO: maybe we should convert lists to arrays as well.
    return try env.toArray(value).map {
      try Element.convert(from: $0, within: env)
    }
  }
}

/// Dictionary conversions to and from Emacs values.
///
/// It only works for dictionaries with both keys and values being `EmacsConvertible`.
/// Dictionaries are constructed to and from Lisp alists. Other candidates,
/// plists and hash tables are not yet supported.
extension Dictionary: EmacsConvertible
where
  Key: EmacsConvertible,
  Value: EmacsConvertible
{
  public func convert(within env: Environment) throws -> EmacsValue {
    let cells = self.map { ConsCell(car: $0, cdr: $1) }
    return try List(from: cells).convert(within: env)
  }

  public static func convert(from value: EmacsValue, within env: Environment)
    throws -> [Key: Value]
  {
    let raw = try List<ConsCell<Key, Value>>.convert(from: value, within: env)
    return Dictionary(
      uniqueKeysWithValues: raw.map { cons in (cons.car, cons.cdr) })
  }
}

/// Optional conversions to and from Emacs values.
///
/// It only works for optional types, where the underlying type itself
/// is `EmacsConvertible`. The conversion is almost 1-to-1 because both
/// languages use `nil` for representing the lack of a value and that's
/// how we convert between the languages: `nil` converts to and from `nil`,
/// otherwise it's simply and underlying type conversion.
extension Optional: EmacsConvertible where Wrapped: EmacsConvertible {
  public func convert(within env: Environment) throws -> EmacsValue {
    return try self?.convert(within: env) ?? env.Nil
  }

  public static func convert(from value: EmacsValue, within env: Environment)
    throws -> Self
  {
    return try env.isNil(value)
      ? nil : try Wrapped.convert(from: value, within: env)
  }
}

/// The protocol for converting custom Swift object into opaque Emacs values.
///
/// When using this conversion, the result would be absolutely opaque on the
/// Emacs side. No built-in operations are available for such objects, so
/// it only makes sense together with declaring a number of function accepting
/// it as a parameter.
///
/// The object is retained before giving it to the Emacs world and released
/// when the corresponding value is garbage-collected on the Emacs side of things.
public protocol OpaquelyEmacsConvertible: AnyObject, EmacsConvertible {}

extension OpaquelyEmacsConvertible {
  public func convert(within env: Environment) throws -> EmacsValue {
    try env.make(Unmanaged.passRetained(self).toOpaque()) { ptr in
      // This closure is going to get called when the value is garbage-collected
      // on the Emacs side.
      if let nonNullPtr = ptr {
        // Let's release it here, so the value won't leak when there is no need
        // for it.
        //
        // NOTE: here we cannot capture Self type because C-conforming functions
        //       are not allowed to do that, however, releasing it as `AnyObject`
        //       does the trick.
        Unmanaged<AnyObject>.fromOpaque(nonNullPtr).release()
      }
    }
  }

  public static func convert(from value: EmacsValue, within env: Environment)
    throws -> Self
  {
    // First let's try converting it to some opaque pointer (we can fail here,
    // if it's not a user pointer at all).
    let candidate = Unmanaged<AnyObject>.fromOpaque(try env.toOpaque(value))
      .takeUnretainedValue()
    // And only then let's try to check that it has the right type (for Emacs
    // all user pointers are the same and it is a Swift responsibility to check
    // their types).
    guard let result = candidate as? Self else {
      throw EmacsError.wrongType(
        expected: "\(Self.self)", actual: "\(type(of: candidate))", value: value
      )
    }
    return result
  }
}

extension Environment {
  /// Emacs `nil` value.
  public var Nil: EmacsValue {
    try! intern("nil")
  }
  /// Emacs `t` value.
  public var t: EmacsValue {
    try! intern("t")
  }
  /// Check if the given Emacs value is `nil`.
  public func isNil(_ value: EmacsValue) throws -> Bool {
    try !isNotNil(value)
  }
  /// Check if the given Emacs value is not `nil`.
  public func isNotNil(_ value: EmacsValue) throws -> Bool {
    try pointee.is_not_nil(raw, value.raw)
  }
  //
  // Value factories
  //
  func make(_ from: String) throws -> EmacsValue {
    EmacsValue(
      from: try check(pointee.make_string(raw, from, from.utf8.count)))
  }
  func make(_ from: Int) throws -> EmacsValue {
    EmacsValue(from: try check(pointee.make_integer(raw, from)))
  }
  func make(_ from: Double) throws -> EmacsValue {
    EmacsValue(from: try check(pointee.make_float(raw, from)))
  }
  func make(_ from: [EmacsValue]) throws -> EmacsValue {
    try apply("vector", with: from)
  }
  func make(
    _ value: RawOpaquePointer,
    with finalizer: @escaping RawFinalizer = { _ in () }
  ) throws -> EmacsValue {
    EmacsValue(
      from: try check(pointee.make_user_ptr(raw, finalizer, value)))
  }

  //
  // Converter functions
  //
  func toString(_ value: EmacsValue) throws -> String {
    var len = 0
    // The first call to `copy_string_contents` is needed to determine
    // the actual length of the string...
    let _ = try check(
      pointee.copy_string_contents(raw, value.raw, nil, &len))
    // ...then allocate the buffer of the right size...
    var buf = [CChar](repeating: 0, count: len)
    // ...and use it again with that buffer to fill.
    let _ = try pointee.copy_string_contents(raw, value.raw, &buf, &len)
    // Swift owns this memory know, nothing to be worried about!
    return String(cString: buf)
  }
  func toInt(_ value: EmacsValue) throws -> Int {
    try Int(check(pointee.extract_integer(raw, value.raw)))
  }
  func toDouble(_ value: EmacsValue) throws -> Double {
    try Double(check(pointee.extract_float(raw, value.raw)))
  }
  func toArray(_ value: EmacsValue) throws -> [EmacsValue] {
    let size = try check(pointee.vec_size(raw, value.raw))
    // We can only get values one by one, but we also need to
    // initialize our array with some values, so we used our
    // original value to take all the spots at first.
    var result = [EmacsValue](repeating: value, count: size)

    for i in 0..<size {
      result[i] = EmacsValue(
        from: try check(pointee.vec_get(raw, value.raw, i)))
    }

    return result
  }
  func toOpaque(_ value: EmacsValue) throws -> RawOpaquePointer {
    // All the raw pointers are consifered nullable by Swift, but
    // Emacs actually has these values marked as non null.
    // So, if we didn't throw during the check, it's OK to force unwrap.
    try check(pointee.get_user_ptr(raw, value.raw))!
  }
}

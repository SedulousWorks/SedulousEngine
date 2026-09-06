using System;

namespace SPIRV_Cross;

/// <summary>
/// A dispatchable handle.
/// </summary>
[CRepr]public struct spvc_context : IEquatable<spvc_context>, IHashable
{
	public this(int handle) { Handle = handle; }
	public int Handle { get; set mut; }
	public bool IsNull => Handle == 0;
	public static spvc_context Null => spvc_context(0);
	public static implicit operator spvc_context(int handle) => spvc_context(handle);
	public static bool operator ==(spvc_context left, spvc_context right) => left.Handle == right.Handle;
	public static bool operator !=(spvc_context left, spvc_context right) => left.Handle != right.Handle;
	public static bool operator ==(spvc_context left, int right) => left.Handle == right;
	public static bool operator !=(spvc_context left, int right) => left.Handle != right;
	public bool Equals(spvc_context other) => Handle == other.Handle;
	public int GetHashCode() => Handle.GetHashCode();
}

/// <summary>
/// A dispatchable handle.
/// </summary>
[CRepr]public struct spvc_parsed_ir : IEquatable<spvc_parsed_ir>, IHashable
{
	public this(int handle) { Handle = handle; }
	public int Handle { get; set mut; }
	public bool IsNull => Handle == 0;
	public static spvc_parsed_ir Null => spvc_parsed_ir(0);
	public static implicit operator spvc_parsed_ir(int handle) => spvc_parsed_ir(handle);
	public static bool operator ==(spvc_parsed_ir left, spvc_parsed_ir right) => left.Handle == right.Handle;
	public static bool operator !=(spvc_parsed_ir left, spvc_parsed_ir right) => left.Handle != right.Handle;
	public static bool operator ==(spvc_parsed_ir left, int right) => left.Handle == right;
	public static bool operator !=(spvc_parsed_ir left, int right) => left.Handle != right;
	public bool Equals(spvc_parsed_ir other) => Handle == other.Handle;
	public int GetHashCode() => Handle.GetHashCode();
}

/// <summary>
/// A dispatchable handle.
/// </summary>
[CRepr]public struct spvc_compiler : IEquatable<spvc_compiler>, IHashable
{
	public this(int handle) { Handle = handle; }
	public int Handle { get; set mut; }
	public bool IsNull => Handle == 0;
	public static spvc_compiler Null => spvc_compiler(0);
	public static implicit operator spvc_compiler(int handle) => spvc_compiler(handle);
	public static bool operator ==(spvc_compiler left, spvc_compiler right) => left.Handle == right.Handle;
	public static bool operator !=(spvc_compiler left, spvc_compiler right) => left.Handle != right.Handle;
	public static bool operator ==(spvc_compiler left, int right) => left.Handle == right;
	public static bool operator !=(spvc_compiler left, int right) => left.Handle != right;
	public bool Equals(spvc_compiler other) => Handle == other.Handle;
	public int GetHashCode() => Handle.GetHashCode();
}

/// <summary>
/// A dispatchable handle.
/// </summary>
[CRepr]public struct spvc_compiler_options : IEquatable<spvc_compiler_options>, IHashable
{
	public this(int handle) { Handle = handle; }
	public int Handle { get; set mut; }
	public bool IsNull => Handle == 0;
	public static spvc_compiler_options Null => spvc_compiler_options(0);
	public static implicit operator spvc_compiler_options(int handle) => spvc_compiler_options(handle);
	public static bool operator ==(spvc_compiler_options left, spvc_compiler_options right) => left.Handle == right.Handle;
	public static bool operator !=(spvc_compiler_options left, spvc_compiler_options right) => left.Handle != right.Handle;
	public static bool operator ==(spvc_compiler_options left, int right) => left.Handle == right;
	public static bool operator !=(spvc_compiler_options left, int right) => left.Handle != right;
	public bool Equals(spvc_compiler_options other) => Handle == other.Handle;
	public int GetHashCode() => Handle.GetHashCode();
}

/// <summary>
/// A dispatchable handle.
/// </summary>
[CRepr]public struct spvc_resources : IEquatable<spvc_resources>, IHashable
{
	public this(int handle) { Handle = handle; }
	public int Handle { get; set mut; }
	public bool IsNull => Handle == 0;
	public static spvc_resources Null => spvc_resources(0);
	public static implicit operator spvc_resources(int handle) => spvc_resources(handle);
	public static bool operator ==(spvc_resources left, spvc_resources right) => left.Handle == right.Handle;
	public static bool operator !=(spvc_resources left, spvc_resources right) => left.Handle != right.Handle;
	public static bool operator ==(spvc_resources left, int right) => left.Handle == right;
	public static bool operator !=(spvc_resources left, int right) => left.Handle != right;
	public bool Equals(spvc_resources other) => Handle == other.Handle;
	public int GetHashCode() => Handle.GetHashCode();
}

/// <summary>
/// A dispatchable handle.
/// </summary>
[CRepr]public struct spvc_type : IEquatable<spvc_type>, IHashable
{
	public this(int handle) { Handle = handle; }
	public int Handle { get; set mut; }
	public bool IsNull => Handle == 0;
	public static spvc_type Null => spvc_type(0);
	public static implicit operator spvc_type(int handle) => spvc_type(handle);
	public static bool operator ==(spvc_type left, spvc_type right) => left.Handle == right.Handle;
	public static bool operator !=(spvc_type left, spvc_type right) => left.Handle != right.Handle;
	public static bool operator ==(spvc_type left, int right) => left.Handle == right;
	public static bool operator !=(spvc_type left, int right) => left.Handle != right;
	public bool Equals(spvc_type other) => Handle == other.Handle;
	public int GetHashCode() => Handle.GetHashCode();
}

/// <summary>
/// A dispatchable handle.
/// </summary>
[CRepr]public struct spvc_constant : IEquatable<spvc_constant>, IHashable
{
	public this(int handle) { Handle = handle; }
	public int Handle { get; set mut; }
	public bool IsNull => Handle == 0;
	public static spvc_constant Null => spvc_constant(0);
	public static implicit operator spvc_constant(int handle) => spvc_constant(handle);
	public static bool operator ==(spvc_constant left, spvc_constant right) => left.Handle == right.Handle;
	public static bool operator !=(spvc_constant left, spvc_constant right) => left.Handle != right.Handle;
	public static bool operator ==(spvc_constant left, int right) => left.Handle == right;
	public static bool operator !=(spvc_constant left, int right) => left.Handle != right;
	public bool Equals(spvc_constant other) => Handle == other.Handle;
	public int GetHashCode() => Handle.GetHashCode();
}

/// <summary>
/// A dispatchable handle.
/// </summary>
[CRepr]public struct spvc_set : IEquatable<spvc_set>, IHashable
{
	public this(int handle) { Handle = handle; }
	public int Handle { get; set mut; }
	public bool IsNull => Handle == 0;
	public static spvc_set Null => spvc_set(0);
	public static implicit operator spvc_set(int handle) => spvc_set(handle);
	public static bool operator ==(spvc_set left, spvc_set right) => left.Handle == right.Handle;
	public static bool operator !=(spvc_set left, spvc_set right) => left.Handle != right.Handle;
	public static bool operator ==(spvc_set left, int right) => left.Handle == right;
	public static bool operator !=(spvc_set left, int right) => left.Handle != right;
	public bool Equals(spvc_set other) => Handle == other.Handle;
	public int GetHashCode() => Handle.GetHashCode();
}

/// <summary>
/// A dispatchable handle.
/// </summary>
[CRepr]public struct spvc_error_callback : IEquatable<spvc_error_callback>, IHashable
{
	public this(int handle) { Handle = handle; }
	public int Handle { get; set mut; }
	public bool IsNull => Handle == 0;
	public static spvc_error_callback Null => spvc_error_callback(0);
	public static implicit operator spvc_error_callback(int handle) => spvc_error_callback(handle);
	public static bool operator ==(spvc_error_callback left, spvc_error_callback right) => left.Handle == right.Handle;
	public static bool operator !=(spvc_error_callback left, spvc_error_callback right) => left.Handle != right.Handle;
	public static bool operator ==(spvc_error_callback left, int right) => left.Handle == right;
	public static bool operator !=(spvc_error_callback left, int right) => left.Handle != right;
	public bool Equals(spvc_error_callback other) => Handle == other.Handle;
	public int GetHashCode() => Handle.GetHashCode();
}


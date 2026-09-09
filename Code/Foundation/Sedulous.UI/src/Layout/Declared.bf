using System;

namespace Sedulous.UI;

/// A LayoutStyle field that remembers whether it was SET.
///
/// Assignment declares it; a default constructed field is undeclared and the cascade may fill
/// it from a sheet. A declared value ALWAYS wins over the sheet, even when it happens to equal
/// the default: that is the CSS inline style rule, and without the flag there would be no way
/// to tell "the author wrote width: wrap" from "nobody said".
///
/// DIVERGES from Raptor in how the value is reached. C++ gives it an implicit conversion and
/// `operator->`; Beef has the conversion but no arrow, so member access reads `.Value` and the
/// conversion carries the rest.
struct Declared<T> where bool : operator T == T
{
	public T Value;
	public bool IsDeclared;

	public this()
	{
		Value = default;
		IsDeclared = false;
	}

	public this(T value)
	{
		Value = value;
		IsDeclared = true;
	}

	public this(T value, bool isDeclared)
	{
		Value = value;
		IsDeclared = isDeclared;
	}

	/// Assigning a plain value DECLARES it, which is what makes `style.Width = .Match()` mean
	/// what it reads as.
	public static operator Declared<T>(T value) => .(value);
	public static operator T(Declared<T> declared) => declared.Value;

	/// Back to undeclared, so the sheet may fill the field again. `defaultValue` is what the
	/// field then reads as.
	public void Clear(T defaultValue = default) mut
	{
		Value = defaultValue;
		IsDeclared = false;
	}

	[Commutable]
	public static bool operator==(Declared<T> a, Declared<T> b) =>
		(a.IsDeclared == b.IsDeclared) && (a.Value == b.Value);
}

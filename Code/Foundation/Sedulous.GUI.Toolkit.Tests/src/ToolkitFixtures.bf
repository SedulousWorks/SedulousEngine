using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.GUI;

namespace Sedulous.GUI.Toolkit.Tests;

/// A clipboard in memory.
class MemoryClipboard : IClipboard
{
	public String Text = new .() ~ delete _;

	public bool HasText => Text.Length != 0;
	public void GetText(String outText) { outText.Append(Text); }
	public void SetText(StringView text) { Text.Set(text); }
}

/// A format of its own for the tests: Core's binary serializer, its bytes held as the text.
class BlobFormat : IPropertyTextFormat
{
	public void Write(delegate void(ISerializer ar) write, String outText)
	{
		let stream = scope MemoryStream();
		let ar = scope BinarySerializer(stream, .Write);
		write(ar);
		if (!ar.IsOk)
			return;
		let bytes = stream.Bytes;
		outText.Append(StringView((char8*)bytes.Ptr, bytes.Length));
	}

	public bool Read(StringView text, delegate void(ISerializer ar) read)
	{
		let stream = scope MemoryStream();
		stream.Write(Span<uint8>((uint8*)text.Ptr, text.Length));
		stream.Seek(0, .Begin);
		let ar = scope BinarySerializer(stream, .Read);
		read(ar);
		return ar.IsOk;
	}
}

/// What the toolkit's tests share.
static class ToolkitFixtures
{
	/// A root of a GUI of its own, `width` by `height`, held by the caller: it releases it, and the
	/// GUI goes with it.
	public static SceneRoot NewRoot(float width, float height)
	{
		let context = new GUIContext();
		let root = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		root.Size = .(width, height);
		return root;
	}

	/// One step of the GUI's clock (`seconds`, by ticks), then a layout.
	public static void Frame(SceneRoot root, float seconds = 0.016f)
	{
		root.Context.Update(Seconds(seconds));
		root.UpdateLayout();
	}

	public static TimeSpan Seconds(double s) => TimeSpan((int64)(s * (double)TimeSpan.TicksPerSecond));

	/// doctest's Approx: within a relative epsilon (scaled by 1 plus the larger magnitude).
	public static bool Near(double a, double b, double epsilon = 1.2e-5) =>
		Math.Abs(a - b) < epsilon * (1.0 + Math.Max(Math.Abs(a), Math.Abs(b)));

	/// The world point at `node`'s middle.
	public static Float2 Middle(Node node) => node.ConvertToWorldSpace(.(node.Size.X * 0.5f, node.Size.Y * 0.5f));

	/// A move there, a press and its release.
	public static void Click(EventDispatcher d, Float2 at, uint32 modifiers = 0)
	{
		d.InjectMouseMove(at, modifiers);
		d.InjectMouseDown(at, .Left, modifiers);
		d.InjectMouseUp(at, .Left, modifiers);
	}

	/// Every `T` under `node` (itself among them), in tree order, into `outFound`.
	public static void Collect<T>(Node node, List<T> outFound) where T : Node
	{
		if (let found = node as T)
			outFound.Add(found);
		for (int i = 0; i < node.ChildCount; i++)
			Collect(node.GetChildAt(i), outFound);
	}

	/// `markup` made with every registered element (the GUI's and the toolkit's); null when it does
	/// not load. The caller releases what comes back.
	public static Node Load(StringView markup)
	{
		RegisterGuiElements();
		RegisterToolkitElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		return loader.LoadFromString(markup);
	}

	/// Object `object`'s value at `path` as a number (the value disposed).
	public static double FloatOf(IPropertySource source, StringView path, int object)
	{
		var value = source.GetValue(path, object);
		defer value.Dispose();
		return value.AsFloat;
	}

	public static int64 IntOf(IPropertySource source, StringView path, int object)
	{
		var value = source.GetValue(path, object);
		defer value.Dispose();
		return value.AsInt;
	}

	/// Whether object `object`'s value at `path` is the text `expected`.
	public static bool TextIs(IPropertySource source, StringView path, int object, StringView expected)
	{
		var value = source.GetValue(path, object);
		defer value.Dispose();
		return (value.Kind == .String) && (value.AsString == expected);
	}

	/// Object `object`'s default at `path` as a number (the value disposed).
	public static double DefaultFloatOf(IPropertySource source, StringView path, int object)
	{
		var value = source.GetDefault(path, object);
		defer value.Dispose();
		return value.AsFloat;
	}

	/// Whether object `object` has no default at `path`.
	public static bool HasNoDefault(IPropertySource source, StringView path, int object)
	{
		var value = source.GetDefault(path, object);
		defer value.Dispose();
		return value.IsEmpty;
	}

	/// Whether `path` reads as mixed over the source's objects.
	public static bool IsMixed(IPropertySource source, StringView path, PropertyKind kind)
	{
		var value = ReadPropertyValue(source, path, kind);
		defer value.Dispose();
		return value.Mixed;
	}

	/// The info named `name` among `infos`, or null.
	public static PropertyInfo Find(List<PropertyInfo> infos, StringView name)
	{
		for (let info in infos)
		{
			if (info.Name == name)
				return info;
		}
		return null;
	}

	/// Asserts `a` is near `b`, saying both when it is not.
	public static void CheckNear(double a, double b, double epsilon = 1.2e-5)
	{
		Test.Assert(Near(a, b, epsilon), scope String()..AppendF("{} is not near {}", a, b));
	}
}

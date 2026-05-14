namespace Sedulous.Editor.App;

using System;
using Sedulous.Engine.Core;
using Sedulous.Editor.Core;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Shell;
using Sedulous.UI.Toolkit;
using Sedulous.Particles;

/// Extends PropertyGridDescriptor with editor-specific controls
/// (ResourceRefEditor with file browse dialogs, etc.) plus the
/// particle-specific descriptor methods declared via interface extension
/// in Sedulous.Particles (RangeFloat, RangeVector2, RangeColor,
/// CurveFloat, CurveColor, CurveVector2, EmissionShape). Stub
/// implementations show read-only labels; real editors land in follow-ups.
class EditorPropertyGridDescriptor : PropertyGridDescriptor
{
	private IDialogService mDialogs;
	private ISerializerProvider mSerializerProvider;
	private ResourceSystem mResourceSystem;
	private EditorContext mEditorContext;

	public this(PropertyGrid grid, IDialogService dialogs, ISerializerProvider serializerProvider = null,
		ResourceSystem resourceSystem = null, EditorContext editorContext = null) : base(grid)
	{
		mDialogs = dialogs;
		mSerializerProvider = serializerProvider;
		mResourceSystem = resourceSystem;
		mEditorContext = editorContext;
	}

	public override void ResRef(StringView name, delegate ResourceRef() getter, delegate void(ResourceRef) setter,
		StringView extensionFilter = default)
	{
		let editor = new ResourceRefEditor(name, getter, setter,
			dialogs: mDialogs, serializerProvider: mSerializerProvider,
			resourceSystem: mResourceSystem, editorContext: mEditorContext,
			extensionFilter: extensionFilter,
			ownsCallbacks: true, category: CurrentCategory);
		mGrid.AddProperty(editor);
	}

	public override void ResRefList(StringView name, delegate int32() countGetter,
		delegate ResourceRef(int32) getter, delegate void(int32, ResourceRef) setter)
	{
		let editor = new ResourceRefListEditor(name, countGetter, getter, setter,
			dialogs: mDialogs, editorContext: mEditorContext,
			ownsCallbacks: true, category: CurrentCategory);
		mGrid.AddProperty(editor);
	}

	// ===== Particle IPropertyDescriptor extension methods (stub) =====
	// Real editors land in tasks #37 and #38. For now, each surfaces a
	// read-only summary so the property grid renders something instead of
	// failing to compile.

	public void RangeFloat(StringView name, RangeFloat* ptr)
	{
		let summary = scope String();
		summary.AppendF("{:F3} .. {:F3}", ptr.Min, ptr.Max);
		mGrid.AddProperty(new StringEditor(name, summary, category: CurrentCategory));
	}

	public void RangeVector2(StringView name, RangeVector2* ptr)
	{
		let summary = scope String();
		summary.AppendF("({:F2},{:F2}) .. ({:F2},{:F2})",
			ptr.Min.X, ptr.Min.Y, ptr.Max.X, ptr.Max.Y);
		mGrid.AddProperty(new StringEditor(name, summary, category: CurrentCategory));
	}

	public void RangeColor(StringView name, RangeColor* ptr)
	{
		let summary = scope String();
		summary.AppendF("rgba ({:F2},{:F2},{:F2},{:F2}) .. ({:F2},{:F2},{:F2},{:F2})",
			ptr.Min.X, ptr.Min.Y, ptr.Min.Z, ptr.Min.W,
			ptr.Max.X, ptr.Max.Y, ptr.Max.Z, ptr.Max.W);
		mGrid.AddProperty(new StringEditor(name, summary, category: CurrentCategory));
	}

	public void CurveFloat(StringView name, ParticleCurveFloat* ptr)
	{
		let summary = scope $"({ptr.KeyCount} keys)";
		mGrid.AddProperty(new StringEditor(name, summary, category: CurrentCategory));
	}

	public void CurveColor(StringView name, ParticleCurveColor* ptr)
	{
		let summary = scope $"({ptr.KeyCount} keys)";
		mGrid.AddProperty(new StringEditor(name, summary, category: CurrentCategory));
	}

	public void CurveVector2(StringView name, ParticleCurveVector2* ptr)
	{
		let summary = scope $"({ptr.KeyCount} keys)";
		mGrid.AddProperty(new StringEditor(name, summary, category: CurrentCategory));
	}

	public void EmissionShape(StringView name, EmissionShape* ptr)
	{
		let summary = scope $"{ptr.Type}";
		mGrid.AddProperty(new StringEditor(name, summary, category: CurrentCategory));
	}
}

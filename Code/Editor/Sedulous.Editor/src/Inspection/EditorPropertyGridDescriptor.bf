namespace Sedulous.Editor;

using System;
using Sedulous.Engine.Core;
using Sedulous.Editor.Core;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Shell;
using Sedulous.UI.Toolkit;
using Sedulous.Particles;
using Sedulous.Core.Mathematics;

/// Extends PropertyGridDescriptor with editor-specific controls.
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

	public override void ResRef(StringView name, StringView displayName, delegate ResourceRef() getter, delegate void(ResourceRef) setter,
		StringView extensionFilter = default)
	{
		let editor = new ResourceRefEditor(name, getter, setter,
			dialogs: mDialogs, serializerProvider: mSerializerProvider,
			resourceSystem: mResourceSystem, editorContext: mEditorContext,
			extensionFilter: extensionFilter,
			ownsCallbacks: true, category: CurrentCategory);
		ApplyDisplayName(editor, name, displayName);
		mGrid.AddProperty(editor);
	}

	public override void ResRefList(StringView name, StringView displayName, delegate int32() countGetter,
		delegate ResourceRef(int32) getter, delegate void(int32, ResourceRef) setter,
		StringView extensionFilter = default)
	{
		let editor = new ResourceRefListEditor(name, countGetter, getter, setter,
			dialogs: mDialogs, editorContext: mEditorContext,
			extensionFilter: extensionFilter,
			ownsCallbacks: true, category: CurrentCategory);
		ApplyDisplayName(editor, name, displayName);
		mGrid.AddProperty(editor);
	}

	// ===== Particle types: real editors =====

	public override void RangeFloat(StringView name, RangeFloat* ptr)
	{
		mGrid.AddProperty(new RangeFloatEditor(name, ptr, category: CurrentCategory));
	}

	public override void RangeVector2(StringView name, RangeVector2* ptr)
	{
		mGrid.AddProperty(new RangeVector2Editor(name, ptr, category: CurrentCategory));
	}

	public override void RangeColor(StringView name, RangeColor* ptr)
	{
		mGrid.AddProperty(new RangeColorEditor(name, ptr, category: CurrentCategory));
	}

	public override void EmissionShape(StringView name, EmissionShape* ptr)
	{
		mGrid.AddProperty(new EmissionShapeEditor(name, ptr, category: CurrentCategory));
	}

	public override void CurveFloat(StringView name, ParticleCurveFloat* ptr, float displayMin = 0, float displayMax = 0)
	{
		mGrid.AddProperty(new CurveFloatEditor(name, ptr, category: CurrentCategory,
			displayMin: displayMin, displayMax: displayMax));
	}

	public override void CurveVector2(StringView name, ParticleCurveVector2* ptr, float displayMin = 0, float displayMax = 0)
	{
		mGrid.AddProperty(new CurveVector2Editor(name, ptr, category: CurrentCategory,
			displayMin: displayMin, displayMax: displayMax));
	}

	public override void CurveColor(StringView name, ParticleCurveColor* ptr)
	{
		mGrid.AddProperty(new CurveColorEditor(name, ptr, category: CurrentCategory));
	}

	public override void Vec4(StringView name, StringView displayName, Vector4* ptr)
	{
		let editor = new Vector4Editor(name, ptr, category: CurrentCategory);
		ApplyDisplayName(editor, name, displayName);
		mGrid.AddProperty(editor);
	}

	public override void Color4(StringView name, StringView displayName, Vector4* ptr)
	{
		let editor = new Vector4ColorEditor(name, ptr, category: CurrentCategory);
		ApplyDisplayName(editor, name, displayName);
		mGrid.AddProperty(editor);
	}
}

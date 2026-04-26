namespace Sedulous.Editor.App;

using System;
using Sedulous.Engine.Core;
using Sedulous.Editor.Core;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Shell;
using Sedulous.UI.Toolkit;

/// Extends PropertyGridDescriptor with editor-specific controls
/// (ResourceRefEditor with file browse dialogs, etc.)
class EditorPropertyGridDescriptor : PropertyGridDescriptor
{
	private IDialogService mDialogs;
	private ISerializerProvider mSerializerProvider;
	private ResourceSystem mResourceSystem;

	public this(PropertyGrid grid, IDialogService dialogs, ISerializerProvider serializerProvider = null,
		ResourceSystem resourceSystem = null) : base(grid)
	{
		mDialogs = dialogs;
		mSerializerProvider = serializerProvider;
		mResourceSystem = resourceSystem;
	}

	public override void ResRef(StringView name, delegate ResourceRef() getter, delegate void(ResourceRef) setter)
	{
		let editor = new ResourceRefEditor(name, getter, setter,
			dialogs: mDialogs, serializerProvider: mSerializerProvider,
			resourceSystem: mResourceSystem,
			ownsCallbacks: true, category: CurrentCategory);
		mGrid.AddProperty(editor);
	}

	public override void ResRefList(StringView name, delegate int32() countGetter,
		delegate ResourceRef(int32) getter, delegate void(int32, ResourceRef) setter)
	{
		let editor = new ResourceRefListEditor(name, countGetter, getter, setter,
			dialogs: mDialogs, ownsCallbacks: true, category: CurrentCategory);
		mGrid.AddProperty(editor);
	}
}

using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.GUI.Resources;

// Cooked GUI documents and style sheets. Sedulous.UI's counterpart: Sedulous.UI.Resource.
//
// Each payload is VALIDATED TEXT: the cook (GUI.Pipeline) parses a `.xml` document with the GUI's
// markup loader and a `.css` sheet with its CSS parser, fails on what cannot be read, and ships the
// source text; whatever hosts the GUI parses it again (a document is a template: each use builds
// its own tree from it). Free of the GUI framework, so a headless tool reads them. Nothing is
// embedded: a sheet or a document names an image, a vector image, a font or another document by
// its asset guid, which the host's resource provider answers, so an icon is cooked once however
// many sheets draw it.

/// Cooked GUI document: validated `.xml` markup.
[Serializable(1)]
class GuiDocumentSource
{
	public String Markup = new .() ~ delete _;
}

/// The runtime product: the document's markup, a template each use builds a tree from.
class GuiDocument
{
	public String Markup = new .() ~ delete _;
}

/// Cooked GUI style sheet: validated `.css`.
[Serializable(1)]
class GuiStyleSheetSource
{
	public String Css = new .() ~ delete _;
}

/// The runtime product: the sheet's CSS, for whatever styles a GUI with it.
class GuiStyleSheet
{
	public String Css = new .() ~ delete _;
}

/// Makes a document from its cooked markup.
class GuiDocumentFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<GuiDocument>();
	public Type CookedType => typeof(GuiDocumentSource);

	/// A string copy out of the stored record: nothing global is touched and no device is
	/// needed, so it runs entirely on a worker.
	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => Build(instance);

	public Object DecodeStage(Instance instance) => Build(instance);

	public Object FinalizeStage(ResourceManager manager, Object decoded) => decoded;

	private Object Build(Instance instance)
	{
		let stored = instance.ReadObject();
		defer delete stored;
		let source = stored as GuiDocumentSource;
		if (source == null)
			return null;
		let product = new GuiDocument();
		product.Markup.Set(source.Markup);
		return product;
	}
}

/// Makes a style sheet from its cooked CSS.
class GuiStyleSheetFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<GuiStyleSheet>();
	public Type CookedType => typeof(GuiStyleSheetSource);

	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => Build(instance);

	public Object DecodeStage(Instance instance) => Build(instance);

	public Object FinalizeStage(ResourceManager manager, Object decoded) => decoded;

	private Object Build(Instance instance)
	{
		let stored = instance.ReadObject();
		defer delete stored;
		let source = stored as GuiStyleSheetSource;
		if (source == null)
			return null;
		let product = new GuiStyleSheet();
		product.Css.Set(source.Css);
		return product;
	}
}

/// Registration for the GUI resource types.
[SerializableRegistry]
static class GuiResources
{
	/// The GUI resource module: the module the engine composition takes this library's factories
	/// from, built on first use so no static initialisation order matters.
	public static ResourceModule Module => sModule ?? (sModule = new .("gui", () => RegisterAll(), new .(
		.ByDefault<GuiDocument, GuiDocumentSource, GuiDocumentFactory>(),
		.ByDefault<GuiStyleSheet, GuiStyleSheetSource, GuiStyleSheetFactory>())));
	private static ResourceModule sModule ~ delete _;
}

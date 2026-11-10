using System;

namespace Sedulous.GUI;

// GUI.Code: the code editor (a document of lines, multi-cursor editing, incremental highlighting
// from language definitions its owners supply, diagnostics, completion through a language service).
// foundation.ui's counterpart: UI.Toolkit's CodeEditView. A satellite of the GUI: it knows no
// language; a language's definition and its service are its owners'.
//
// CodeDocument.bf: lines, positions, anchors, edits, undo with selections. CodeLanguage.bf: a
// language's definition, its tokenizer. CodeSheet.bf: its default sheet, over the theme's tokens.
// CodeFindBar.bf: the find, replace and go-to-line bar. CodeCompletion.bf: the language service (the
// host's), the completion list. CodeEditor.bf: the view: shaped lines in view, several carets, the
// keymap's text commands. Its widgets' reflection is their [GuiReflect] and [GuiProperty]
// attributes: the code editor an element markup places, its text and settings given in code or
// markup.

static
{
	private static bool sCodeElementsRegistered = false;

	/// Registers the code editor's element types (ElementTypes.Register), once: a host calls it at
	/// start-up beside RegisterGuiElements, so markup and code can make them by tag.
	public static void RegisterCodeElements()
	{
		if (sCodeElementsRegistered)
			return;
		sCodeElementsRegistered = true;
		ElementTypes.Register(CodeEditor.StaticGuiType);
	}
}

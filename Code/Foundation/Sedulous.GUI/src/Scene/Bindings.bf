using System;
using System.Collections;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// Node's bindings by name: any reflected property (its type's or a base's, found by its own name
// or the CSS name markup writes it by) binds to an expression, converted to the property's type,
// so native code, markup and scripts bind any widget's properties this way, a library's included;
// the properties a user changes write back; a translatable property binds to a key of the GUI's
// Localization. Each is one of the node's bindings (Node.BindFor): binding a property again
// replaces its binding.

extension Node
{
	/// Binds the reflected property named `name` (this node's type's or a base's) to `expression`'s
	/// value, converted to the property's type: native code, markup and scripts bind any widget's
	/// properties this way, a library's included. False when the node has no such writable
	/// property. OWNERSHIP of `expression` transfers (deleted at once when nothing binds); the
	/// binding disposes each value it returns.
	public bool BindProperty(StringView name, delegate System.Variant() expression)
	{
		let property = GuiType.Find(name);
		if ((property == null) || !property.CanWrite)
		{
			delete expression;
			return false;
		}
		// Bound again, a translation of it ends (BindTranslation records its own after this).
		for (int i = 0; i < mTranslations.Count; i++)
		{
			if (GuiType.Find(mTranslations[i].Property) == property)
			{
				delete mTranslations[i];
				mTranslations.RemoveAt(i);
				break;
			}
		}
		BindFor(property, false, new [=this, =property, =expression] () =>
			{
				var value = expression();
				defer value.Dispose();
				// The write is not a read: setting a property must not make this binding follow it.
				// A value that does not convert to the property's type sets nothing.
				Observer.Untracked(scope [&] () => { property.Set(this, value); });
			} ~ delete expression);
		return true;
	}

	/// The reverse: `write` takes the property's value now and whenever it changes (the user moved
	/// a slider, typed). Only for the properties a widget's user changes (marked TwoWay); false for
	/// any other. OWNERSHIP of `write` transfers (deleted at once when nothing binds); the value it
	/// is given is borrowed for the call.
	public bool BindPropertyBack(StringView name, delegate void(System.Variant value) write)
	{
		let property = GuiType.Find(name);
		if ((property == null) || !property.IsTwoWay)
		{
			delete write;
			return false;
		}
		BindFor(property, true, new [=this, =property, =write] () =>
			{
				var value = property.Get(this); // followed
				defer value.Dispose();
				Observer.Untracked(scope [&] () => { write(value); });
			} ~ delete write);
		return true;
	}

	/// Binds `property` to `model`'s value `key`, as markup's `{{key}}` does: it follows the value,
	/// and writes it back when the property is one the user changes. False when the node has no
	/// such writable property. The bindings hold references to `model`.
	public bool BindData(StringView property, DataModel model, StringView key)
	{
		let name = new String(key);
		model.AddRef();
		if (!BindProperty(property, new [=model, =name] () => { return model.Get(name); } ~ { model.ReleaseRef(); delete name; }))
			return false;
		let backName = new String(key);
		model.AddRef();
		BindPropertyBack(property, new [=model, =backName] (value) => { model.Set(backName, value); } ~ { model.ReleaseRef(); delete backName; });
		return true;
	}

	/// BindProperty for text: `text` appends the value to the string it is given (cleared before
	/// each run). The binding keeps that string and hands it on unowned, so a run makes no text of
	/// its own beyond what the property's conversion makes. False when no such writable property.
	/// OWNERSHIP of `text` transfers (deleted at once when nothing binds).
	public bool BindText(StringView property, delegate void(String outText) text)
	{
		let buffer = new String();
		return BindProperty(property, new [=text, =buffer] () =>
			{
				buffer.Clear();
				text(buffer);
				return System.Variant.Create(buffer);
			} ~ { delete text; delete buffer; });
	}

	/// BindProperty for a number, converted to the property's type (a slider's value, a progress
	/// bar's, a label's text). False when no such writable property. OWNERSHIP of `number`
	/// transfers (deleted at once when nothing binds).
	public bool BindNumber(StringView property, delegate double() number)
	{
		return BindProperty(property, new [=number] () => { return System.Variant.Create(number()); } ~ delete number);
	}

	/// BindProperty for a boolean (a node's Visible, a menu item's checked). False when no
	/// such writable property. OWNERSHIP of `value` transfers (deleted at once when nothing binds).
	public bool BindBool(StringView property, delegate bool() value)
	{
		return BindProperty(property, new [=value] () => { return System.Variant.Create(value()); } ~ delete value);
	}

	/// Binds reflected property `property` (one marked Translatable) to the text of `key` in the
	/// GUI's Localization: resolved now and again when the language changes, the node joins a GUI,
	/// or a named argument changes. With a count, the key's plural form for it, `{0}` the count and
	/// `args` from `{1}`; else `args` from `{0}`. A key shows as written while no Localization is set
	/// or auto-translation is off. False when the property is none such. `fallback` shows where no
	/// table has the key, or the GUI has no Localization (a widget's own label, "OK", over "gui.ok");
	/// empty: the key shows, as for markup's @key. The binding keeps copies of `count` and `args`
	/// (the caller keeps its own) and a reference to `data`.
	public bool BindTranslation(StringView property, StringView key, DataModel data, TranslationArgument count,
		Span<TranslationArgument> args, StringView fallback = default)
	{
		let info = GuiType.Find(property);
		if ((info == null) || !info.IsTranslatable)
			return false;
		let keyText = new String(key);
		let fallbackText = new String(fallback);
		TranslationArgument countCopy = null;
		if (count != null)
		{
			countCopy = new TranslationArgument();
			countCopy.Set(count);
		}
		let argsCopy = new List<TranslationArgument>();
		for (let a in args)
		{
			let copy = new TranslationArgument();
			copy.Set(a);
			argsCopy.Add(copy);
		}
		if (data != null)
			data.AddRef();
		let bound = BindProperty(property, new [=this, =keyText, =fallbackText, =data, =countCopy, =argsCopy] () =>
			{
				// The GUI it is in (a binding made before it joins one reruns when it does).
				let root = ObserveSceneRoot();
				let loc = (root != null) ? root.Context.Localization : null;
				if (root != null)
					root.Context.TrackLanguage();
				if ((loc == null) || !IsAutoTranslating)
					return TextVariant((fallbackText.Length != 0) ? fallbackText : keyText);
				if ((fallbackText.Length != 0) && !loc.Has(keyText))
					return TextVariant(fallbackText); // no table names it: the widget's own
				// Arguments as text, a named one read from the GUI's data (followed). The count goes
				// as its text too: a translation prints it as it prints the number.
				let texts = scope List<String>();
				defer { ClearAndDeleteItems!(texts); }
				let values = scope List<Object>();
				int64 n = 0;
				if (countCopy != null)
				{
					var raw = BindingsDetail.ArgumentValue(countCopy, data);
					defer raw.Dispose();
					var c = ConvertVariant(raw, typeof(int64));
					defer c.Dispose();
					if (c.HasValue)
						n = c.Get<int64>();
					let text = new String();
					n.ToString(text);
					texts.Add(text);
					values.Add(text);
				}
				for (let a in argsCopy)
				{
					var raw = BindingsDetail.ArgumentValue(a, data);
					defer raw.Dispose();
					let text = new String();
					FormatVariant(raw, text);
					texts.Add(text);
					values.Add(text);
				}
				let span = Span<Object>(values.Ptr, values.Count);
				let result = new String();
				if (countCopy != null)
					loc.FormatPlural(keyText, n, result, params span);
				else if (!argsCopy.IsEmpty)
					loc.Format(keyText, result, params span);
				else
					result.Append(loc.Text(keyText));
				return System.Variant.Create(result, true);
			} ~ { delete keyText; delete fallbackText; data?.ReleaseRef(); delete countCopy; DeleteContainerAndItems!(argsCopy); });
		if (!bound)
			return false;
		// Recorded by the property's own name (the inspector asks by it), after the binding, which
		// ends any translation the property had.
		let record = new TranslatedProperty();
		record.Property.Set(info.Name);
		record.Key.Set(key);
		mTranslations.Add(record);
		return true;
	}

	/// BindTranslation with no arguments and no fallback: markup's `@key`, or a count alone.
	public bool BindTranslation(StringView property, StringView key, DataModel data = null, TranslationArgument count = null)
	{
		return BindTranslation(property, key, data, count, Span<TranslationArgument>(), default);
	}
}

/// What Bindings.bf keeps out of the public surface.
internal static class BindingsDetail
{
	/// A translation's argument as a value: a named one read from `data` (a read a binding
	/// follows), anything else its text. The caller disposes it.
	public static System.Variant ArgumentValue(Node.TranslationArgument argument, DataModel data)
	{
		if (argument.IsName && (data != null))
			return data.Get(argument.Text);
		return TextVariant(argument.Text);
	}
}

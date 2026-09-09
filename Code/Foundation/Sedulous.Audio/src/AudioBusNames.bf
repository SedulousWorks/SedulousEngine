using System;

namespace Sedulous.Audio;

/// Naming the fixed buses.
static class AudioBusNames
{
	/// The fixed bus a name means, ASCII case insensitively. False when it is not one of the
	/// four, which is what tells a caller to look among the named buses instead.
	///
	/// The SHARED seam between applying a layout, validating a cooked one, and addressing a
	/// bus by string: three readings of the same name would drift apart.
	public static bool TryParse(StringView name, out AudioBus bus)
	{
		bus = .Master;

		if (Equals(name, "master"))
			return true;
		if (Equals(name, "effects"))
		{
			bus = .Effects;
			return true;
		}
		if (Equals(name, "music"))
		{
			bus = .Music;
			return true;
		}
		if (Equals(name, "ui"))
		{
			bus = .UI;
			return true;
		}
		return false;
	}

	/// A fixed bus's canonical name.
	public static StringView NameOf(AudioBus bus)
	{
		switch (bus)
		{
		case .Master: return "Master";
		case .Effects: return "Effects";
		case .Music: return "Music";
		case .UI: return "UI";
		}
	}

	/// The lower case comparison, against an already lower case literal.
	private static bool Equals(StringView name, StringView lowerCase)
	{
		if (name.Length != lowerCase.Length)
			return false;

		for (int i < name.Length)
		{
			var c = name[i];
			if ((c >= 'A') && (c <= 'Z'))
				c = (char8)(c + 32);
			if (c != lowerCase[i])
				return false;
		}
		return true;
	}
}

using System;
using System.Collections;
using Sedulous.Runtime;

namespace Sedulous.Engine.Project;

/// What became of a project's plugin entry in a host.
enum PluginState : uint8
{
	case Loaded;
	/// Not enabled on the host's platform: absent, as the entry asks.
	case NotEnabled;
	/// Compiled in, and refused (the reason says why).
	case Refused;
	/// Not in this host: its entry and settings are kept as written.
	case Missing;

	/// Its name as the tools report it.
	public StringView Name
	{
		get
		{
			switch (this)
			{
			case .Loaded: return "loaded";
			case .NotEnabled: return "notEnabled";
			case .Refused: return "refused";
			default: return "missing"; // Missing
			}
		}
	}
}

/// What became of one entry, so the editor and the tools report a project's plugins the same way.
class PluginStatus
{
	public PluginState State = .Missing;
	/// Why it is not loaded; empty when it is.
	public String Reason = new .() ~ delete _;
	/// The platforms the entry names that its manifest lacks.
	public List<String> UnsupportedPlatforms = new .() ~ DeleteContainerAndItems!(_);

	/// The status of `entry` in `host`, the process's plugin host after it enabled the
	/// project's entries; a null host is one that enables no plugins, where every entry is
	/// missing.
	public static void Of(EnabledPlugin entry, PluginHost host, PluginStatus outStatus)
	{
		let id = entry.Id;
		if (host == null)
		{
			outStatus.State = .Missing;
			outStatus.Reason.AppendF("plugin '{}' is not loaded: this host loads no plugins", id);
			return;
		}
		if (let manifest = host.Manifest(id))
			entry.UnsupportedPlatforms(manifest, outStatus.UnsupportedPlatforms);
		if (host.IsLoaded(id))
		{
			outStatus.State = .Loaded;
			return;
		}
		let report = host.Report;
		for (let absent in report.NotEnabled)
		{
			if (absent == id)
			{
				outStatus.State = .NotEnabled;
				outStatus.Reason.AppendF("plugin '{}' is not enabled on {}", id, host.Platform);
				return;
			}
		}
		let refusal = report.FindRefusal(id);
		if ((refusal != null) && host.Knows(id))
		{
			outStatus.State = .Refused;
			outStatus.Reason.Set(refusal.Reason);
			return;
		}
		outStatus.State = .Missing;
		outStatus.Reason.AppendF("plugin '{}' is not in this build", id);
	}
}

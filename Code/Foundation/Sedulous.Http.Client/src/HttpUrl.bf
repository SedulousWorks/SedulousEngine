using System;
using Sedulous.Http;

namespace Sedulous.Http.Client;

/// A URL the client can fetch.
class HttpUrl
{
	/// https.
	public bool Secure = false;
	public String Host = new .() ~ delete _;
	/// 80 or 443 when the URL names none.
	public uint16 Port = 0;
	/// The path and query, "/" at the least.
	public String Target = new .() ~ delete _;

	public bool DefaultPort => Port == (Secure ? 443 : 80);

	/// `url` split for a request into this; false, `outError` saying why, when it is not an
	/// http(s) URL this client fetches (another scheme, no host, an IPv6 literal, a bad port).
	public bool Parse(StringView url, String outError)
	{
		Secure = false;
		Host.Clear();
		Port = 0;
		Target.Clear();
		StringView rest;
		if ((url.Length >= 8) && HttpHeader.AsciiEqualsIgnoreCase(url.Substring(0, 8), "https://"))
		{
			Secure = true;
			rest = url.Substring(8);
		}
		else if ((url.Length >= 7) && HttpHeader.AsciiEqualsIgnoreCase(url.Substring(0, 7), "http://"))
			rest = url.Substring(7);
		else
		{
			outError.AppendF("'{}' is not an http:// or https:// URL", url);
			return false;
		}
		int end = 0;
		while ((end < rest.Length) && (rest[end] != '/') && (rest[end] != '?') && (rest[end] != '#'))
			end++;
		var authority = rest.Substring(0, end);
		var target = rest.Substring(end);
		let fragment = target.IndexOf('#');
		if (fragment >= 0)
			target = target.Substring(0, fragment); // a fragment never goes to the server
		let at = authority.LastIndexOf('@');
		if (at >= 0)
			authority = authority.Substring(at + 1); // credentials are not sent
		if (!authority.IsEmpty && (authority[0] == '['))
		{
			outError.Append("an IPv6 address is not supported (the sockets are IPv4)");
			return false;
		}
		var colon = authority.LastIndexOf(':');
		if (colon < 0)
			colon = authority.Length;
		Host.Set(authority.Substring(0, colon));
		if (Host.IsEmpty)
		{
			outError.AppendF("'{}' names no host", url);
			return false;
		}
		Port = Secure ? 443 : 80;
		if (colon < authority.Length)
		{
			let port = authority.Substring(colon + 1);
			uint32 value = 0;
			for (let c in port)
			{
				if ((c < '0') || (c > '9') || (value > 65535))
				{
					outError.AppendF("'{}' has a bad port", url);
					return false;
				}
				value = value * 10 + (uint32)((int)c - (int)'0');
			}
			if (port.IsEmpty || (value == 0) || (value > 65535))
			{
				outError.AppendF("'{}' has a bad port", url);
				return false;
			}
			Port = (uint16)value;
		}
		if (target.IsEmpty)
			Target.Set("/");
		else
		{
			if (target[0] == '?')
				Target.Append('/');
			Target.Append(target);
		}
		return true;
	}

	/// A redirect's Location made absolute against this URL, which sent it.
	public void Resolve(StringView location, String outUrl)
	{
		let scheme = Secure ? "https" : "http";
		if (((location.Length >= 7) && HttpHeader.AsciiEqualsIgnoreCase(location.Substring(0, 7), "http://"))
			|| ((location.Length >= 8) && HttpHeader.AsciiEqualsIgnoreCase(location.Substring(0, 8), "https://")))
		{
			outUrl.Append(location);
			return;
		}
		if (location.StartsWith("//"))
		{
			outUrl.AppendF("{}:{}", scheme, location);
			return;
		}
		if (DefaultPort)
			outUrl.AppendF("{}://{}", scheme, Host);
		else
			outUrl.AppendF("{}://{}:{}", scheme, Host, Port);
		if (location.StartsWith("/"))
		{
			outUrl.Append(location);
			return;
		}
		// Relative: against this URL's directory.
		var path = StringView(Target);
		let query = path.IndexOf('?');
		if (query >= 0)
			path = path.Substring(0, query);
		var slash = path.Length;
		while ((slash > 0) && (path[slash - 1] != '/'))
			slash--;
		outUrl.Append(path.Substring(0, slash));
		outUrl.Append(location);
	}
}

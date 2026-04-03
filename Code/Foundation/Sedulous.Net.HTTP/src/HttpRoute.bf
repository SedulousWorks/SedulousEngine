namespace Sedulous.Net.HTTP;

using System;

/// Delegate type for HTTP request handlers.
public delegate void HttpHandler(HttpRequest request, HttpResponse response);

/// An HTTP route matching a method + path pattern to a handler.
public class HttpRoute
{
	public HttpMethod Method;
	public String PathPattern ~ delete _;
	public HttpHandler Handler ~ delete _;

	public this(HttpMethod method, StringView pathPattern, HttpHandler handler)
	{
		Method = method;
		PathPattern = new String(pathPattern);
		Handler = handler;
	}

	/// Check if this route matches the given method and path.
	public bool Matches(HttpMethod method, StringView path)
	{
		if (Method != method)
			return false;

		// Exact match
		if (path == PathPattern)
			return true;

		// Wildcard match: pattern ending with "*"
		if (PathPattern.EndsWith('*'))
		{
			let prefix = StringView(PathPattern, 0, PathPattern.Length - 1);
			return path.StartsWith(prefix);
		}

		return false;
	}
}

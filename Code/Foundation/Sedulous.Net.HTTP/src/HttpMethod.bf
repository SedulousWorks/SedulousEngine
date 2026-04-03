namespace Sedulous.Net.HTTP;

using System;

public enum HttpMethod
{
	case GET;
	case POST;
	case PUT;
	case DELETE;
	case PATCH;
	case HEAD;
	case OPTIONS;

	public override void ToString(String strBuffer)
	{
		switch (this)
		{
		case .GET:     strBuffer.Append("GET");
		case .POST:    strBuffer.Append("POST");
		case .PUT:     strBuffer.Append("PUT");
		case .DELETE:  strBuffer.Append("DELETE");
		case .PATCH:   strBuffer.Append("PATCH");
		case .HEAD:    strBuffer.Append("HEAD");
		case .OPTIONS: strBuffer.Append("OPTIONS");
		}
	}

	public static Result<HttpMethod> Parse(StringView str)
	{
		if (StringView.Compare(str, "GET", true) == 0)         return .Ok(.GET);
		if (StringView.Compare(str, "POST", true) == 0)        return .Ok(.POST);
		if (StringView.Compare(str, "PUT", true) == 0)         return .Ok(.PUT);
		if (StringView.Compare(str, "DELETE", true) == 0)      return .Ok(.DELETE);
		if (StringView.Compare(str, "PATCH", true) == 0)       return .Ok(.PATCH);
		if (StringView.Compare(str, "HEAD", true) == 0)        return .Ok(.HEAD);
		if (StringView.Compare(str, "OPTIONS", true) == 0)     return .Ok(.OPTIONS);
		return .Err;
	}
}

namespace Sedulous.Net.HTTP;

using System;

public enum HttpStatusCode : int32
{
	// 1xx Informational
	case Continue = 100;
	case SwitchingProtocols = 101;

	// 2xx Success
	case OK = 200;
	case Created = 201;
	case Accepted = 202;
	case NoContent = 204;

	// 3xx Redirection
	case MovedPermanently = 301;
	case Found = 302;
	case NotModified = 304;

	// 4xx Client Error
	case BadRequest = 400;
	case Unauthorized = 401;
	case Forbidden = 403;
	case NotFound = 404;
	case MethodNotAllowed = 405;
	case RequestTimeout = 408;
	case Conflict = 409;
	case Gone = 410;
	case LengthRequired = 411;
	case PayloadTooLarge = 413;
	case UnsupportedMediaType = 415;
	case TooManyRequests = 429;

	// 5xx Server Error
	case InternalServerError = 500;
	case NotImplemented = 501;
	case BadGateway = 502;
	case ServiceUnavailable = 503;
	case GatewayTimeout = 504;

	public void GetReasonPhrase(String strBuffer)
	{
		switch (this)
		{
		case .Continue:              strBuffer.Append("Continue");
		case .SwitchingProtocols:    strBuffer.Append("Switching Protocols");
		case .OK:                    strBuffer.Append("OK");
		case .Created:               strBuffer.Append("Created");
		case .Accepted:              strBuffer.Append("Accepted");
		case .NoContent:             strBuffer.Append("No Content");
		case .MovedPermanently:      strBuffer.Append("Moved Permanently");
		case .Found:                 strBuffer.Append("Found");
		case .NotModified:           strBuffer.Append("Not Modified");
		case .BadRequest:            strBuffer.Append("Bad Request");
		case .Unauthorized:          strBuffer.Append("Unauthorized");
		case .Forbidden:             strBuffer.Append("Forbidden");
		case .NotFound:              strBuffer.Append("Not Found");
		case .MethodNotAllowed:      strBuffer.Append("Method Not Allowed");
		case .RequestTimeout:        strBuffer.Append("Request Timeout");
		case .Conflict:              strBuffer.Append("Conflict");
		case .Gone:                  strBuffer.Append("Gone");
		case .LengthRequired:        strBuffer.Append("Length Required");
		case .PayloadTooLarge:       strBuffer.Append("Payload Too Large");
		case .UnsupportedMediaType:  strBuffer.Append("Unsupported Media Type");
		case .TooManyRequests:       strBuffer.Append("Too Many Requests");
		case .InternalServerError:   strBuffer.Append("Internal Server Error");
		case .NotImplemented:        strBuffer.Append("Not Implemented");
		case .BadGateway:            strBuffer.Append("Bad Gateway");
		case .ServiceUnavailable:    strBuffer.Append("Service Unavailable");
		case .GatewayTimeout:        strBuffer.Append("Gateway Timeout");
		default:                     strBuffer.Append("Unknown");
		}
	}
}

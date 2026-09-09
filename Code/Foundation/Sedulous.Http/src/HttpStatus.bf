using System;

namespace Sedulous.Http;

/// The reason phrases this server emits.
static class HttpStatus
{
	/// The phrase for a status. A generic one for anything not listed, because the phrase is
	/// advisory: the NUMBER is what a client acts on.
	public static StringView Text(int32 status)
	{
		switch (status)
		{
		case 200: return "OK";
		case 202: return "Accepted";
		case 204: return "No Content";
		case 400: return "Bad Request";
		case 401: return "Unauthorized";
		case 404: return "Not Found";
		case 405: return "Method Not Allowed";
		case 413: return "Content Too Large";
		case 500: return "Internal Server Error";
		case 501: return "Not Implemented";
		case 503: return "Service Unavailable";
		default: return "Status";
		}
	}
}

using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Http;

namespace Sedulous.Http.Client;

/// A game's HTTP: it sends requests through the run's IHttpClient (native, or the browser's in a
/// web build) and hears the answers by callback on the game's thread.
///
///     http.Get("https://example.com/scores", new (status, body, error) => { ... });
///
/// A handler hears (status, body, error): the status and body text of the response (a 404 is a
/// response), or status 0 and why in `error` when none came (no network, a timeout, a refused
/// certificate). Bodies are text both ways for now.
///
/// The run owns one and registers it as a service. The client is made by the run's factory on
/// the first request, so a game that never asks starts no thread and opens nothing; the run pumps
/// it each frame. A game in the editor's play mode is a game like any other.
///
/// The facade OWNS each handler: it is deleted after its answer, on Cancel, and by Reset, which
/// drops a request under way unanswered (the run resets as its session ends, so no answer reaches
/// a game that has gone).
class HttpFacade
{
	public typealias Factory = delegate IHttpClient();
	/// A request's handler: the status and body of the response, or status 0 and why in
	/// `error`; the views are valid for the call alone.
	public typealias ResponseHandler = delegate void(int32 status, StringView body, StringView error);

	/// OWNED: what makes the client.
	private Factory mFactory ~ delete _;
	/// OWNED: made on the first request.
	private IHttpClient mClient ~ delete _;
	/// A request waiting for its answer, and the handler that hears it.
	private class Waiting
	{
		public uint64 Id;
		/// OWNED; null when none was passed.
		public ResponseHandler Handler ~ delete _;
	}

	/// The requests under way by id, OWNED until their answer is delivered or they go. The
	/// client's callback holds its Waiting, which lives exactly as long as the request: an
	/// answered one goes in Answer, a cancelled one is never answered.
	private Dictionary<uint64, Waiting> mWaiting = new .() ~ DeleteDictionaryAndValues!(_);

	/// Takes OWNERSHIP of `factory`, which replaces any earlier one.
	public void SetFactory(Factory factory)
	{
		delete mFactory;
		mFactory = factory;
	}

	/// The client, made now if this is the first request; null when the run has no factory.
	public IHttpClient Client
	{
		get
		{
			if ((mClient == null) && (mFactory != null))
				mClient = mFactory();
			return mClient;
		}
	}

	/// Delivers the answers that have arrived; their handlers run here. Each frame.
	public void Pump()
	{
		if (mClient != null)
			mClient.Pump();
	}

	/// Drops the client and every request under way, their handlers never called: when the game
	/// that sent them ends.
	public void Reset()
	{
		DeleteAndNullify!(mClient);
		for (let entry in mWaiting)
			delete entry.value;
		mWaiting.Clear();
	}

	/// Requests sent and not yet answered or cancelled.
	public int Pending => (mClient != null) ? mClient.Pending : 0;

	/// GETs `url`; `handler(status, body, error)` hears the answer on the pump. The request's id
	/// (for Cancel), or nought when this run has no HTTP (the handler is then deleted, never
	/// called). TAKES OWNERSHIP of the handler, which may be null.
	public int32 Get(StringView url, ResponseHandler handler) => Send(HttpClientRequest.Get(url), handler);

	/// POSTs `body` as `contentType` to `url`, as Get does.
	public int32 Post(StringView url, StringView contentType, StringView body, ResponseHandler handler) =>
		Send(HttpClientRequest.Post(url, contentType, body), handler);

	/// Any method, `headers` "Name: value" lines (empty for none; a line without a colon is
	/// skipped), as Get does.
	public int32 Request(StringView method, StringView url, StringView headers, StringView body, ResponseHandler handler) =>
		Send(BuildRequest(method, url, headers, body), handler);

	/// A request of `method` to `url`, with `headers` ("Name: value" lines) and `body`.
	private static HttpClientRequest BuildRequest(StringView method, StringView url, StringView headers, StringView body)
	{
		let request = new HttpClientRequest(url);
		request.Method.Set(method);
		request.Body.AddRange(Span<uint8>((uint8*)body.Ptr, body.Length));
		for (var line in headers.Split('\n'))
		{
			if (line.EndsWith('\r'))
				line = line.Substring(0, line.Length - 1);
			let colon = line.IndexOf(':');
			if (colon < 0)
				continue;
			var value = line.Substring(colon + 1);
			while (value.StartsWith(' '))
				value = value.Substring(1);
			request.Headers.Add(new .(line.Substring(0, colon), value));
		}
		return request;
	}

	/// Its handler is never called; a request under way is dropped.
	public void Cancel(int32 id)
	{
		if ((id <= 0) || (mClient == null))
			return;
		mClient.Cancel((uint64)id);
		if (mWaiting.GetAndRemove((uint64)id) case .Ok(let entry))
			delete entry.value;
	}

	/// Sends `request` (taken) with `handler` (taken) waiting for its answer.
	private int32 Send(HttpClientRequest request, ResponseHandler handler)
	{
		let waiting = new Waiting();
		waiting.Handler = handler;
		return SendWaiting(request, waiting);
	}

	/// Sends `request` (taken) with `waiting` (taken, and deleted with its handler when there is
	/// no client).
	private int32 SendWaiting(HttpClientRequest request, Waiting waiting)
	{
		let client = Client;
		if (client == null)
		{
			delete request;
			delete waiting;
			return 0;
		}
		waiting.Id = client.Send(request, new [=this, =waiting](response) => Answer(waiting, response));
		mWaiting[waiting.Id] = waiting;
		return (int32)waiting.Id;
	}

	/// The answer goes to the request's handler as (status, body, error), and the request goes.
	private void Answer(Waiting waiting, HttpClientResponse response)
	{
		mWaiting.Remove(waiting.Id);
		defer delete waiting;
		if (waiting.Handler != null)
			waiting.Handler(response.Status, response.BodyText, response.Error);
	}
}

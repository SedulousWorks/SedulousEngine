using System;
using System.Collections;
using Sedulous.Http;
using Sedulous.Http.Client;

namespace Sedulous.Http.Client.Tests;

/// The Http facade over a stand-in client that records what is sent and answers when the test
/// says, so the facade is checked without a network: Get, Post, and Request with its headers
/// reach the client as asked; handlers hear (status, body, error) on the pump; a cancelled request
/// is never answered; the client is made only on the first request; a run with no factory gets
/// nought back.
class HttpFacadeTests
{
	private class Recorded
	{
		public uint64 Id;
		public HttpClientRequest Request ~ delete _;
		public delegate void(HttpClientResponse response) Done ~ delete _;
		public bool Cancelled = false;
		public bool Delivered = false;
	}

	/// Answers only when told; Pump delivers what Answer queued, as a real client does.
	private class FakeClient : IHttpClient
	{
		public List<Recorded> Log = new .() ~ DeleteContainerAndItems!(_);
		private List<(Recorded recorded, HttpClientResponse response)> mQueued = new .() ~ delete _;
		private uint64 mNext = 0;

		public ~this()
		{
			for (let q in mQueued)
				delete q.response;
		}

		public uint64 Send(HttpClientRequest request, delegate void(HttpClientResponse response) done)
		{
			let r = new Recorded();
			r.Id = ++mNext;
			r.Request = request;
			r.Done = done;
			Log.Add(r);
			return r.Id;
		}

		public void Cancel(uint64 id)
		{
			for (let r in Log)
			{
				if (r.Id == id)
					r.Cancelled = true;
			}
		}

		public void Pump()
		{
			for (let q in mQueued)
			{
				q.recorded.Delivered = true;
				if (!q.recorded.Cancelled)
					q.recorded.Done(q.response);
				delete q.response;
			}
			mQueued.Clear();
		}

		public int Pending
		{
			get
			{
				var pending = 0;
				for (let r in Log)
				{
					if (!r.Cancelled && !r.Delivered)
						pending++;
				}
				return pending;
			}
		}

		/// Queues the answer to request `index`, delivered on the next Pump.
		public void Answer(int index, int32 status, StringView body, StringView error = default)
		{
			let response = new HttpClientResponse();
			response.Status = status;
			response.Body.AddRange(Span<uint8>((uint8*)body.Ptr, body.Length));
			response.Error.Set(error);
			mQueued.Add((Log[index], response));
		}
	}

	/// A script handler that records the arguments it was called with.
	/// A facade whose factory makes `fake` (counting the calls), counting the clients it made.
	private class Bed
	{
		public HttpFacade Http = new .() ~ delete _;
		public FakeClient Fake;
		public int Made = 0;

		public this()
		{
			Http.SetFactory(new () =>
				{
					Made++;
					Fake = new FakeClient();
					return Fake;
				});
		}
	}

	/// What the handlers heard, as "status [body] [error]" lines, and how many the facade
	/// deleted (each handler counts its own deletion through the closure's destructor).
	private class HandlerLog
	{
		public List<String> Heard = new .() ~ DeleteContainerAndItems!(_);
		public int Deleted = 0;

		public HttpFacade.ResponseHandler Handler() => new [=this] (status, body, error) =>
			{
				Heard.Add(new String()..AppendF("{} [{}] [{}]", status, body, error));
			} ~ { Deleted++; };
	}

	/// Get, Post and Request reach the client as asked, the client made once, on the first.
	[Test]
	public static void GetPostAndRequestReachTheClientAsAsked()
	{
		let log = scope HandlerLog();
		let bed = scope Bed();
		Test.Assert(bed.Made == 0, "no request, no client");
		let a = bed.Http.Get("https://example.com/scores", log.Handler());
		let b = bed.Http.Post("https://example.com/score", "application/json", "{\"s\":5}", log.Handler());
		let c = bed.Http.Request("PUT", "https://example.com/name", "X-Token: abc\r\nnot a header\nAccept:  text/plain", "Rae", log.Handler());
		Test.Assert(bed.Made == 1);
		Test.Assert((a == 1) && (b == 2) && (c == 3));
		let sent = bed.Fake.Log;
		Test.Assert((sent[0].Request.Method == "GET") && (sent[0].Request.Url == "https://example.com/scores"));
		Test.Assert(sent[1].Request.Method == "POST");
		Test.Assert(sent[1].Request.Headers[0].Value == "application/json");
		Test.Assert(StringView((char8*)sent[1].Request.Body.Ptr, sent[1].Request.Body.Count) == "{\"s\":5}");
		Test.Assert(sent[2].Request.Method == "PUT");
		Test.Assert(sent[2].Request.Headers.Count == 2, "a line without a colon is skipped");
		Test.Assert((sent[2].Request.Headers[0].Name == "X-Token") && (sent[2].Request.Headers[0].Value == "abc"));
		Test.Assert((sent[2].Request.Headers[1].Name == "Accept") && (sent[2].Request.Headers[1].Value == "text/plain"));
		Test.Assert(StringView((char8*)sent[2].Request.Body.Ptr, sent[2].Request.Body.Count) == "Rae");
	}

	/// A handler hears (status, body, error) on the pump and is deleted after; a cancelled one is
	/// deleted at the cancel and never called.
	[Test]
	public static void HandlersHearTheAnswerAndAreDeletedAfterACancelledOneNever()
	{
		let log = scope HandlerLog();
		let bed = scope Bed();
		bed.Http.Get("https://example.com/a", log.Handler());
		let cancelled = bed.Http.Get("https://example.com/b", log.Handler());
		bed.Http.Get("https://example.com/c", log.Handler());
		bed.Fake.Answer(0, 200, "hello");
		bed.Fake.Answer(2, 0, "", "timed out after 30 s");
		bed.Http.Cancel(cancelled);
		Test.Assert(log.Deleted == 1, "the cancelled one, at the cancel");
		Test.Assert(bed.Fake.Log[1].Cancelled, "the client dropped it");
		Test.Assert(log.Heard.IsEmpty, "nothing before the pump");
		bed.Http.Pump();
		Test.Assert(log.Heard.Count == 2);
		Test.Assert(log.Heard[0] == "200 [hello] []", log.Heard[0]);
		Test.Assert(log.Heard[1] == "0 [] [timed out after 30 s]", log.Heard[1]);
		Test.Assert(log.Deleted == 3, "each answered one after its answer");
		Test.Assert(bed.Http.Pending == 0);
	}

	/// No factory: nought back and the handler deleted, never called. Reset drops a request
	/// under way, its handler deleted, never called, though its answer had come.
	[Test]
	public static void WithNoClientOrAfterResetAHandlerIsDeletedUncalled()
	{
		let log = scope HandlerLog();
		let none = scope HttpFacade();
		Test.Assert(none.Get("https://example.com/", log.Handler()) == 0);
		Test.Assert(log.Deleted == 1, "no HTTP: deleted at once");

		let bed = scope Bed();
		bed.Http.Get("https://example.com/", log.Handler());
		bed.Http.Post("https://example.com/", "text/plain", "x", log.Handler());
		bed.Fake.Answer(0, 200, "late");
		Test.Assert(bed.Http.Pending == 2);
		bed.Http.Reset();
		Test.Assert(log.Deleted == 3, "both dropped and deleted");
		Test.Assert(bed.Http.Pending == 0);
		bed.Http.Get("https://example.com/again", log.Handler());
		Test.Assert(bed.Made == 2, "a new client for the next request");
		bed.Http.Pump();
		Test.Assert(log.Heard.IsEmpty, "never called");
	}
}

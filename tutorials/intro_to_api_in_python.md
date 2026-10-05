# Intro to APIs in Python

In this tutorial, we'll use the **Regulatory Radar** demo app: a small Python API for a Regulatory Affairs team.
It serves FDA/EU regulatory updates, openFDA data (510(k) clearances, recalls), and the product portfolio of a fictional company we named *Acme MedTech*.

## Get the app code

Open a terminal (Windows: PowerShell) and clone the repository:

```bash
git clone https://github.com/alonitac/RegulatoryRadarDemo.git
```

Open it in Cursor: **File > Open Folder...** and choose `RegulatoryRadarDemo`.

## Python project basics

Let's review a few concepts that are common to Python projects.

### Virtual environment (venv)

**Virtual environment** is a folder that contains all the dependencies and the Python runtime for the project (a.k.a. "Python interpreter"). It is used to isolate the project from the rest of the system.

The easiest way to create one is through the Cursor Command Palette:

1. Make sure the `RegulatoryRadarDemo` folder is open in Cursor.
2. Open the Command Palette: `Ctrl+Shift+P` (Windows / Linux) or `Cmd+Shift+P` (macOS).
3. Type `Python: Create Environment...` and press Enter.
4. Choose **Venv**.
5. Choose the Python interpreter to use (pick the latest Python 3 version in the list).

Cursor creates a `.venv` folder in the project and selects it as the project's Python interpreter.

Open a new terminal: **Terminal > New Terminal** (or `` Ctrl+` ``). Your prompt should start with `(.venv)`, which means the environment is active. 

> [!TIP]
> You can create the environment directly from the terminal with `python3 -m venv .venv` and then activate it with by `.venv/bin/activate` (macOS / Linux) or `.venv\Scripts\Activate.ps1` (Windows (PowerShell)).

### Install dependencies

**Dependencies** are packages other people wrote that our app uses. They're usually listed in `requirements.txt`. To install them, run:

```bash
pip install -r requirements.txt
```

Key ones: `fastapi` (a framework allows you to configure your API), `uvicorn` (the server that runs your code), `httpx` (a tool that makes HTTP requests to openFDA), `pytest` (a tool that runs your tests).

### Run the API

Open a new terminal and run:

```bash
python -m uvicorn app.main:app --reload
```

- `app.main:app` means the `app` object in `app/main.py`.
- `--reload` restarts the server whenever you save a file.
- Stop it with `Ctrl+C`.

The API now listens on `http://127.0.0.1:8000`.

## What are APIs?

As humans, we usually communicate with apps using a graphical user interface (GUI). But there are apps that we communicate with in a programmatic way using APIs.

An **API** (Application Programming Interface) is a programmatic way to talk to an app.
We usually communicate with APIs over a protocol called **HTTP**: a **client** (browser, `curl`, Postman, another app) sends a **request** and the **server** returns a **response**.

Let's see it in action. 

`curl` is a command-line HTTP client. Add `-v` (verbose) to see exactly what is sent and received.
With the server running, open a **second** terminal and run:

```bash
curl -v http://127.0.0.1:8000/products/pulse-dr
```

Output:

```text
* Connected to 127.0.0.1 (127.0.0.1) port 8000
> GET /products/pulse-dr HTTP/1.1
> Host: 127.0.0.1:8000
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 200 OK
< date: Sat, 03 Oct 2026 21:19:57 GMT
< server: uvicorn
< content-length: 343
< content-type: application/json
<
{"id":"pulse-dr","name":"Acme Pulse DR","category":"Cardiac rhythm management","intended_use":"Dual-chamber implantable pacemaker for patients with symptomatic bradycardia.","fda_pathway":"PMA","markets":["US","EU"],"has_software":true,"uses_ai":false,"tags":["implantable","cardiac","software","connected","cybersecurity"],"product_codes":[]}
```

How to read it:

- Lines starting with `>` are the **request** curl sends:
  - `GET /products/pulse-dr HTTP/1.1`: the **method**, the **endpoint** (path), and the HTTP version.
  - `Host`, `User-Agent`, `Accept`: request **headers**.
- Lines starting with `<` are the **response** from the server:
  - `HTTP/1.1 200 OK`: the **status code**.
  - `content-type: application/json` and the other lines: response **headers**.
- The blank `<` line separates the headers from the **body**: the JSON at the bottom.
- Lines starting with `*` are curl's own notes (connection info), not part of HTTP.


The **method** tells the server what you want to do with the resource at the URL.

| Method | Purpose  | Example |
| --- | --- | --- | --- |
| `GET` | Read data. Doesn't change anything on the server. |  `GET /products` |
| `POST` | Create a new resource. | `POST /products` |
| `PUT` | Replace an existing resource entirely. | `PUT /products/pulse-dr` |
| `PATCH` | Update part of an existing resource. | `PATCH /products/pulse-dr` |
| `DELETE` | Remove a resource. | `DELETE /products/pulse-dr` |

The **status code** is a 3-digit number in the response that tells you whether the request worked. The first digit is the category:

| Range | Category | Meaning |
| --- | --- | --- |
| `2xx` | Success | The request worked. |
| `3xx` | Redirection | The resource moved, go to another URL. |
| `4xx` | Client error | The request was wrong (the client's mistake). |
| `5xx` | Server error | The server failed to handle a valid request (the server's mistake). |

### Other important concepts

- **Headers** are key-value metadata sent with the request or response. Common ones:
  - `Content-Type`: the format of the body being sent, e.g. `application/json`.
  - `Accept`: the format the client wants back.
  - `Authorization`: credentials, e.g. `Bearer <token>` or an API key.
- **JSON** (JavaScript Object Notation) is the most common format for API bodies: `{"name": "Acme Pulse DR", "uses_ai": false}`.
- **Path parameters** identify a specific resource: `/products/pulse-dr` (`pulse-dr` is the product ID).
- **Query parameters** filter or tune the result, after a `?` and joined with `&`: `/recalls?query=defibrillator&limit=3`.
- **Stateless**: every request is independent. The server doesn't remember your previous requests, so each one must carry everything it needs (like the API key).
- **HTTP vs HTTPS**: HTTPS is HTTP encrypted with TLS. Use it for anything on the internet, especially with credentials.
- **REST**: a common style for designing APIs where URLs name resources (`/products`) and methods say the action (`GET`, `POST`, ...). Regulatory Radar follows it.


You can review the REAMD.md file of the project to see the available endpoints and their documentation.

## Environment variables and `.env`

**Environment variables** are variables that live outside the code.
This means you can change the variable value without editing code. A very common use case is **API keys**. You can store them in the environment variables so you don't commit the value to the repository.

A `.env` file is a plain-text list of `KEY=VALUE` lines that the app (might) loads at startup. Create yours from the template:

```bash
cp .env.example .env
```

```ini
OPENFDA_MODE=fixture        # fixture = saved sample data (offline), live = real api.fda.gov
OPENFDA_API_KEY=            # optional
```

See how the app reads them in `app/config.py` (`os.getenv(...)`).

> [!IMPORTANT]
> `.env` is listed in `.gitignore`. **Never commit secrets to git**.


## Testing

**Tests** are code that checks your code. Run them after every change to catch what you broke.

**API tests** send real HTTP requests to the app and check the response (status code + body). See `tests/test_api.py`:

```python
def test_health_reports_fixture_mode():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "mode": "fixture"}
```

Run them:

```bash
python -m pytest
```


# Exercises

### :pencil2: HTTP protocol - comprehension checks

Please complete [the following set of multi-choice questions](https://exit-zero-academy.github.io/DevOpsTheHardWayAssets/multichoice-questions/intro_to_api_in_python.html).

### :pencil2: Project exploration and Cursor rules

One of the first things you can do when you start working on an existing project is to understand the project structure, its architecture, and how to use it.

Open the Cursor chat (the chat icon on the top right of the screen), at the bottom of the chat box, switch the mode to **Ask** (read-only, it won't change files), and select `Sonnet` or any equivalent mid-level model in the model picker.

Now we want to ask the agent to explain a few questions. 

But before we do so, we want to help the agent to provide better answers.
For that, we'll use a feature called **rules**.

Rules are a short system-level instructions that Cursor automatically adds to every conversation.

To demonstrate it, ask the agent the following questions:

> Where do the products come from? Where do the regulatory updates come from?

You might notice the agent's answers contain code snippets, which are redundant as you are not a developer.

Tell the agent who you are once, by adding a **user rule**:

 1. Open **Cursor Settings** (the settings icon on the top right of the screen) and go to the **Customize** section, then go to the **Rules** section.
 2. Add a new **User Rule** (a rule that applies to all your projects) and write something like:
    ```text
    I'm tech-oriented but not a developer. I don't know code.
    Explain things in plain language, and avoid code snippets unless I ask for them.
    ```
 3. Open a **fresh conversation** (a new chat, so the agent starts clean).
 4. Send the same question again and compare the answers. How is the new answer?

Let's ask a few more important questions about the `.env` file:


> - The `.env` file contains the `OPENFDA_MODE` variable. What's the difference between `fixture` and `live` mode?
> - How do I work with the real openFDA API?
> - The `.env` file contains the `OPENFDA_TIMEOUT_SECONDS` variable. What does it do?


### :pencil2: Vibe coding: what kind of device is each product?

Let's start using the built in Cursor coding assistant to add new functionality to our API. We'll begin with the most naive and simple approach, known as **vibe coding**: you describe what you want in plain language and trust the LLM to handle everything (coding style, architecture, design decisions), judging the result only by trying it.

:warning: In vibe coding the harness is very weak. You give the LLM no guidance, no conventions and no guardrails, and just hope it's good enough to complete the task. The goal of this exercise is to let you *experience* it. Later in the course we'll build a proper harness (skills, MCPs, steering, and more).

In the US, every type of medical device has a 3-letter **product code**. For example, `DXY` is an implantable pacemaker. The FDA keeps a **classification** database that tells, for each product code:

- the **device name**, for example "Implantable Pacemaker Pulse-Generator",
- the **device class**, which is the risk level: class 1 is low risk (like a bandage), class 2 is medium, and class 3 is high risk (like a pacemaker),
- the **medical specialty**, for example "Cardiovascular".

Our products already list their product codes in `data/portfolio.yaml`, and a sample of the classification database is saved in `data/fixtures/classification.json`. But the API doesn't use this data yet, so nobody can see what kind of device each product is.

In **Agent** mode, ask exactly this, without adding any more details:

> Add an endpoint `GET /products/{product_id}/classification` that shows the FDA classification of the product.

Try it:

```bash
curl "http://127.0.0.1:8000/products/pulse-dr/classification"
```

The agent may well implement this successfully, and the decisions it made along the way may well be reasonable. But did you aprroved them? Where are those decisions written down? Did it miss something you would have wanted? That's the gap we'll close later in the next tutorial.

**Discard the changes.** In the Cursor chat, click **Undo All** (or restore the checkpoint before your prompt). 

### :pencil2: Debug a bug: with and without Debug mode

A user who's using your API (e.g. a Regulatory Affairs team member) reports:

> "I asked for updates since July 1st, 2025, and got an update from **June**. Updates from August and November 2025 are missing."

Reproduce it:

```bash
curl "http://127.0.0.1:8000/updates?since=2025-07-01"
```

Expected: `eu-ai-act-high-risk-obligations` (2025-08-01), `eu-post-market-surveillance` (2025-11-05), `fda-qmsr-iso-13485` (2026-02-09).

Look at what you actually get.

**Round 1: without Debug mode.** New chat, **Agent** mode. Paste the bug report and ask the agent to find and fix the bug.

Reading the output, notice what the agent does: it usually reads the code, makes an educated guess about the cause, and edits the code right away, without ever running it to confirm the guess. Sometimes the guess is right, but often it "fixes" the wrong thing, or only hides the symptom.

Undo the fix:

```bash
git restore .
```

**Round 2: with Debug mode.** New chat, switch to **Debug** mode, paste the same bug report.
Debug mode follows a very methodical process to find the root cause of a bug: it forms hypotheses, adds temporary logs to the code, asks you to reproduce the bug (run the curl again), reads the real values from the logs, and only then fixes the bug and removes the logs. In practice, this evidence-based approach is much, much more successful.


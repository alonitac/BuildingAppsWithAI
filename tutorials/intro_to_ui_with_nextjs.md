# Intro to UI Apps with Next.js

In the RAG tutorial you built a chat assistant in RAGFlow. It works, but it lives inside RAGFlow's own UI. What if you want your own chat app for your team: your design, your features, your company's logo?

In this tutorial we'll use **ChatRAG**: the thinnest possible chat app on top of a RAGFlow chat assistant. You'll make it better in the exercises.

```text
 ┌───────────┐  POST /api/chat   ┌──────────────────┐  RAGFlow API + API key  ┌───────────┐
 │  Browser  │ ────────────────► │  Next.js server  │ ──────────────────────► │  RAGFlow  │
 │  (user)   │ ◄──────────────── │  (ChatRAG)       │ ◄────────────────────── │           │
 └───────────┘   HTML, JSON      └──────────────────┘                         └───────────┘
```

ChatRAG has no database. The chats and their messages are stored in RAGFlow.

## Get the app code

1. Open [https://github.com/alonitac/ChatRAG](https://github.com/alonitac/ChatRAG), click **Use this template** > **Create a new repository**, keep the name `ChatRAG`, and set **Owner** to your GitHub username.
2. Clone **your** copy, and open it in Cursor:

    ```bash
    git clone https://github.com/<your-username>/ChatRAG.git
    ```

## The client and the server

A web app runs in two places.

The **client** is the user's browser. It draws the page, and it reacts when the user types and clicks.

The **server** is a program on a machine you run. In the diagram above, that program is the Next.js server.

Each piece of the UI runs in one of those two places. You'll see which piece is which later.

The browser understands three languages: **HTML**, **CSS**, and **JavaScript**.

**HTML** is structure and content. In ChatRAG that is the list of chats, the text of each message, the input box, and the Send button.

**CSS** is the look: colors, fonts, sizes, and layout. A user message is a blue bubble on the right. An assistant message is a gray bubble.

**JavaScript** is behavior. It runs when you click Send, shows "Thinking..." while you wait, and updates the page when the answer arrives.

| Language | Job |
| --- | --- | --- |
| **HTML** | Structure and content | 
| **CSS** | Look |
| **JavaScript** | Behavior |

## Node.js: JavaScript on the server

The browser runs JavaScript. In the server we can use any language we want, Python, Go, etc.
In 2009, Node.js was created to run JavaScript on the server.

The benefit of using Node.js is that the whole app is one language: the page, the button, and the API endpoints.

## TypeScript

Plain JavaScript, often called **vanilla JavaScript**, is messy and hard to write directly. **TypeScript** lets developers write the same app in a much clearer and stricter way. Files of backend logic end in `.ts`, and files that also conain UI components end in `.tsx`.

Before the app runs, that TypeScript goes through **transpilation**, a translation into vanilla JavaScript. Node.js then runs that JavaScript on the server, and the browser runs it on the client: TypeScript is only a better way to write, and the code that actually runs is JavaScript.

```ts
function greet(name: string): string {
  return "Hello, " + name;
}
```

transpiles to:

```js
function greet(name) {
  return "Hello, " + name;
}
```

The `: string` marks are there to help the writing. Transpilation removes them, and what remains is vanilla JavaScript.

You write the `.ts` and `.tsx` files, and you leave the generated JavaScript alone. In this project, Next.js does the transpilation when you start the app, and puts the result in a folder named `.next/`. Git ignores that folder.


## The pieces of a frontend project

### npm

**npm** is the package manager, the way `pip` is for Python. It installs code other people wrote, and it runs the project's commands.

- **`package.json`** lists the `dependencies` (needed to run the app), the `devDependencies` (needed only while developing: TypeScript, ESLint, tests), and the `scripts`.
- **`npm install`** reads `package.json` and downloads everything into **`node_modules/`**. The folder is huge. Never edit it or commit it. You can delete it and run `npm install` again.
- **`package-lock.json`** records the exact versions. Commit it, so everyone gets the same ones.
- **`npm run <script>`** runs a script from `package.json`:

| Command | What it does |
| --- | --- |
| `npm run dev` | Development server. Next.js transpiles on each save, and the page updates. |
| `npm run build` | Type check, then a production build (another transpilation, stricter than `dev`). |
| `npm run start` | Runs the production build. |
| `npm run lint` | ESLint. The rule check from the lint section above. |

> [!IMPORTANT]
> Code that works in `npm run dev` can fail the type check in `npm run build`, or fail `npm run lint`. Always ask the agent to run `build` and `lint` before it says it's done.

> [!WARNING]
> npm packages run code on your computer when installed, and attackers publish look-alike names. When the agent adds a package, check the `package.json` diff. `npm audit` lists known vulnerabilities.

### Run the app

```bash
npm install
cp .env.example .env.local      # Windows: copy .env.example .env.local
```

Fill in `.env.local`:

- `RAGFLOW_URL`: the address of your RAGFlow server.
- `RAGFLOW_API_KEY`: in RAGFlow, click your avatar (top right) > **API** > create a new key.
- `RAGFLOW_CHAT_ID`: the ID of your chat assistant. Find it with the API:

    ```bash
    curl -H "Authorization: Bearer <your-api-key>" "<ragflow-url>/api/v1/chats"
    ```

Then:

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) and ask a question about the documents in your RAGFlow dataset.

Next.js has transpiled your TypeScript. A new `.next/` folder holds that JavaScript and the rest of the build output. It is listed in `.gitignore`, so it stays off GitHub. Your source files are still the `.ts` and `.tsx` files.

### The project

```text
ChatRAG/
├── src/
│   ├── app/                    # every folder is a URL
│   │   ├── layout.tsx          # the frame around every page: <html>, fonts
│   │   ├── page.tsx            # the page at /: the list of chats + the open chat
│   │   ├── loading.tsx         # shown while the page loads its data
│   │   ├── globals.css         # global styles + Tailwind
│   │   └── api/chat/route.ts   # the endpoint POST /api/chat
│   ├── components/
│   │   └── Chat.tsx            # the chat: messages, input, Send
│   └── lib/
│       └── ragflow.ts          # the calls to the RAGFlow API
├── package.json                # dependencies and scripts
├── package-lock.json           # exact versions; commit this
├── tsconfig.json               # TypeScript settings, including noEmit
├── eslint.config.mjs           # the ESLint rules
├── next.config.ts              # Next.js settings
├── .env.example                # which variables are needed (committed)
└── .env.local                  # the real values (NOT committed)
```

In Next.js, **folders are URLs**: `src/app/page.tsx` is `/`, `src/app/settings/page.tsx` would be `/settings`, and `src/app/api/chat/route.ts` is the endpoint `/api/chat`.


## How a page gets to the screen

The browser still receives only HTML, CSS, and JavaScript. Next.js transpiles your TypeScript into that JavaScript. Tailwind turns short class names into CSS. React components describe the HTML.

### Components

A **component** is a reusable piece of UI, written as a function that returns HTML-like code (**TSX**). Look at a piece of `src/components/Chat.tsx`:

```tsx
{messages.map((message, i) => (
  <div className={message.role === "user" ? "ml-auto bg-blue-100" : "bg-gray-100"}>
    {message.content}
  </div>
))}
```

For every message, draw a box. User messages are blue, on the right (`ml-auto`). Assistant messages are gray.

`Chat` also has **state**: values that change while you use it.

```tsx
const [messages, setMessages] = useState(history);   // the messages on the screen
const [question, setQuestion] = useState("");        // what you're typing
const [waiting, setWaiting] = useState(false);       // show "Thinking..."?
```

When the state changes, React **re-renders**: it runs the component again, and updates only what changed on the screen.

### Tailwind CSS

Instead of a separate CSS file, you add short class names to each element:

| Class | Means |
| --- | --- |
| `p-4`, `px-3`, `mt-6` | Padding (space inside), margin (space outside) |
| `text-sm`, `font-bold`, `text-gray-500` | Font size, weight, color |
| `bg-blue-600`, `rounded`, `border` | Background, rounded corners, border |
| `flex`, `gap-2`, `w-64` | Layout: a row or column, space between, width |
| `sm:...`, `hover:...`, `dark:...` | Only on screens ≥ 640px / on mouse over / in dark mode |

## Server and client components

The most important concept when you vibe-code with Next.js. Every component runs in **one** of two places:

| | **Server component** (the default) | **Client component** (`"use client"` at the top) |
| --- | --- | --- |
| Runs | On the Next.js server | In the user's browser |
| Can | Fetch data, use secrets from `.env.local` | React to clicks and typing (`useState`, `onClick`) |
| Can't | React to clicks and typing | Keep secrets: its code is sent to the browser |

In ChatRAG:

- `page.tsx` is a **server** component: it fetches the chat list and the messages from RAGFlow, with the API key.
- `Chat.tsx` is a **client** component: it reacts to typing and to Send.
- When you click Send, `Chat` (in the browser) calls **our** endpoint, `/api/chat`, and `route.ts` (on the server) calls RAGFlow with the key. This pattern is called **BFF** (Backend for Frontend). The browser never sees the key.

Why not call RAGFlow straight from the browser? The key would be visible to every user. And browsers block requests to other addresses, unless the server allows it (**CORS**).

> [!WARNING]
> Variables that start with `NEXT_PUBLIC_` are copied into the JavaScript sent to the browser. Agents sometimes "fix" a client component by renaming a secret to `NEXT_PUBLIC_...`. Never put a secret there.

## UI tests with Playwright

**Playwright** opens a real browser and uses the app the way a person does. It opens a page, finds a button, clicks or types, then checks the screen. A **test** is that sequence, written as a small program. When a check fails, the test fails.

### A first test

This test checks that ChatRAG's opening screen has the controls a person needs. It never sends a question, so it runs with RAGFlow offline.

Leave `npm run dev` running, and install Playwright in the ChatRAG project:

```bash
npm init playwright@latest      # TypeScript, folder "tests", install the browsers
```

The installer creates `tests/example.spec.ts`, a demo that opens playwright.dev. Delete it, and add `tests/chat-page.spec.ts`:

```ts
import { test, expect } from "@playwright/test";

test("the chat page is ready", async ({ page }) => {
  await page.goto("http://localhost:3000");

  await expect(page.getByRole("link", { name: "+ New chat" })).toBeVisible();
  await expect(page.getByRole("textbox", { name: "Question" })).toBeVisible();
  await expect(page.getByRole("button", { name: "Send" })).toBeVisible();
});
```

Playwright gives the test a `page`: one browser tab.

- `page.goto` opens the app.
- `getByRole` finds an element by its **role** and its **name**: a link named "+ New chat", a text box named "Question", a button named "Send". The name is the text on the screen. The text box gets its name from `aria-label="Question"` in `Chat.tsx`.
- `toBeVisible()` passes when the element is on the screen. Send looks faded until you type, because it is disabled, and the check still passes. It fails when the button is missing.

```bash
npx playwright test tests/chat-page.spec.ts
npx playwright test --ui        # watch every step
```

In `--ui`, the browser performs each line. That is the whole idea: a test is a user, written down. 



### What to test

Write tests of two kinds.

**A full business flow.** One complete path, from the user's first action to the result they came for. In ChatRAG: start a chat, ask a question, get an answer, and see the new chat in the list.

**One component, every case.** Pick a single piece and check each situation it can be in. For the question box: Send is disabled while the box is empty, Send is disabled again while "Thinking..." is on the screen, the question appears as your message, and the answer appears when it arrives.

A flow checks that the pieces work together. A component test checks that one piece handles its situations.

### The Playwright MCP

An agent can draft a test by reading `page.tsx` and `Chat.tsx`, which means it can draft a test by statically analyzing the code. We wish the agent could have a browser to run the code and "see" the results.

But wait, browsers do have an API to interact with the page, why not writing an MCP server that uses it?

The **Playwright MCP** server gives the agent that browser. The Playwright MCP server hands to the agent a list of actions a user can perform: open a URL, click, type, read the page.


# Exercises


### :pencil2: The browser DevTools

The **DevTools** are the most useful tool for understanding and debugging any web app. In Chrome or Edge, right click on the page > **Inspect** (or `F12`).

1. Go to the tab where you see the HTML and CSS, try to change some visual properties of the page (a text, a background color, a border, etc.). Take a look how the changes are reflected in the page (it's saved only in your browser, until you refresh).
2. Open the **Network** tab, and refresh the page, try to send some message in the chat. Click on the `chat` request and take a look at the headers, the payload and the response:
3. **Slow network.** In the Network tab, change **No throttling** to **Slow 4G**, and send a question. What does the user see while waiting? Is it good user experience?
4. **Console.** Break the app: put a wrong `RAGFLOW_API_KEY` in `.env.local`, restart `npm run dev`, and refresh. What does the user see? Where is the real error, in the browser **Console** or in the **terminal** of `npm run dev`?
5. **Phone.** Click the **device toolbar** icon (a phone and a tablet), and pick a phone. Is the app usable? 

When you report a UI bug to the agent, give it what you found here: the error from the Console or the terminal, the failed request from the Network tab.





### :pencil2: Make it beautiful: with and without the `frontend-design` skill

Are you also can notice UI designed by agents? 
Agents, without guidance, all design the same way: a white page, a purple gradient, the same font, the same rounded cards. People call it **"AI slop"**. 

Anthropic's great **`frontend-design`** skill teaches the agent to make deliberate design choices.

**Round 1: without the skill.** Branch `design-no-skill`. New chat, **Agent** mode:

> Redesign ChatRAG: it's an internal assistant that answers questions about our company's documents. Make it look professional and pleasant to use, on desktop and on a phone. Don't change how it works. Run `npm run build` and `npm run lint` when you're done.

Take screenshots, and commit.

**Round 2: with the skill.** `git switch main`, then branch `design-with-skill`. Install the skill:

```bash
npx skills add anthropics/skills --skill frontend-design -a cursor
```

New chat, the same prompt, with one more line at the beginning: *"Use the frontend-design skill."* Take screenshots, and commit.

Compare. Which would you give your team? Merge the one you prefer into `main`.





### :pencil2: Like and dislike

Let users rate the answers with 👍 / 👎. 

Obviously, results should be saved somewhere. Before you decide to allocate a new database for the ratings, check if RAGFlow already supports feedback on messages (yes it does! let's utilize it). 


1. Read the RAGFlow docs for this endpoint: [HTTP API reference](https://ragflow.io/docs/dev/http_api_reference), section **Update message feedback in a chat assistant's session** (`PUT /api/v1/chats/{chat_id}/sessions/{session_id}/messages/{msg_id}/feedback`).
2. New chat, **Agent** mode:

    > Add 👍 / 👎 buttons under every assistant message. Store the feedback in RAGFlow, using the "Update message feedback in a chat assistant's session" endpoint from https://ragflow.io/docs/dev/http_api_reference. On 👎, let the user write optionally what was wrong. When I open an old chat, show the feedback I already gave. Keep the API key on the server.

3. Check it: rate a message, refresh, is it still there? Look at the Network tab: which request did the browser send? Then check RAGFlow itself:

    ```bash
    curl -H "Authorization: Bearer <your-api-key>" "<ragflow-url>/api/v1/chats/<chat-id>/sessions/<session-id>"
    ```

    Do you see `thumbup` on the message?




### :pencil2: UI tests with the Playwright MCP

Write either a full business flow or every case of one component. The Playwright MCP lets the agent read the page. 

**Step I: Playwright in the project.** If `tests/chat-page.spec.ts` already passes, skip the install. Otherwise run `npm init playwright@latest` (TypeScript, folder `tests`, install the browsers) and delete `tests/example.spec.ts`.

In `playwright.config.ts`, set `baseURL` to `http://localhost:3000`, and set the `webServer` command to `npm run dev` (ask the agent to fix the file if either is missing). Playwright then starts the app for the tests, and reuses it when `npm run dev` is already running.

**Step II: add the MCP server.** **Cursor Settings > Tools & MCP**, add a new server, and add to `mcp.json`:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

Unlike the GitHub MCP server, this server runs **on your computer** (`command` instead of `url`). No token needed.

**Step III: let the agent explore and write the tests.** New chat:

> Use the Playwright MCP to open http://localhost:3000 and explore the app like a user.
> Read the accessibility snapshot, and use the roles and names you find there.
> Then write Playwright tests in `tests/` for these business flows:
> 1. Start a new chat, ask a question, get an answer, and see the new chat in the list.
> 2. Open an existing chat from the list, and see its history.
> 3. Rate an answer with 👍, refresh, and see the rating is still there.
>
> Use getByRole and getByLabel locators. Run the tests with `npx playwright test` until they pass.

Watch the browser: the agent clicks through your app.

### :pencil2: Accessibility

**Accessibility** (a11y) means that everyone can use the app: people who use a screen reader, people who can't use a mouse, people who see poorly or are color blind. 

The common standard is **WCAG 2.2**, level **AA**. Agents don't take care of it unless you ask.

1. **Keyboard only.** Put the mouse aside. Use `Tab`, `Shift+Tab` and `Enter`. Can you start a new chat, open an old one, ask a question, and rate the answer? Can you always see where you are?
2. **Lighthouse.** DevTools > **Lighthouse** > select only **Accessibility** > **Analyze page load**. What's the score? What did it find?
3. **Automated checks.** Ask the agent:

    > Add `@axe-core/playwright`, and write a Playwright test that checks the app for WCAG 2.2 AA violations, with a chat open. Fail on serious and critical violations. Run it.

4. **Fix.** Ask the agent to fix the violations, and to make the app fully usable with the keyboard. Also: does a screen reader announce the new answer when it arrives?

Automated tools find only part of the problems. Steps 1 and 2, done by a human, are still needed.


# Configuration guide

This guide describes the settings that the current version reads: `settings.json` and `workflows.json` in the same folder as this file. It is the one maintained guide; the package build copies it unchanged beside the packaged `settings.json`.

## General rules

### Packaged RAG

`rag/rag.exe` provides `prepare`, `index --replace`, `query` and `serve` commands.
`query` uses the configured `mode`, or `hybrid` when absent; `--mode` overrides it.
`--add` is not implemented. See `rag/OHJE-FI.md` in the package for command syntax.
`embedding.exe [--settings FILE]` uses the same startup component to start only
`application.rag.embeddingServer`. RAG mode must be `start` or `connect` so this
definition is available. It starts no backend, retrieval service or generation
server. It keeps the native arguments unchanged and stops only its own child.

`npm run package` also builds `rag/rag-service.exe` as an independent Node single
executable. It needs no installed Node, npm or PowerShell. The application still
calls RAG over HTTP. `settings.json` selects its executable and `--config` argument.
RAG reads `rag.config.json` beside its executable by default, regardless of cwd.
The build copies `rag/packaging/rag.distribution.json` unchanged to that location
and installs an empty knowledge index at the path it names (currently `initial_index/index.sqlite`):
`rag/packaging/empty_index/index.sqlite`, a valid index with no documents or chunks. The build refuses an
index with content; knowledge content is not delivered. The customer builds the own index (rag\OHJE-FI.md).
This is an explicit build-time seed, not a runtime restore: startup never
populates, replaces or repairs a customer's database. Change `database` and
restart RAG to use another compatible index. A missing/invalid index is an error.
No runtime build, model path, file size, SHA or historical probe fingerprint is
required to open or rebuild an index. Vector encoding/dimensions and readable
SQLite data remain necessary. Rebuild embeddings when changing the embedding
model; changing a llama-server version alone does not require a rebuild.
RAG loads the index into memory: replacing the file takes effect after restart,
not during an active request. An absent seed does not block packaging.
Source knowledge and `rag/output` scripts are not included or removed.
The complete build must include the configured embedding runtime and model as
well as the generation runtime and models. The current distribution settings
select the E2B Vulkan configuration and E5 CPU configuration.

Packaging does not require branding. Apply `branding/apply-brand.mjs` explicitly
only when updating the brand. Package file hashes, copy comparisons and runtime
binary inspection are off by default; `npm run package -- --verify-files` opts
into these build-time checks. MANIFEST.json is inventory, not a startup gate.
The normal package build replaces its output folder; use a fresh `--out` for
packages with user data. RAG-only packaging preserves existing config/database.

`mode: "hybrid"` selects retrieval. `acceptance.score: "cosine"` with `min: 0.86`
selects the provisional filter; `"hybrid"` is not an acceptance score.

### Shared configuration rules

- **When changes take effect.** Both files are read once when the application starts. Restart it after an edit (Ctrl+C, then start again). There is no hot reload. A run keeps the settings it started with.
- **Strict validation.** Unknown keys, wrong types, out-of-range values and missing required keys stop the start with a message that names the key. Nothing is guessed or filled in. There are no hidden defaults: every key listed as required must be written.
- **Paths.** A relative path resolves against the file that contains it (`settings.json` or `workflows.json`). An absolute path is used as written. llama-server runs with the folder of `settings.json` as its working directory, so a relative model path in its `args` (for example `models/x.gguf`) means a file beside `settings.json`.
- **Command line.** `--settings FILE` selects another settings file (development `node start.mjs --settings FILE`, package `ticket-demo.cmd --settings FILE`). `ticket-demo.exe --serve` starts only the HTTP backend.
- **Environment.** `LLAMA_API_KEY` is read (sent as a bearer token when llama-server runs with `--api-key`). Credentials never go into the files.
- **Model trace (development only).** `TICKET_DEMO_MODEL_TRACE=1` in the environment of the start (exactly `1`; unset or any other value = off) makes the backend write every model call of the workflows to `model-trace\model-trace-<UTC start time>-<pid>.jsonl` beside settings.json: one JSON line per event with `seq`, `time`, `runId`, `workflow`, `role` (call id), `callId`, `event` (`request`, `response`, `error`) and `endpoint` (`/apply-template`, `/tokenize`, `/completion`). A request holds the body exactly as sent; a response holds the HTTP status and the raw answer body as received (for the streamed `/completion` the raw event stream and `stream`: `final`, `no-final-chunk`, `error-event` or the abort error), before the application parses it. No HTTP headers or credentials are written; free chat is not traced. The file contains the deviation descriptions: enable it only for testing and delete the files afterwards. `model-trace/` is ignored by Git.
- **Version.** Settings only select behaviour that the running version implements. For example, `auth.mode` `"none"` works only with a version built with it; editing `settings.json` does not add the capability to an older `ticket-demo.exe`.

## settings.json

Top level: `application` (object, required) and `servers` (array, required, at least one entry). No other keys.

### Application and selection

| Key | Purpose | Values | Required |
|---|---|---|---|
| `application.server` | The server definition used: its `url` always; its `executable` and `args` in `start` mode | an `id` from `servers` | yes |
| `application.modelServer` | `"start"`: the startup starts the selected llama-server, then the application. `"connect"`: it starts only the application and uses a llama-server that is already running | `"start"`, `"connect"` | yes |
| `application.workflowFile` | The workflow file | path, normally `"workflows.json"` (the package requires this name) | yes |
| `application.workflow` | The workflow, or the set of workflows the user chooses from, without a restart | an `id` in the workflow file, or a list of unique `id`s; no default among them. Each one is validated at start with its own export target; slots and context are checked at each run against the running server | yes |
| `application.probeMs` | Timeout of readiness and status probes to llama-server (`/health`, `/props`, `/v1/models`), and of each readiness check during start | integer 100-60000 (ms) | yes |

### Network and access

| Key | Purpose | Values | Required |
|---|---|---|---|
| `application.listen.host` | Address the application listens on | a host name or IP address; `"127.0.0.1"` for this computer only; a LAN address or `"0.0.0.0"` (all interfaces) needs `auth.mode` `"none"` | yes |
| `application.listen.port` | Port of the application | integer 0-65535 (0 = any free port; for tests) | yes |
| `application.auth.mode` | Authentication mode | see below | yes |

`auth.mode` values:

| Value | State | Meaning |
|---|---|---|
| `"local"` | supported | One local user. `listen.host` must be a loopback address (`127.0.0.1`, `localhost`, `::1`); requests must come from this computer with a loopback `Host` header. |
| `"none"` | supported | No authentication, for a trusted private network. Any listen address. Every request is accepted and all users share one identity: there is no user separation, every user can see and cancel the shared jobs. Access relies on network restrictions (firewall, private network). No login, token or identity provider. |
| `"oidc"`, `"trusted-proxy"` | reserved, not implemented | The start stops with a message before any process starts. |
| any other value | invalid | The start stops with a validation message. |

Address separation: `listen.host` is where the application listens; the browser uses this computer's own address (for example `http://192.168.137.184:3000/`), never `0.0.0.0`. The model-server `url` is separate; with llama-server on the same computer it can stay `http://127.0.0.1:8080`. The browser talks only to the application, which forwards chat and model requests to llama-server.

### User interfaces and capacity

| Key | Purpose | Values | Required |
|---|---|---|---|
| `application.ui.integrated` | Folder of the integrated UI (chat and tickets) served at `/` | path or `null` (not served; `/` then redirects to `/standalone/`). Development `"../tools/ui/dist"` (build it with `npm run build` in `tools/ui`), package `"ui"` | yes |
| `application.ui.standalone` | Folder of the standalone ticket view served at `/standalone/` | path or `null`. Development and package `"public"` | yes |
| `application.capacity.maxActiveJobs` | Workflow runs and chat generations running at the same time (all users together) | integer 1-64 | yes |
| `application.capacity.queueLength` | Jobs that may wait; a full queue answers `QUEUE_FULL` | integer 0-1000 | yes |

`maxActiveJobs` counts jobs; the calls inside one workflow run are limited separately by the workflow's `maxConcurrentCalls`, and llama-server's own slots (`-np`) are a third, separate setting.

### Accepted tickets

| Key | Purpose | Values | Required |
|---|---|---|---|
| `application.tickets.directory` | Folder where "Hyväksy ja tallenna" writes accepted tickets, on the computer that runs the application (not the browser's computer) | path, or `null` (saving is off: the save action is disabled and `POST /api/tickets` answers `TICKETS_DISABLED`). Development and package `"tickets"` | yes |

- **Path.** A relative path resolves against the folder of `settings.json`: development `ticket-demo\tickets\`, package `tickets\` beside `ticket-demo.exe`. An absolute path (for example a shared network folder) is used as written. The folder is created on the first save. The browser never sends or chooses a path.
- **Files.** One file per accepted ticket, `<submission id>.json` (UTF-8 JSON). The file is created exclusively and is never replaced. A repeated save of the same draft (double click, retry after a lost answer) returns the ticket that already exists; the same draft with other content is refused (`TICKET_CONFLICT`).
- **Validation.** The application checks the submitted values against the selected workflow's field definitions (types, allowed values, required text) and the source text against the workflow's `inputs`. A failed check writes nothing and answers `TICKET_INVALID` with the problems per field.
- **Content.** `format` `"manugenius-deviation-ticket"`, `formatVersion` `1`, `ticketId` (assigned by the application, `PK-YYYYMMDD-XXXXXX`), `savedAt` (UTC), `workflow` (`id`, `workflowHash`, `settingsHash`), `generation` (`origin`, `runId`, `model`, `promptVersion`, `generatedAt` as the run result gave them to the browser), `source` (the description and the user's answers to model questions), `fields` (the values the user accepted), `aiSuggestionFields` (fields whose definition has `"aiSuggestion": true`, the same mark that highlights them in the view; it states the field's purpose, not the origin or correctness of a value), `modelDraft`, `editedFields` and `reviewedFields`. With Excel export on for the workflow, also `export` (see "Excel register export").
- **Not included.** No user identity: with `auth.mode` `"local"` or `"none"` there is no authenticated operator. The work-context values of the "Alkutiedot" panel are a UI example and are not saved.
- Saved files are audit records. They are not automatically training data.

### Excel register export (`application.export`)

Optional. After the ticket JSON is saved, the application adds the accepted values as **one new row** of a named Excel table in one shared `.xlsx` register. It does not make one Excel file per ticket. The JSON file stays the original record; the export never changes it. The export program is `ticket-export.exe` (Go, [../ticket-export/](../ticket-export/README.md)); the application starts it as a direct child process for each attempt (no shell, not a service). Request, result and exit codes: [../ticket-export/CONTRACT.md](../ticket-export/CONTRACT.md).

| Key | Purpose | Values | Required |
|---|---|---|---|
| `application.export` | Export on or off | object, or `null`. Absent or `null` = off (default in both repository settings files; existing installations keep their behaviour) | no |
| `export.program` | The export program | path; relative to `settings.json`. Package: `"ticket-export.exe"` (beside `ticket-demo.exe`). Development: `"../ticket-export/bin/ticket-export.exe"` after `go build -o bin/ticket-export.exe .` in `ticket-export/` | yes |
| `export.timeoutMs` | Time limit of one export attempt; the application then stops the process | 1000–600000 | yes |
| `export.lockWaitMs` | How long one attempt waits for another export of the same register | 0–600000, smaller than `timeoutMs` | yes |
| `export.targets[]` | One target per workflow | list; a workflow without a target exports nothing | yes |
| `targets[].workflow` | Workflow id | id of a workflow in `workflows.json` | yes |
| `targets[].kind` | Destination kind | `"excel"` (the only kind) | yes |
| `targets[].file` | The register workbook | path to an existing `.xlsx`; relative to `settings.json`; an absolute or network path is used as written | yes |
| `targets[].sheet` | Sheet that holds the table | sheet name | yes |
| `targets[].table` | Named Excel table (Excel: Table Design → Table Name) | table name | yes |
| `targets[].technicalColumns` | Column headers of the export's own values | object with `exportId`, `contentHash`, `ticketId`, `savedAt` (all four) | yes |
| `targets[].fieldColumns` | Field id → column header | object; keys are field `id`s of the workflow (never the UI `label`) | yes |
| `targets[].omitFields` | Fields that are deliberately not exported | list of field `id`s | yes (may be `[]`) |

Example (copy into `application`; it matches the example register `examples\poikkeamarekisteri-esimerkki.xlsx` and the workflow `single-call`): [../ticket-export/examples/export-settings.example.json](../ticket-export/examples/export-settings.example.json).

- **Checks at start.** The settings reader checks the target of the selected workflow: every field of the workflow is in exactly one of `fieldColumns` or `omitFields`; no unknown field id; no column header twice (case is ignored). A new field in `workflows.json` therefore stops the start until it is mapped or omitted. A text-result workflow cannot have a target. Missing program or register files give a start-up warning, and each export then fails with its reason.
- **Supported register.** One `.xlsx` workbook (no `.xlsm`, no macros) with a named table on the named sheet. The table has a header row, no totals row and no calculated columns (no formulas in table columns). Every mapped header exists in the table with the same text. The table may have more columns (for example "Käsittelijä"); the new row leaves them empty. The row below the table must be empty, so the table can grow. The application never adds, removes or renames columns and never repairs the structure.
- **Row.** The row goes after the last used row of the table, and the table range (with its filter range) grows by that row. A new table's empty first row is used first. The new row takes the cell formats of the row above. Other sheets, earlier rows and the rest of the workbook stay as they are.
- **Values.** Text is written as a text cell: leading zeros, measurement texts and text that starts with `=` stay text. A JSON number (a field of type `number`) becomes a number cell. `null` and empty text are both an empty cell; the JSON record keeps the difference. Line breaks and Unicode stay as written. Text longer than an Excel cell (32767 characters) fails the export with `VALUE_TOO_LONG`; nothing is truncated. `savedAt` is written as text in the local time of the backend computer with its UTC offset (ISO 8601, for example `2026-10-29T00:12:55+02:00`); the ticket JSON and the export state files keep UTC (`Z`).
- **Technical columns.** `exportId` is a UUID made when the ticket is approved; `contentHash` is `sha256:` plus the hash of the exported values. A retry finds its row by `exportId`: the same id and hash means "already exported" (no new row), the same id with another hash is `EXPORT_CONFLICT` (nothing is changed). Do not edit these two columns.
- **Resolved at approval.** The ticket JSON stores `export`: `exportId`, `target` (`kind`, absolute `file`, `sheet`, `table`), `columns`, `omittedFields` and `contentHash`. A retry uses these stored values; a later settings change does not move or remap an approved ticket. The program path, `timeoutMs` and `lockWaitMs` come from the current settings.
- **State.** `<tickets.directory>\export-status\<submission id>.json` holds the state of each export (`running`, `exported`, `failed`, number of attempts, row, error code and technical message). A state file that says `running` after a restart is reported as interrupted (`EXPORT_INTERRUPTED`). A ticket with `export` and no state file never started.
- **Locking.** Exports of one register run one after another: the application queues them, and `ticket-export` holds `<register>.ticket-export.lock` without sharing while it writes, so another export process waits up to `lockWaitMs` (on a network share this relies on the file server's sharing rules; not tested). Windows releases the lock when the process ends; the lock file may stay and can be deleted when no export runs. The register is written to a temporary file `~ticket-export-*.tmp` in the same folder and then replaces the register; the register is never written in place. An open workbook (Excel), a read-only file or a missing write permission fails the attempt with a retryable error. The application never removes another program's lock or an Excel owner file (`~$...`).
- **Retry.** There is no automatic retry. The view shows "Yritä Excel-vientiä uudelleen" for a failed or interrupted export; `POST /api/tickets/<submission id>/export` starts one new attempt with the same export id. `GET /api/tickets/<submission id>/export` returns the state. Both use the same identity boundary as the other API routes; the browser names only the submission id.
- **Not included.** No SharePoint upload, no Power BI refresh and no other destination. A register on a network share is an ordinary file write.

### Server definitions (`servers[]`)

| Key | Purpose | Values | Required |
|---|---|---|---|
| `id` | Name used by `application.server` | lower-case letters, digits and `-`, starting with a letter or digit, at most 41 characters; unique | yes |
| `url` | Address of llama-server that the application calls | `http://host:port` (or `https://`) | yes |
| `description` | Free text; never interpreted | string | no |
| `executable` | `llama-server.exe` to start | path | only for the selected server in `start` mode |
| `args` | Native llama-server arguments | array of strings | only for the selected server in `start` mode |

- `args` are passed to llama-server unchanged, one array item per argument, with no quoting, translation or additions. Typical ones: `-m` model file, `--model-draft` draft model, `--device`, `-ngl`, `-np` (slots), `-c` (total context; per-slot context = `-c` / `-np`), `-t`, `--host`, `--port`. The selected executable's `llama-server --help` describes the options it supports; this guide does not repeat them.
- A JSON value inside an argument is written as an escaped string, for example `"--chat-template-kwargs", "{\"enable_thinking\":false}"`; a backslash is written twice (`"per_layer_token_embd\\.weight=CPU"`).
- Keep `url` consistent with `--host`/`--port` in `args`. In `start` mode a mismatch is printed as a warning; nothing is changed.
- Slots and per-slot context are read from the running llama-server (`/props`). A workflow whose `maxConcurrentCalls` is above the reported slots fails at run start (`SLOTS_MISMATCH`).

### Start versus connect

`application.modelServer` controls the generation server independently of
`application.rag.mode`. To start both locally, set both to `"start"`.
To start generation without RAG, use modelServer `"start"` and rag.mode `"off"`.
If port 8080 reports `ECONNREFUSED` with modelServer `"connect"`, start that server
separately or select `"start"`; changing RAG mode does not start it. Restart
`npm start` after changing settings. No package rebuild is needed for development.

- `"start"`: before anything is started, the startup checks the settings and the workflow, the authentication mode and listen address, that the listen port is free, and that the selected server's `executable` and its model files (`-m`/`--model`, `-md`/`--model-draft`) exist. If a server already answers at the selected `url`, the start stops: it never reuses, stops or replaces that server. Otherwise llama-server starts (log: `logs/llama-<time>.log` beside `settings.json`), the startup waits for `/health`, then starts the application. Ctrl+C stops only these two processes.
- `"connect"`: no llama-server is started and no local inference files are needed; the application connects to `url`. A llama-server started separately keeps running when the application stops.
- Only the selected server is checked. Other server definitions may name files that do not exist on this computer.

### RAG retrieval (`application.rag`)

Optional knowledge retrieval for calls with a `rag` budget (workflows.json). The retrieval service is the separate
RAG component (repository-root `rag/`, `scripts/serve.mjs`); its own `rag.config.json` selects the index, the
embedding model, the retrieval mode, the candidate count, topK (a maximum) and the relevance acceptance policy
(`rag/OHJE-FI.md`). The backend sends only the query and never imports RAG code.

| Key | Purpose | Values | Required |
|---|---|---|---|
| `mode` | `"off"`: no retrieval. `"connect"`: call a running service at `url`. `"start"`: the startup also starts the processes below | string | yes (absent `rag` = off) |
| `url` | RAG service address (`POST /retrieve`, `GET /health`) | `http://host:port` | yes |
| `requestTimeoutMs` | Limit of one retrieval request | 1000-120000 | yes |
| `readyTimeoutMs` | `start`: limit for each started process to answer `/health` with 200 | 1000-600000 | no (120000) |
| `embeddingServer` | `start`: optional embedding llama-server: `{ executable, args, url }` | object or null | no |
| `service` | `start`: the RAG service: `{ executable, args, url }`; `url` must equal `rag.url` | object or null | for `start` |

- **Retrieval in a run.** One lookup per run, from the user's inputs and clarification answers, before the model calls. It uses the run's cancel and timeout. Only the passages the service accepted are offered to the calls with a `rag` budget: `source_data.knowledge_notes` (`source-data-json`) or the call's knowledge input (`sections`). User facts and `approved_context` do not change. Each call selects passages for itself; the accepted passages are not changed.
- **Empty retrieval.** Zero accepted passages is a successful lookup (`retrieval.state` `"empty"`): the calls run with no knowledge, exactly as without RAG, and the view shows "Ei riittävän osuvaa tietopohjaohjetta".
- **Failure.** An unavailable, overloaded, rejected or timed-out lookup fails the run with `RAG_*`. The view offers "Yritä tietopohjahakua uudelleen" and "Jatka ilman tietopohjaa" (`/api/run` body `"rag": "skip"`). A failed lookup is never shown as RAG assistance.
- **Evidence.** The run result and the saved ticket (`retrieval`) keep every accepted passage with its exact text, id, source lines, `process`, `document_type`, warnings, scores and acceptance decision; per RAG call (`calls[]`) which passages reached the model, which token limit left the others out and the token counts; the candidates the service rejected with the reason (`below_relevance_threshold`, `process_mismatch`, `duplicate`, `beyond_top_k`), without text; and the service identity with its acceptance policy.
- **start.** The executables and model files are checked and the `url`s must not answer before anything starts. Each process starts hidden in the folder of `settings.json` (relative paths in `args` resolve there; a bare `executable` such as `node` is found in PATH), with a log in `logs/`, and must answer `/health` with 200 within `readyTimeoutMs`. Order: model server (`modelServer` `"start"`), embedding server, RAG service, backend. A failure or Ctrl+C during startup stops the processes this startup started. If an own RAG process exits later, the startup stops the other own RAG process only; the backend and the model server keep running and report retrieval as unavailable.

### Retrieved passages in free chat (`application.chatRetrieval`)

Shared budget of retrieved passages for a chat request (`src/chat-retrieval.js`). Absent = chat retrieval off. A
chat request without a retrieval source is forwarded unchanged. Sources (both need `application.rag` not `off`):
`rag`, the central knowledge base with the service's own acceptance decisions ("Käytä tietopohjaa" in the + menu,
off by default, a browser chat preference); and `documents`, the conversation's attached `.txt`/`.md` files in
"Hae tiedostosta" mode (the default for those files). Current values: 1024 / 128 / 768, shares 512 / 256.

| Key | Purpose | Values | Required |
|---|---|---|---|
| `responseTokens` | Response reserve of a request without its own positive `max_tokens`; also sent as its `max_tokens` | integer >= 1 | yes |
| `marginTokens` | Safety margin in the context check | integer >= 0 | yes |
| `maxKnowledgeTokens` | Optional cap of the passage tokens, common to all sources | integer >= 1 or null | no (null: only the slot context limits) |
| `sourceShares` | Target shares of the cap when `documents` and `rag` are used together: `{ "documents": 512, "rag": 256 }`. Flexible: each source first fills its share in its own rank order, then the room left goes to the remaining passages of both. One source alone may use the whole cap. Sum <= `maxKnowledgeTokens` | object | no (absent: no shares) |

- **Conversation documents.** The browser reads the file; the backend sends the text to the RAG service (`POST /documents`) under an owner key of the identity and the conversation id. The service parses it (Markdown or plain text), chunks it with the chunking settings of the served index, skips and reports chunks over the embedding model's token limit, and embeds it once. It keeps documents in memory only, never in the index database: at most 200000 characters and 400 chunks per document, 5 per conversation, 100 in all, one processing at a time, removed after 4 hours unused. "Poista hausta", a deleted conversation and a restart remove them; after a restart the chat registers the document again from its own copy before the next question. Search per question: hybrid ranking over the active documents, at most 5 chunks, accepted at or above the median cosine of the query over the searched chunks (no process filter, not the knowledge-base threshold). Locations are file name and line numbers of the attached text. Office documents (`.docx`, `.pptx`, `.xlsx`, `.xls`, `.msg`) are converted to Markdown on upload (`POST /api/chat/convert`, all files of one upload in one [markitdown](../markitdown/README.md) run; it takes several seconds) and are then text attachments in either mode. The converter has a fixed location, no setting: `markitdown\markitdown-cli.exe` beside ticket-demo.exe (development: repository root). PDF and other formats keep the earlier behaviour (whole text or images).
- **Continuation.** "Jatka" sends the exact passages the answer used again (source `reuse`, body `retrieval_reuse`), budgeted anew, with no new retrieval. If they are not available or do not all fit (HTTP 409), the chat asks before a continuation without them. Each continuation has its own evidence.

- **Context limit.** The per-slot context that the running server reports (`/props`, from `-c` and `-np` of the server definition). There is no separate chat context setting.
- **Budget.** The complete templated request is counted with the generation server's tokenizer. Condition: count + calibration delta (shared with the workflow calls) + response reserve + `marginTokens` <= slot context. If the question and the conversation do not fit without passages, the request is refused (HTTP 413, `exceed_context_size_error`); nothing is removed.
- **Passages.** Whole passages in rank order, after the user's text in the last user message, framed as untrusted source material. A passage that does not fit, or that is incomplete, contains special-token text or the frame delimiter, is omitted whole and never cut.
- **Request.** Headers `X-Retrieval-Source` (a source of `GET /api/chat/retrieval`), `X-Conversation-Id` and `X-Message-Id` (the assistant message). Body field `retrieval_query`: the user's own text of the question (it must equal that text; never forwarded). The answer header `X-Retrieval-State` is `used`, `none_fit` or `empty`. A failed lookup answers with `error.retrieval_failed` (`RAG_*`) and generates nothing; the chat offers "Yritä uudelleen" and "Jatka ilman tietopohjaa" (that request only).
- **Evidence.** `GET /api/jobs/:id` (owner only) returns `evidence`: owner, conversation, message, completion id, outcome (`done`, `cancelled`, `failed`) and per passage the id, origin, exact text, rank order, prompt position, `sentToModel` and the omission reason. The backend keeps it in memory with the job (the last 100 finished jobs); the chat saves it with the answer in the browser's chat database ("Lähteet (n)") and never sends it to the model.
- **Calibration.** Reported prompt tokens: `usage.prompt_tokens`, else `timings.cache_n + prompt_n` of the last stream chunk.

## workflows.json

Top level: `{ "workflows": [ ... ] }`. Each workflow needs an `id`; only the selected workflow is validated in full, so an unfinished workflow does not block the others.

### Workflow

| Key | Purpose | Values | Required |
|---|---|---|---|
| `id` | Name used by `application.workflow` | same rule as server ids; unique | yes |
| `description` | Free text, shown in the UIs | string | yes |
| `inputs` | Texts the user writes | array of `{ "id", "label", "maxChars", "placeholder" }`; `id` lower-case letters, digits, `_`; `maxChars` 1-100000; `label` is the visible and accessible name of the text area; optional `placeholder` (1-200 characters) is an example shown in the empty text area. The UIs support exactly one input | yes |
| `ui` | Texts of the ticket view that depend on the workflow's purpose (below) | object | no (defaults) |
| `timeoutMs` | Time limit of one run | integer 1000-600000 | yes |
| `maxConcurrentCalls` | Calls of one run in flight at once | integer 1-16; must not exceed the server's slots | yes |
| `fields` | Result fields of a structured workflow | array of field definitions (below); omit for a plain-text workflow | no |
| `calls` | Model calls | array (below), at least one | yes |
| `result.text` | Plain-text workflow: the call whose text is the result | call id | for a workflow without `fields` |
| `result.questions` | Questions to the user (below) | object | no |

**Plain-text versus structured.** Without `fields` the workflow is plain text: calls have no `response`, the result is the text of `result.text`, and the UIs show it read-only. With `fields` it is structured: every call has a `response`, all responses are the same kind, every field is owned by exactly one call, and the UIs show an editable form with approval.

### Fields (`fields[]`)

| Key | Purpose | Values | Required |
|---|---|---|---|
| `id` | Field name in the result | letters, digits, `_`, starting with a letter | yes |
| `type` | JSON type | `"string"`, `"number"`, `"null"` or an array of them (`["string", "null"]` = may be empty) | yes |
| `enum` | Allowed values | array (strings, numbers, `null`) | no; required with `control` `"enum"` |
| `minLength`, `maxLength` | Text length limits | integers | no |
| `description` | Guidance to the model (JSON schema and field guidance); not shown in the UI | string | no |
| `label` | Field label in the form | string | yes |
| `control` | Form control | `"text"`, `"area"`, `"enum"` | yes |
| `enumLabels` | Display names of enum values | object; keys must be `enum` values | no |
| `section` | Form section heading; sections appear in the order of their first field | string | yes |
| `help` | Help text for the user, shown under the field label and linked to the control (`aria-describedby`). Only text: it does not mark the field as a model suggestion | string | no |
| `aiSuggestion` | The field's purpose is a model suggestion or assessment, not a recorded fact: the view marks this field ("Mallin ehdotus") and saved tickets list it in `aiSuggestionFields` | `true`/`false` | no (false) |
| `width` | Layout wish in the integrated view | `"auto"`, `"half"`, `"full"` | no (`"auto"`) |

**Model-facing versus presentation keys.** `type`, `enum`, `minLength`, `maxLength` and `description` form the JSON Schema (json_schema, field guidance, backend validation). `label`, `control`, `enumLabels`, `section`, `help`, `aiSuggestion`, `width`, the input `placeholder` and the `ui` block are presentation only: they never reach the JSON Schema or a prompt, and the browser receives every field key except `description`.

**`help` versus `aiSuggestion`.** Mark a field with `aiSuggestion` when its value is the model's own suggestion or assessment (for example a suggested action or the model's confidence), not a fact taken from the description. Adding or removing `help` never changes this; the application never infers the mark from the field id or the help text. A section may mix marked and unmarked fields; only the marked ones are highlighted.

**Layout and order.** Fields appear in the order of `fields`. Sections (`section` is the heading and the grouping key) appear in the order of their first field. In the integrated view on a wide screen `"full"` uses the whole row, `"half"` half of it (two consecutive half fields share a row), and `"auto"` is `"full"` for `control` `"area"` and `"half"` for `"text"` and `"enum"`. On a narrow screen every field uses the whole width. The value never changes the width: long text wraps (`area`) or scrolls inside the control (`text`). Review notes stay inside their field. Colours, typography and spacing belong to the application; configuration cannot add CSS or HTML. The standalone view shows one column and ignores `width`.

Every listed field is required in the result and no other field is allowed. The fields `standardised_issue_summary`, `detailed_cause` and `outcome_description` must also not be blank when present (fixed in code).

### View texts (`ui`)

All keys are optional. Defaults (`public/fields.js` `UI_DEFAULTS`) are neutral; the four ticket workflows set the approved deviation texts.

| Key | Purpose | Values | Default |
|---|---|---|---|
| `title` | View heading and browser title | 1-80 characters | `"Tikettikirjaus"` |
| `introTitle` | Heading of the empty view | 1-120 characters | `title` |
| `intro` | Text of the empty view | 1-400 characters | `"Kirjoita kuvaus alla. Malli tekee tikettiehdotuksen, jonka tarkistat ja tallennat itse."` |
| `generateLabel` | Main action under the description | 1-40 characters | `"Luo tikettiehdotus"` |
| `newLabel` | Action after a saved ticket | 1-40 characters | `"Uusi tiketti"` |

General actions, status and error messages ("Hyväksy ja tallenna", "Hylkää luonnos", "Ajotiedot", ...) are application texts and are not configurable. An unknown key, an empty text or a text over its limit stops the start with a message such as `workflows.json "x"/ui: unknown key "subtitle"` or `.../fields/2/width: must be equal to one of the allowed values (auto, half, full)`.

**Example: the same view for another purpose, by configuration only** (restart applies it). The test fixture `test/fixtures/variant-workflows.json` is a complete example (a maintenance request).

```json
"inputs": [{ "id": "request_text", "label": "Huoltopyynnön kuvaus", "maxChars": 2000, "placeholder": "Mikä laite, mikä vika ja onko käyttö estynyt?" }],
"ui": { "title": "Huoltopyyntö", "generateLabel": "Luo huoltopyyntö", "newLabel": "Uusi huoltopyyntö" },
"fields": [
  { "id": "equipment_name", "type": "string", "label": "Laite", "control": "text", "section": "Kohde", "width": "half", "help": "Laitteen nimi tai tunnus konekilvestä." },
  { "id": "urgency", "type": ["string", "null"], "enum": ["stop", "soon", null], "enumLabels": { "stop": "Käyttö estynyt", "soon": "Tällä viikolla" }, "label": "Kiireellisyys", "control": "enum", "section": "Kohde" },
  { "id": "repair_hint", "type": ["string", "null"], "label": "Korjausvihje", "control": "area", "section": "Vika ja korjaus", "aiSuggestion": true }
]
```

### Calls (`calls[]`)

| Key | Purpose | Values | Required |
|---|---|---|---|
| `id` | Call name | lower-case letters, digits, `_` | yes |
| `prompt` | Prompt file, relative to `workflows.json` | path | yes |
| `promptFormat` | How inputs are added to the prompt | `"sections"` (default): prompt, then `label` and text per input, separated by blank lines. `"source-data-json"`: prompt, then a JSON object `{source_data, derived_data}` | no |
| `inputs` | What the call receives | array of `{ "from": inputId, "label", "quoted": true/false }` (`quoted` wraps the text in double quotes) or `{ "fromFields": [fieldIds], "label" }` (values from earlier calls). `"sections"` needs `label` on every input; `"source-data-json"` takes no `label`/`quoted` and at most one `fromFields` | yes |
| `dependsOn` | Calls that must finish first | array of call ids declared earlier; `fromFields` may only use fields of these calls | no (none) |
| `response` | How the reply is read | `{ "format": "json" }` (all fields, constrained JSON), `{ "format": "json", "fields": [...] }` (those fields), `{ "parse": "field-lines", "fields": [...] }` (`field: value` lines, reviewable draft). Omit for plain text | for structured workflows |
| `fieldGuidance` | Append the field descriptions to the prompt | `true`/`false`; needs a JSON response | no (false) |
| `maxInputTokens` | Fixed input limit of this call | integer >= 1; also `maxInputTokens + n_predict + marginTokens` must fit the per-slot context | no (input + `n_predict` + margin must fit the per-slot context) |
| `marginTokens` | Safety margin in the context check | integer >= 0 | no (0) |
| `rag` | Budget with RAG on: `{ "maxInputTokens", "maxKnowledgeTokens" }`. Accepted passages are added whole in rank order while the added tokens stay within `maxKnowledgeTokens` and the whole input within `maxInputTokens`; others are omitted and shown. Counted with the model server's tokenizer on the templated request. Without passages the call's own limit applies (`maxInputTokens`, else the per-slot context) | `"source-data-json"`: passages in `knowledge_notes`; `"sections"`: exactly one input `{ "knowledge": true, "label": "..." }`, rendered only when there are passages; `rag.maxInputTokens >= maxInputTokens` when set; `rag.maxInputTokens + n_predict + marginTokens` must fit the per-slot context | no |
| `generation` | Settings sent to llama-server for this call | object (below) | yes |

**Dependencies and concurrency.** Calls start in declaration order as soon as their `dependsOn` are done, at most `maxConcurrentCalls` at once. The first failure stops the run and aborts running calls. Input is never truncated: a too long input is refused.

**Result handling.** JSON calls: the replies are merged by field ownership and validated; any problem fails the run. Field-line calls: the draft is assembled with review notes for missing, conflicting or not-allowed values; they must be reviewed before approval.

### Generation (`calls[].generation`)

`n_predict` (integer 1-8192) is required and is the only output-token limit; the context checks use it. Every other key is optional and sent only when written: `temperature`, `dynatemp_range`, `dynatemp_exponent`, `top_k`, `top_p`, `min_p`, `typical_p`, `top_n_sigma`, `xtc_probability`, `xtc_threshold`, `repeat_last_n`, `repeat_penalty`, `frequency_penalty`, `presence_penalty`, `dry_multiplier`, `dry_base` (>= 1), `dry_allowed_length`, `dry_penalty_last_n`, `dry_sequence_breakers`, `mirostat` (0, 1, 2), `mirostat_tau`, `mirostat_eta`, `adaptive_target`, `adaptive_decay`, `min_keep`, `samplers`, `seed` (integer; omit for a random seed), `ignore_eos`, `stop`, `cache_prompt`. An unwritten key uses llama-server's own default. Browser requests cannot change these values.

### Questions (`result.questions`)

| Key | Purpose | Values | Required |
|---|---|---|---|
| `call` | Call that asks the questions | call id | yes |
| `heading` | Name of the questions in that call's reply | name that is not a field id | yes |
| `max` | Questions shown | integer 1-10 | yes |
| `answers` | `"rerun"`: answers are added to `source_data` and the whole workflow runs again (JSON responses only). `"store"`: answers are only stored with the record (field-line responses only) | `"rerun"`, `"store"` | yes |
| `description`, `maxLength` | `"rerun"` only: guidance and length of each question in the JSON schema | string, integer | no |

Answer limits are fixed in code: at most 6 answers, 300 characters per question and 1000 per answer.

## Examples

Shortened: only the changed `application` keys and the selected server are shown.

**1. Local only (default).** Browser on the same computer: `http://127.0.0.1:3000/`.

```json
"application": { "listen": { "host": "127.0.0.1", "port": 3000 }, "auth": { "mode": "local" }, "modelServer": "start", "server": "gemma4-e4b-cuda0-4slot" }
```

**2. Application and llama-server on one computer, used from a laptop without authentication.** Start on the HP computer; open `http://<HP address>:3000/` on the laptop (for example `http://192.168.137.184:3000/`). llama-server stays on loopback; the server definition (its `url` `http://127.0.0.1:8080` and its `args`) is unchanged.

```json
"application": { "listen": { "host": "0.0.0.0", "port": 3000 }, "auth": { "mode": "none" }, "modelServer": "start", "server": "gemma4-e4b-cuda0-4slot" }
```

Instead of `"0.0.0.0"` (all interfaces) the HP computer's own LAN address can be written. `"none"` gives no authenticated user separation; anyone who reaches the address can use the application, so it relies on the network being restricted.

**3. Connect to a model server that is already running.** Start llama-server yourself (or keep it running), then start the application; no local llama-server or model file is needed.

```json
"application": { "modelServer": "connect", "server": "existing" },
"servers": [{ "id": "existing", "description": "started separately", "url": "http://127.0.0.1:8080" }]
```

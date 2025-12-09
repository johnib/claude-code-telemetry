# Claude Code OTLP Telemetry Schema

This document describes the raw OTLP telemetry data sent by Claude Code. Captured from version 2.0.62.

## Overview

Claude Code sends telemetry via OTLP HTTP to port 4318. The data includes:
- **Logs**: Event-based telemetry (tool usage, API requests, decisions)
- **Metrics**: Cumulative counters (cost, tokens, active time)

## Resource Attributes

All telemetry includes these resource-level attributes identifying the client:

| Attribute | Type | Description | Example |
|-----------|------|-------------|---------|
| `host.arch` | string | CPU architecture | `arm64` |
| `os.type` | string | Operating system | `darwin` |
| `os.version` | string | OS version | `24.6.0` |
| `service.name` | string | Always `claude-code` | `claude-code` |
| `service.version` | string | Claude Code version | `2.0.62` |

## Common Log Attributes

All log events include these attributes:

| Attribute | Type | Description |
|-----------|------|-------------|
| `user.id` | string | Hashed user identifier |
| `session.id` | string | UUID for the session |
| `organization.id` | string | Organization UUID |
| `user.email` | string | User email address |
| `user.account_uuid` | string | Account UUID |
| `terminal.type` | string | Terminal application (e.g., `WarpTerminal`) |
| `event.name` | string | Short event name |
| `event.timestamp` | string | ISO 8601 timestamp |

---

## Log Events

### 1. `claude_code.api_request`

Emitted after each API call to Claude.

**Event-specific attributes:**

| Attribute | Type | Description | Example |
|-----------|------|-------------|---------|
| `model` | string | Model used | `claude-opus-4-5-20251101` |
| `input_tokens` | string | Input token count | `372` |
| `output_tokens` | string | Output token count | `32` |
| `cache_read_tokens` | string | Tokens read from cache | `31133` |
| `cache_creation_tokens` | string | Tokens written to cache | `156` |
| `cost_usd` | string | Cost in USD | `0.0187215` |
| `duration_ms` | string | Request duration in ms | `845` |

**Sample:**
```json
{
  "timeUnixNano": "1765308150324000000",
  "observedTimeUnixNano": "1765308150324000000",
  "body": {
    "stringValue": "claude_code.api_request"
  },
  "attributes": [
    {"key": "user.id", "value": {"stringValue": "d05889..."}},
    {"key": "session.id", "value": {"stringValue": "53a31003-709a-4a68-b3ea-92f0f26e0bb6"}},
    {"key": "organization.id", "value": {"stringValue": "a3ac161e-b4c2-447d-989c-7db8462305a0"}},
    {"key": "user.email", "value": {"stringValue": "user@example.com"}},
    {"key": "event.name", "value": {"stringValue": "api_request"}},
    {"key": "event.timestamp", "value": {"stringValue": "2025-12-09T19:22:30.324Z"}},
    {"key": "model", "value": {"stringValue": "claude-haiku-4-5-20251001"}},
    {"key": "input_tokens", "value": {"stringValue": "372"}},
    {"key": "output_tokens", "value": {"stringValue": "32"}},
    {"key": "cache_read_tokens", "value": {"stringValue": "0"}},
    {"key": "cache_creation_tokens", "value": {"stringValue": "0"}},
    {"key": "cost_usd", "value": {"stringValue": "0.0005319999999999999"}},
    {"key": "duration_ms", "value": {"stringValue": "845"}}
  ]
}
```

---

### 2. `claude_code.tool_decision`

Emitted when a tool permission decision is made (accept/reject).

**Event-specific attributes:**

| Attribute | Type | Description | Example |
|-----------|------|-------------|---------|
| `tool_name` | string | Tool being authorized | `Bash` |
| `decision` | string | Decision made | `accept`, `reject` |
| `source` | string | How decision was made | `user_temporary`, `allowlist` |

**Sample:**
```json
{
  "timeUnixNano": "1765308148846000000",
  "observedTimeUnixNano": "1765308148846000000",
  "body": {
    "stringValue": "claude_code.tool_decision"
  },
  "attributes": [
    {"key": "user.id", "value": {"stringValue": "d05889..."}},
    {"key": "session.id", "value": {"stringValue": "53a31003-709a-4a68-b3ea-92f0f26e0bb6"}},
    {"key": "event.name", "value": {"stringValue": "tool_decision"}},
    {"key": "event.timestamp", "value": {"stringValue": "2025-12-09T19:22:28.846Z"}},
    {"key": "decision", "value": {"stringValue": "accept"}},
    {"key": "source", "value": {"stringValue": "user_temporary"}},
    {"key": "tool_name", "value": {"stringValue": "Bash"}}
  ]
}
```

---

### 3. `claude_code.tool_result`

Emitted after a tool execution completes.

**Event-specific attributes:**

| Attribute | Type | Description | Example |
|-----------|------|-------------|---------|
| `tool_name` | string | Tool executed | `Bash` |
| `success` | string | Whether tool succeeded | `true`, `false` |
| `duration_ms` | string | Execution time in ms | `632` |
| `tool_parameters` | string | JSON of tool params | `{"bash_command":"docker-compose",...}` |
| `tool_result_size_bytes` | string | Result size in bytes | `294` |
| `decision_source` | string | How permission was granted | `user_temporary` |
| `decision_type` | string | Permission type | `accept` |

**Sample:**
```json
{
  "timeUnixNano": "1765308149479000000",
  "observedTimeUnixNano": "1765308149479000000",
  "body": {
    "stringValue": "claude_code.tool_result"
  },
  "attributes": [
    {"key": "user.id", "value": {"stringValue": "d05889..."}},
    {"key": "session.id", "value": {"stringValue": "53a31003-709a-4a68-b3ea-92f0f26e0bb6"}},
    {"key": "event.name", "value": {"stringValue": "tool_result"}},
    {"key": "event.timestamp", "value": {"stringValue": "2025-12-09T19:22:29.479Z"}},
    {"key": "tool_name", "value": {"stringValue": "Bash"}},
    {"key": "success", "value": {"stringValue": "true"}},
    {"key": "duration_ms", "value": {"stringValue": "632"}},
    {"key": "tool_parameters", "value": {"stringValue": "{\"bash_command\":\"docker-compose\",\"full_command\":\"docker-compose up -d\",\"description\":\"Start docker-compose stack\"}"}},
    {"key": "tool_result_size_bytes", "value": {"stringValue": "294"}},
    {"key": "decision_source", "value": {"stringValue": "user_temporary"}},
    {"key": "decision_type", "value": {"stringValue": "accept"}}
  ]
}
```

---

## Metrics

All metrics are cumulative sums (monotonic counters) with `aggregationTemporality: 1` (cumulative).

### Common Metric Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `user.id` | string | Hashed user identifier |
| `session.id` | string | UUID for the session |
| `organization.id` | string | Organization UUID |
| `user.email` | string | User email address |
| `user.account_uuid` | string | Account UUID |
| `terminal.type` | string | Terminal application |

---

### 1. `claude_code.cost.usage`

Cumulative cost in USD.

| Attribute | Type | Description | Example |
|-----------|------|-------------|---------|
| `model` | string | Model name | `claude-opus-4-5-20251101` |

**Sample data point:**
```json
{
  "attributes": [
    {"key": "model", "value": {"stringValue": "claude-opus-4-5-20251101"}}
  ],
  "startTimeUnixNano": "1765308152946000000",
  "timeUnixNano": "1765308156654000000",
  "asDouble": 0.0187215
}
```

---

### 2. `claude_code.token.usage`

Cumulative token count.

| Attribute | Type | Description | Example |
|-----------|------|-------------|---------|
| `model` | string | Model name | `claude-opus-4-5-20251101` |
| `type` | string | Token type | `input`, `output`, `cacheRead`, `cacheCreation` |

**Sample data points:**
```json
[
  {
    "attributes": [
      {"key": "type", "value": {"stringValue": "input"}},
      {"key": "model", "value": {"stringValue": "claude-opus-4-5-20251101"}}
    ],
    "asDouble": 1
  },
  {
    "attributes": [
      {"key": "type", "value": {"stringValue": "output"}},
      {"key": "model", "value": {"stringValue": "claude-opus-4-5-20251101"}}
    ],
    "asDouble": 87
  },
  {
    "attributes": [
      {"key": "type", "value": {"stringValue": "cacheRead"}},
      {"key": "model", "value": {"stringValue": "claude-opus-4-5-20251101"}}
    ],
    "asDouble": 31133
  },
  {
    "attributes": [
      {"key": "type", "value": {"stringValue": "cacheCreation"}},
      {"key": "model", "value": {"stringValue": "claude-opus-4-5-20251101"}}
    ],
    "asDouble": 156
  }
]
```

---

### 3. `claude_code.active_time.total`

Cumulative active time in seconds.

| Attribute | Type | Description | Example |
|-----------|------|-------------|---------|
| `type` | string | Time type | `cli` |

**Sample data point:**
```json
{
  "attributes": [
    {"key": "type", "value": {"stringValue": "cli"}}
  ],
  "startTimeUnixNano": "1765308149520000000",
  "timeUnixNano": "1765308156654000000",
  "asDouble": 5.578
}
```

---

## Raw Data Capture

Raw OTLP data is captured to JSONL files (one JSON object per line):
- `otel-collector/logs/logs.jsonl` - Log events
- `otel-collector/logs/metrics.jsonl` - Metrics

These files capture data **before** any OTel Collector transformations.

**View captured data:**
```bash
# Pretty-print logs
tail -f otel-collector/logs/logs.jsonl | jq .

# Pretty-print metrics
tail -f otel-collector/logs/metrics.jsonl | jq .

# Extract unique event types
cat otel-collector/logs/logs.jsonl | jq -s '.[].resourceLogs[].scopeLogs[].logRecords[].body.stringValue' | sort -u
```

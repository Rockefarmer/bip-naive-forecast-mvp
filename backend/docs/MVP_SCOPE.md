# MVP Scope (Contract) — v1.0

> **Project:** TidanWolf Forecast App (Phase 1)  
> **Mode:** Build in Public | Research & Education Only | **Not investment advice**  
> **Status:** **LOCKED** (Week 2)

---

## 1) Purpose

Ship a minimal, trustable MVP that forecasts **quarterly fundamentals** for **three tickers** and explains *why* using **transcript evidence** — fast, minimal, and reproducible.

---

## 2) Hard Boundaries (Non-Negotiable)

- **Use case:** Research & education only. **Not investment advice.**
- **Phase 1 tickers only:** `AAPL`, `MSFT`, `NVDA`
- **Frequency:** Quarterly
- **Forecast horizon:** **Next 4 quarters** ✅ *(LOCKED)*
- **Metrics:** **Revenue** + **Net Income** (quarterly)

---

## 3) MUST Scope (What We Ship)

### 3.1 Two-Screen Flow
**Page A → Page B**

#### Page A — Search
- Search box (ticker input)
- 3 quick-pick buttons: **AAPL / MSFT / NVDA**
- Unsupported ticker → show: **“Not in Phase 1”** (no extra flow)

#### Page B — Forecast Details
- Single page renders: header + charts + “Why” + disclaimer

---

### 3.2 Header Block (Page B)
Show:
- Company name
- Ticker
- **Price**
- **Market cap**

---

### 3.3 Two Core Charts (Page B)
Two charts:
1) **Revenue**
2) **Net Income**

Each chart must include:
- **History line** (past quarters)
- **Forecast dashed line** (next 4 quarters)
- **80% interval shading** (lower/upper band)

---

### 3.4 One-Sentence Explanation (80% Band)
A single plain-language sentence explaining what the 80% range means.

Example:
> “The shaded 80% range means our model expects the result to land inside this band about 8 out of 10 times (based on historical patterns).”

---

### 3.5 “Why” Explainability (Strict Output + Evidence Only)
Output exactly:
- **2 tailwinds** (positive drivers)
- **1 headwind** (risk)
- **1 attribution sentence** (what drove revenue / net income movement)

**Evidence rule:** Every claim must include a **verbatim transcript quote**.  
If not supported → add to `unknowns` (no guessing).

---

### 3.6 Forecasting Baseline + Auto Fallback
- Baseline model: **ETS or SARIMA**
- **TFT when available**
- **Auto fallback rule:** if TFT fails/unavailable → return baseline forecast + intervals  
  (Page B must still render)

---

## 4) LOCKED Technical Parameters

1) **Data source:** **Financial Modeling Prep (FMP)** ✅ *(LOCKED)*  
   - quarterly financials, quote/meta, transcripts
2) **Chart library:** **Plotly** ✅ *(LOCKED)*
3) **Forecast horizon:** **Next 4 quarters** ✅ *(LOCKED)*

---

## 5) NOT NOW (Explicitly Out of Scope)

- User accounts / login / subscription system
- Community features (comments / follows / messages)
- Multi-stock comparison / portfolio analysis
- Complex candlestick charts & indicator dashboards (MACD/KDJ/etc.)
- Real-time quotes / intraday forecasting
- Macro / industry dashboards (rates/inflation/sector overview)
- Long research-report style interpretation / very long text output
- Training your own large model / on-device LLM
- Multi-device professional layouts (tablet/desktop “pro”)

---

## 6) Definition of Done (Acceptance Criteria)

For **each** ticker (`AAPL`, `MSFT`, `NVDA`), MVP is done when:
- Page A → Page B works end-to-end
- Header shows company/ticker/price/market cap
- Both charts render with **history + 4Q forecast + 80% band**
- “Why” outputs **exactly 2 + 1 + 1**, each with transcript quotes
- If TFT isn’t ready, baseline still produces forecasts + bands (**no blank states**)

---

## 7) API Contract v0 (Minimum Required for Page B)

**GET** `/v0/forecast?ticker=AAPL`

```json
{
  "ticker": "AAPL",
  "company_meta": {
    "name": "Apple Inc.",
    "price": 0.0,
    "market_cap": 0,
    "currency": "USD"
  },
  "series_history": {
    "revenue": [
      {"period_end": "YYYY-MM-DD", "value": 0.0}
    ],
    "net_income": [
      {"period_end": "YYYY-MM-DD", "value": 0.0}
    ]
  },
  "series_forecast": {
    "revenue": [
      {"period_end": "YYYY-MM-DD", "yhat": 0.0, "p10": 0.0, "p90": 0.0}
    ],
    "net_income": [
      {"period_end": "YYYY-MM-DD", "yhat": 0.0, "p10": 0.0, "p90": 0.0}
    ]
  },
  "why": {
    "tailwinds": [
      {"claim": "...", "evidence_quote": "...", "speaker": "..."},
      {"claim": "...", "evidence_quote": "...", "speaker": "..."}
    ],
    "headwind": {
      "claim": "...",
      "evidence_quote": "...",
      "speaker": "..."
    },
    "attribution": {
      "sentence": "...",
      "evidence_quote": "..."
    },
    "unknowns": []
  },
  "model": {
    "name": "ETS|SARIMA|TFT",
    "version": "x.y.z"
  },
  "data_timestamp": "ISO-8601",
  "disclaimer": "Research & education only. Not investment advice."
}

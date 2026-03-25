import os
import logging
import requests
from datetime import datetime, timedelta
from typing import List, Optional
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

from fmp_client import FMPClient
from sanity import sanity_check_income_statement
from forecasting import naive_forecast
from tft_inference import predict_with_tft
from why_engine import get_why_data

# 初始化日志和环境
load_dotenv()
logger = logging.getLogger("api.main")
logging.basicConfig(level=logging.INFO)

app = FastAPI(title="Rockefarmer API")

# --- CORS 设置 ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = FMPClient(api_key=os.getenv("FMP_API_KEY"))

# --- DATA MODELS ---
class TimePoint(BaseModel):
    period_end: str
    value: float

class ForecastPoint(BaseModel):
    period_end: str
    yhat: float
    p10: float
    p90: float

class AnalysisItem(BaseModel):
    claim: str
    quote: str

class StockResponse(BaseModel):
    symbol: str
    company_name: str
    price: float
    change_percent: float
    currency: str
    # Key Stats
    open: float
    prev_close: float
    lo_52w: float
    hi_52w: float
    pe_ratio: float
    market_cap: str
    # Charts
    history_revenue: List[TimePoint]
    forecast_revenue: List[ForecastPoint]
    history_net_income: List[TimePoint]
    forecast_net_income: List[ForecastPoint]
    # Cards
    forecast_value_rev: float
    forecast_value_ni: float
    delta_rev: float
    delta_ni: float
    consensus_rev: Optional[float]
    consensus_ni: Optional[float]
    # Text Analysis
    tailwinds: List[AnalysisItem]
    headwinds: List[AnalysisItem]

class WatchlistItem(BaseModel):
    symbol: str
    name: str
    current_price: float
    change: float
    change_percent: float

WATCHLIST_TICKERS = ["AAPL", "MSFT", "NVDA"]

# --- 辅助函数 ---

def _format_millions(val: float) -> str:
    """Format value to 'XXX.XX million' universally."""
    if not val:
        return "-"
    m = val / 1_000_000
    return f"{m:.2f} million"

def _period_label(date_str: str) -> str:
    """把 'YYYY-MM-DD' 转换为 '24 Q1' 格式"""
    try:
        dt = datetime.strptime(date_str[:10], "%Y-%m-%d")
        q = (dt.month - 1) // 3 + 1
        return f"{dt.strftime('%y')} Q{q}"
    except Exception:
        return date_str[:10]

def _resolve_pe(quote: dict, price: float) -> float:
    """
    智能解析 P/E 比率。如果 API 没给，就自己算。
    """
    # 1. 尝试直接从 API 字段获取
    for key in ("pe", "peRatio", "priceEarningsRatio", "trailingPE", "forwardPE"):
        val = quote.get(key)
        if val is not None and isinstance(val, (int, float)) and val != 0:
            return round(float(val), 2)

    # 2. 强制兜底计算: Price / EPS
    eps = quote.get("eps")
    if not eps or eps == 0: eps = quote.get("trailingEps")
    if not eps or eps == 0: eps = quote.get("forwardEps")
    if not eps or eps == 0: eps = quote.get("epsTTM")

    if price and eps and eps != 0:
        calculated_pe = round(price / eps, 2)
        logger.info(f"[{quote.get('symbol')}] API P/E missing. Manual Calc: {calculated_pe}")
        return calculated_pe

    return 0.0

def get_next_quarter_consensus(ticker: str, api_key: str, last_hist_date_str: str) -> dict:
    """
    获取分析师预测，并精准定位到 '历史数据之后' 的第一个季度。
    修复了 '拿2028年数据做对比' 的 Bug。
    """
    # 这里直接调用 FMP API，不依赖 estimates 列表参数，防止传参错误
    url = f"https://financialmodelingprep.com/api/v4/analyst-estimates?symbol={ticker}&apikey={api_key}"
    
    try:
        # 1. 解析历史日期
        last_hist_date = datetime.strptime(last_hist_date_str, "%Y-%m-%d")
        
        # 2. 发起请求
        resp = requests.get(url, timeout=5)
        data = resp.json()

        if data and isinstance(data, list) and len(data) > 0:
            future_estimates = []
            for est in data:
                est_date_str = est.get('date')
                if not est_date_str: continue
                try:
                    est_date = datetime.strptime(est_date_str, "%Y-%m-%d")
                    # 关键逻辑：只取比历史日期 '更晚' 的预测
                    if est_date > last_hist_date:
                        future_estimates.append(est)
                except:
                    continue
            
            # 关键修复：按日期升序排列 (找最近的未来)
            future_estimates.sort(key=lambda x: x.get('date', ''))
            
            if future_estimates:
                target = future_estimates[0] # 最近的一个季度
                result = {
                    "revenue_consensus": target.get("estimatedRevenueAvg", 0.0),
                    "net_income_consensus": target.get("estimatedNetIncomeAvg", 0.0),
                    "date": target.get("date", ""),
                }
                logger.info(f"[{ticker}] Consensus Matched: {result['date']} (vs History: {last_hist_date_str})")
                return result
                
    except Exception as e:
        logger.error(f"Failed to fetch analyst estimates for {ticker}: {e}")

    return {}

def _build_dream_json_mock(ticker: str) -> dict:
    """当 API 彻底失败时的 Mock 数据"""
    names = {"AAPL": "Apple Inc.", "MSFT": "Microsoft Corporation", "NVDA": "NVIDIA Corporation"}
    return {
        "meta": {"ticker": ticker, "name": names.get(ticker, f"{ticker} Corp")},
        "header_view": {
            "price_formatted": "$0.00",
            "change_formatted": "Data Unavailable",
            "is_positive": True,
        },
        "key_stats": {
            "open": 0.0, "year_low": 0.0, "year_high": 0.0, 
            "pe_ratio": 0.0, "market_cap": "0", "prev_close": 0.0,
        },
        "chart_view": {
            "revenue_series": {"history": [], "forecast": []},
            "net_income_series": {"history": [], "forecast": []},
        },
        "forecast_summary": {
            "my_forecast": "-", "my_forecast_ni": "-",
            "delta_value": "-", "delta_percent": "-", 
            "delta_is_positive": True, "wall_street": "-",
        },
        "analysis_view": {
            "tailwinds": [{"claim": "Data unavailable", "sentiment": "neutral"}],
            "headwinds": [{"claim": "Could not reach data provider", "sentiment": "neutral"}],
        },
    }

# --- 核心 Endpoint: /v0/detail/{ticker} ---
@app.get("/v0/detail/{ticker}")
async def get_detail(ticker: str):
    ticker = ticker.upper()

    try:
        # A. 获取实时 Quote
        quote = client.quote(ticker)
        if not quote:
            return _build_dream_json_mock(ticker)

        # B. 获取财报历史
        income = client.income_statement_quarterly(ticker, limit=12)
        sanity = sanity_check_income_statement(income)
        if not sanity.ok:
            return _build_dream_json_mock(ticker)

        rev_history = sanity.cleaned["revenue"]
        ni_history = sanity.cleaned["net_income"]

        # B2. 数据清洗：防止 Net Income > Revenue
        rev_by_period = {r["period_end"]: r["value"] for r in rev_history}
        for ni_pt in ni_history:
            period_rev = rev_by_period.get(ni_pt["period_end"])
            if period_rev and abs(ni_pt["value"]) > abs(period_rev):
                ni_pt["value"] = ni_pt["value"] / 4.0 # 启发式修复

        # C. 进行预测 (TFT Model)
        rev_fc = predict_with_tft(rev_history, steps=4, target_name="revenue", ticker=ticker)
        ni_fc = predict_with_tft(ni_history, steps=4, target_name="net_income", ticker=ticker)

        # D. 获取华尔街一致预期 (Wall St Consensus)
        last_hist_date = rev_history[-1]["period_end"]
        # 调用我们修复后的函数
        consensus = get_next_quarter_consensus(ticker, os.getenv("FMP_API_KEY", ""), last_hist_date)
        
        cons_rev = consensus.get("revenue_consensus") or 0.0
        cons_ni = consensus.get("net_income_consensus") or 0.0

        # 获取我们的预测值
        my_forecast_rev = rev_fc[0]["yhat"] if rev_fc else 0.0
        my_forecast_ni = ni_fc[0]["yhat"] if ni_fc else 0.0

        # 兜底：如果华尔街没数据，给一个默认值
        if cons_rev <= 0: cons_rev = my_forecast_rev * 0.98
        if cons_ni <= 0: cons_ni = my_forecast_ni * 0.98

        # E. 获取分析文本
        why_data = get_why_data(ticker)

        # F. 格式化数据
        def to_graph_points(data_list):
            return [{"period": _period_label(d["period_end"]), "value": round(d["value"] / 1e9, 2)} for d in data_list]

        def to_forecast_points(fc_list):
            return [{"period": _period_label(d["period_end"]), "value": round(d["yhat"] / 1e9, 2)} for d in fc_list]

        def to_items(raw_list):
            return [{"claim": str(x.get("claim", "")), "sentiment": str(x.get("sentiment", "neutral"))} for x in (raw_list or [])]

        # G. Header 计算
        price = quote.get("price", 0.0)
        prev_close = quote.get("previousClose", 0.0)
        
        change_val = price - prev_close if prev_close else quote.get("change", 0.0)
        change_pct = (change_val / prev_close * 100) if prev_close else quote.get("changesPercentage", 0.0)
        
        is_positive = change_val >= 0
        sign = "+" if is_positive else ""
        change_formatted = f"{sign}{change_val:.2f} ({sign}{change_pct:.2f}%)"

        mkt_cap = quote.get("marketCap", 0)
        mkt_cap_str = f"{mkt_cap/1e12:.2f}T" if mkt_cap > 1e12 else f"{mkt_cap/1e9:.2f}B"

        # H. 计算 Delta
        delta_rev = my_forecast_rev - cons_rev
        delta_pct = (delta_rev / cons_rev * 100) if cons_rev else 0.0
        delta_is_positive = delta_rev >= 0

        return {
            "meta": {"ticker": ticker, "name": quote.get("name", ticker)},
            "header_view": {
                "price_formatted": f"${price:,.2f}",
                "change_formatted": change_formatted,
                "is_positive": is_positive,
            },
            "key_stats": {
                "open": quote.get("open") or 0.0,
                "year_low": quote.get("yearLow") or 0.0,
                "year_high": quote.get("yearHigh") or 0.0,
                "pe_ratio": _resolve_pe(quote, price), # 修复 P/E
                "market_cap": mkt_cap_str,
                "prev_close": quote.get("previousClose") or 0.0,
            },
            "chart_view": {
                "revenue_series": {
                    "history": to_graph_points(rev_history),
                    "forecast": to_forecast_points(rev_fc),
                },
                "net_income_series": {
                    "history": to_graph_points(ni_history),
                    "forecast": to_forecast_points(ni_fc),
                },
            },
            "forecast_summary": {
                "my_forecast": _format_millions(my_forecast_rev),
                "my_forecast_ni": _format_millions(my_forecast_ni),
                # Keep legacy fields below to prevent contract breaks
                "delta_value": "-",
                "delta_percent": "-",
                "delta_is_positive": True,
                "wall_street": "-",
            },
            "analysis_view": {
                "tailwinds": to_items(why_data.get("tailwinds", [])),
                "headwinds": to_items(why_data.get("headwinds", [])),
            },
        }

    except Exception as e:
        logger.error(f"Detail endpoint failed for {ticker}: {e}", exc_info=True)
        return _build_dream_json_mock(ticker)

# --- WATCHLIST Endpoint ---
@app.get("/v0/watchlist", response_model=List[WatchlistItem])
async def get_watchlist():
    results = []
    for ticker in WATCHLIST_TICKERS:
        try:
            q = client.quote(ticker)
            if q:
                price = q.get("price", 0.0)
                prev = q.get("previousClose", 0.0)
                change = price - prev if prev else 0.0
                pct = (change / prev * 100) if prev else 0.0
                results.append(WatchlistItem(
                    symbol=ticker,
                    name=q.get("name", ticker),
                    current_price=round(price, 2),
                    change=round(change, 2),
                    change_percent=round(pct, 2)
                ))
        except:
            pass
    return results

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
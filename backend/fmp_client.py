import os
from typing import Any, Dict, List, Optional
import requests
from datetime import datetime, date

# --- STANDALONE FUNCTIONS ---

def get_fmp_consensus(ticker: str, api_key: str):
    """
    Fetches Quarterly Analyst Estimates using the /stable/ endpoint.
    """
    url = "https://financialmodelingprep.com/stable/analyst-estimates"
    
    params = {
        "symbol": ticker,
        "apikey": api_key,
        "period": "quarter", 
        "limit": 30
    }
    
    try:
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()
        
        if not data or not isinstance(data, list):
            return None

        # --- FIX 3: ROBUST DATE FILTERING ---
        today = date.today() # Uses local server time; for production, consider timezone.utc
        
        future_estimates = []
        for d in data:
            if not d.get('date'): continue
            
            # Parse FMP date string "YYYY-MM-DD"
            try:
                est_date = datetime.strptime(d['date'], "%Y-%m-%d").date()
            except ValueError:
                continue # Skip invalid dates
                
            if est_date > today:
                future_estimates.append(d)
        
        # Sort by date (ascending) to find the nearest future quarter
        future_estimates.sort(key=lambda x: x['date'])
        
        if not future_estimates:
            return None
            
        next_q = future_estimates[0]

        # 3. Extract key metrics (try multiple field names for robustness)
        rev_avg = (
            next_q.get("revenueAvg")
            or next_q.get("estimatedRevenueAvg")
            or next_q.get("revenue")
        )
        ni_avg = (
            next_q.get("netIncomeAvg")
            or next_q.get("estimatedNetIncomeAvg")
            or next_q.get("netIncome")
        )
        return {
            "source": "FMP Analyst Estimates",
            "quarter_date": next_q.get("date"),
            "revenue_consensus": rev_avg,
            "net_income_consensus": ni_avg,
            "eps_consensus": next_q.get("epsAvg") or next_q.get("estimatedEpsAvg"),
            "analyst_count": next_q.get("numAnalystsRevenue") or next_q.get("numberAnalystsRevenue"),
        }

    except Exception as e:
        print(f"Error fetching FMP consensus: {e}")
        return None

# --- CLIENT CLASS ---

class FMPClient:
    """
    Minimal FMP client for MVP.
    """
    def __init__(self, api_key: Optional[str] = None, base_url: str = "https://financialmodelingprep.com/stable"):
        self.api_key = api_key or os.getenv("FMP_API_KEY", "")
        self.base_url = base_url.rstrip("/")
        self.session = requests.Session()

    def _get_json(self, path: str, params: Dict[str, Any]) -> Any:
        if not self.api_key:
            raise RuntimeError("FMP_API_KEY is missing.")
        params = dict(params)
        params["apikey"] = self.api_key
        url = f"{self.base_url}/{path.lstrip('/')}"
        resp = self.session.get(url, params=params, timeout=20)
        resp.raise_for_status()
        return resp.json()

    def quote(self, symbol: str) -> Dict[str, Any]:
        data = self._get_json("quote", {"symbol": symbol.upper()})
        return data[0] if isinstance(data, list) and data else {}

    def income_statement_quarterly(self, symbol: str, limit: int = 16) -> List[Dict[str, Any]]:
        data = self._get_json(
            "income-statement",
            {"symbol": symbol.upper(), "period": "quarter", "limit": int(limit)}
        )
        return data if isinstance(data, list) else []
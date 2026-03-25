import os
import requests
from dotenv import load_dotenv

# 加载 .env 里的 FMP_API_KEY
load_dotenv()
API_KEY = os.getenv("FMP_API_KEY")
TICKER = "NVDA"

def print_section(title, data):
    print(f"\n{'='*10} {title} {'='*10}")
    print(data)

def audit_stock():
    print(f"🔍 AUDITING TICKER: {TICKER}")

    # 1. 查 Quote (找 P/E 和 EPS)
    url_quote = f"https://financialmodelingprep.com/api/v3/quote/{TICKER}?apikey={API_KEY}"
    quote = requests.get(url_quote).json()[0]
    print_section("1. QUOTE DATA (For P/E)", {
        "price": quote.get("price"),
        "pe": quote.get("pe"),
        "eps": quote.get("eps"),
        "timestamp": quote.get("timestamp")
    })

    # 2. 查 Analyst Estimates (找 Wall St 数据)
    # 注意：我们查未来 4 个季度的预测
    url_estimates = f"https://financialmodelingprep.com/api/v3/analyst-estimates/{TICKER}?period=quarter&limit=4&apikey={API_KEY}"
    estimates = requests.get(url_estimates).json()
    
    print(f"\n{'='*10} 2. ANALYST ESTIMATES (For Delta) {'='*10}")
    if estimates:
        for est in estimates:
            print(f"Date: {est.get('date')} | Est Revenue: {est.get('estimatedRevenueAvg')} | Est EPS: {est.get('estimatedEpsAvg')}")
    else:
        print("❌ No estimates found!")

    # 3. 查 Income Statement (找历史营收单位)
    url_financials = f"https://financialmodelingprep.com/api/v3/income-statement/{TICKER}?period=quarter&limit=2&apikey={API_KEY}"
    financials = requests.get(url_financials).json()
    
    print(f"\n{'='*10} 3. HISTORICAL DATA (For Scale Check) {'='*10}")
    if financials:
        last_q = financials[0]
        print(f"Date: {last_q.get('date')} | Revenue: {last_q.get('revenue')} | Net Income: {last_q.get('netIncome')}")
    
if __name__ == "__main__":
    audit_stock()
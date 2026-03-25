# api/mock_payload.py
# Mock payload for MVP API (schema-aligned)
# Used by: api/main.py -> from .mock_payload import mock_payload

mock_payload = {
    "ticker": "AAPL",
    "company_meta": {
        "name": "Apple Inc.",
        "price": 195.12,
        "market_cap": 3000000000000,
        "currency": "USD",
    },
    "series_history": {
        "revenue": [
            {"period_end": "2021-12-31", "value": 123_900_000_000},
            {"period_end": "2022-03-31", "value": 97_300_000_000},
            {"period_end": "2022-06-30", "value": 82_900_000_000},
            {"period_end": "2022-09-30", "value": 90_100_000_000},
            {"period_end": "2022-12-31", "value": 117_200_000_000},
            {"period_end": "2023-03-31", "value": 94_800_000_000},
            {"period_end": "2023-06-30", "value": 81_800_000_000},
            {"period_end": "2023-09-30", "value": 89_500_000_000},
            {"period_end": "2023-12-31", "value": 119_600_000_000},
            {"period_end": "2024-03-31", "value": 90_800_000_000},
            {"period_end": "2024-06-30", "value": 85_800_000_000},
            {"period_end": "2024-09-30", "value": 94_900_000_000},
            {"period_end": "2024-12-31", "value": 124_300_000_000},
            {"period_end": "2025-03-31", "value": 92_600_000_000},
            {"period_end": "2025-06-30", "value": 87_200_000_000},
            {"period_end": "2025-09-30", "value": 96_400_000_000},
        ],
        "net_income": [
            {"period_end": "2021-12-31", "value": 34_600_000_000},
            {"period_end": "2022-03-31", "value": 25_000_000_000},
            {"period_end": "2022-06-30", "value": 19_400_000_000},
            {"period_end": "2022-09-30", "value": 20_700_000_000},
            {"period_end": "2022-12-31", "value": 30_000_000_000},
            {"period_end": "2023-03-31", "value": 24_200_000_000},
            {"period_end": "2023-06-30", "value": 19_900_000_000},
            {"period_end": "2023-09-30", "value": 22_900_000_000},
            {"period_end": "2023-12-31", "value": 33_900_000_000},
            {"period_end": "2024-03-31", "value": 23_600_000_000},
            {"period_end": "2024-06-30", "value": 21_400_000_000},
            {"period_end": "2024-09-30", "value": 24_100_000_000},
            {"period_end": "2024-12-31", "value": 36_300_000_000},
            {"period_end": "2025-03-31", "value": 24_800_000_000},
            {"period_end": "2025-06-30", "value": 22_300_000_000},
            {"period_end": "2025-09-30", "value": 25_100_000_000},
        ],
    },
    "series_forecast": {
        "revenue": [
            {"period_end": "2025-12-31", "yhat": 126_000_000_000, "p10": 118_000_000_000, "p90": 134_000_000_000},
            {"period_end": "2026-03-31", "yhat": 95_000_000_000, "p10": 89_000_000_000, "p90": 101_000_000_000},
            {"period_end": "2026-06-30", "yhat": 89_000_000_000, "p10": 83_000_000_000, "p90": 96_000_000_000},
            {"period_end": "2026-09-30", "yhat": 98_000_000_000, "p10": 92_000_000_000, "p90": 105_000_000_000},
        ],
        "net_income": [
            {"period_end": "2025-12-31", "yhat": 37_000_000_000, "p10": 33_000_000_000, "p90": 41_000_000_000},
            {"period_end": "2026-03-31", "yhat": 26_000_000_000, "p10": 23_000_000_000, "p90": 29_000_000_000},
            {"period_end": "2026-06-30", "yhat": 23_000_000_000, "p10": 20_000_000_000, "p90": 26_000_000_000},
            {"period_end": "2026-09-30", "yhat": 27_000_000_000, "p10": 24_000_000_000, "p90": 30_000_000_000},
        ],
    },
    "why": {
        "tailwinds": [
            {
                "claim": "Services revenue reached an all-time record with strong year-over-year growth.",
                "evidence_quote": "Services achieved an all-time revenue record...",
                "speaker": "Management",
            },
            {
                "claim": "iPhone revenue grew year-over-year and set a quarterly record.",
                "evidence_quote": "iPhone set a revenue record for the quarter...",
                "speaker": "Management",
            },
        ],
        "headwind": {
            "claim": "Supply constraints affected availability on certain iPhone models.",
            "evidence_quote": "despite supply constraints we faced...",
            "speaker": "Management",
        },
        "attribution": {
            "sentence": "Revenue performance was primarily supported by strength in Services and iPhone.",
            "evidence_quote": "These results were driven by ...",
        },
        "unknowns": [],
    },
    "model": {"name": "MOCK", "version": "0.1.0"},
    "data_timestamp": "2025-12-31T23:59:59Z",
    "disclaimer": "For research and education only. Not investment advice.",
}

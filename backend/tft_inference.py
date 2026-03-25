"""
tft_inference.py
~~~~~~~~~~~~~~~~
Wrapper around the trained Temporal Fusion Transformer model.
Falls back to naive_forecast if the model cannot be loaded or inference fails.
"""

from __future__ import annotations

import logging
import os
import pickle
from pathlib import Path
from typing import Any, Dict, List

logger = logging.getLogger("api.tft_inference")

# ---------------------------------------------------------------------------
# Model directory – same folder as this script
# ---------------------------------------------------------------------------
_MODEL_DIR = Path(__file__).resolve().parent

# Cache loaded models so we only deserialise once per process
_MODEL_CACHE: Dict[str, Any] = {}


def _load_model(target_name: str) -> Any:
    """
    Attempt to load the TFT model artefact for *target_name*.

    Search order:
        1.  tft_model.pkl   (pickle – e.g. Darts / sklearn-compatible wrapper)
        2.  tft_model.pt    (PyTorch state-dict or TorchScript)
        3.  tft_model.pth   (alternative PyTorch extension)

    Returns the loaded model object, or raises on failure.
    """
    if target_name in _MODEL_CACHE:
        return _MODEL_CACHE[target_name]

    # --- Try .pkl first (Darts / generic pickle) -------------------------
    pkl_path = _MODEL_DIR / "tft_model.pkl"
    if pkl_path.exists():
        with open(pkl_path, "rb") as f:
            model = pickle.load(f)  # noqa: S301
        logger.info("TFT model loaded from %s", pkl_path)
        _MODEL_CACHE[target_name] = model
        return model

    # --- Try .pt / .pth (PyTorch) ----------------------------------------
    for ext in ("pt", "pth"):
        pt_path = _MODEL_DIR / f"tft_model.{ext}"
        if pt_path.exists():
            import torch  # deferred import – only needed when file exists

            model = torch.load(pt_path, map_location="cpu", weights_only=False)
            model.eval() if hasattr(model, "eval") else None
            logger.info("TFT model loaded from %s", pt_path)
            _MODEL_CACHE[target_name] = model
            return model

    raise FileNotFoundError("No TFT model file found (.pkl / .pt / .pth)")


def _run_tft_inference(
    model: Any,
    history: List[Dict[str, Any]],
    steps: int,
    target_name: str,
    ticker: str,
) -> List[Dict[str, Any]]:
    """
    Run the loaded TFT model and return forecasts.

    Must return the **same contract** as naive_forecast:
        [{"period_end": "YYYY-MM-DD", "yhat": float, "p10": float, "p90": float}, ...]
    """
    import pandas as pd
    import numpy as np
    import torch
    from pytorch_forecasting import TemporalFusionTransformer

    # 1. 确保模型是 pytorch-forecasting 的 TFT 实例
    if not isinstance(model, TemporalFusionTransformer):
        raise TypeError("Loaded model is not a pytorch_forecasting TemporalFusionTransformer.")

    # 2. 将传入的 history 转换为 DataFrame
    df = pd.DataFrame(history)
    df["period_end"] = pd.to_datetime(df["period_end"])
    df = df.sort_values("period_end").reset_index(drop=True)

    # 3. 构建模型必需的核心特征 (Data Imputation / Mocking)
    # WARNING: 实际生产中，你需要从 API 获取这些真实的财务特征。
    # 这里为了防止崩溃，进行了最小化的结构伪造。
    df["ticker"] = ticker
    df["gics_sectors"] = "Information Technology"
    df["year"] = df["period_end"].dt.year
    df["quarter_int"] = df["period_end"].dt.quarter
    df["time_idx"] = np.arange(len(df))

    # 将真实的 value 转换为模型需要的目标列 (处理可能的 <= 0 的情况)
    df["revenue_log"] = np.log1p(df["value"].clip(lower=0))

    # TODO: 如果你的模型强依赖 totalAssets_lag1 等其他 10+ 个特征，
    # 必须在这里补全默认值（如 0.0），否则 TimeSeriesDataSet 的
    # validation 环节会报错。

    # 4. 执行预测
    # pytorch-forecasting 支持直接传入 DataFrame 进行 predict
    try:
        # mode="quantiles" 返回分位数预测
        prediction = model.predict(df, mode="quantiles", return_x=False)

        # 提取中位数 (0.5 分位数) 作为 yhat，0.1 和 0.9 作为置信区间
        # 假设预测形状为 (1, steps, num_quantiles)
        preds_array = prediction.detach().cpu().numpy().squeeze()

        results = []
        last_date = df["period_end"].iloc[-1]

        for i in range(steps):
            # 按季度递增日期
            next_date = last_date + pd.DateOffset(months=3 * (i + 1))

            # 从对数域反转回真实数值级
            # index 取决于训练时定义的 quantiles 列表 (例如 [0.1, 0.5, 0.9])
            # 假设 [:, 1] 是中位数，[:, 0] 是 p10, [:, 2] 是 p90
            try:
                yhat_log = preds_array[i, 1] if preds_array.ndim > 1 else preds_array[i]
                p10_log = preds_array[i, 0] if preds_array.ndim > 1 else yhat_log * 0.9
                p90_log = preds_array[i, 2] if preds_array.ndim > 1 else yhat_log * 1.1
            except IndexError:
                # 兼容未开启 quantiles 预测的情况
                yhat_log = preds_array[i]
                p10_log = yhat_log
                p90_log = yhat_log

            yhat_lvl = np.expm1(yhat_log)
            p10_lvl = np.expm1(p10_log)
            p90_lvl = np.expm1(p90_log)

            results.append({
                "period_end": next_date.strftime("%Y-%m-%d"),
                "yhat": float(yhat_lvl),
                "p10": float(p10_lvl),
                "p90": float(p90_lvl),
            })

        return results

    except Exception as e:
        logger.error("PyTorch Forecasting prediction failed: %s", e)
        raise


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def predict_with_tft(
    history: List[Dict[str, Any]],
    steps: int = 4,
    target_name: str = "revenue",
    ticker: str = "AAPL",
) -> List[Dict[str, Any]]:
    """
    Predict future quarterly values using the TFT model.

    Returns the **exact same structure** as ``naive_forecast``:
        [{"period_end": "YYYY-MM-DD", "yhat": float, "p10": float, "p90": float}, ...]

    On ANY failure (missing model file, torch import error, shape mismatch,
    etc.) this function silently falls back to ``naive_forecast``.
    """
    try:
        model = _load_model(target_name)
        result = _run_tft_inference(model, history, steps, target_name, ticker)
        logger.info("TFT prediction succeeded for %s (%d steps)", target_name, steps)
        return result
    except Exception as exc:
        logger.warning(
            "TFT inference failed for %s – falling back to naive_forecast: %s",
            target_name,
            exc,
        )
        from forecasting import naive_forecast
        return naive_forecast(history, steps)

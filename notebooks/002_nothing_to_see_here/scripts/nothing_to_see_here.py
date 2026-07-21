"""This code plots overnight and intraday returns for any Yahoo Finance ticker symbol.

Requirements:  Python 3.12+ and matplotlib.

Before running, set INPUT_DATA_DIR to the local directory in which you wish to store the files with price data that
this code will download from Yahoo Finance.

Articles:
    [2016]  Information, Impact, Ignorance, Illegality, Investing, and Inequality
                https://ssrn.com/abstract=2859097, https://arxiv.org/abs/1612.06855
    [2018]  How to Increase Global Wealth Inequality for Fun and Profit
                https://ssrn.com/abstract=3282845, https://arxiv.org/abs/1811.04994
    [2019]  Celebrating Three Decades of Worldwide Stock Market Manipulation
                https://ssrn.com/abstract=3490879, https://arxiv.org/abs/1912.01708
    [2020]  Strikingly Suspicious Overnight and Intraday Returns
                https://ssrn.com/abstract=3705017, https://arxiv.org/abs/2010.01727
    [2021]  They Chose to Not Tell You
                https://ssrn.com/abstract=3894013, https://arxiv.org/abs/2107.12516
    [2022]  They Still Haven't Told You
                https://ssrn.com/abstract=3998202, https://arxiv.org/abs/2201.00223
    [2023]  Nothing to See Here: How to Say It When You Need to
                https://ssrn.com/abstract=4619084

Using plot_one_sym_linear(), you can make any plot in:
    Figures 2-4 of [2022]
    Figure 2 of [2021]
    Figure 1 of [2020]
    Figures 2-3 of [2019]
    Figure 1 of [2018]
  and the plot of overnight and intraday returns to the S&P 500 SPDR ETF referenced in [2016]

Using plot_one_sym_log(), you can make any plot in:
    Figures 3-10 of [2023]  (e.g., plot_one_sym_log("SPY", show_returns=True))
    Figures 6-7 of [2022]
    Figures 1 and 3 of [2021]

Using plot_what_you_would_expect(), you can make any plot in:
    Figure 2 of [2023]  (e.g., plot_what_you_would_expect("2023", 25) makes the bottom right plot)
    Figure 1 of [2022]  (e.g., plot_what_you_would_expect("2022", 50) makes the bottom right plot)

Using histogram_returns(), you can make Figure 4 of [2021] (e.g., histogram_returns("SPY"))

Earlier versions of this code explicitly made all figures in our most recent article on this topic.
As the number of individual plots in our articles increased -- Figures 3-10 of [2023] show 224 individual plots --
the fraction of code devoted to handling all those individual plots increased
(obscuring the simplicity of the code needed to make any single plot), and the time until the code failed decreased
(because Yahoo Finance stopped providing data for one of the stocks).

This version of the code just makes a (linear or log) plot of one ticker symbol.
You can use it to reproduce any individual plot of overnight and intraday returns in our articles on this topic,
and to make a similar plot for any other ticker symbol you wish (as long as Yahoo Finance provides data for it).

Bruce Knuteson (knuteson@mit.edu), 2023-10-31

Updates:
  2024-10-13: download_data_from_yahoo_finance() now downloads Yahoo Finance data in json format from /v7/finance/chart/
                (because the csv format from /v7/finance/download/ is no longer available)
"""

import logging
import os
import random
from datetime import datetime, timedelta
from json import dumps, loads
from math import ceil, erf, floor, log10, sqrt
from statistics import pstdev
from time import mktime, sleep
from types import MappingProxyType
from typing import Iterable, Literal, NamedTuple
from urllib.parse import quote, urlencode
from zoneinfo import ZoneInfo

import requests
from matplotlib.axes import Axes
from matplotlib.dates import YearLocator, date2num
from matplotlib.figure import Figure
from matplotlib.pyplot import (
    clf,
    figtext,
    figure,
    gca,
    gcf,
    hist,
    ion,
    savefig,
    title,
    xlabel,
    xlim,
    ylabel,
    ylim,
)

# ADJUST INPUT_DATA_DIR AS NECESSARY FOR YOUR LOCAL ENVIRONMENT
# csv files with open and close prices will be downloaded to INPUT_DATA_DIR
INPUT_DATA_DIR = "."
DEFAULT_START_DATE, DEFAULT_END_DATE = datetime(1990, 1, 1), datetime(2023, 9, 30)

# Turn on interactive mode.  Immediately show all matplotlib figures.
ion()

SymbolDetailsDict = MappingProxyType[str, dict[str, str | datetime | list[datetime]]]
SYMBOL_DETAILS_DICT: SymbolDetailsDict = MappingProxyType(
    dict(
        [
            # Cleaning comments:
            # [open=close=high=low] open == close == high == low for many days before this date
            # [open=close] open == close for many days before this date
            # [all_okay] prices are okay from this date onward (even on days the price doesn't move much)
            # [stale_open] stale open prices for many days before this date
            # [negative_adj_close] small or negative adjusted close prices before this date
            # [uk_x100] prices are off by a factor of 100
            # Indices (as shown in [2018, 2019, 2020, 2021, 2022, 2023])
            (
                "SPY",
                dict(
                    name="S&P 500 SPDR ETF",
                    country="United States",
                    short_name="S&P 500",
                ),
            ),
            (
                "^IXIC",
                dict(
                    name="NASDAQ Composite",
                    country="United States",
                    short_name="NASDAQ",
                ),
            ),
            (
                "IWM",
                dict(
                    name="iShares Russell 2000 ETF",
                    country="United States",
                    short_name="Russell 2000",
                ),
            ),
            (
                "MDY",
                dict(
                    name="S&P 400 Mid-Cap SPDR ETF",
                    country="United States",
                    short_name="S&P 400",
                ),
            ),
            (
                "XIU.TO",
                dict(name="iShares TSX 60 ETF", country="Canada", short_name="TSX 60"),
            ),
            (
                "HUKX.L",
                dict(
                    name="HSBC FTSE 100 ETF",
                    country="United Kingdom",
                    short_name="FTSE 100",
                    bad_data_dates=[datetime(2022, 6, 14)],
                ),
            ),  # [uk_x100]
            ("^FCHI", dict(name="CAC 40", country="France")),
            (
                "^IBEX",
                dict(name="IBEX 35", country="Spain", start_date=datetime(1999, 2, 23)),
            ),  # [stale_open]
            ("^GDAXI", dict(name="DAX", country="Germany")),
            (
                "^AEX",
                dict(
                    name="AEX",
                    country="Netherlands",
                    bad_data_dates=[datetime(1995, 12, 26)],
                ),
            ),  # bad prices
            ("^BFX", dict(name="BEL 20", country="Belgium")),
            (
                "OBXEDNB.OL",
                dict(
                    name="DNB OBX ETF",
                    country="Norway",
                    short_name="DNB OBX",
                    # open prices are zero from 2009-01-01 to 2009-05-06
                    start_date=datetime(2009, 5, 8),
                    bad_data_dates=[
                        datetime(2009, 11, 12),  # zero open price
                        datetime(2009, 11, 13),  # zero open price
                        datetime(2013, 1, 4),
                    ],
                ),
            ),  # bad close price
            (
                "IMIB.MI",
                dict(
                    name="iShares FTSE MIB ETF", country="Italy", short_name="FTSE MIB"
                ),
            ),
            (
                "^TA125.TA",
                dict(
                    name="TA-125",
                    country="Israel",
                    # more than half of the TA-125 overnight returns are zero before 2007.
                    start_date=datetime(2007, 1, 8),
                ),
            ),
            ("^NSEI", dict(name="NIFTY 50", country="India")),
            (
                "^BSESN",
                dict(name="S&P BSE SENSEX", country="India", short_name="SENSEX"),
            ),
            (
                "STW.AX",
                dict(
                    name="SPDR S&P/ASX 200 Fund",
                    country="Australia",
                    short_name="ASX 200",
                ),
            ),
            ("^SET.BK", dict(name="SET Index", country="Thailand", short_name="SET")),
            (
                "^KS11",
                dict(name="KOSPI Composite Index", country="Korea", short_name="KOSPI"),
            ),
            (
                "^TWII",
                dict(name="TSEC Weighted Index", country="Taiwan", short_name="TSEC"),
            ),
            (
                "ES3.SI",
                dict(
                    name="SPDR Straits Times Index ETF",
                    country="Singapore",
                    short_name="Straits Times",
                ),
            ),
            ("^N225", dict(name="Nikkei 225", country="Japan")),
            (
                "^HSI",
                dict(
                    name="Hang Seng Index", country="Hong Kong", short_name="Hang Seng"
                ),
            ),
            (
                "000001.SS",
                dict(name="SSE Composite Index", country="China", short_name="SSE"),
            ),
            # Meme stocks, shown in Figure 3 of [2021] and Figure 6 of [2022]
            ("GME", dict(name="GameStop")),
            ("AMC", dict(name="AMC Entertainment", short_name="AMC")),
            # Evergrande, shown in Figure 7 of [2022]
            (
                "3333.HK",
                dict(name="China Evergrande Group", start_date=datetime(2010, 1, 1)),
            ),
            # Figures 4-10 of [2023]
            ("BIO", dict(start_date=datetime(1991, 4, 17))),  # [stale_open]
            ("FMCC", dict(start_date=datetime(1990, 1, 1))),  # [all_okay]
            ("FNMA", dict(start_date=datetime(1990, 1, 1))),  # [all_okay]
            ("HPQ", dict(start_date=datetime(1994, 6, 9))),  # [stale_open]
            (
                "NVR",
                dict(start_date=datetime(1993, 10, 1)),
            ),  # NVR was in bankrupcy from 1993-04 through 1993-09-30
            (
                "ACA.PA",
                dict(start_date=datetime(2007, 1, 19)),
            ),  # before this, adj_close < 0
            ("CS.PA", dict(start_date=datetime(2006, 9, 19))),  # [stale_open]
            (
                "MC.PA",
                dict(
                    bad_data_dates=[
                        datetime(2000, 3, 13),
                        datetime(2000, 4, 14),
                        datetime(2000, 4, 21),
                        datetime(2000, 4, 24),
                        datetime(2000, 5, 1),
                        datetime(2000, 5, 9),
                        datetime(2000, 6, 12),
                        datetime(2000, 6, 19),
                        datetime(2000, 11, 12),
                        datetime(2009, 11, 13),  # bad open prices
                        datetime(2013, 1, 4),
                    ]
                ),
            ),  # bad close price
            ("TEP.PA", dict(start_date=datetime(1996, 1, 9))),  # [open=close=high=low]
            ("SRT.DE", dict(start_date=datetime(2003, 1, 27))),  # [stale_open]
            ("AAL.L", dict(start_date=datetime(2001, 5, 8))),  # [open=close=high=low]
            ("AV.L", dict(start_date=datetime(2002, 7, 3))),  # [open=close=high=low]
            (
                "BA.L",
                dict(
                    start_date=datetime(1997, 5, 19),  # [open=close=high=low]
                    bad_data_dates=[datetime(2022, 6, 14)],
                ),
            ),  # [uk_x100]
            (
                "BARC.L",
                dict(
                    start_date=datetime(1997, 5, 19),  # [open=close=high=low]
                    bad_data_dates=[datetime(2022, 6, 14)],
                ),
            ),  # [uk_x100]
            ("BP.L", dict(start_date=datetime(2000, 8, 2))),  # [open=close=high=low]
            ("BT-A.L", dict(start_date=datetime(1997, 5, 19))),  # [open=close=high=low]
            ("FCIT.L", dict(start_date=datetime(1997, 5, 19))),  # [open=close=high=low]
            ("JD.L", dict(start_date=datetime(2005, 5, 5))),  # [stale_open]
            ("LAND.L", dict(start_date=datetime(1997, 5, 19))),  # [open=close=high=low]
            ("LLOY.L", dict(start_date=datetime(2003, 6, 4))),  # [open=close]
            (
                "LSEG.L",
                dict(start_date=datetime(2003, 7, 1)),
            ),  # bad open prices before this
            ("MRO.L", dict(start_date=datetime(2005, 11, 29))),  # [open=close]
            (
                "NWG.L",
                dict(
                    start_date=datetime(1997, 5, 19),  # [open=close=high=low]
                    bad_data_dates=[
                        datetime(2000, 8, 2),  # suspect open price
                        datetime(2003, 8, 12),
                        datetime(2003, 8, 26),
                        datetime(2003, 9, 17),
                    ],
                ),
            ),  # bad open
            ("STAN.L", dict(start_date=datetime(2003, 6, 25))),  # [open=close]
            (
                "VOD.L",
                dict(start_date=datetime(2006, 8, 1)),
            ),  # divergence before 20060801 is too large to plot
            ("WTB.L", dict(start_date=datetime(1997, 5, 19))),  # [open=close=high=low]
            (
                "ADANIENT.NS",
                dict(start_date=datetime(2003, 9, 4)),
            ),  # [negative_adj_close]
            (
                "CIPLA.NS",
                dict(bad_data_dates=[datetime(2004, 5, 11)]),
            ),  # prices too high by a factor of ~5
            ("ITC.NS", dict(start_date=datetime(1996, 2, 2))),  # [stale_open]
            (
                "LT.NS",
                dict(bad_data_dates=[datetime(2006, 9, 27)]),
            ),  # prices seemingly too low by a factor of ~2
            (
                "RELIANCE.NS",
                dict(start_date=datetime(1997, 11, 5)),
            ),  # suspicious prices for several days before this date
            (
                "WIPRO.NS",
                dict(start_date=datetime(1999, 9, 27)),
            ),  # two short periods of strange prices before this date
            ("600050.SS", dict(start_date=datetime(2006, 9, 13))),  # [stale_open]
            (
                "600745.SS",
                dict(start_date=datetime(2008, 7, 8)),
            ),  # many missing prices before this date
            (
                "603259.SS",
                dict(start_date=datetime(2018, 5, 30)),
            ),  # [open=close=high=low]
            (
                "603799.SS",
                dict(start_date=datetime(2015, 2, 26)),
            ),  # [open=close=high=low]
            (
                "603986.SS",
                dict(start_date=datetime(2017, 3, 15)),
            ),  # [open=close=high=low]
        ]
    )
    # Many stocks trading in France have stale open and close prices before 1995-08-01.  (Figure 5 of [2023])
    | dict(
        (sym_pa, dict(start_date=datetime(1995, 8, 1)))
        for sym_pa in "BN.PA BNP.PA EN.PA".split()
    )
    # Many stocks trading in the UK have prices off by a factor of 100 on 2022-06-14 [uk_x100].  (Figure 7 of [2023])
    | dict(
        (sym_l, dict(bad_data_dates=[datetime(2022, 6, 14)]))
        for sym_l in "CPG.L NG.L PRU.L".split()
    )
    # Many stocks trading in India have stale open prices before 1996-06-05 [stale_open].  (Figure 8 of [2023])
    | dict(
        (sym_ns, dict(start_date=datetime(1996, 6, 5)))
        for sym_ns in (
            "EICHERMOT.NS HDFCBANK.NS HINDALCO.NS M&M.NS "
            "ONGC.NS SUNPHARMA.NS "
            "TATACONSUM.NS TATAMOTORS.NS"
        ).split()
    )
    # Some stocks trading in Japan have many seemingly stale open prices in late 2008 and early 2009, in the depths of
    # the 2008 financial crisis.  Left to itself, our automatic data cleaner would note these seemingly stale open
    # prices and throw out the problematic period and all previous dates, discarding the mostly good data from 2000 to
    # early 2009.  We manually reviewed the data for the following stocks and have chosen to keep the full history,
    # including the period in late 2008 and early 2009 with some seemingly stale open prices.  (Figure 9 of [2023])
    | dict(
        (sym_t, dict(start_date=datetime(2000, 1, 4)))  # [all_okay]
        for sym_t in "1925.T 2768.T 5201.T 5333.T 8001.T 8058.T".split()
    )
    # Additional data cleaning comments:
    #   + Many stocks trading in Italy have bad adjusted close prices before 2001-05-22.
    #   + Many stocks trading in Israel have bad price data before ~2007-01-08
    #           and/or prices off by a factor of 100 on 20100425, 20100502, 20220410, and/or 20220614.
)


def return_percent_to_string(r_pct: float) -> str:
    """Turn the return r_pct (expressed in units of percent) into a string suitable for display."""
    r_str = (
        (("%+." + str(ceil(-log10(100 + r_pct))) + "f%%") % r_pct)
        if r_pct <= -99.995
        # show "-99.995%" (rather than "-100.00%")
        else "%+.2f%%" % r_pct
        if r_pct < -99.82
        # show "-99.88%" (rather than "-100%")
        else "%+.1f%%" % r_pct
        if r_pct < -99
        # show "-99.8%" (rather than "-100%")
        else "%+.1f%%" % r_pct
        if -1 < r_pct < 1
        # show "+0.2%" (because "+0%" looks like a mistake)
        else "%+.0f%%" % r_pct
        if r_pct < 1e3
        # show "+333%"
        else "+" + "{:,.0f}".format(r_pct) + "%"
    )  # show "+333,333%"
    return (" " if r_pct < 0 else "") + r_str


def format_money_as_string(m: float, currency_sym: str = None) -> str:
    """Turn the float m into a string suitable for display."""
    money_as_string = (
        ("%." + str(ceil(-log10(m))) + "f") % m
        if m < 5e-5
        # show "0.00004" (rather than "0.0000")
        else "%.4f" % m
        if m < 1.95e-3
        # show "0.0013" (rather than "0.00")
        else "%.3f" % m
        if m < 1e-2
        # show "0.003" (rather than "0.00")
        else "%.2f" % m
        if m < 1e2
        # show "3.12"
        else "%.0f" % m
        if m < 1e4
        # show "123" (rather than "123.45")
        else "{:,}".format(int(m))  # show "12,345" (rather than "12345.67")
    )
    return (currency_sym or "") + money_as_string


def cumulate_returns(returns: list[float]) -> list[float]:
    """Cumulate returns."""
    r0 = 0
    cumulated = []
    for r1 in returns:
        r0 = (1 + r0) * (1 + r1) - 1
        cumulated.append(r0)
    return cumulated


def sym_to_currency_tex(sym: str) -> str | None:
    """Return the (latex) currency symbol for the country in which sym trades."""
    exchange = "US" if len(sym.split(".")) == 1 else sym.split(".")[1]
    if exchange in "DE MI PA".split():  # Germany, Italy, France
        return "€"
    else:
        return dict(
            US="$",
            AX="A$",
            L="£",
            TO="Can$",
            HK="HK$",
            BK="฿",
            KS="₩",
            KQ="₩",  # Hong Kong, Bangkok, Korea
            BO="₹",
            NS="₹",  # India: Bombay Stock Exchange, National Stock Exchange
            SS=r"CN$\yen$",
            T=r"JP$\yen$",  # China's Shanghai Stock Exchange, Japan's Tokyo Stock Exchange
        ).get(exchange)


def clip(x: float, lo: float, hi: float) -> float:
    """Clip x to the range (lo, hi)."""
    return lo if x < lo else hi if x > hi else x


def no_box(ax: Axes, keep_yticks: bool = False) -> None:
    """Remove the frame around the subplot ax."""
    for side in "top left right".split():
        ax.spines[side].set_visible(False)
    if not keep_yticks:
        ax.yaxis.set_ticks([], [])


type YahooFinanceFileFormat = Literal["csv", "json"]


def get_data_filename(sym: str, ext: YahooFinanceFileFormat) -> str:
    """Get the name of the local file with open and close prices for sym."""
    return os.path.join(INPUT_DATA_DIR, sym + "." + ext)


class SymbolIsDelistedError(Exception):
    """This error indicates the symbol has been delisted (and price data for the symbol are no longer available)."""


def download_data_from_yahoo_finance(sym: str) -> None:
    """Download historical open/close data for sym from Yahoo! Finance.

    Example: https://query1.finance.yahoo.com/v7/finance/chart/SPY? ...
                ... period1=631170000&period2=1599022800&interval=1d&events=history&includeAdjustedClose=true

    Note:  Yahoo! Finance occasionally changes something that breaks this download.
           If you find this routine broken, please email me with the error, and I will try to find a fix."""
    d1 = DEFAULT_START_DATE
    d2 = (
        SYMBOL_DETAILS_DICT.get(sym, {}).get("end_date") or DEFAULT_END_DATE
    ) + timedelta(days=1)
    url_params = dict(
        interval="1d",
        events="history",
        period1=int(mktime((d1.year, d1.month, d1.day, 0, 0, 0, 0, 0, 0))),
        period2=int(mktime((d2.year, d2.month, d2.day, 0, 0, 0, 0, 0, 0))),
        includeAdjustedClose="true",
    )
    my_url = (
        "https://query1.finance.yahoo.com/v7/finance/chart/%s?" % quote(sym)
    ) + urlencode(url_params)
    r_headers = {
        "User-Agent": "Mozilla/5.0 (Windows; U; Windows NT 5.0; en-GB; rv:1.8.1.12) "
        "Gecko/20080201 Firefox/2.0.0.12"
    }
    print("Downloading %s data from Yahoo! Finance." % sym)
    r = requests.get(my_url, headers=r_headers)
    data = r.content.decode("utf-8")
    if "404 not found" in data:
        print(
            "Yahoo Finance did not provide the data we expect.  Waiting for a bit before retrying."
        )
        sleep(30)
        print("Downloading %s data from Yahoo! Finance." % sym)
        r = requests.get(my_url, headers=r_headers)
        data = r.content.decode("utf-8")

    j = loads(data)

    with open(get_data_filename(sym, "json"), "w", encoding="utf-8") as f:
        f.write(data)
    # If we will be downloading multiple files from Yahoo! Finance, do not be obnoxious about it.
    sleep(3)

    jerr = j["chart"].get("error")
    if jerr and jerr.get("code") == "Not Found":
        err = SymbolIsDelistedError(sym)
        err.add_note(
            "Yahoo Finance data download error:  "
            + (jerr.get("description") or "see " + get_data_filename(sym, "json"))
        )
        raise err
    try:
        jr = j["chart"]["result"][0]
        assert "timestamp" in jr, jr.keys()
        jriq = jr["indicators"]["quote"][0]
        assert all(k in jriq for k in ["high", "open", "low", "close"]), jriq.keys()
        assert "adjclose" in jr["indicators"]["adjclose"][0]
    except (AssertionError, IndexError, KeyError, TypeError) as err:
        err.add_note(
            "Yahoo Finance did not provide the data we expect.  The contents of %s should contain a clue "
            "as to what the problem is." % get_data_filename(sym, "json")
        )
        raise


def get_historical_open_close_data(sym: str, *, debug: bool = False) -> list[str]:
    """Return Yahoo! Finance's historical open/close price data for sym.
    Download the data if necessary."""
    if os.path.exists(get_data_filename(sym, "csv")):
        file_fmt: YahooFinanceFileFormat = "csv"
    elif os.path.exists(get_data_filename(sym, "json")):
        file_fmt = "json"
    else:
        download_data_from_yahoo_finance(sym)
        file_fmt = "json"
    data_filename = get_data_filename(sym, file_fmt)
    if file_fmt == "csv":
        with open(data_filename, encoding="utf-8") as f:
            data = f.read().split("\n")
        # double-check the header
        data_header = data[0].strip()
        if "delisted" in data_header:
            raise SymbolIsDelistedError(sym)
        assert data_header == "Date,Open,High,Low,Close,Adj Close,Volume", (
            sym,
            data_header,
        )
        return data
    elif file_fmt == "json":
        with open(data_filename, encoding="utf-8") as f:
            j = loads(f.read())
        err = j["chart"].get("error")
        if err and err.get("code") == "Not Found":
            raise SymbolIsDelistedError(sym)
        jr = j["chart"]["result"][0]
        tz = ZoneInfo(jr["meta"]["exchangeTimezoneName"])
        dates = [
            datetime.fromtimestamp(t, ZoneInfo("UTC"))
            .astimezone(tz)
            .strftime("%Y-%m-%d")
            for t in jr["timestamp"]
        ]
        jriq = jr["indicators"]["quote"][0]
        data = ["Date,Open,High,Low,Close,Adj Close,Volume"]
        data += [
            dates[i]
            + ","
            + ",".join(
                map(
                    dumps,
                    [
                        jriq["open"][i],
                        jriq["high"][i],
                        jriq["low"][i],
                        jriq["close"][i],
                        jr["indicators"]["adjclose"][0]["adjclose"][i],
                        jriq["volume"][i],
                    ],
                )
            )
            for i in range(len(dates))
        ]
        if debug:
            # write a csv file (because the csv file is a lot easier to manually debug than the json file)
            with open(get_data_filename(sym, "csv"), "w", encoding="utf-8") as f_csv:
                f_csv.write("\n".join(data) + "\n")
        return data


class OneDatePrices(NamedTuple):
    """One line of a file downloaded from Yahoo Finance"""

    date: datetime
    open: float
    close: float
    close_adj: float
    volume: float
    high: float
    low: float


def get_prices_open_close_adj_dates(
    original_data: list[str],
    start_date: datetime = None,
    end_date: datetime = None,
    bad_data_dates: Iterable[datetime] = (),
) -> list[OneDatePrices]:
    """Check original_data for a few known problems, and return a list of OneDatePrices.

    @param original_data: a list of the lines of a file, one line per date
    @param start_date: provided if data before start_date are suspect
    @param end_date: provided if data after end_date are suspect (or unavailable)
    @param bad_data_dates: provided if data for specific dates are suspect"""
    # Make sure the header is what we expect.
    assert original_data[0].strip() == "Date,Open,High,Low,Close,Adj Close,Volume", (
        original_data[0]
    )

    data = [d.split(",") for d in original_data[1:] if d and "null" not in d]
    data = [
        OneDatePrices(
            date=datetime.strptime(d[0], "%Y-%m-%d"),
            open=float(d[1]),
            close=float(d[4]),
            close_adj=float(d[5]),
            volume=float(d[-1]),
            high=float(d[2]),
            low=float(d[3]),
        )
        for d in data
    ]
    # Remove dates outside our date range.
    data = [
        d
        for d in data
        if (start_date or DEFAULT_START_DATE)
        <= d.date
        <= (end_date or DEFAULT_END_DATE)
    ]
    # Remove any known bad dates.
    data = [d for d in data if d.date not in bad_data_dates]

    if start_date:
        # If start_date is explicitly set, proceed assuming the data have been manually checked and start_date has been
        # thoughtfully determined.
        pass
    else:
        # If start_date is not explicitly set, automatically check for a few known problems
        # and try to set an appropriate start_date if any such problems are found.

        # In some cases (like the DAX before 1993-12-14), price_open == price_close because Yahoo! Finance does not have
        # opening prices.  If we are dealing with data like the DAX starting on 1993-01-01, recognize this, and
        # only return data from 1993-12-14 onward.
        if (i := [d.open != d.close for d in data].index(True)) > 1:
            data = data[i:]

        # If there are days with a negative adjusted close price or zero open price, drop these and all previous dates.
        # (See for example ADANIENT.NS before 2002-09-04.)
        for i in range(len(data), 0, -1):
            if data[i - 1].close_adj <= 0 or data[i - 1].open == 0:
                data = data[i:]
                break

        new_start_date: datetime | None = None
        # Check for stale open prices.
        # If there are many consecutive days with open == yesterday's close, drop these and all previous dates.
        # (See for example ^IBEX before 1999-02-23.)
        i_sd: int | None = None
        sd: datetime | None = None
        for i, d in enumerate(data):
            if (
                i > 0
                and d.open == data[i - 1].close
                and (d.volume or d.high != d.close or d.low != d.close)
            ):
                # the open price is equal to the previous day's close price and there is some indication of trading
                # (either nonzero volume or a different high or low price)
                if sd is None:
                    i_sd, sd = i, d.date
            elif sd:
                if (d.date - sd).days >= 20 and i - i_sd >= 10:
                    new_start_date = (
                        max(new_start_date, d.date) if new_start_date else d.date
                    )
                i_sd, sd = None, None
        # Check for unknown open prices.
        # If there are many consecutive days with open_price == today's close_price, then there is a good chance the
        # open price is unknown (to Yahoo Finance), and they just provided the close price for the open price.
        # In this case, we should discard the problematic period and all previous dates.
        # (See for example BARC.L before 1997-05-19.)
        i_sd, sd = None, None
        for i, d in enumerate(data):
            if d.open == d.close and (
                d.volume or d.high != d.close or d.low != d.close
            ):
                # the open price is equal to the close price and there is some indication of trading
                # (either nonzero volume or a different high or low price)
                if sd is None:
                    i_sd, sd = i, d.date
            elif sd:
                if (d.date - sd).days >= 20 and i - i_sd >= 10:
                    new_start_date = (
                        max(new_start_date, d.date) if new_start_date else d.date
                    )
                i_sd, sd = None, None
        if new_start_date:
            data = [d for d in data if d.date >= new_start_date]

    bad_dates: set[datetime] = set()
    # Discard any dates with open = high = low = close
    # (unless there is just a little volume, which could legitimately produce open = high = low = close).
    bad_dates |= set(
        d.date
        for d in data
        if d.open == d.high == d.low == d.close and not (0 < d.volume <= 1e4)
    )
    # Discard any dates with volume = 0 and price_open or price_close not between the day's high and low.
    # (See for example DG.PA on 2001-12-25.)
    if (
        len([d for d in data if d.volume > 0]) / len(data) > 0.8
    ):  # we have daily volumes, for the most part
        bad_dates |= set(
            d.date
            for d in data
            if (
                d.volume == 0
                and (
                    not (d.low <= d.open <= d.high) or not (d.low <= d.close <= d.high)
                )
            )
        )
    data = [d for d in data if d.date not in bad_dates]

    return data


def compute_returns_overnight_intraday(
    price_open: list[float],
    price_close: list[float],
    price_close_adj: list[float],
    dates_datetime: list[datetime],
) -> tuple[list[float], list[float]]:
    """Compute overnight and intraday returns from open and close prices.
    @return: (returns_overnight, returns_intraday)"""
    assert (
        len(price_open)
        == len(price_close)
        == len(price_close_adj)
        == len(dates_datetime)
    )
    n_days = len(dates_datetime)
    if n_days == 0:
        return [], []

    # Intraday returns are the returns from open to close.
    # returns_intraday[0] is the return from open on dates_datetime[0] to close on dates_datetime[0]
    returns_intraday = [price_close[i] / price_open[i] - 1 for i in range(n_days)]

    # Use adjusted prices to get close to close returns.
    # returns_close_to_close[1] is the return from close on dates_datetime[0] to close on dates_datetime[1]
    returns_close_to_close = [0.0] + [
        price_close_adj[i] / price_close_adj[i - 1] - 1 for i in range(1, n_days)
    ]

    # Overnight returns are close to close returns sans intraday returns.
    # returns_overnight[1] is the return from close on dates_datetime[0] to open on dates_datetime[1]
    returns_overnight = [0.0] + [
        (1 + returns_close_to_close[i]) / (1 + returns_intraday[i]) - 1
        # A big time gap (let's say two weeks or more) means we are missing data.
        # We should not attribute the total return over this time gap to overnight.
        if dates_datetime[i] - dates_datetime[i - 1] < timedelta(days=14)
        else 0
        for i in range(1, n_days)
    ]

    return returns_overnight, returns_intraday


class PlotData(object):
    """The data necessary to make a plot of cumulative overnight and intraday returns."""

    def __init__(
        self,
        dates_datetime: list[datetime],
        returns_overnight: list[float],
        returns_intraday: list[float],
    ) -> None:
        """returns_intraday[i] is the return from market open to market close on dates_datetime[i].
        returns_overnight[i] is the return from market close on dates_datetime[i-1] to market open on dates_datetime[i].
        """
        assert len(dates_datetime) == len(returns_overnight) == len(returns_intraday), (
            len(dates_datetime),
            len(returns_overnight),
            len(returns_intraday),
        )
        assert returns_overnight[0] == 0
        self._dates_datetime = list(dates_datetime)
        self._returns_overnight = list(returns_overnight)
        self._returns_intraday = list(returns_intraday)

    @property
    def n_days(self) -> int:
        """the number of days for which self has data"""
        return len(self._dates_datetime)

    @property
    def first_date(self) -> datetime:
        """the first date for which self has data"""
        return self._dates_datetime[0]

    @property
    def last_date(self) -> datetime:
        """the last date for which self has data"""
        return self._dates_datetime[-1]

    def plot_data(
        self, ax: Axes, vertical_scale: str = "linear"
    ) -> tuple[list[float], list[float]]:
        """Plot the cumulative overnight and intraday returns on the axis ax,
        with either linear or logarithmic vertical scale.
        @return: (overnight_curve, intraday_curve)"""
        r_func = dict(
            linear=(lambda r1: r1 * 100),  # show return in units of percent
            log=(
                lambda r1: r1 + 1
            ),  # show return as "this is what $1 turns into", log scale
        )[vertical_scale]
        overnight_curve = [r_func(r) for r in cumulate_returns(self._returns_overnight)]
        intraday_curve = [r_func(r) for r in cumulate_returns(self._returns_intraday)]
        dates_datenum = [date2num(d) for d in self._dates_datetime]
        assert overnight_curve[0] == r_func(
            0
        )  # just making sure we have what we expect
        ax.margins(x=0, y=0)
        ax.plot_date(dates_datenum, overnight_curve, fmt="-b", linewidth=1.5)
        ax.plot_date(dates_datenum, intraday_curve, fmt="-g", linewidth=1.5)
        if vertical_scale == "log":
            ax.set_yscale("log")
        return overnight_curve, intraday_curve

    def histogram_returns(self) -> None:
        """Histogram the distribution of overnight and intraday returns."""
        assert len(self._returns_overnight) == len(self._returns_intraday)
        assert self._returns_overnight[0] == 0  # no need to include this
        r = 3  # the horizontal axis of the histogram extends from -3% to +3%
        c = (
            r - 0.07
        )  # put underflow and overflow in the leftmost and rightmost bins, respectively
        n_bins = 10 * r * 2  # the histogram bin width is 0.1%
        hist(
            [clip(r1 * 1e2, -c, +c) for r1 in self._returns_overnight[1:]],
            bins=n_bins,
            range=(-r, +r),
            color="b",
            histtype="step",
            label="overnight",
        )
        hist(
            [clip(r1 * 1e2, -c, +c) for r1 in self._returns_intraday],
            bins=n_bins,
            range=(-r, +r),
            color="g",
            histtype="step",
            label="intraday",
        )
        xlim(-(r + 0.03), r + 0.03)
        # Print the overnight and intraday volatilities.
        # *Cap outliers for a more robust estimate.
        print(
            "overnight volatility* = %.2f%%"
            % (pstdev([clip(r1 * 100, -5, +5) for r1 in self._returns_overnight]))
        )
        print(
            "intraday volatility* = %.2f%%"
            % (pstdev([clip(r1 * 100, -5, +5) for r1 in self._returns_intraday]))
        )
        print("  (*See code for details.)")


def get_plot_data(sym: str, start_date: datetime = None) -> PlotData:
    """Extract the returns we want to plot from historical open and close prices."""
    data = get_historical_open_close_data(sym)
    s = SYMBOL_DETAILS_DICT.get(sym, {})
    try:
        one_date_prices = get_prices_open_close_adj_dates(
            data, s.get("start_date"), s.get("end_date"), s.get("bad_data_dates", [])
        )
        if start_date:
            one_date_prices = [d for d in one_date_prices if d.date >= start_date]

        price_open = [d.open for d in one_date_prices]
        price_close = [d.close for d in one_date_prices]
        price_close_adj = [d.close_adj for d in one_date_prices]
        dates_datetime = [d.date for d in one_date_prices]

        returns_overnight, returns_intraday = compute_returns_overnight_intraday(
            price_open, price_close, price_close_adj, dates_datetime
        )
    except AssertionError:
        logging.error("offending sym=%s" % sym)
        raise
    return (
        PlotData(dates_datetime, returns_overnight, returns_intraday)
        if dates_datetime
        else None
    )


def plot_returns_linear(plot_data: PlotData) -> None:
    """Draw a plot of cumulative overnight and intraday returns."""
    ax: Axes = gca()
    overnight_curve, intraday_curve = plot_data.plot_data(ax)
    # Add yticks on the right edge of the plot.
    todays_value = dict(overnight=overnight_curve[-1], intraday=intraday_curve[-1])
    todays_value_y = todays_value.copy()
    # If the cumulative overnight and intraday values are very close together, the text will overlap on the plot,
    # making the values hard to read.  In this case, we want to shift the position of the text slightly, to make sure
    # the final cumulative values are easy to read.  (Here, todays_value_{overnight,intraday} is the final value, and
    # todays_value_{overnight,intraday}_y is the position of the text that we may want to shift.)
    max_y = max(max(overnight_curve), max(intraday_curve))
    y_bottom = -100
    min_y_sep = 0.1 * (max_y - y_bottom)
    d = todays_value["overnight"] - todays_value["intraday"]
    if abs(d) < min_y_sep:
        todays_value_y["overnight"] += ((min_y_sep - abs(d)) / 2.0) * (
            +1 if d >= 0 else -1
        )
        todays_value_y["intraday"] += ((min_y_sep - abs(d)) / 2.0) * (
            -1 if d >= 0 else +1
        )
    ytick_right_x = xlim()[0] + (xlim()[-1] - xlim()[0]) * 1.005
    for k in todays_value.keys():
        ax.text(
            ytick_right_x,
            todays_value_y[k],
            return_percent_to_string(todays_value[k]),
            verticalalignment="center",
        )
    # Set yticks on the left side of the plot.
    ax.yaxis.set_ticks([0], [0])
    ax.set_ylim(y_bottom)


def plot_returns_log(
    plot_data: PlotData, *, currency_sym: str = None, show_returns: bool = False
) -> tuple[str, str]:
    """Draw a plot of cumulative returns.
    @return: (cumulative_overnight_return_str, cumulative_intraday_return_str)"""
    ax: Axes = gca()
    overnight_curve, intraday_curve = plot_data.plot_data(ax, vertical_scale="log")
    # Add yticks on the right edge of the plot.
    todays_value = dict(overnight=overnight_curve[-1], intraday=intraday_curve[-1])

    todays_value_y = todays_value.copy()
    # If the cumulative overnight and intraday values are very close together, the text will overlap on the plot,
    # making the values hard to read.  In this case, we want to shift the position of the text slightly, to make sure
    # the final cumulative values are easy to read.  (Here, todays_value_{overnight,intraday} is the final value, and
    # todays_value_{overnight,intraday}_y is the position of the text that we may want to shift.)
    max_y = max(max(overnight_curve), max(intraday_curve))
    min_y = min(min(overnight_curve), min(intraday_curve))
    min_y_sep = 0.1 * (log10(max_y) - log10(min_y))
    d = log10(todays_value["overnight"]) - log10(todays_value["intraday"])
    if abs(d) < min_y_sep:
        todays_value_y["overnight"] *= 10 ** (
            ((min_y_sep - abs(d)) / 2.0) * (+1 if d >= 0 else -1)
        )
        todays_value_y["intraday"] *= 10 ** (
            ((min_y_sep - abs(d)) / 2.0) * (-1 if d >= 0 else +1)
        )

    ytick_right_x = xlim()[0] + (xlim()[-1] - xlim()[0]) * 1.005
    if show_returns:
        start_str = "0"
        cumulative_str = dict(
            (k, return_percent_to_string((todays_value[k] - 1) * 100))
            for k in todays_value.keys()
        )
    else:
        start_str = (currency_sym or "") + "1"
        cumulative_str = dict(
            (k, format_money_as_string(todays_value[k], currency_sym))
            for k in todays_value.keys()
        )
    for k in todays_value.keys():
        ax.text(
            ytick_right_x,
            todays_value_y[k],
            " " + cumulative_str[k],
            verticalalignment="center",
        )
    # Set yticks on the left side of the plot.
    ax.yaxis.set_ticks([1], [start_str])
    ax.yaxis.set_tick_params(which="minor", left=False)
    return cumulative_str["overnight"], cumulative_str["intraday"]


def plot_one_sym_linear(sym: str) -> None:
    """Draw a plot of cumulative returns for the symbol sym."""
    fig: Figure = figure(1)
    fig.clf()
    fig.set_size_inches(6.0, 6.0, forward=True)
    plot_data = get_plot_data(sym)
    plot_returns_linear(plot_data)
    sym_details = SYMBOL_DETAILS_DICT.get(sym) or {}
    min_plot_date = datetime(
        sym_details.get("start_date", plot_data.first_date).year, 1, 1
    )
    ax: Axes = gca()
    ax.xaxis.set_major_locator(
        YearLocator(
            5
            if min_plot_date < datetime(2000, 1, 1)
            else 2
            if min_plot_date <= datetime(2012, 1, 1)
            else 1
        )
    )
    no_box(ax)
    ax.legend(
        ("overnight return", "intraday return"),
        loc="upper left",
        bbox_to_anchor=(0.00, 1.00),
        fontsize="large",
        frameon=False,
    )
    fig.text(
        0.52,
        0.95,
        sym,
        horizontalalignment="center",
        verticalalignment="top",
        transform=fig.transFigure,
        fontsize="x-large",
    )
    fig.subplots_adjust(
        left=0.05, right=0.85 - 0.016 * max(0, floor(log10(ylim()[1]) - 5))
    )


def plot_one_sym_log(sym: str, *, show_returns: bool = False) -> None:
    """Plot the value of $1 invested in sym, getting only overnight or intraday returns, with logarithmic scale.

    If show_returns is True, make exactly the same plot, but show the cumulative overnight and intraday returns
    (rather than the value of $1) at the right edge of the plot."""
    fig = figure(1)
    fig.clf()
    fig.set_size_inches(6.0, 6.5, forward=True)

    plot_data = get_plot_data(sym)
    currency_sym = sym_to_currency_tex(sym)
    s1, s2 = plot_returns_log(
        plot_data, currency_sym=currency_sym, show_returns=show_returns
    )
    n_chars_to_make_room_for_at_right = max(len(s1), len(s2))
    ax: Axes = gca()
    no_box(ax, keep_yticks=True)
    s = SYMBOL_DETAILS_DICT.get(sym) or {}
    min_plot_date = datetime(s.get("start_date", plot_data.first_date).year, 1, 1)
    ax.xaxis.set_major_locator(
        YearLocator(
            5
            if min_plot_date <= datetime(2000, 1, 1)
            else 2
            if min_plot_date <= datetime(2012, 1, 1)
            else 1
        )
    )
    fig.subplots_adjust(
        top=0.9,
        left=0.06 + (0 if show_returns else 0.01 * len(currency_sym or "")),
        right=0.94 - 0.011 * n_chars_to_make_room_for_at_right,
    )
    # Add figure title and legend.
    ax.legend(
        ("overnight", "intraday"),
        loc="upper left",
        bbox_to_anchor=(0.00, 1.00),
        frameon=False,
    )
    fig_text_kwargs = dict(horizontalalignment="center", transform=fig.transFigure)
    if show_returns:
        fig.text(
            0.52,
            0.90,
            sym,
            verticalalignment="bottom",
            fontsize="large",
            **fig_text_kwargs,
        )
        fig.text(
            0.52,
            0.89,
            "(log scale)",
            verticalalignment="top",
            fontsize="small",
            **fig_text_kwargs,
        )
    else:
        fig.text(
            0.52,
            0.90,
            (
                "Value of %(currency_sym)s1 invested in %(sym)s,\n"
                "getting only overnight or intraday returns\n(logarithmic vertical scale)"
                % dict(currency_sym=(currency_sym or ""), sym=sym)
            ),
            verticalalignment="bottom",
            fontsize="large",
            **fig_text_kwargs,
        )


def histogram_returns(sym: str, show_detail: bool = False) -> None:
    """Histogram sym's overnight and intraday returns.
    With sym == "SPY", make Figure 4 of [2021]."""
    plot_data = get_plot_data(sym)
    plot_data.histogram_returns()
    ax: Axes = gca()
    ax.legend(loc=2)
    if show_detail:  # show details a technically-minded person might care about
        figtext(0.135, 0.65, "bin width = 0.1%")
        figtext(0.135, 0.60, "total days = %d" % plot_data.n_days)
        ylabel("number of days per 0.1%")
    else:  # remove any lines and numbers we can
        no_box(ax)
        print("total days = %d" % plot_data.n_days)
    xlabel("return (%)")
    title(
        "Distribution of %s overnight and intraday returns\n(%d - %d)"
        % (sym, plot_data.first_date.year, plot_data.last_date.year)
    )


def plot_what_you_would_expect(which_article_yyyy: str, which_plot: int) -> None:
    """Make one of the individual plots in Figure 1 of [2022] or in Figure 2 of [2023], showing what you would expect
    overnight/intraday returns to look like if prices were a random walk and returns were due to the bearing of risk.

    @param which_article_yyyy: should be "2022" for Figure 1 of [2022] or "2023" for Figure 2 of [2023]
    @param which_plot: which of the individual plots to make
                        If which_article_yyyy=="2022", which_plot should be between 1 and 50.
                        If which_article_yyyy=="2023", which_plot should be between 1 and 25."""
    assert (
        which_article_yyyy == "2022"
        and 1 <= which_plot <= 50
        or which_article_yyyy == "2023"
        and 1 <= which_plot <= 25
    ), (which_article_yyyy, which_plot)
    # Feel free/encouraged to modify these parameters
    # (and change the for loop below to make a grid of plots, rather than a single plot) to see how things change.
    start_date, end_date = datetime(1990, 1, 1), datetime(2021, 12, 31)
    random_seed = 0  # random number seed
    expected_return_per_year = 0.07  # mu = 7%/year
    expected_volatility_per_sqrt_year = 0.20  # sigma = 20%/sqrt(year)
    cumulative_return_needed_to_survive = (
        3.0  # only keep plots with total return >= +300%
    )
    # The fraction of a day's price variance that realizes overnight can also be changed, but only in a limited range
    # (to remain consistent with the value realized in the world's stock markets).
    fraction_of_price_variance_realized_overnight = 1.0 / 3
    article_parameters = (
        start_date == datetime(1990, 1, 1)
        and end_date == datetime(2021, 12, 31)
        and random_seed == 0
        and expected_return_per_year == 0.07
        and expected_volatility_per_sqrt_year == 0.20
        and cumulative_return_needed_to_survive == 3.0
        and fraction_of_price_variance_realized_overnight == 1.0 / 3
    )

    # Given the parameters above, calculate some useful quantities and assert that things make sense.
    days_per_year = (
        365.25 * 5 / 7
    )  # In this toy world, the market is open Monday through Friday every week of the year.
    expected_return_per_day = expected_return_per_year / days_per_year
    fraction_of_price_variance_realized_intraday = (
        1 - fraction_of_price_variance_realized_overnight
    )
    # In all indices and individual stocks over the time period we consider,
    # the distribution of intraday returns is wider than the distribution of overnight returns.
    assert (
        fraction_of_price_variance_realized_overnight
        < fraction_of_price_variance_realized_intraday
    ), (
        "In the world's stock markets, prices move more intraday (between market open and market close) "
        "than they do overnight (between market close and market open).  "
        "See for example Figure 4 of 'They Chose to Not Tell You' [2021]."
    )
    o_i = (
        fraction_of_price_variance_realized_overnight
        / fraction_of_price_variance_realized_intraday
    )
    assert 0.25 <= o_i < 0.75, (
        "fraction_of_price_variance_realized_overnight is not reasonable"
    )
    # Returns are due to the bearing of risk.
    expected_return_per_overnight_period = (
        expected_return_per_day * fraction_of_price_variance_realized_overnight
    )
    expected_return_per_intraday_period = (
        expected_return_per_day * fraction_of_price_variance_realized_intraday
    )
    expected_volatility_per_sqrt_day = expected_volatility_per_sqrt_year / sqrt(
        days_per_year
    )
    expected_volatility_one_overnight_period = expected_volatility_per_sqrt_day * sqrt(
        fraction_of_price_variance_realized_overnight
    )
    expected_volatility_one_intraday_period = expected_volatility_per_sqrt_day * sqrt(
        fraction_of_price_variance_realized_intraday
    )
    assert (
        sqrt(
            expected_volatility_one_overnight_period**2
            + expected_volatility_one_intraday_period**2
        )
        * sqrt(days_per_year)
        == expected_volatility_per_sqrt_year
    )
    # As a final check, make sure this isn't going to take too long.
    n_days_total = (end_date - start_date).days * 5.0 / 7  # only weekdays
    x = (
        expected_return_per_day * n_days_total - cumulative_return_needed_to_survive
    ) / (expected_volatility_per_sqrt_day * sqrt(n_days_total))
    # (see e.g. https://stats.stackexchange.com/a/187909)
    fraction_of_plots_we_generate_that_we_expect_to_survive = (1 + erf(x / sqrt(2))) / 2
    assert fraction_of_plots_we_generate_that_we_expect_to_survive > 1e-3, (
        "this is going to take too long",
        fraction_of_plots_we_generate_that_we_expect_to_survive,
    )

    clf()
    random.seed(
        random_seed
    )  # to make a reproducible plot, explicitly seed the random number generator.
    for i in range({"2022": 50, "2023": 25}[which_article_yyyy]):
        while True:
            d = start_date
            returns_overnight = []
            returns_intraday = []
            dates_datetime = []
            total_return = 0.0
            while d <= end_date:
                if d.weekday() < 5:  # Monday through Friday
                    dates_datetime.append(d)
                    returns_overnight.append(
                        random.gauss(
                            expected_return_per_overnight_period,
                            expected_volatility_one_overnight_period,
                        )
                        # there is no overnight return on the very first day
                        if returns_overnight
                        else 0.0
                    )
                    returns_intraday.append(
                        random.gauss(
                            expected_return_per_intraday_period,
                            expected_volatility_one_intraday_period,
                        )
                    )
                    total_return = (1 + total_return) * (1 + returns_overnight[-1]) * (
                        1 + returns_intraday[-1]
                    ) - 1
                d += timedelta(days=1)
            if total_return > cumulative_return_needed_to_survive:
                if which_article_yyyy == "2023" and article_parameters:
                    cumulative_returns_overnight = cumulate_returns(returns_overnight)
                    cumulative_returns_intraday = cumulate_returns(returns_intraday)
                    y_height = log10(
                        1
                        + max(
                            *cumulative_returns_overnight, *cumulative_returns_intraday
                        )
                    ) - log10(
                        1
                        + min(
                            *cumulative_returns_overnight, *cumulative_returns_intraday
                        )
                    )
                    final_divergence = abs(
                        log10(1 + cumulative_returns_overnight[-1])
                        - log10(1 + cumulative_returns_intraday[-1])
                    )
                    assert 0 <= final_divergence <= y_height, (
                        final_divergence,
                        y_height,
                    )
                    # The value of 0.44 here has been fine-tuned to pass exactly 25 plots in [2023].
                    if final_divergence / y_height < 0.44:
                        continue
                break  # this one is a survivor

        if i + 1 == which_plot:
            plot_data = PlotData(dates_datetime, returns_overnight, returns_intraday)
            if which_article_yyyy == "2022":
                plot_returns_linear(plot_data)
                y_start = 0
            else:
                plot_returns_log(plot_data, show_returns=True)
                y_start = 1
            ax = gca()
            ax.xaxis.set_major_locator(YearLocator(10))
            no_box(ax)
            ax.yaxis.set_ticks([], [], minor=True)
            # show the value where the blue and green curves start at the left of the top left plot
            ax.text(
                date2num(plot_data.first_date - timedelta(days=120)),
                y_start,
                "0",
                verticalalignment="center",
                horizontalalignment="right",
            )
            break  # we have made the requested plot, so no need to continue

    # Add figure title and legend.
    ax: Axes = gca()
    fig: Figure = gcf()
    fig.set_size_inches(6, 6)
    ax.legend(
        ("overnight", "intraday"),
        loc="upper left",
        bbox_to_anchor=(0.02, 1.00),
        fontsize="large",
        frameon=False,
    )
    if article_parameters:
        vars_text = ("\nPlot #%d " % which_plot) + {
            "2022": "of Figure 1 of They Still Haven't Told You (2022)",
            "2023": "of Figure 2 of Nothing to See Here (2023)",
        }[which_article_yyyy]
        fig.text(
            0.52,
            0.92,
            vars_text,
            horizontalalignment="center",
            verticalalignment="bottom",
            transform=fig.transFigure,
            fontsize=12,
        )
    else:
        vars_text = (
            r"$\mu=%(mu_pct)s\ /\ {\\rm year}$, $\sigma= %(sigma_pct)s\ /\ \sqrt{\\rm year}$\n"
            "overnight variance / intraday variance = %(overnight_intraday)s\n"
            "keeping plots with total return $>%(survivor_pct)s$"
            % dict(
                mu_pct="%.0f" % (expected_return_per_year * 1e2) + r"\%",
                sigma_pct="%.0f" % (expected_volatility_per_sqrt_year * 1e2) + r"\%",
                overnight_intraday=("1 / 2" if 0.49 < o_i < 0.51 else "%0.2f" % o_i),
                survivor_pct="%+.0f" % (cumulative_return_needed_to_survive * 1e2)
                + r"\%",
            )
        )
        vars_text += "\nplot #%d" % which_plot
        fig.text(
            0.05,
            0.85,
            vars_text,
            horizontalalignment="left",
            verticalalignment="top",
            transform=ax.transAxes,
            fontsize=8,
        )
    fig.subplots_adjust(left=0.10, right=0.86)


if __name__ == "__main__":
    # Make a linear plot
    # plot_one_sym_linear("AAPL")
    # Make a log plot
    plot_one_sym_log("AAPL", show_returns=True)
    savefig("aapl_log.pdf")

#set page(paper: "us-letter", margin: 1in)
#set text(size: 10pt)
#set par(justify: true)

#align(center)[
  #text(size: 20pt, weight: "bold")[Optimal Event Trading]
]

#v(1em)

#columns(2)[
  = Introduction

  Event driven hedge funds rely on forming views on catalysts to generate PnL.
  In the case of earnings, a PM can generate 25% to 50% of their PnL from
  these bets. Thus, it is important to develop a framework for positioning
  and trading around events.

  = Market Impact Model

  To specify the cost of trading, we adopt the market-impact framework of
  Almgren and Chriss @almgren2000. Temporary price impact is taken to
  be linear in the trading rate: executing at rate $dot(x)(t)$ displaces the
  execution price by an amount proportional to $dot(x)(t)$. Because the cost
  accrued over an instant is the product of this displacement and the amount
  traded, it is quadratic in the rate.

  At calendar time $t$ you trade at a dollar rate $dot(x)(t)$ against a
  market dollar volume rate $v(t)$; the participation rate is
  $ pi(t) = dot(x)(t) / v(t). $

  = Heuristic Model

  We begin by developing a minimal model that isolates the essential
  trade-off governing event-driven position sizing. The trade is reduced to
  two competing terms: the expected profit accruing from the position held
  on the event date, $alpha(t) x(t)$, and the transaction cost incurred in
  establishing that position. Maximizing their difference yields a closed-form expression for
  the optimal size. Despite its simplicity, the model recovers the standard
  heuristics used by practitioners and provides quantitative guidance that
  we refine in the more general treatment that follows.
]

#bibliography("references.bib", title: "References", style: "ieee")

#pagebreak()

= Appendix

== Notation

#table(
  columns: (auto, 1fr, auto),
  align: (center, left, center),
  table.header([*symbol*], [*meaning*], [*units*]),
  [$v(t)$],
  [market's instantaneous dollar volume rate — the rate at which the tape
   prints, at calendar time $t$],
  [\$/day],

  [$tau(t) = integral_0^t v(s) dif s$],
  [cumulative market dollars traded since $t = 0$],
  [\$],

  [$V$],
  [a fixed reference daily volume — ADV, used only to rescale],
  [\$/day],

  [$dot(x)(t)$],
  [your dollar trading rate],
  [\$/day],

  [$x(t)$],
  [position, in dollars],
  [\$],

  [$alpha(t)$],
  [expected return over the event],
  [dimensionless],

  [$pi(t) = dot(x)(t) \/ v(t)$],
  [participation rate — your trading rate as a fraction of market volume],
  [dimensionless],
)

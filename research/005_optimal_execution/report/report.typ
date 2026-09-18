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

  As the foundational market-impact model, we present the framework of
  Almgren and Chriss @almgren2000. An investor holding $X$ shares must
  liquidate the full position by a fixed horizon $T$. Liquidating quickly
  concentrates trading into a short window and pushes execution prices away
  from the pre-trade price: *market impact*. Liquidating slowly avoids that
  cost but leaves the position exposed to the market's random drift for
  longer: *timing risk*. Almgren and Chriss cast this trade-off as a
  mean-variance optimization over the liquidation schedule.

  Discretize the horizon into $N$ steps of length $tau = T slash N$. Let
  $x_k$ denote the shares still held after step $k$, with $x_0 = X$ and
  $x_N = 0$, and let $n_k = x_(k-1) - x_k$ be the shares traded in step $k$.
  Three parameters drive the cost: permanent impact $gamma$ (the lasting
  price shift per share traded, which the market never unwinds), temporary
  impact $eta$ (the transient price concession demanded for trading at a
  given rate, which decays once trading stops), and volatility $sigma$ (the
  size of the position's random price moves per unit time).

  Permanent impact contributes $1/2 gamma X^2$ to expected cost: each share
  traded shifts the price by a further increment of $gamma$, so the average
  share pays half the full depression $gamma X$, giving a total of $X
  dot.c 1/2 gamma X = 1/2 gamma X^2$. This is fixed by the total size $X$
  and unaffected by the schedule, since every admissible schedule
  liquidates the same $X$. Temporary impact contributes
  $(eta slash tau) sum_(k=1)^N n_k^2$: because the cost of a step is
  quadratic in its trading rate, spreading the same shares over more time
  reduces it. The variance of total cost, driven by how many shares remain
  exposed and for how long, is $sigma^2 sum_(k=1)^N tau x_k^2$. Almgren and
  Chriss minimize
  $ EE("cost") + lambda VV("cost") $
  over the schedule $x_1, dots, x_(N-1)$, where $lambda >= 0$ is the
  trader's risk aversion. The full derivation, taken to its continuous-time
  limit, is given in the Appendix.

  The optimal schedule is
  $ x(t) = X (sinh(kappa(T-t))) / (sinh(kappa T)), quad
    kappa = sqrt(lambda sigma^2 slash eta). $
  The single parameter $kappa$ governs the shape of the liquidation curve.
  As $lambda -> 0$ (risk-neutral), $kappa -> 0$ and the schedule becomes
  linear: a constant liquidation rate, i.e. minimum-impact, TWAP-like
  execution. As $lambda$ grows, $kappa$ grows and the curve front-loads:
  more of the position is sold early, trading higher impact cost for lower
  exposure to timing risk. The quantity $1 slash kappa$ sets the
  characteristic time scale (the "half-life") over which the position is
  unwound.

  Temporary price impact is taken to be linear in the trading rate:
  executing at rate $dot(x)(t)$ displaces the execution price by an amount
  proportional to $dot(x)(t)$. Because the cost accrued over an instant is
  the product of this displacement and the amount traded, it is quadratic
  in the rate, consistent with the $eta n_k^2 slash tau$ term above.

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
  [market's instantaneous dollar volume rate: the rate at which the tape
   prints, at calendar time $t$],
  [\$/day],

  [$tau(t) = integral_0^t v(s) dif s$],
  [cumulative market dollars traded since $t = 0$],
  [\$],

  [$V$],
  [a fixed reference daily volume: ADV, used only to rescale],
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
  [participation rate: your trading rate as a fraction of market volume],
  [dimensionless],
)

== Almgren-Chriss derivation

Following @almgren2000, the discrete-time objective introduced in the
Market Impact Model section is
$ min_(x_1,\, dots,\, x_(N-1)) quad
  underbrace(1/2 gamma X^2 + eta/tau sum_(k=1)^N n_k^2, EE["cost"])
  + lambda underbrace(sigma^2 sum_(k=1)^N tau x_k^2, VV["cost"]). $
The permanent-impact term $1/2 gamma X^2$ does not depend on the schedule
$x_1, dots, x_(N-1)$ and drops out of the minimization; only the temporary
impact and variance terms shape the optimal path.

*Continuous limit.* Taking $N -> infinity$ with $tau = T slash N -> 0$,
write $x(t)$ for the holdings path and $dot(x)(t) = lim_(tau -> 0) (-n_k
slash tau)$ for the (negative) trading rate. The sums become integrals and
the objective reduces to
$ min_(x(dot)) integral_0^T [eta dot(x)(t)^2 + lambda sigma^2 x(t)^2] dif t,
  quad x(0) = X, quad x(T) = 0. $

*Euler-Lagrange.* This is a standard calculus-of-variations problem with
Lagrangian $L(x, dot(x)) = eta dot(x)^2 + lambda sigma^2 x^2$. The
Euler-Lagrange condition $dif/(dif t) (partial L)/(partial dot(x)) =
(partial L)/(partial x)$ gives
$ 2 eta dot.double(x)(t) = 2 lambda sigma^2 x(t)
  quad => quad dot.double(x)(t) = kappa^2 x(t), quad
  kappa^2 = lambda sigma^2 / eta. $

*Solving the ODE.* The general solution of $dot.double(x) = kappa^2 x$ is
$x(t) = A sinh(kappa t) + B cosh(kappa t)$. Imposing $x(T) = 0$ and $x(0) =
X$ and solving for $A, B$ collapses this to the single closed form
$ x(t) = X (sinh(kappa(T-t))) / (sinh(kappa T)). $

*Risk-neutral limit.* As $kappa -> 0$ the expression is a $0 slash 0$
indeterminate; using $sinh(z) approx z$ for small $z$,
$ (sinh(kappa(T-t))) / (sinh(kappa T))
  ->_(kappa -> 0) (kappa(T-t)) / (kappa T) = (T-t) / T, $
so $x(t) = X(1 - t slash T)$: constant-rate liquidation, recovering the
$lambda = 0$ (pure minimum-impact) case.

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

  = Optimal Execution

  As the foundational framework for optimal execution, we present the
  model of Almgren and Chriss @almgren2000. An investor holding $X$ shares
  must
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

  Accumulating a position instead of liquidating one leaves this analysis
  unchanged: the objective is direction-blind, since cost enters only
  through $n_k^2$, so only the boundary conditions flip, from
  $x_0 = X, x_N = 0$ to $x_0 = 0, x_N = X$. The optimal buy schedule is the
  exact time-reversal of the sell schedule,
  $x_"buy"(t) = X sinh(kappa t) slash sinh(kappa T)$, obtained from the sell
  formula by swapping $t <-> T-t$.

  Temporary price impact is taken to be linear in the trading rate:
  executing at rate $dot(x)(t)$ displaces the execution price by an amount
  proportional to $dot(x)(t)$. Because the cost accrued over an instant is
  the product of this displacement and the amount traded, it is quadratic
  in the rate, consistent with the $eta n_k^2 slash tau$ term above.
]

#bibliography("references.bib", title: "References", style: "ieee")

#pagebreak()

= Appendix

== Notation

#table(
  columns: (auto, 1fr, auto),
  align: (center, left, center),
  table.header([*symbol*], [*meaning*], [*units*]),
  [$X$],
  [total shares to be liquidated (or accumulated)],
  [shares],

  [$T$],
  [trading horizon],
  [day],

  [$tau = T slash N$],
  [length of one discretization step, with $N$ the number of steps],
  [day],

  [$x_k$, $x(t)$],
  [shares still held after step $k$, or at time $t$],
  [shares],

  [$n_k = x_(k-1) - x_k$],
  [shares traded in step $k$],
  [shares],

  [$gamma$],
  [permanent-impact coefficient: the persistent price shift per share
   traded],
  [\$/share²],

  [$eta$],
  [temporary-impact coefficient: the price concession per unit trading
   rate],
  [\$·day/share²],

  [$sigma$],
  [volatility of the traded asset],
  [\$/share/√day],

  [$lambda$],
  [risk aversion: the trader's chosen weight on cost variance],
  [1/\$],

  [$kappa = sqrt(lambda sigma^2 slash eta)$],
  [decay parameter setting the schedule's unwind timescale],
  [1/day],
)

== Almgren-Chriss derivation

Following @almgren2000, the discrete-time objective introduced in the
Optimal Execution section is
$ min_(x_1,\, dots,\, x_(N-1)) quad
  underbrace(1/2 gamma X^2 + eta/tau sum_(k=1)^N n_k^2, EE["cost"])
  + lambda underbrace(sigma^2 sum_(k=1)^N tau x_k^2, VV["cost"]). $
The permanent-impact term $1/2 gamma X^2$ does not depend on the schedule
$x_1, dots, x_(N-1)$ and drops out of the minimization. Naming the
remaining coefficients $a = eta slash tau$ and $b = lambda sigma^2 tau$
turns what is left into
$ F = a sum_(k=1)^N (x_(k-1) - x_k)^2 + b sum_(k=1)^(N-1) x_k^2, $
with the endpoints $x_0 = X$ and $x_N = 0$ held fixed and only the
interior holdings $x_1, dots, x_(N-1)$ free.

*First-order condition.* $F$ is a sum of squares, a convex bowl with a
single minimum where every partial derivative vanishes. For an interior
$x_j$, the only terms containing it are $(x_(j-1) - x_j)^2$,
$(x_j - x_(j+1))^2$, and $b x_j^2$, so
$ (partial F)/(partial x_j) = a [-2(x_(j-1) - x_j) + 2(x_j - x_(j+1))]
  + 2 b x_j = 0. $
Dividing by $2$ and rearranging gives a recurrence linking each holding to
its two neighbors:
$ x_(j+1) - 2 x_j + x_(j-1) = b/a x_j = (lambda sigma^2 tau^2)/eta x_j. $

*The recurrence is a discrete second derivative.* The left-hand side is
exactly the centered second-difference stencil,
$x_(j+1) - 2 x_j + x_(j-1) approx tau^2 dot.double(x)(t_j)$. Dividing the
recurrence by $tau^2$ and taking $N -> infinity$ ($tau -> 0$) turns it
into the ODE
$ dot.double(x)(t) = kappa^2 x(t), quad kappa^2 = (lambda sigma^2)/eta. $
The discrete first-order condition and the continuous Euler-Lagrange
equation for this problem coincide; the recurrence above is simply that
equation sampled on a grid.

*Solving the ODE.* The general solution of $dot.double(x) = kappa^2 x$ is
$x(t) = A e^(kappa t) + B e^(-kappa t)$. For a *sell* schedule, impose
$x(0) = X$ and $x(T) = 0$:
$ A + B = X, quad A e^(kappa T) + B e^(-kappa T) = 0. $
Solving for $A, B$ and folding the exponentials into hyperbolic sines
($sinh z = 1/2 (e^z - e^(-z))$) collapses this to the single closed form
$ x(t) = X (sinh(kappa(T-t))) / (sinh(kappa T)). $

*Risk-neutral limit.* As $kappa -> 0$ the expression is a $0 slash 0$
indeterminate; using $sinh(z) approx z$ for small $z$,
$ (sinh(kappa(T-t))) / (sinh(kappa T))
  ->_(kappa -> 0) (kappa(T-t)) / (kappa T) = (T-t) / T, $
so $x(t) = X(1 - t slash T)$: constant-rate liquidation, recovering the
$lambda = 0$ (pure minimum-impact) case.

*Buying as the mirror image.* Accumulating a position instead of
liquidating one leaves the objective, and therefore the ODE, unchanged:
$n_k$ (and $dot(x)$) enter only squared, so cost is direction-blind. Only
the boundary conditions flip, to $x(0) = 0$ and $x(T) = X$, which gives
$A = -B$ and
$ x(t) = X (sinh(kappa t)) / (sinh(kappa T)). $
The sell and buy schedules are exact time-reversals of one another,
related by swapping $t <-> T - t$:
$ x_"sell"(t) = X (sinh(kappa(T-t)))/(sinh(kappa T)), quad
  x_"buy"(t) = X (sinh(kappa t))/(sinh(kappa T)). $

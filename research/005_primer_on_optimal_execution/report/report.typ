#set page(paper: "us-letter", margin: 1in)
#set text(size: 10pt)
#set par(justify: true)

#show cite: it => text(fill: rgb("#1a73e8"))[#it]
#show link: it => text(fill: rgb("#c2410c"))[#it]
#show regex("^\[\d+\]"): it => text(fill: rgb("#1a73e8"))[#it]

#align(center)[
  #text(size: 20pt, weight: "bold")[A Primer on Optimal Execution]

  #v(0.5em)
  #text(size: 12pt)[BayQuant]
]

#v(1em)

#columns(2)[
  == The Trading Dilemma

  Liquidating a large position is no free lunch: execution moves prices
  against the order. Sell it all at once and *market impact* is
  concentrated into a short, severe shock. Spread it out and impact
  cost falls, but the remaining shares sit exposed to the market's
  random swings for longer: *timing risk*. This primer works through the
  model of Almgren and Chriss @almgren2000, who cast optimal liquidation
  as a mean-variance problem, minimizing a *risk-adjusted cost*: expected
  cost plus risk aversion times its variance. It derives the optimal
  schedule and replicates their efficient frontier.

  == Price Dynamics and Impact

  The price follows Arithmetic Brownian Motion (ABM), disturbed by
  volatility and drift (exogenous) and by the trader's own activity
  (endogenous). Discretizing the
  horizon into $N$ steps of length $tau = T slash N$, with grid points
  $t_k = k tau$, $x_k$ shares held after step $k$ ($x_0 = X$, $x_N = 0$)
  and $n_k = x_(k-1) - x_k$ shares traded in step $k$, the price process is
  $ S_k = S_(k-1) + #text(fill: red)[$alpha$] tau + sigma sqrt(tau) xi_k - tau g(n_k/tau), quad #link(<eq-price-process-appendix>)[(1)] $ <eq-price-process>
  where $xi_k$ are i.i.d. shocks with zero mean and unit variance,
  independent of the trading, $g(v)$
  is the *permanent impact* (persists in the price process), and the drift
  #text(fill: red)[$alpha$] is taken as #text(fill: red)[zero] throughout since no directional
  information is assumed.

  ABM is an assumption. Its shocks $sigma sqrt(tau) xi_k$ have a fixed
  dollar size; under geometric Brownian motion (GBM) they would instead
  scale with the current price, $sigma S_(k-1) sqrt(tau) xi_k$, making
  the risk of each step depend on the path the price has taken. Over
  trading horizons of days, however, fractional price changes are small,
  so the two are practically indistinguishable @almgren2000. Moreover, ABM
  is far more tractable: it keeps the variance of the cost a simple
  quadratic in the holdings.

  Trading also incurs a *temporary impact* $h(v)$: a transient
  concession on the execution price of a single step, so the price actually 
  received in step $k$ is
  $ tilde(S)_k = S_(k-1) - h(n_k/tau). $
  In both $g$ and $h$, the argument $v = n_k slash tau$ is the average rate
  of trading during the interval $t_(k-1)$ to $t_k$.

  == Cost of Trading

  Following Perold (1988) #cite(<perold1988>), the *implementation shortfall*
  $X S_0 - sum_k n_k tilde(S)_k$ is the
  cost of trading relative to the initial book value. Expanding the
  capture term $sum_k n_k tilde(S)_k$ (total trading revenue) gives the
  shortfall's expectation and variance
  #align(center, grid(columns: 2, align: horizon, column-gutter: 1em,
    [$ E(x) &= sum_k tau x_k g(n_k/tau) + sum_k n_k h(n_k/tau), \
      V(x) &= sigma^2 sum_k tau x_k^2. $ <eq-capture-main>],
    link(<eq-capture>)[(2)],
  ))
  Specializing to linear impact, $g(v) = gamma v$ and $h(v) = epsilon
  "sgn"(v) + eta v$ (with $epsilon$ a fixed cost per trade, e.g. half the
  bid-ask spread), summation by parts gives the permanent-impact term
  $ sum_k tau x_k g(n_k/tau)
    = 1/2 gamma X^2 - 1/2 gamma sum_k n_k^2, quad #link(<eq-perm-impact-appendix>)[(3)] $ <eq-perm-impact>
  so its contribution to $E(x)$ is *not* schedule-independent at finite
  $tau$. Temporary impact contributes
  $ sum_k n_k h(n_k/tau) = epsilon sum_k abs(n_k) + (eta slash tau) sum_k n_k^2. $
  Combining, and
  writing $overline(eta) = eta - 1/2 gamma tau$ to absorb the
  schedule-dependent permanent-impact term,
  $ E(x) = 1/2 gamma X^2 + epsilon sum_k abs(n_k)
    + overline(eta)/tau sum_k n_k^2. $
  For a monotone schedule ($n_k$ all one sign), $sum_k abs(n_k) = X$ (a
  telescoping sum), so only the last term shapes the schedule. Almgren and Chriss minimize the
  utility function
  $ U(x) = E(x) + lambda V(x) $
  over $x_1, dots, x_(N-1)$, where $lambda >= 0$ is risk aversion.

  == The Optimal Schedule

  The terms $1/2 gamma X^2 + epsilon X$ are the same for every schedule,
  so they do not change the optimal schedule and can be dropped.
  What remains is a quadratic in the holdings,
  $ U(x) = overline(eta)/tau sum_k (x_(k-1) - x_k)^2
    + lambda sigma^2 tau sum_k x_k^2, $
  with the endpoints $x_0 = X$ and $x_N = 0$ held fixed and only the
  interior holdings $x_1, dots, x_(N-1)$ free. The first sum penalizes
  trading fast (impact cost), the second penalizes holding inventory
  (timing risk). $U(x)$ is convex, so its unique minimum is where every
  partial derivative vanishes, which gives the second-order linear recurrence
  $ (x_(j+1) - 2 x_j + x_(j-1))/tau^2 = tilde(kappa)^2 x_j, quad
    tilde(kappa)^2 = (lambda sigma^2)/overline(eta), quad #link(<eq-recurrence-appendix>)[(4)] $ <eq-recurrence>
  a discrete analogue of $dot.double(x)(t) = tilde(kappa)^2 x(t)$, where:
  - $x(t)$ is the position still held at time $t$;
  - $dot.double(x)(t)$ measures how the pace of trading $abs(dot(x)(t))$
    changes: zero at a constant pace, positive when a seller slows down;
  - $tilde(kappa)^2$ is the price of risk relative to the price of impact.
  Multiplying by $overline(eta)$ gives $overline(eta) dot.double(x)(t) =
  lambda sigma^2 x(t)$: at every moment, the change in the marginal impact
  cost of trading balances the marginal risk cost of holding $x(t)$ shares.
  The trader therefore sells fastest while the position is large and
  slows down as it shrinks, so the holdings path is convex, bowing below
  the straight line of constant-rate trading.

  Solving it gives a decay rate $theta$, the solution of
  $ 2/tau^2 (cosh(theta tau) - 1) = tilde(kappa)^2, quad #link(<eq-decay-appendix>)[(5)] $ <eq-decay>
  and the optimal liquidation trajectory
  $ x_j = X (sinh(theta(T - t_j))) / (sinh(theta T)), quad #link(<eq-holdings-appendix>)[(6)] $ <eq-holdings>
  for $j = 0, dots, N$, with the associated trade list
  $ n_j = (2 sinh(1/2 theta tau)) / (sinh(theta T))
    cosh(theta(T - t_(j-1/2))) X, quad #link(<eq-trades-appendix>)[(7)] $ <eq-trades>
  for $j = 1, dots, N$, where $t_(j-1/2) = (j - 1/2) tau$ is the midpoint
  of step $j$.

  *Continuous-time limit.* As $tau -> 0$, $overline(eta) -> eta$ and both
  $theta$ and $tilde(kappa)$ tend to $kappa = sqrt(lambda sigma^2 slash
  eta)$. The trajectory (6) becomes
  $ x(t) = X (sinh(kappa(T - t))) / (sinh(kappa T)), $
  the solution of $dot.double(x)(t) = kappa^2 x(t)$, and the trading rate
  $n_j slash tau$ from (7) becomes
  $ -dot(x)(t) = X kappa (cosh(kappa(T - t))) / (sinh(kappa T)). $
  The minus sign makes a sale's rate positive, matching $n_k = x_(k-1) -
  x_k$; a purchase has negative $n_k$ and rate, and every equation holds
  unchanged.

  == The Shape of the Schedule

  $theta$ alone governs the curve's shape. As $lambda -> 0$, $theta -> 0$
  and $sinh(z) approx z$ makes the schedule linear: constant-rate,
  TWAP-like execution. As $lambda$ grows, $theta$ grows and the curve
  front-loads, accepting more impact cost in return for less timing
  risk.

  #image("../output/optimal_holdings_trajectory.png", width: 100%)

  == The Efficient Frontier

  Sweeping $lambda >= 0$ traces out a curve of $(V(x), E(x))$ pairs, one
  per optimal trajectory: the *efficient frontier* of optimal execution.
  Each point is the lowest expected cost achievable at that variance; no
  monotone schedule beats the frontier on both at once. At $lambda = 0$
  the frontier sits at its minimum-cost, maximum-variance end (the TWAP
  schedule, which minimizes $sum_k n_k^2$ for fixed $X$); increasing
  $lambda$ moves along the frontier toward lower variance at higher cost
  as the schedule front-loads.

  The figure replicates Figure 1 of @almgren2000 with their test-case
  parameters ($X = 10^6$ shares, $T = 5$ days, $N = 5$). Past the
  risk-neutral point B, $lambda < 0$ (dashed) describes a risk-seeking
  trader who delays selling and pays more in both cost and variance, so
  that branch is not efficient. At each point, the slope of the frontier
  is $-lambda$; the straight line shows this tangent at $lambda =
  10^(-6)$.

  #image("../output/efficient_frontier.png", width: 100%)

  == Half-Life of a Trade

  For $theta T gt.tilde 1$, $sinh(theta(T-t)) slash sinh(theta T) approx
  e^(-theta t)$, so holdings decay approximately exponentially,
  $x(t) approx X e^(-theta t)$, and $1 slash theta$ is the timescale of
  the unwind: after a time $1 slash theta$, about $e^(-1) approx 37%$ of
  the position remains. The time for the position to fall to half
  its initial size is the *half-life*
  $ t_(1\/2) = ln(2) / theta approx ln(2) / kappa
    = ln(2) sqrt(eta / (lambda sigma^2)). $
  Half-life shrinks with risk aversion $lambda$ and volatility $sigma$
  (faster unwinds when risk is costlier) and grows with the
  temporary-impact coefficient $eta$ (slower unwinds when trading is more
  expensive).

  == Buying as the Mirror Image

  Since cost enters only through $n_k^2$, the objective is direction-blind:
  accumulating a position just flips the boundary conditions to $x_0 = 0$,
  $x_N = X$, giving the time-reversal of the sell schedule,
  $ x_j = X (sinh(theta t_j)) / (sinh(theta T)). $

  == Implementation: Numerical Stability

  Equations (5) to (7) are exact but fail in floating point at both ends
  of the risk-aversion range. Three rewrites keep them accurate.

  *Decay rate.* Inverting (5) directly gives $theta = tau^(-1)
  "arccosh"(1 + 1/2 tilde(kappa)^2 tau^2)$, but for small $tilde(kappa)
  tau$ the argument rounds to 1 and $theta$ collapses to 0 (in double
  precision already at $tilde(kappa) tau approx 10^(-8)$). Since $cosh z -
  1 = 2 sinh^2(z slash 2)$, (5) is equivalent to $2 tau^(-1) sinh(1/2 theta
  tau) = tilde(kappa)$, which inverts without cancellation:
  $ theta = 2/tau "arcsinh"((tilde(kappa) tau)/2). $

  *Overflow.* $sinh(theta T)$ overflows in double precision once $theta T
  gt.tilde 710$, and (6) and (7) then evaluate to $infinity slash infinity$.
  Factoring out the dominant exponential leaves only non-positive
  exponents,
  $ x_j = X e^(-theta t_j) (1 - e^(-2 theta(T - t_j))) / (1 - e^(-2 theta T)), $
  $ n_j = X (2 sinh(1/2 theta tau) e^(-theta t_(j-1/2))
    (1 + e^(-2 theta(T - t_(j-1/2))))) / (1 - e^(-2 theta T)). $
  Computing the trades from (7) rather than as $x_(j-1) - x_j$ also avoids
  cancellation late in an aggressive schedule, when consecutive holdings
  are nearly equal.

  *Risk-neutral limit.* As $theta -> 0$, each $1 - e^(-u)$ factor above
  loses its leading digits to cancellation; evaluating it as
  $-"expm1"(-u)$ keeps full precision for small $u$. At $theta = 0$
  exactly the expressions are $0 slash 0$, so that case returns the linear
  schedule $x_j = X (T - t_j) slash T$, $n_j = X slash N$ directly.
]

#pagebreak()

= Appendix

== Price Process from Continuous Time <eq-price-process-appendix>

#link(<eq-price-process>)[Equation (1)]
$ dif S_t = (alpha - g(v_t)) dif t + sigma dif W_t, $
where $v_t$ is the trader's continuous trading rate. Discretizing via
Euler-Maruyama, with $n_k slash tau$ standing in for $v_t$ and
$W_(t_k) - W_(t_(k-1)) approx sqrt(tau) xi_k$ for the Brownian increment
over step $k$, gives
$ S_k = S_(k-1) + alpha tau + sigma sqrt(tau) xi_k - tau g(n_k/tau),
  quad k = 1, dots, N. $

== Capture Identity <eq-capture>

#link(<eq-capture-main>)[Equation (2)]

*Temporary impact.* The capture (total trading revenue) is
$sum_k n_k tilde(S)_k$. Substituting the execution price
$tilde(S)_k = S_(k-1) - h(n_k/tau)$ splits it into trading at the
prevailing price minus the temporary-impact concession,
$ sum_(k=1)^N n_k tilde(S)_k
  = sum_(k=1)^N n_k S_(k-1) - sum_(k=1)^N n_k h(n_k/tau). $

*Summation by parts.* Writing $n_k = x_(k-1) - x_k$ in the first sum and
shifting the index of its first half by one,
$ sum_(k=1)^N n_k S_(k-1)
  &= sum_(k=0)^(N-1) x_k S_k - sum_(k=1)^N x_k S_(k-1) \
  &= x_0 S_0 + sum_(k=1)^N x_k (S_k - S_(k-1)), $
where the second line pairs the terms with the same $x_k$ and uses
$x_N = 0$ to extend the first sum to $k = N$. With $x_0 = X$, the revenue
is the initial book value $X S_0$ plus the price change of each step
earned on the shares still held.

*Price dynamics.* By equation (1) with zero drift, each price change is
$S_k - S_(k-1) = sigma sqrt(tau) xi_k - tau g(n_k/tau)$. Substituting it
gives the capture identity
$ sum_(k=1)^N n_k tilde(S)_k = X S_0 + sum_(k=1)^N (sigma sqrt(tau) xi_k -
  tau g(n_k/tau)) x_k - sum_(k=1)^N n_k h(n_k/tau). $

*Expectation and variance.* The implementation shortfall is therefore
$ X S_0 - sum_(k=1)^N n_k tilde(S)_k
  = - sum_(k=1)^N sigma sqrt(tau) xi_k x_k
  + sum_(k=1)^N tau x_k g(n_k/tau) + sum_(k=1)^N n_k h(n_k/tau). $
Only the first sum is random. The $xi_k$ have zero mean, so it drops out
of the expectation, giving $E(x)$; the last two sums are fixed by the
schedule, and the $xi_k$ are independent with unit variance, so the
variance is $V(x) = sigma^2 sum_k tau x_k^2$.

== Permanent-Impact Summation by Parts <eq-perm-impact-appendix>

#link(<eq-perm-impact>)[Equation (3)]

Since $n_k = x_(k-1) - x_k$,
$ x_(k-1)^2 - x_k^2 = (x_(k-1) - x_k)(x_(k-1) + x_k) = n_k x_(k-1) + n_k x_k. $
Summing over $k = 1, dots, N$ telescopes the left side to $x_0^2 - x_N^2 =
X^2$, giving
$ sum_k n_k x_(k-1) + sum_k n_k x_k = X^2. $
Separately, $n_k(x_(k-1) - x_k) = n_k^2$, so
$ sum_k n_k x_(k-1) - sum_k n_k x_k = sum_k n_k^2. $
Subtracting the second identity from the first and dividing by 2,
$ sum_k n_k x_k = 1/2 X^2 - 1/2 sum_k n_k^2. $
Multiplying by $gamma$ gives equation (3).

== Optimal-Schedule Recurrence <eq-recurrence-appendix>

#link(<eq-recurrence>)[Equation (4)]

Take general endpoints $x_0 = X_0$ and
$x_N = X_T$. $U(x)$ is a sum of squares, a convex bowl with a single minimum
where every partial derivative vanishes. For an interior $x_j$, the only
terms containing it are $(x_(j-1) - x_j)^2$, $(x_j - x_(j+1))^2$, and
$lambda sigma^2 tau x_j^2$, so
$ (partial U)/(partial x_j) = overline(eta)/tau
  [-2(x_(j-1) - x_j) + 2(x_j - x_(j+1))]
  + 2 lambda sigma^2 tau x_j = 0. $
Dividing by $2 overline(eta) slash tau$ and rearranging gives
$ x_(j+1) - 2 x_j + x_(j-1)
  = (lambda sigma^2)/overline(eta) tau^2 x_j
  = tilde(kappa)^2 tau^2 x_j, $
and dividing by $tau^2$ gives equation (4).

== Decay Rate <eq-decay-appendix>

#link(<eq-decay>)[Equation (5)]

Equation (4) is a second-order linear homogeneous difference equation
with constant coefficients and values fixed at both ends. Its solution
space is two-dimensional, so the task is to find two independent
solutions and fit two constants.

Substituting the trial solution $x_j = e^(theta t_j)$, with
$t_(j plus.minus 1) = t_j plus.minus tau$,
$ (e^(theta tau) - 2 + e^(-theta tau))/tau^2 e^(theta t_j)
  = 2/tau^2 (cosh(theta tau) - 1) e^(theta t_j)
  = tilde(kappa)^2 e^(theta t_j). $
The factor $e^(theta t_j)$ never vanishes, so $e^(theta t_j)$ is an exact
solution whenever $theta$ satisfies the cosh relation, equation (5).
$theta$ differs
from $tilde(kappa)$ because a second difference is not a second
derivative: $2(cosh z - 1) = z^2 + z^4 slash 12 + dots$, so
$theta = tilde(kappa) + O(tau^2)$. Because $cosh$ is even, $e^(-theta t_j)$
is also a solution; the ratio $e^(2 theta t_j)$ of the two is non-constant
for $theta > 0$, so they are independent and span every solution.

== Optimal Liquidation Trajectory <eq-holdings-appendix>

#link(<eq-holdings>)[Equation (6)]

*Boundary conditions.* The general solution of equation (4) is
$ x_j = A e^(theta t_j) + B e^(-theta t_j), $
and the two endpoints give a linear system in $A$ and $B$,
$ A + B = X_0, quad A e^(theta T) + B e^(-theta T) = X_T. $
From the first equation $B = X_0 - A$; substituting into the second and
using $e^(theta T) - e^(-theta T) = 2 sinh(theta T)$,
$ A = (X_T - X_0 e^(-theta T)) / (2 sinh(theta T)), quad
  B = (X_0 e^(theta T) - X_T) / (2 sinh(theta T)). $
Reassembling $x_j = A e^(theta t_j) + B e^(-theta t_j)$ and grouping the
two coefficients,
$ 2 sinh(theta T) thin x_j
  &= X_T (e^(theta t_j) - e^(-theta t_j))
   + X_0 (e^(theta T) e^(-theta t_j) - e^(-theta T) e^(theta t_j)) \
  &= X_T (e^(theta t_j) - e^(-theta t_j))
   + X_0 (e^(theta(T - t_j)) - e^(-theta(T - t_j))) \
  &= 2 X_T sinh(theta t_j) + 2 X_0 sinh(theta(T - t_j)), $
where the second line used $e^(theta T) e^(-theta t_j) = e^(theta(T - t_j))$
and $e^(-theta T) e^(theta t_j) = e^(-theta(T - t_j))$. Each $sinh$ emerges
on its own from a pair of exponentials of opposite sign, so no basis has to
be guessed in advance. Dividing by $2 sinh(theta T)$ gives
$ x_j = (X_0 sinh(theta(T - t_j)) + X_T sinh(theta t_j)) / (sinh(theta T)), $
a hyperbolic interpolation between the endpoints: the first term carries
$X_0$ and vanishes at $t = T$, the second carries $X_T$ and vanishes at
$t = 0$. As $theta -> 0$ it reduces to the straight line
$x_j = (X_0 (T - t_j) + X_T t_j) slash T$, and larger $theta$ bows the path
further from it. Setting $X_0 = X$, $X_T = 0$ gives equation (6).

*Time consistency.* Re-planning at step $m$ from the current position
$x_m$, with $X_T = 0$ over the remaining horizon $T - t_m$, gives
$ x_j = x_m (sinh(theta(T - t_j))) / (sinh(theta(T - t_m))),
  quad j = m, dots, N. $
If $x_m$ is on schedule, $x_m = X sinh(theta(T - t_m)) slash
sinh(theta T)$ by equation (6), the factor $sinh(theta(T - t_m))$ cancels
and the re-planned path is exactly the remainder of equation (6).

== Trade List <eq-trades-appendix>

#link(<eq-trades>)[Equation (7)]

Since $n_j = x_(j-1) - x_j$, equation (6) gives
$ n_j = X / (sinh(theta T))
  [sinh(theta(T - t_(j-1))) - sinh(theta(T - t_j))]. $
The identity $sinh u - sinh v = 2 cosh((u+v) slash 2) sinh((u-v) slash 2)$,
with $u - v = theta tau$ and $(u+v) slash 2 = theta(T - t_(j-1/2))$, gives
equation (7).

== Notation

#table(
  columns: (auto, 1fr, auto),
  align: (center, left, center),
  stroke: 0.4pt,
  table.header([*symbol*], [*meaning*], [*units*]),
  [$X$],
  [total shares to be liquidated (or accumulated)],
  [shares],

  [$X_0$, $X_T$],
  [holdings at the start and end of a schedule; $X_0 = X$ and $X_T = 0$
   for a full liquidation],
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

  [$S_k$, $S(t)$],
  [security price after step $k$, or at time $t$, with $S_0$ the
   initial price],
  [\$/share],

  [$alpha$],
  [drift rate of the price process; assumed zero throughout],
  [\$/share/day],

  [$xi_k$],
  [i.i.d. shock in step $k$, zero mean and unit variance],
  [—],

  [$n_k = x_(k-1) - x_k$],
  [shares traded in step $k$],
  [shares],

  [$n_k slash tau$],
  [trading rate during step $k$: shares traded per unit time, not to be
   confused with $n_k$ itself],
  [shares/day],

  [$g(v)$],
  [function of trading rate $v$ entering the price process; its effect
   carries forward into $S_k$],
  [\$/share],

  [$tilde(S)_k$],
  [actual price per share received in step $k$],
  [\$/share],

  [$h(v)$],
  [temporary-impact function: the drop in average price per share
   from trading at rate $v$ during one interval; does not carry
   forward into $S_k$],
  [\$/share],

  [$E(x)$],
  [expected cost of trading schedule $x$],
  [\$],

  [$V(x)$],
  [variance of the cost of trading schedule $x$],
  [\$²],

  [$U(x) = E(x) + lambda V(x)$],
  [utility function minimized over the schedule; convex, so its unique
   minimum is found by setting $partial U slash partial x_j = 0$],
  [\$],

  [$gamma$],
  [permanent-impact coefficient: the persistent price shift per share
   traded],
  [\$/share²],

  [$eta$],
  [temporary-impact coefficient: the price concession per unit trading
   rate],
  [\$·day/share²],

  [$epsilon$],
  [fixed cost per trade in $h(v)$, e.g. half the bid-ask spread plus
   fees],
  [\$/share],

  [$overline(eta) = eta - 1/2 gamma tau$],
  [temporary-impact coefficient net of the permanent-impact
   schedule-dependent term; $overline(eta) -> eta$ as $tau -> 0$],
  [\$·day/share²],

  [$sigma$],
  [volatility of the traded asset],
  [\$/share/√day],

  [$lambda$],
  [risk aversion: the trader's chosen weight on cost variance],
  [1/\$],

  [$tilde(kappa) = sqrt(lambda sigma^2 slash overline(eta))$],
  [coefficient of the discrete optimality recurrence],
  [1/day],

  [$theta$],
  [decay rate of the optimal schedule, solving $2 tau^(-2) (cosh(theta
   tau) - 1) = tilde(kappa)^2$; $theta -> kappa$ as $tau -> 0$],
  [1/day],

  [$kappa = sqrt(lambda sigma^2 slash eta)$],
  [continuous-time limit of both $theta$ and $tilde(kappa)$],
  [1/day],
)

$gamma$ and $eta$ each carry an extra factor of $1 slash "share"$ beyond
what "a price shift per share traded" suggests, because *price* is itself
quoted in \$/share: a shift in that per-share price, per share traded, is
(\$/share)/share = \$/share².

#bibliography("references.bib", title: "References", style: "ieee")

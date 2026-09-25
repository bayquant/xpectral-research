#set page(paper: "us-letter", margin: 1in)
#set text(size: 10pt)
#set par(justify: true)

#show cite: it => text(fill: rgb("#1a73e8"))[#it]
#show link: it => text(fill: rgb("#c2410c"))[#it]
#show regex("^\[\d+\]"): it => text(fill: rgb("#1a73e8"))[#it]

#align(center)[
  #text(size: 20pt, weight: "bold")[Optimal Execution]

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
  random swings for longer: *timing risk*. This report replicates
  Almgren and Chriss @almgren2000, who cast optimal liquidation as
  minimizing expected cost plus a constant times its variance.

  == Price Dynamics and Impact

  The price follows Arithmetic Brownian Motion, disturbed by volatility,
  drift, and the trader's own activity. Discretizing the horizon into $N$
  steps of length $tau = T slash N$, with $x_k$ shares held after step
  $k$ ($x_0 = X$, $x_N = 0$) and $n_k = x_(k-1) - x_k$ shares traded in
  step $k$, the price process is
  $ S_k = S_(k-1) + #text(fill: red)[$alpha$] tau + sigma sqrt(tau) xi_k - tau g(n_k/tau), quad #link(<eq-price-process-appendix>)[(1)] $ <eq-price-process>
  where $xi_k$ are i.i.d. shocks with zero mean and unit variance, $g(v)$
  is the *permanent impact* (persists in the price process), and the drift
  #text(fill: red)[$alpha$] is taken as #text(fill: red)[zero] throughout since no directional
  information is assumed.
  Trading also incurs a *temporary impact* $h(v)$: a transient
  concession on the execution price of a single step, so the price actually 
  received on sale $k$ is
  $ tilde(S)_k = S_(k-1) - h(n_k/tau). $
  In both $g$ and $h$, the argument $v = n_k slash tau$ is the average rate
  of trading during the interval $t_(k-1)$ to $t_k$.

  == Cost of Trading

  Following Perold (1988) #cite(<perold1988>), the *implementation shortfall*
  #box[$X S_0 - sum_k n_k tilde(S)_k$ #link(<eq-capture>)[(2)]] <eq-capture-main> is the
  cost of trading relative to the initial book value. Expanding the
  capture term $sum_k n_k tilde(S)_k$ (total trading revenue) gives the
  shortfall's expectation and variance
  $ E(x) = sum_k tau x_k g(n_k/tau) + sum_k n_k h(n_k/tau), $
  $ V(x) = sigma^2 sum_k tau x_k^2. $
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
  For a monotone schedule ($n_k$ all one sign), $sum_k abs(n_k) = X$, so
  only the last term shapes the schedule. Almgren and Chriss minimize the
  utility function
  $ U(x) = E(x) + lambda V(x) $
  over $x_1, dots, x_(N-1)$, where $lambda >= 0$ is risk aversion.

  == The Optimal Schedule

  Dropping the schedule-independent terms $1/2 gamma X^2 + epsilon X$
  and writing $a = overline(eta) slash tau$, $b = lambda sigma^2 tau$ turns
  the objective into the quadratic form
  $ U = a sum_k (x_(k-1) - x_k)^2 + b sum_k x_k^2, $
  with the endpoints $x_0 = X_0$ and $x_N = X_T$ held fixed and only the
  interior holdings $x_1, dots, x_(N-1)$ free.

  *Stationarity condition* (the gradient vanishes, $nabla U = 0$). $U$ is a sum of
  squares, a convex bowl with a single minimum where every partial
  derivative vanishes. For an interior
  $x_j$, the only terms containing it are $(x_(j-1) - x_j)^2$,
  $(x_j - x_(j+1))^2$, and $b x_j^2$, so
  $ (partial U)/(partial x_j) = a [-2(x_(j-1) - x_j) + 2(x_j - x_(j+1))]
    + 2 b x_j = 0. $
  Dividing by 2 and rearranging gives:
  $ x_(j+1) - 2 x_j + x_(j-1) = b/a x_j
    = (lambda sigma^2)/overline(eta) tau^2 x_j
    = tilde(kappa)^2 tau^2 x_j. $

  *Linear difference equation.* Dividing by $tau^2$ exposes a centered second
  difference,
  $ (x_(j+1) - 2 x_j + x_(j-1))/tau^2 = tilde(kappa)^2 x_j, quad
    t_j = j tau. $
  This is a linear, constant-coefficient, second-order difference equation
  with values fixed at both ends, $x_0 = X_0$ and $x_N = X_T$. Liquidation
  sets $X_0 = X$ and $X_T = 0$, but general endpoints cost nothing and also
  cover re-planning partway through a trade. A second-order equation has a
  two-dimensional solution space, so the task is to find two independent
  solutions and fit two constants.

  *Characteristic equation and roots.* Substituting the trial solution
  $x_j = e^(theta t_j)$, the shifted terms are $x_(j plus.minus 1) =
  e^(theta t_j) e^(plus.minus theta tau)$, so the left-hand side becomes
  $ 1/tau^2 e^(theta t_j) (e^(-theta tau) - 2 + e^(theta tau))
    = 2/tau^2 (cosh(theta tau) - 1) e^(theta t_j), $
  using $e^(theta tau) + e^(-theta tau) = 2 cosh(theta tau)$. Cancelling
  $e^(theta t_j)$ from both sides leaves the characteristic equation
  $ 2/tau^2 (cosh(theta tau) - 1) = tilde(kappa)^2. $
  Here $tilde(kappa)$ is the known input and $theta$, the decay rate of the
  schedule, is the output. They differ because a second difference is not a
  second derivative: $2(cosh z - 1) = z^2 + z^4 slash 12 + dots$, so
  $theta = tilde(kappa) + O(tau^2)$. Since $cosh$ is even, the roots come
  in the pair $plus.minus theta$, giving the two fundamental solutions
  $e^(theta t_j)$ and $e^(-theta t_j)$.

  *General solution and boundary conditions.* The general solution is any
  combination of the two fundamental solutions, with two free constants.
  Since $sinh u = 1/2 (e^u - e^(-u))$, both $sinh(theta(T - t_j))$ and
  $sinh(theta t_j)$ are such combinations, so it can be written
  $ x_j = P sinh(theta(T - t_j)) + Q sinh(theta t_j). $
  This basis is chosen so that each term vanishes at one endpoint:
  $sinh(theta t_j)$ at $t = 0$ and $sinh(theta(T - t_j))$ at $t = T$.
  Each boundary condition then fixes one constant on its own. At $t = 0$
  the $Q$ term drops, so $X_0 = P sinh(theta T)$; at $t = T$ the $P$ term
  drops, so $X_T = Q sinh(theta T)$. Substituting
  $P = X_0 slash sinh(theta T)$ and $Q = X_T slash sinh(theta T)$ gives the
  schedule
  $ x_j = (X_0 sinh(theta(T - t_j)) + X_T sinh(theta t_j)) / (sinh(theta T)), $
  a hyperbolic interpolation between the two endpoints. As $theta -> 0$ it
  reduces to the straight line $x_j = (X_0 (T - t_j) + X_T t_j) slash T$,
  and larger $theta$ bows the path further from it. Setting $X_0 = X$ and
  $X_T = 0$ gives the liquidation trajectory
  $ x_j = X (sinh(theta(T - t_j))) / (sinh(theta T)), quad #link(<eq-holdings-appendix>)[(4)] $ <eq-holdings>
  for $j = 0, dots, N$, and the associated trade list
  $ n_j = (2 sinh(1/2 theta tau)) / (sinh(theta T))
    cosh(theta(T - t_(j-1/2))) X, quad #link(<eq-trades-appendix>)[(5)] $ <eq-trades>
  for $j = 1, dots, N$, where $t_(j-1/2) = (j - 1/2) tau$ is the midpoint
  of step $j$.

  *Continuous-time limit.* As $tau -> 0$, $overline(eta) -> eta$ and both
  $theta$ and $tilde(kappa)$ tend to $kappa = sqrt(lambda sigma^2 slash
  eta)$, so (4) becomes $x(t) = X sinh(kappa(T-t)) slash sinh(kappa T)$, the
  solution of $dot.double(x) = kappa^2 x$, and the trading rate $n_j slash
  tau$ in (5) becomes $-dot(x)(t)$.

  == The Shape of the Schedule

  $theta$ alone governs the curve's shape. As $lambda -> 0$, $theta -> 0$
  and $sinh(z) approx z$ makes the schedule linear: constant-rate,
  TWAP-like execution. As $lambda$ grows, $theta$ grows and the curve
  front-loads, trading more impact cost for less timing risk. $1 /
  theta$ is the characteristic unwind timescale.

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
  that branch is not efficient. The straight line is tangent at $lambda =
  10^(-6)$ with slope $-lambda$.

  #image("../output/efficient_frontier.png", width: 100%)

  == Half-Life of a Trade

  For $theta T gt.tilde 1$, $sinh(theta(T-t)) slash sinh(theta T) approx
  e^(-theta t)$, so holdings decay approximately exponentially,
  $x(t) approx X e^(-theta t)$. The time for the position to fall to half
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
]

#bibliography("references.bib", title: "References", style: "ieee")

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

Substituting the price dynamics and temporary-impact price into the
definition of capture (total trading revenue), $sum_k n_k tilde(S)_k$, and
expanding gives equation (2):
$ sum_(k=0)^N n_k tilde(S)_k = X S_0 + sum_(k=1)^N (sigma sqrt(tau) xi_k -
  tau g(n_k/tau)) x_k - sum_(k=1)^N n_k h(n_k/tau). $

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

== Solving the Optimal-Schedule Recurrence <eq-holdings-appendix>

#link(<eq-holdings>)[Equation (4)]

Substituting $x_j = e^(theta t_j)$ into the recurrence, with
$t_(j plus.minus 1) = t_j plus.minus tau$,
$ (e^(theta tau) - 2 + e^(-theta tau))/tau^2 e^(theta t_j)
  = 2/tau^2 (cosh(theta tau) - 1) e^(theta t_j)
  = tilde(kappa)^2 e^(theta t_j), $
so the exponential is an exact solution whenever $theta$ satisfies the
cosh relation, and by symmetry so is $e^(-theta t_j)$. Since
$sinh z = 1/2 (e^z - e^(-z))$, both $sinh(theta(T - t_j))$ and
$sinh(theta t_j)$ are constant combinations of $e^(plus.minus theta t_j)$,
so the general solution can be written
$ x_j = P sinh(theta(T - t_j)) + Q sinh(theta t_j). $
At $t = 0$ the $Q$ term vanishes, so $X_0 = P sinh(theta T)$; at
$t_N = T$ the $P$ term vanishes, so $X_T = Q sinh(theta T)$. Each
coefficient is read off directly, with no $2 times 2$ system to solve,
and setting $X_0 = X$, $X_T = 0$ gives equation (4).

== Trade List <eq-trades-appendix>

#link(<eq-trades>)[Equation (5)]

Since $n_j = x_(j-1) - x_j$, equation (4) gives
$ n_j = X / (sinh(theta T))
  [sinh(theta(T - t_(j-1))) - sinh(theta(T - t_j))]. $
The identity $sinh u - sinh v = 2 cosh((u+v) slash 2) sinh((u-v) slash 2)$,
with $u - v = theta tau$ and $(u+v) slash 2 = theta(T - t_(j-1/2))$, gives
equation (5).

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
  [actual price per share received on sale $k$],
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

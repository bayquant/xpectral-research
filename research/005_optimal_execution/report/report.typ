#set page(paper: "us-letter", margin: 1in)
#set text(size: 10pt)
#set par(justify: true)

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

  Following Perold (#cite(<perold1988>, form: "year")), the *implementation shortfall*
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
  $tau$: the correction is $O(tau)$ and only vanishes in the
  continuous-time limit. Temporary impact contributes
  $epsilon sum_k abs(n_k) + (eta slash tau) sum_k n_k^2$. Combining, and
  writing $overline(eta) = eta - 1/2 gamma tau$ to absorb the correction,
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
  with the endpoints $x_0 = X$ and $x_N = 0$ held fixed and only the
  interior holdings $x_1, dots, x_(N-1)$ free.

  *First-order condition.* $U$ is a sum of squares, a convex bowl with a
  single minimum where every partial derivative vanishes. For an interior
  $x_j$, the only terms containing it are $(x_(j-1) - x_j)^2$,
  $(x_j - x_(j+1))^2$, and $b x_j^2$, so
  $ (partial U)/(partial x_j) = a [-2(x_(j-1) - x_j) + 2(x_j - x_(j+1))]
    + 2 b x_j = 0. $
  Dividing by 2 and rearranging gives a recurrence linking each holding to
  its two neighbors:
  $ x_(j+1) - 2 x_j + x_(j-1) = b/a x_j. $

  *A discrete second derivative.* The left-hand side is exactly the
  centered second-difference stencil, $x_(j+1) - 2 x_j + x_(j-1) approx
  tau^2 dot.double(x)(t_j)$. Dividing by $tau^2$ and taking $N -> infinity$,
  the $O(tau)$ correction $overline(eta) -> eta$ vanishes, turning the
  recurrence into the continuous-time condition
  $ dot.double(x)(t) = kappa^2 x(t), quad kappa^2 = (lambda sigma^2)/eta. $

  Solved subject to $x(0) = X$, $x(T) = 0$, this collapses to the single
  closed form
  $ x(t) = X (sinh(kappa(T-t))) / (sinh(kappa T)), quad #link(<eq-ode-solution-appendix>)[(4)] $ <eq-ode-solution>

  == The Shape of the Schedule

  $kappa$ alone governs the curve's shape. As $lambda -> 0$, $kappa -> 0$
  and $sinh(z) approx z$ makes the schedule linear: constant-rate,
  TWAP-like execution. As $lambda$ grows, $kappa$ grows and the curve
  front-loads, trading more impact cost for less timing risk. $1 /
  kappa$ is the characteristic unwind timescale.

  #image("../output/optimal_holdings_trajectory.png", width: 100%)

  == Buying as the Mirror Image

  Since cost enters only through $n_k^2$, the objective is direction-blind:
  accumulating a position just flips the boundary conditions to $x_0 = 0$,
  $x_N = X$, giving the time-reversal of the sell schedule,
  $ x(t) = X (sinh(kappa t)) / (sinh(kappa T)). $
]

#bibliography("references.bib", title: "References", style: "ieee")

#pagebreak()

= Appendix

== Notation

#table(
  columns: (auto, 1fr, auto),
  align: (center, left, center),
  stroke: 0.4pt,
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
   schedule-dependent correction; $overline(eta) -> eta$ as $tau -> 0$],
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

$gamma$ and $eta$ each carry an extra factor of $1 slash "share"$ beyond
what "a price shift per share traded" suggests, because *price* is itself
quoted in \$/share: a shift in that per-share price, per share traded, is
(\$/share)/share = \$/share².

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

== Solving the Optimal-Schedule ODE <eq-ode-solution-appendix>

#link(<eq-ode-solution>)[Equation (4)]

The general solution of $dot.double(x)(t) = kappa^2 x(t)$ is
$x(t) = A e^(kappa t) + B e^(-kappa t)$. Imposing $x(0) = X$ and
$x(T) = 0$,
$ A + B = X, quad A e^(kappa T) + B e^(-kappa T) = 0. $
Solving for $A, B$ and folding the exponentials into hyperbolic sines
($sinh z = 1/2 (e^z - e^(-z))$) collapses this to equation (4).

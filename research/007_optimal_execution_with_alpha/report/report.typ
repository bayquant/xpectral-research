#set page(paper: "us-letter", margin: 1in)
#set text(size: 10pt)
#set par(justify: true)

#show cite: it => text(fill: rgb("#1a73e8"))[#it]
#show link: it => text(fill: rgb("#c2410c"))[#it]
#show regex("^\[\d+\]"): it => text(fill: rgb("#1a73e8"))[#it]

#align(center)[
  #text(size: 20pt, weight: "bold")[Optimal Execution with Alpha]

  #v(0.5em)
  #text(size: 12pt)[BayQuant]
]

#v(1em)

#columns(2)[
  == From Liquidation to Alpha

  _A Primer on Optimal Execution_ solved the Almgren–Chriss liquidation
  problem @almgren2000 with no directional view: the price drift $alpha$
  was set to zero. Here the trader has a view. Holding a share earns an
  expected return $alpha(t)$, and the case of interest is an earnings
  event, whose alpha arrives in a single instant. The optimal schedule
  turns out to be the liquidation curve plus a Green's-function response
  to the event. Adding the event's own jump variance then caps the
  position carried into the print. The last section compares the model
  with the round-trip version in Paleologo @paleologo2021.

  The analysis is in continuous time. The discrete grid of the primer
  returns only to derive the optimality equation and to check the closed
  forms numerically. In continuous time, permanent impact contributes
  $1/2 gamma (x(T)^2 - x(0)^2)$ whatever the schedule, so only the
  temporary impact $eta$ shapes it.

  == The Objective

  The trader holds $x(t)$ shares and must go from $x(0) = X$ to $x(T) = 0$.
  At every instant three things happen:
  - trading costs $eta dot(x)^2$, quadratic in speed, so trading twice as
    fast costs four times as much;
  - holding costs risk $lambda sigma^2 x^2$;
  - holding earns alpha $alpha(t) x$.
  The trader chooses the whole path to minimize
  $ J[x] = integral_0^T [eta dot(x)^2 + lambda sigma^2 x^2 - alpha(t) x]
    dif t. quad (1) $ <eq-objective>
  This is the primer's $E + lambda V$ with the drift switched back on:
  every share held through a drift $alpha$ earns it, which lowers the
  expected shortfall by $integral alpha(t) x(t) dif t$.

  == The Optimality Equation

  To minimize a function of many variables, set every partial derivative
  to zero. Split $[0, T]$ into $N$ buckets of length $tau$, with holdings
  $x_1, dots, x_(N-1)$ free and the endpoints $x_0 = X$ and $x_N = 0$
  fixed. The objective becomes
  $ J = sum_k [eta/tau (x_(k-1) - x_k)^2 + lambda sigma^2 tau x_k^2
    - alpha_k tau x_k]. $
  A single holding $x_k$ appears in exactly four places: the trade into
  bucket $k$, the trade out of it, its own risk and its own alpha. Setting
  the derivative to zero,
  $ (2 eta)/tau (2 x_k - x_(k-1) - x_(k+1)) + 2 lambda sigma^2 tau x_k
    - alpha_k tau = 0, $
  and dividing by $2 eta tau$,
  $ (x_(k+1) - 2 x_k + x_(k-1))/tau^2 = kappa^2 x_k - alpha_k/(2 eta),
    quad kappa^2 = (lambda sigma^2)/eta. $
  The left side is the change in trading speed, from
  $(x_k - x_(k-1)) slash tau$ into bucket $k$ to $(x_(k+1) - x_k) slash
  tau$ out of it, divided by $tau$: a discrete acceleration. As $tau -> 0$
  it becomes
  $ dot.double(x) - kappa^2 x = - alpha(t)/(2 eta).
    quad #link(<eq-optimality-appendix>)[(2)] $ <eq-optimality>
  This is a balance of forces. Risk ($kappa^2 x$) pushes the trader to
  sell, alpha ($alpha slash 2 eta$) pushes the trader to hold, and
  $dot.double(x)$, the change in trading speed, absorbs the difference.
  Each discrete condition links only $x_(k-1)$, $x_k$ and $x_(k+1)$, so
  the discrete problem is a tridiagonal linear system.

  == No Alpha: The Liquidation Curve

  With $alpha = 0$, equation (2) is $dot.double(x) = kappa^2 x$, solved by
  $e^(plus.minus kappa t)$. The combination with $x(T) = 0$ and $x(0) = X$
  is
  $ x_"base" (t) = X (sinh kappa(T - t))/(sinh kappa T), quad (3) $
  the continuous limit of the primer's schedule, where the discrete decay
  rate $theta$ tends to $kappa$. $1 slash kappa = sqrt(eta slash lambda
  sigma^2)$ is the time scale of the unwind.

  == An Earnings Event

  Let all the alpha arrive at the print, $alpha(t) = a delta(t - t_e)$,
  so the trader earns $a x(t_e)$ on whatever is held through it.
  Integrating (2) over a vanishing window around $t_e$: the integral of
  $dot.double(x)$ is the change in speed across the window, the integral of
  $kappa^2 x$ vanishes, and the delta integrates to $a$, so
  $ dot(x)(t_e^+) - dot(x)(t_e^-) = - a/(2 eta).
    quad #link(<eq-jump-appendix>)[(4)] $ <eq-jump>
  The position is continuous, since a jump would need infinite speed and
  infinite cost. Only the trading rate jumps: for $a > 0$ the trader sells
  $a slash 2 eta$ shares per day faster after the print, so the path has a
  corner at $t_e$.

  == The Green's Function

  Let $G(t, s)$ be the response to a unit impulse at time $s$ with both
  endpoints held at zero: $partial_t^2 G - kappa^2 G = -delta(t - s)$,
  $G(0, s) = G(T, s) = 0$. Away from $s$ it solves the unforced equation,
  and gluing the two sides together at $s$ gives
  $ G(t, s) = (sinh(kappa t_(<)) sinh kappa(T - t_(>)))
    /(kappa sinh kappa T), quad #link(<eq-green-appendix>)[(5)] $ <eq-green>
  where $t_(<)$ is the smaller of $t$ and $s$, and $t_(>)$ the larger.
  Equation (2) is linear, so solutions add. The base curve (3) carries the
  boundary conditions and the Green's term carries the event while
  vanishing at both ends:
  $ x(t) = x_"base" (t) + a/(2 eta) G(t, t_e). quad (6) $
  For a general alpha the second term becomes $(2 eta)^(-1) integral_0^T
  G(t, s) alpha(s) dif s$.

  For $a > 0$ the trader holds extra inventory into the print and sells it
  off faster afterward. For $a < 0$ the trader sells ahead and arrives
  lighter. With the Almgren–Chriss Table 1 stock ($X = 10^6$ shares,
  $sigma = 0.95$, $eta = 2.5 times 10^(-6)$, $T = 5$ days), $lambda =
  10^(-6)$ ($kappa = 0.60$ per day) and a mid-horizon print worth
  $a = 1$ dollar per share, the trader carries 363,000 shares through it
  instead of 212,000.

  #image("../output/event_trajectory.png", width: 100%)

  The bump reaches only about $1 slash kappa$ either side of the print, so
  an event far away barely affects trading today. An event near either end
  of the horizon has little effect, because $G$ vanishes there and there is
  no time to build or unwind the extra position.

  #image("../output/event_timing.png", width: 100%)

  == Event Risk

  An earnings print also carries jump variance $sigma_J^2$. Adding
  $lambda sigma_J^2 x(t_e)^2$ to (1), the jump condition picks up a second
  term,
  $ dot(x)(t_e^+) - dot(x)(t_e^-) = rho x_e - a/(2 eta), quad
    rho = (lambda sigma_J^2)/eta, quad #link(<eq-jump-appendix>)[(7)] $
  with $x_e = x(t_e)$. The impulse now depends on the unknown $x_e$, but
  superposition still holds:
  $ x(t) = x_"base" (t) + G(t, t_e) (a/(2 eta) - rho x_e). $
  Setting $t = t_e$ and solving for $x_e$, with $G_(e e) = G(t_e, t_e)$,
  $ x_e = (x_"base" (t_e) + G_(e e) a slash 2 eta)/(1 + rho G_(e e))
    = w x_"base" (t_e) + (1 - w) x^star, quad (8) $
  where
  $ w = 1/(1 + rho G_(e e)), quad x^star = a/(2 lambda sigma_J^2). $
  $x^star$ is the position the event alone would call for: minimizing
  $lambda sigma_J^2 x^2 - a x$. The position at the print is a blend of
  where the liquidation would put the trader and what the event alone
  wants, and the larger the jump risk, the more the event wins. When
  $x^star < x_"base" (t_e)$, the trader arrives lighter than with no view
  at all, even though the alpha is positive. In the example, a jump of
  5% of the price ($sigma_J = 2.5$ dollars) gives $w = 0.35$ and
  $x^star =$ 80,000, and the position at the print falls to 126,000
  shares.

  #image("../output/event_risk.png", width: 100%)

  == The Book, Translated

  Paleologo @paleologo2021 solves this model for a round trip: start flat,
  build a position to capture the event alpha, and unwind it ($X = 0$),
  with no event-variance term. His symbols map into ours as follows.

  #table(
    columns: (1fr, 1fr),
    align: center,
    stroke: 0.4pt,
    table.header([*book*], [*here*]),
    [$kappa^2 slash 2$], [$eta$],
    [$rho sigma^2 slash 2$], [$lambda sigma^2$],
    [$b$], [$kappa$],
    [$alpha_0$, $t_0$], [$a$, $t_e$],
  )

  With these substitutions the book's equation $kappa^2 dot.double(x) =
  -alpha + rho sigma^2 x$ is exactly (2). Its $F$, $G$ and $c$ solve it by
  variation of parameters: $F$ and $G$ are the two running integrals of
  $alpha e^(plus.minus b zeta)$, and $c$ enforces $x(T) = 0$. That is a
  longer route to the same Green's function. With $X = 0$ the base curve
  vanishes and only the Green's term of (6) remains.

  *Long horizon.* As $T -> infinity$, $sinh kappa(T - t_(>)) slash sinh
  kappa T -> e^(-kappa t_(>))$, so
  $ x(t) = a/(2 eta kappa) sinh(kappa t_(<)) e^(-kappa t_(>)), $
  $ x(t_e) = a/(4 eta kappa) (1 - e^(-2 kappa t_e)), quad
    #link(<eq-long-horizon-appendix>)[(9)] $ <eq-long-horizon>
  which are the book's long-horizon results. Before the event the trader
  buys ever faster, at a rate proportional to $cosh kappa t$. After it the
  position unwinds along $e^(-kappa t)$, quickly at first and then slowly.

  *The trading rate at the event.* Just before the print the buying rate
  is $a/(4 eta) (1 + e^(-2 kappa t_e))$, and just after it the selling rate
  is $a/(4 eta) (1 - e^(-2 kappa t_e))$. They differ by exactly the jump
  $a slash 2 eta$ of (4). The book says they are equal in size, which holds
  only when the event is far away ($kappa t_e >> 1$).

  *Risk-aversion convention.* The book's problem statement prices risk as
  $rho sigma^2 slash 2$, but its Lagrangian and its rate $b = rho sigma
  slash kappa$ use $rho^2 sigma^2$. One convention has to be picked. With
  $rho sigma^2$, the rate is $b = sigma sqrt(rho) slash kappa$.

  *Equation (11.9).* The book's risk-neutral solution has two branches
  that do not meet at $t_0$: the left gives $alpha_0 t_0 slash kappa^2$
  and the right $alpha_0 t_0 (1 - t_0) slash kappa^2$. It also mixes
  $T -> infinity$ with $T = 1$. The limit $lambda -> 0$ of (5) is
  $G -> t_(<) (T - t_(>)) slash T$, so the position is a tent, continuous
  at the print:
  $ x(t) = a/(2 eta) (t_(<) (T - t_(>)))/T.
    quad #link(<eq-tent-appendix>)[(10)] $ <eq-tent>
  With $T = 1$ the left branch is $alpha_0 (1 - t_0) t slash kappa^2$, not
  $alpha_0 t slash kappa^2$. With $T -> infinity$ the position after
  $t_0$ is flat: a risk-neutral trader never unwinds.

  #image("../output/round_trip.png", width: 100%)

  *What the book leaves out.* The book notes that conviction is strongest
  on the earnings date, but its risk term uses the same $sigma$
  everywhere. The position it carries through the print therefore ignores
  the print's own variance, which is the largest risk in the trade. With
  $X = 0$, (8) gives
  $ x_e = (G_(e e) a slash 2 eta)/(1 + rho G_(e e))
    -> x^star = a/(2 lambda sigma_J^2) $
  as $sigma_J -> infinity$: the event variance caps the book's position at
  the event-only size, $alpha_0 slash rho sigma_J^2$ in the book's units.

  *Volume time.* The book measures time in volume and keeps $sigma$ and
  $kappa$ constant on that clock. That is an assumption about clock time:
  both are constant in volume time only if variance per unit clock time
  grows with volume, $sigma_t^2 prop v_t$, and impact shrinks with it,
  $eta_t prop 1 slash v_t$, so that $sigma_t^2 eta_t$ is constant
  (#link(<eq-volume-time-appendix>)[appendix]).
]

#pagebreak()

= Appendix

== Optimality Equation in Continuous Time <eq-optimality-appendix>

#link(<eq-optimality>)[Equation (2)]

Suppose $x(t)$ minimizes (1), and perturb it to $x + epsilon h$, where
$h(0) = h(T) = 0$ so the endpoints stay fixed. At the minimum no
perturbation lowers $J$ to first order, so
$ integral_0^T [2 eta dot(x) dot(h) + 2 lambda sigma^2 x h - alpha h]
  dif t = 0 quad "for every" h. $
Integrating the first term by parts, and using $h(0) = h(T) = 0$ to drop
the boundary term, $integral dot(x) dot(h) dif t = - integral
dot.double(x) h dif t$, so
$ integral_0^T [-2 eta dot.double(x) + 2 lambda sigma^2 x - alpha] h
  dif t = 0 quad "for every" h. $
An integral that vanishes against every $h$ forces the bracket to vanish.
Dividing by $-2 eta$ gives equation (2). Integration by parts plays the
role of the discrete observation that $x_k$ appears in two neighboring
trades.

== Jump Conditions <eq-jump-appendix>

#link(<eq-jump>)[Equations (4) and (7)]

Write the event alpha as $a delta(t - t_e)$ and include the event variance
$lambda sigma_J^2 x(t_e)^2$. $dot(x)$ may jump at $t_e$, so integrate by
parts separately on $[0, t_e]$ and $[t_e, T]$:
$ integral_0^T dot(x) dot(h) dif t
  = h(t_e) [dot(x)(t_e^-) - dot(x)(t_e^+)]
  - integral_0^T dot.double(x) h dif t. $
The first-order change in $J$ is then
$ integral_0^T [-2 eta dot.double(x) + 2 lambda sigma^2 x] h dif t
  + h(t_e) [2 eta (dot(x)(t_e^-) - dot(x)(t_e^+))
  + 2 lambda sigma_J^2 x_e - a]. $
Perturbations that vanish at $t_e$ give equation (2) away from the event.
A perturbation with $h(t_e) != 0$ then forces the second bracket to
vanish:
$ dot(x)(t_e^+) - dot(x)(t_e^-) = (lambda sigma_J^2)/eta x_e - a/(2 eta)
  = rho x_e - a/(2 eta), $
which is (7), and (4) when $sigma_J = 0$.

== Green's Function <eq-green-appendix>

#link(<eq-green>)[Equation (5)]

Away from $s$, $G$ solves $partial_t^2 G = kappa^2 G$. On each side, take the
solution that already satisfies that side's boundary condition:
$ G = A sinh kappa t quad (t < s), quad
  G = B sinh kappa(T - t) quad (t > s). $
Two conditions at $s$ fix $A$ and $B$. $G$ is continuous,
$ A sinh kappa s = B sinh kappa(T - s), $
and, by (4) with a unit impulse, its slope drops by 1,
$ -B kappa cosh kappa(T - s) - A kappa cosh kappa s = -1. $
Substituting $B = A sinh kappa s slash sinh kappa(T - s)$ into the second
condition,
$ A kappa (sinh kappa s cosh kappa(T - s) + cosh kappa s sinh kappa(T - s))
  = sinh kappa(T - s). $
The bracket is $sinh(kappa s + kappa(T - s)) = sinh kappa T$, so
$ A = (sinh kappa(T - s))/(kappa sinh kappa T), quad
  B = (sinh kappa s)/(kappa sinh kappa T), $
and both branches combine into equation (5).

== Long-Horizon Limit <eq-long-horizon-appendix>

#link(<eq-long-horizon>)[Equation (9)]

For fixed $t_(>)$, as $T -> infinity$,
$ (sinh kappa(T - t_(>)))/(sinh kappa T)
  = (e^(-kappa t_(>)) - e^(-kappa(2T - t_(>))))/(1 - e^(-2 kappa T))
  -> e^(-kappa t_(>)), $
which turns (6) with $X = 0$ into the first line of (9). At $t = t_e$,
$sinh(kappa t_e) e^(-kappa t_e) = 1/2 (1 - e^(-2 kappa t_e))$ gives the
second. Differentiating, the rate just before the print is
$ dot(x)(t_e^-) = a/(2 eta) cosh(kappa t_e) e^(-kappa t_e)
  = a/(4 eta) (1 + e^(-2 kappa t_e)), $
and just after it
$ dot(x)(t_e^+) = - a/(2 eta) sinh(kappa t_e) e^(-kappa t_e)
  = - a/(4 eta) (1 - e^(-2 kappa t_e)). $
Their difference is $-a slash 2 eta$, as (4) requires.

== Risk-Neutral Limit <eq-tent-appendix>

#link(<eq-tent>)[Equation (10)]

As $kappa -> 0$, $sinh z approx z$ in each factor of (5):
$ G(t, s) approx (kappa t_(<) dot kappa(T - t_(>)))/(kappa dot kappa T)
  = (t_(<) (T - t_(>)))/T. $
Both branches equal $t_e (T - t_e) slash T$ at $t = s = t_e$, so the tent
is continuous, and its slopes, $(T - t_e) slash T$ before and $-t_e slash
T$ after, differ by exactly $-1$.

== Volume Time <eq-volume-time-appendix>

Let $v_t$ be the trading volume at clock time $t$, $V$ its average, and
$u$ volume time, $dif u = (v_t slash V) dif t$. Over $dif t$ the price
variance is $sigma_t^2 dif t = sigma_t^2 (V slash v_t) dif u$, so the
variance per unit volume time is $sigma_t^2 V slash v_t$. The impact cost
is $eta_t (dif x slash dif t)^2 dif t = eta_t (v_t slash V) (dif x slash
dif u)^2 dif u$, so the impact per unit volume time is $eta_t v_t slash
V$. Both are constant in $u$ only if $sigma_t^2 prop v_t$ and $eta_t prop
1 slash v_t$, which makes $sigma_t^2 eta_t$ constant in clock time.

== Notation

#table(
  columns: (auto, 1fr, auto),
  align: (center, left, center),
  stroke: 0.4pt,
  table.header([*symbol*], [*meaning*], [*units*]),
  [$x(t)$], [shares held at time $t$], [shares],
  [$X$], [starting position ($X = 0$ for a round trip)], [shares],
  [$T$], [trading horizon], [day],
  [$eta$], [temporary impact coefficient], [\$ day/share#super[2]],
  [$sigma$], [price volatility], [\$/(share day#super[1/2])],
  [$lambda$], [risk aversion], [1/\$],
  [$kappa$], [liquidation rate, $sqrt(lambda sigma^2 slash eta)$], [1/day],
  [$alpha(t)$], [expected return from holding], [\$/(share day)],
  [$a$], [alpha paid at the event], [\$/share],
  [$t_e$], [event time], [day],
  [$sigma_J$], [jump volatility at the event], [\$/share],
  [$rho$], [event-risk rate, $lambda sigma_J^2 slash eta$], [1/day],
  [$G(t, s)$], [Green's function of (2)], [day],
  [$x_e$], [position at the event, $x(t_e)$], [shares],
  [$x^star$], [event-only position, $a slash 2 lambda sigma_J^2$], [shares],
)

#bibliography("references.bib", title: "References", style: "ieee")

#set page(paper: "us-letter", margin: 1in)
#set text(size: 10pt)
#set par(justify: true)

#show cite: it => text(fill: rgb("#1a73e8"))[#it]
#show link: it => text(fill: rgb("#c2410c"))[#it]
#show regex("^\[\d+\]"): it => text(fill: rgb("#1a73e8"))[#it]

#align(center)[
  #set par(spacing: 0.6em)
  #text(size: 20pt, weight: "bold")[Option-Implied PoC for Merger Arbitrage]

  #text(size: 14pt)[Cash Deals]

  #text(size: 12pt)[BayQuant]
]

#v(1em)

#columns(2)[
  == The Question

  When a cash offer is announced, the target's stock jumps toward the
  offer price $W$, the total workout, but stops short of it. The gap, the merger spread, pays
  the holder for the risk that the deal fails. We want two numbers from
  market prices:
  + *Completion*: the market-implied probability of completion $p$ that the deal closes.
    This is the main goal.
  + *Timing*: when the deal resolves, as a hazard curve over its life.
    This is secondary.

  This note sets out how we will estimate both from the target's listed
  options, why options should add information beyond the stock price, and
  how we will test whether they do. We restrict to all-cash deals, where
  the price in the deal-alive state is fixed at $W$. In a stock deal it
  moves with the acquirer.

  Options have been used to read merger beliefs before. Barraclough et al.
  @barraclough2013 use target and bidder calls to infer synergies, and
  Subramanian @subramanian2004 prices target options in stock deals with
  failure as a jump at a random time. Our aim is narrower and practical: a
  daily completion probability for live cash deals.

  == What the Stock Alone Says

  Ignoring discounting and dividends, the target price is a
  probability-weighted average of the offer and the fallback price $S_"break"$,
  the value the stock would return to if the deal broke:
  $ S_0 & = p W + (1 - p) S_"break", \
    p & = (S_0 - S_"break")/(W - S_"break"). quad (1) $
  $S_0$ and $W$ are observed; $S_"break"$ is not. The usual proxy is the
  pre-announcement price, rolled forward by the beta-adjusted market move
  since announcement or by the move in comparable companies. The answer
  is sensitive to that guess. With $W = 50$ and $S_0 = 47$, a fallback of
  35 gives $p = 80%$, and a fallback of 40 gives $p = 70%$. A five-dollar
  error in the unobservable break price moves the answer by ten points. The
  error is also unlikely to be random: a target whose business is
  deteriorating is both more likely to see its deal abandoned and worth
  less on its own.

  The stock gives one equation in two unknowns. Options give a
  cross-section of prices that depend on $p$ and $S_"break"$ in different ways.
  That is the case for using them.

  == The Target at Option Expiry

  Fix an option expiry $T$, and let $q(S)$ be the risk-neutral density
  of the target's price $S_T$. By then the deal is in one of three
  states, and each puts its probability in a different place.

  #table(
    columns: (auto, 1fr, auto),
    align: (left, left, left),
    stroke: 0.4pt,
    table.header([*State*], [*Target at $T$*], [*Risk-neutral density*]),
    [Completed], [Options cash-settled at $W$], [Spike at $W$],
    [Pending], [$W$ less the remaining spread], [Narrow, just below $W$],
    [Failed], [Standalone value], [Wide hump at $mu_"break"$],
  )

  A fourth state, a competing or raised bid, puts mass above $W$. We leave
  it as an extension.

  Completed and pending both sit near $W$, so we pool them into one
  _alive_ state. Let $B$ indicate that the deal has failed by $T$, and let
  $pi_"break" = bb(Q)(B = 1)$ be the probability of that failure. $bb(Q)$
  is the risk-neutral measure, the probabilities implied by market prices,
  so $pi_"break"$ is what the market charges for a break, not a forecast of
  one. It typically sits above the real-world break rate, because investors
  pay extra to insure against losses. Under $bb(Q)$, $S_T$ is a
  two-component mixture:
  $ B & tilde "Bernoulli"(pi_"break"), \
    ln(S_T) | B = 0 & tilde cal(N)(ln(mu_"close") - sigma_"close"^2 slash 2,
      sigma_"close"^2), & quad #link(<mixture-appendix>)[(2)] \
    ln(S_T) | B = 1 & tilde cal(N)(ln(mu_"break") - sigma_"break"^2 slash 2,
      sigma_"break"^2). $ <eq-mixture>
  The close state has mean $mu_"close"$ just below $W$ and a small log
  volatility $sigma_"close"$. The break state has mean $mu_"break"$, where the
  stock lands if the deal fails, and log volatility $sigma_"break"$, how
  uncertain that is. The $-sigma^2 slash 2$ terms make each $mu$ the mean of
  $S_T$ itself rather than of $ln(S_T)$. With $g_"close"$ and $g_"break"$
  the two conditional densities, the density of $S_T$ is
  $ q(S) = (1 - pi_"break") g_"close" (S) + pi_"break" g_"break" (S). $

  The shape matters for how we estimate it. The density is bimodal with a
  near-spike at $W$. Smoothing methods built for index options, such as
  Jackwerth and Rubinstein @jackwerth1996, pick the smoothest density that
  fits the quotes, so they would smear the spike into the trough. We
  therefore fit (2) as a parametric mixture, as Melick and Thomas
  @melick1997 did for crude oil during the Gulf crisis, and apply
  Breeden–Litzenberger @breeden1978 directly only where the density is
  smooth.

  == Why Puts Identify Failure

  A put struck at $K$ pays only in states below $K$. For strikes below the
  alive component, the alive state contributes nothing, so
  $ P(K) = pi_"break" dot P_"B" (K; mu_"break", sigma_"break"), quad (3) $
  where $P_"B"$ is the Black put price on forward $mu_"break"$ with total
  volatility $sigma_"break"$. Puts below the offer are pure claims on failure,
  scaled by $pi_"break"$. Their level across strikes fixes $pi_"break"$ and $mu_"break"$
  together, and their curvature, which by Breeden–Litzenberger is $e^(-r
  T) pi_"break" g_"break" (K)$, fixes the shape of the fallback distribution. The
  forward closes the system:
  $ S_0 e^(r T) - D = (1 - pi_"break") mu_"close" + pi_"break" mu_"break", quad (4) $
  where $D$ is the forward value of dividends paid before $T$. With $mu_"close"$
  set near $W$, (3) and (4) pin down $pi_"break"$, $mu_"break"$ and $sigma_"break"$ from as few as
  three put quotes plus the stock. Calls above $W$ give a check: in a cash
  deal they pay only if a higher bid arrives or the failed stock rallies
  past $W$.

  Bester, Martinez and Rosu @bester2018 document the visible signature of
  this structure in cash mergers from 1996 to 2008: the target's implied
  volatility smile has a kink at the offer price, and the kink grows with
  the success probability. We will use the kink as an independent check
  on $pi_"break"$.

  == Estimation

  For each deal and each trading day:
  + Collect target puts and calls with positive bids, and convert prices
    to forward terms with the rate curve and announced dividends.
  + Fit (2) by minimizing pricing error, each quote weighted by its
    inverse bid–ask spread, with $pi_"break" in [0, 1]$ and (4) imposed. Start
    with $mu_"close" = W$ and a small fixed $sigma_"close"$. Free $mu_"close"$ only
    where strikes near $W$ support it: a pending deal still carries the
    risk of failing after $T$, which pulls $mu_"close"$ below $W$.
  + Correct for early exercise. Listed single-stock options are American,
    and deep in-the-money puts in the failure state are the most exposed.
    We will compare pricing (2) on a binomial tree against simply dropping
    strikes with a material early-exercise premium.
  + Cross-check without a model: take butterflies of put quotes strictly
    below the alive component and add them up. The result should match
    $pi_"break"$. Never difference across $W$.

  == From Failure by $T$ to Completion

  $pi_"break"$ is the probability of failure _by $T$_, not over the deal's life.
  Two routes lead to $p$.

  *Combined estimator (primary).* Take $mu_"break"$ from the options and use it in
  place of the guessed fallback in (1). With discounting to the expected
  close $tau$,
  $ p = (S_0 - e^(-r T) mu_"break")/(W e^(-r tau) - e^(-r T) mu_"break"). quad (5) $
  The options supply the fallback, and the stock supplies the level. This
  assumes the fallback is about the same whether the deal fails before or
  after $T$.

  *Long-dated expiry.* If an expiry lies beyond the outside date, then
  $1 - pi_"break"$ at that expiry is $p$ directly.

  When both are available, they should agree. A gap flags a mis-specified
  fallback or a missing topping-bid state.

  == Timing

  Fitting (2) at each listed expiry $T_1 < T_2 < dots$ gives a failure
  curve $pi_"break" (T_i)$. As with a credit curve, the hazard of failing
  between two expiries, given survival to the first, is
  $ h_i = (pi_"break" (T_i) - pi_"break" (T_(i-1)))/(1 - pi_"break" (T_(i-1))). quad (6) $
  This times failures, not closings. Options can hardly tell "completed
  by $T$" from "pending at $T$", since both put the price near $W$. In
  principle the alive component's width carries some signal (pending
  stock keeps a little volatility, completed stock has none), but it is
  unlikely to survive real quotes. For the closing date we will rely on
  the deal's own calendar (antitrust waiting periods, other approvals,
  the shareholder vote, the outside date) together with the term
  structure of the spread.

  == Risk-Neutral Is Not Real-World

  $pi_"break"$ is a price, not a forecast. Merger arbitrage loses heavily in
  rare states that cluster in market downturns, so it pays like a short
  put and earns a premium for that @mitchell2001. Implied failure
  probabilities should therefore exceed realized failure rates. We will
  estimate the mapping on past deals with a logistic regression of the
  realized outcome on $"logit"(p)$, and report both the raw and the
  calibrated number.

  == Data

  - *Deals*: US all-cash deals with listed target options. For each:
    announcement date, offer price and every revision, outside date,
    regulatory milestones, pre-announcement price, outcome and resolution
    date.
  - *Options*: end-of-day bid and ask by strike and expiry for each
    target, from announcement to resolution.
  - *Market*: the rate curve, dividends, and an index to adjust the
    pre-announcement fallback proxy.

  == Validation

  The test is whether options help. The baseline is (1) with the
  market-adjusted pre-announcement price as fallback. On held-out deals we
  will compare:
  - Brier score and log loss of the predicted outcome at fixed horizons
    after announcement (5, 20 and 60 trading days);
  - calibration plots, before and after the mapping above;
  - internal consistency: model-free against mixture $pi_"break"$, combined
    against long-dated $p$, and kink size against $p$.

  Success means the options-based $p$ beats the baseline out of sample.
  If it does not, that is a finding, and we report it.

  == Open Questions

  - Which data vendor, and the sample period it covers.
  - Topping bids: a third component above $W$, identified from calls
    above $W$, and how often chains can support it.
  - Offer revisions: refit from the revision date with the new $W$.
  - Tender offers close faster than one-step mergers; whether to split
    the sample.
  - The minimum chain quality for a deal-day to enter, for example at
    least three puts below $W$ with positive bids.
]

#pagebreak()

= Appendix

== Lognormal Mixture <mixture-appendix>

#link(<eq-mixture>)[Equation (2)]

Conditional on the outcome, the stock no longer faces a binary event and
behaves like an ordinary stock. Black–Scholes
@black1973 models such a price as a geometric Brownian motion,
$ ln(S_T) = ln(S_0) + alpha T - sigma^2 slash 2 + sigma Z,
  quad Z tilde cal(N)(0, 1), $
with annual drift $alpha$ and volatility $sigma$ over the whole horizon
(annual volatility times $sqrt(T)$). So $ln(S_T)$ is normal with
standard deviation $sigma$, the total volatility that $sigma_"close"$
and $sigma_"break"$ denote. Each state
gets its own lognormal, making (2) a mixture of lognormals, the form
Melick and Thomas @melick1997 used for event-driven distributions.

*The $-sigma^2 slash 2$ shift.* If $ln(S) tilde cal(N)(m, sigma^2)$, the
moment generating function of a normal evaluated at 1 gives
$ bb(E)[S] = bb(E)[e^(ln(S))] = e^(m + sigma^2 slash 2). $
Exponentiating stretches high values more than it shrinks low ones, so
the mean of $S$ sits above $e^m$. Choosing $m = ln(mu) - sigma^2 slash 2$
gives
$ bb(E)[S_T | B] = e^(ln(mu) - sigma^2 slash 2 + sigma^2 slash 2) = mu, $
so $mu_"close"$ and $mu_"break"$ are means in dollars, which is what the
forward constraint (4) needs.

*What is approximate.* A completed deal pays exactly $W$, a point mass.
A lognormal with small $sigma_"close"$ stands in for it and becomes a
spike at $mu_"close"$ as $sigma_"close" -> 0$. A deal can also fail at
any time before $T$, after which the stock diffuses for the time left,
so the exact break distribution blends lognormals with different
horizons. A single lognormal summarizes that blend.

#pagebreak()

= Notation

#table(
  columns: (auto, 1fr),
  align: (center, left),
  stroke: 0.4pt,
  table.header([*symbol*], [*meaning*]),
  [$W$], [total workout: cash paid per target share if the deal closes],
  [$S_0$, $S_T$], [target price today and at option expiry],
  [$S_"break"$], [fallback price if the deal fails],
  [$p$], [probability the deal completes],
  [$T$], [option expiry, years],
  [$tau$], [expected closing date, years],
  [$r$], [continuously compounded rate],
  [$D$], [forward value of dividends paid before $T$],
  [$K$], [strike],
  [$q(S)$], [risk-neutral density of $S_T$],
  [$bb(Q)$], [risk-neutral probability],
  [$pi_"break"$], [risk-neutral probability of failure by $T$],
  [$B$], [indicator that the deal has failed by $T$],
  [$mu_"close"$, $sigma_"close"$], [mean and log volatility of $S_T$ if the deal is alive at $T$],
  [$g_"close"$, $g_"break"$], [densities of $S_T$ given alive and given failed],
  [$mu_"break"$, $sigma_"break"$], [fallback mean at $T$ and its total log volatility],
  [$P(K)$, $P_"B"$], [put price; Black put price],
  [$h_i$], [hazard of failure between expiries $T_(i-1)$ and $T_i$],
)

#bibliography("references.bib", title: "References", style: "ieee")

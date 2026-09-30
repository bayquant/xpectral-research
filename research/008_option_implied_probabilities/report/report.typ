#set page(paper: "us-letter", margin: 1in)
#set text(size: 10pt)
#set par(justify: true)

#show cite: it => text(fill: rgb("#1a73e8"))[#it]
#show link: it => text(fill: rgb("#c2410c"))[#it]
#show regex("^\[\d+\]"): it => text(fill: rgb("#1a73e8"))[#it]

#align(center)[
  #text(size: 20pt, weight: "bold")[Option-Implied Probabilities]

  #v(0.5em)
  #text(size: 12pt)[BayQuant]
]

#v(1em)

#columns(2)[
  == Options as Bets on States

  A call struck at $K$ pays only in the states where the underlying ends
  above $K$. Calls at two nearby strikes differ only in the states between
  them, so the market's prices across strikes say how much it charges for
  each range of outcomes. Breeden and Litzenberger @breeden1978 made this
  exact: the second strike derivative of the call price is the discounted
  risk-neutral density of the underlying at expiry. Ross @ross1976 had
  shown that options on a single asset span its states; Breeden and
  Litzenberger turned that into a formula.

  This note derives the result, checks it numerically under Black–Scholes
  @black1973 and under a bimodal event distribution, shows how the
  implied-volatility smile enters event probabilities, and explains why
  the formula cannot be applied to raw quotes.

  == State Prices

  Let $q(S)$ be the risk-neutral density of $S_T$, and $r$ the continuously
  compounded rate. Any European payoff is worth its discounted
  risk-neutral expectation, so
  $ C(K) = e^(-r T) integral_K^infinity (S - K) q(S) dif S. quad (1) $
  Differentiating in $K$,
  $ (partial C)/(partial K) = -e^(-r T) bb(Q)(S_T > K),
    quad #link(<eq-state-appendix>)[(2)] $ <eq-first>
  $ (partial^2 C)/(partial K^2) = e^(-r T) q(K).
    quad #link(<eq-state-appendix>)[(3)] $ <eq-second>
  The slope of the call curve is a discounted digital option, and its
  curvature is a discounted density: the price today of \$1 paid if $S_T$
  lands in $[K, K + dif K]$, per unit $dif K$. These are the Arrow–Debreu
  state prices. Nothing is assumed about the dynamics of $S$; the result
  needs only calls at every strike. Puts give the same second derivative,
  by put–call parity.

  Two no-arbitrage conditions follow for free. Because $q >= 0$, the call
  curve is convex in $K$. Because $bb(Q)(S_T > K)$ lies in $[0, 1]$, its
  slope lies in $[-e^(-r T), 0]$. Any fitted call curve that breaks either
  condition implies negative probabilities.

  == The Butterfly

  The second difference
  $ (C(K - h) - 2 C(K) + C(K + h))/h^2 -> (partial^2 C)/(partial K^2)
    quad (4) $
  is the price of a portfolio: long one call at $K - h$, short two at $K$,
  long one at $K + h$, scaled by $1 slash h^2$. Its payoff is a triangle of
  height $1 slash h$ and area 1 centred on $K$. As $h$ shrinks it narrows
  into a spike, the payoff of an Arrow–Debreu security. The butterfly is
  what makes state prices tradable.

  #image("../output/butterfly_payoff.png", width: 100%)

  == Probabilities of Events

  Equation (2) gives event probabilities without any density or
  integration:
  $ bb(Q)(S_T < K) = 1 + e^(r T) (partial C)/(partial K). quad (5) $
  The traded version is a tight call spread, long $K - h slash 2$ and
  short $K + h slash 2$, scaled by $1 slash h$: a digital paying \$1 above
  $K$. Under Black–Scholes, with forward $F = S_0 e^(r T)$,
  $ bb(Q)(S_T > K) = N(d_2), quad
    q(K) = (n(d_2))/(K sigma sqrt(T)),
    quad #link(<eq-bs-appendix>)[(6)] $ <eq-bs>
  where $d_2 = (ln(F slash K) - sigma^2 T slash 2) slash sigma sqrt(T)$.
  The probability of finishing in the money is $N(d_2)$, not the delta
  $N(d_1)$.

  == Check Under Black–Scholes

  Take a \$100 stock, three months to expiry, $r = 4%$ and $sigma = 20%$.
  Pricing calls with Black–Scholes and applying (4), the recovered density
  matches (6). The central difference has error $h^2 slash 12$ times the
  density's second derivative (#link(<eq-error-appendix>)[appendix]), so
  halving $h$ should cut the worst-case error fourfold. It does:
  $5.3 times 10^(-4)$, $1.4 times 10^(-4)$, $3.4 times 10^(-5)$ and
  $8.5 times 10^(-6)$ for $h = 4, 2, 1, 0.5$. On a grid 5 cents apart the
  recovered density integrates to 1.0000 and its mean is the forward,
  101.00. Call spreads reproduce $N(d_2)$ to four decimals, giving
  $bb(Q)(S_T < 90) = 13.5%$ and $bb(Q)(S_T > 110) = 18.3%$.

  #image("../output/black_scholes_density.png", width: 100%)

  == A Scheduled Binary Event

  The result is model-free, so it must recover any distribution, including
  ones no smooth model would produce. Consider a stock facing a binary
  event before expiry, such as a regulatory decision. With probability
  $w = 0.6$ it ends near $F_"up" = 1.08 F = 109.09$, otherwise near
  $F_"down" = 88.88$, with volatility $s = 12%$ within each scenario.
  $F_"down"$ is set so that $w F_"up" + (1 - w) F_"down" = F$, as
  risk-neutral pricing requires. A mixture of lognormals prices calls as
  the same mixture of Black–Scholes prices,
  $ C(K) = w C_"BS" (F_"up", K, s) + (1 - w) C_"BS" (F_"down", K, s),
    quad (7) $
  the approach Melick and Thomas @melick1997 used for crude oil during the
  Gulf crisis. Here it is the truth, so the recovery can be checked.

  A trader quoting these options in Black–Scholes terms sees each price
  as its own implied volatility, and the curve is an inverted smile. It
  peaks at 26% near $K = 96$, between the two outcomes, where the event
  decides whether the option pays, and falls to about 16% in either wing,
  where the outcome barely matters.

  #image("../output/event_smile.png", width: 100%)

  Applying (4) to the prices recovers both humps, with a maximum error of
  $2 times 10^(-7)$. A lognormal at the at-the-money volatility puts its
  peak near the trough between the two outcomes.

  #image("../output/event_density.png", width: 100%)

  == The Smile Moves Probability

  A tempting shortcut is to read $bb(Q)(S_T > K)$ as $N(d_2)$ evaluated
  at the implied volatility $sigma(K)$ of each strike. With a smile that
  is wrong. Writing $C(K) = C_"BS" (K, sigma(K))$ and differentiating,
  $ bb(Q)(S_T > K) = N(d_2 (sigma(K))) - e^(r T) cal(V)(K) sigma'(K),
    quad #link(<eq-smile-appendix>)[(8)] $ <eq-smile>
  where $cal(V)$ is the Black–Scholes vega. The slope of the smile shifts
  probability between strikes. For the event stock:

  #table(
    columns: (auto, 1fr, 1fr, 1fr),
    align: center,
    stroke: 0.4pt,
    table.header([$K$], [*true*], [$N(d_2)$], [*with (8)*]),
    [85], [0.9050], [0.9313], [0.9050],
    [95], [0.6441], [0.6588], [0.6441],
    [105], [0.4377], [0.3482], [0.4377],
    [115], [0.1088], [0.0806], [0.1088],
  )

  At $K = 105$, where the curve falls steeply, the
  shortcut understates the chance of the good outcome by 9 points. With
  the skew term, (8) is exact.

  == Why the Recipe Fails on Quotes

  Everything so far used exact prices on a grid 5 cents apart. Real
  options list at a few strikes, often \$1 to \$5 apart, and each quote is
  known only to within its bid–ask spread. Both damage the second
  difference (#link(<eq-error-appendix>)[appendix]):
  - spacing $h$ adds a bias $h^2 q''(K) slash 12$, which smears sharp
    features such as the event's two humps;
  - independent quote errors of size $epsilon$ add density noise of size
    $ e^(r T) sqrt(6) epsilon slash h^2. quad #link(<eq-error-appendix>)[(9)] $ <eq-noise>
  Shrinking $h$ cuts the bias and inflates the noise. With two cents of
  quote error, far inside a typical spread, the noise is 0.050 at \$1
  spacing, larger than the peak density of 0.037, and 29 of 79 butterflies
  imply negative probabilities. At \$5 spacing the noise is 0.002, but the
  two humps blur together and nothing is known between strikes or beyond
  the last one.

  #image("../output/noisy_butterflies.png", width: 100%)

  Neighbouring butterflies share quotes: a price that is too high raises
  the butterfly centred on it and lowers both neighbours. The noise
  therefore alternates in sign from strike to strike, the zigzag in the
  figure.

  == What Comes Next

  The theory is exact, but it needs a smooth, arbitrage-free call curve at
  every strike, and markets supply a few noisy points. The practical
  methods differ in how they fill the gap. Shimko @shimko1993 smooths the
  implied-volatility curve and differentiates the call prices it implies.
  Jackwerth and Rubinstein @jackwerth1996 solve for the smoothest density
  that prices the quotes within their spreads, which makes the fitted call
  curve arbitrage-free by construction.

  Whatever the method, the result is a risk-neutral distribution. It
  prices outcomes in dollars today, weighted by how much investors fear
  them, and generally puts more mass on bad states than their real-world
  frequency.
]

#pagebreak()

= Appendix

== State Prices <eq-state-appendix>

#link(<eq-first>)[Equations (2) and (3)]

Differentiate (1) with the Leibniz rule. The lower limit contributes
$-(K - K) q(K) = 0$, and differentiating the integrand gives $-q(S)$, so
$ (partial C)/(partial K) = -e^(-r T) integral_K^infinity q(S) dif S
  = -e^(-r T) bb(Q)(S_T > K). $
Differentiating again, the integral loses its lower limit:
$ (partial^2 C)/(partial K^2) = e^(-r T) q(K). $
For a put, $P(K) = e^(-r T) integral_0^K (K - S) q(S) dif S$ gives
$partial P slash partial K = e^(-r T) bb(Q)(S_T < K)$. Put–call parity,
$C - P = e^(-r T) (F - K)$, is linear in $K$, so $C$ and $P$ have the same
second derivative.

== Black–Scholes <eq-bs-appendix>

#link(<eq-bs>)[Equation (6)]

On the forward, $C = e^(-r T) (F N(d_1) - K N(d_2))$ with $d_1 = d_2 +
sigma sqrt(T)$. Two facts simplify the derivative. First, $partial d_1
slash partial K = partial d_2 slash partial K = -1 slash (K sigma
sqrt(T))$. Second, $F n(d_1) = K n(d_2)$, since
$ ln (n(d_1))/(n(d_2)) = -(d_1^2 - d_2^2)/2
  = -(d_1 - d_2)(d_1 + d_2)/2 = -ln(F slash K). $
Differentiating $C$,
$ (partial C)/(partial K)
  = e^(-r T) [F n(d_1) (partial d_1)/(partial K) - N(d_2)
  - K n(d_2) (partial d_2)/(partial K)]
  = -e^(-r T) N(d_2), $
because the first and third terms cancel. Differentiating again,
$ (partial^2 C)/(partial K^2) = -e^(-r T) n(d_2) (partial d_2)/(partial K)
  = e^(-r T) (n(d_2))/(K sigma sqrt(T)). $
Comparing with (2) and (3) gives (6).

== Smile Correction <eq-smile-appendix>

#link(<eq-smile>)[Equation (8)]

When each strike has its own implied volatility, $C(K) = C_"BS" (K,
sigma(K))$ and the chain rule gives
$ (d C)/(d K) = (partial C_"BS")/(partial K)
  + (partial C_"BS")/(partial sigma) sigma'(K)
  = -e^(-r T) N(d_2) + cal(V) sigma'(K), $
with vega $cal(V) = e^(-r T) F n(d_1) sqrt(T)$. Multiplying by $-e^(r T)$
and using (2) gives (8). Where the smile slopes down ($sigma' < 0$), the
correction raises $bb(Q)(S_T > K)$ above $N(d_2)$.

== Discretization Error and Noise <eq-error-appendix>

#link(<eq-noise>)[Equation (9)]

Expanding $C(K plus.minus h)$ in a Taylor series, the odd terms cancel in
the second difference:
$ (C(K - h) - 2 C(K) + C(K + h))/h^2 = C'' + h^2/12 C^((4)) + O(h^4). $
Multiplying by $e^(r T)$ and using (3), $e^(r T) C^((4)) = q''$, so the
recovered density is off by $h^2 q''(K) slash 12$.

Now let each quote carry an independent error $epsilon_i$ with standard
deviation $epsilon$. The butterfly combines them as $epsilon_(i-1) - 2
epsilon_i + epsilon_(i+1)$, whose variance is $(1 + 4 + 1) epsilon^2$.
The density error therefore has standard deviation $e^(r T) sqrt(6)
epsilon slash h^2$. Adjacent butterflies share two quotes, and the
correlation between neighbours is
$ ("Cov"(-2 epsilon_i + epsilon_(i+1), epsilon_i - 2 epsilon_(i+1)))
  /(6 epsilon^2) = (-2 - 2)/6 = -2/3, $
which produces the alternating signs.

== Notation

#table(
  columns: (auto, 1fr),
  align: (center, left),
  stroke: 0.4pt,
  table.header([*symbol*], [*meaning*]),
  [$S_T$], [underlying price at expiry],
  [$S_0$, $F$], [spot price and forward, $F = S_0 e^(r T)$],
  [$K$], [strike],
  [$T$], [time to expiry, years],
  [$r$], [continuously compounded rate],
  [$q(S)$], [risk-neutral density of $S_T$],
  [$bb(Q)$], [risk-neutral probability],
  [$C(K)$, $P(K)$], [call and put prices],
  [$h$], [strike spacing],
  [$sigma$, $sigma(K)$], [volatility; implied volatility at $K$],
  [$N$, $n$], [standard normal cdf and pdf],
  [$d_1$, $d_2$], [Black–Scholes terms, $d_1 = d_2 + sigma sqrt(T)$],
  [$cal(V)$], [Black–Scholes vega],
  [$w$], [probability of the good event outcome],
  [$F_"up"$, $F_"down"$], [scenario forwards],
  [$s$], [volatility within each scenario],
  [$epsilon$], [standard deviation of quote error],
)

#bibliography("references.bib", title: "References", style: "ieee")

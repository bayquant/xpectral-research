# The Almgren–Chriss Impact Model — Core Flow of Ideas

*One connected line of reasoning: from the trading dilemma, to the cost function, to the derivation of the optimal schedule (discrete and continuous), to its shape, its symmetry, and how to calibrate it.*

---

## Stage 1 — The dilemma that starts everything

You must liquidate $X$ shares over a horizon $T$. Two extremes are both bad:

- **Trade fast** → your own flow pushes the price against you. This is **market impact**.
- **Trade slow** → you sit exposed while the price wanders. This is **timing risk** (volatility).

Fast costs impact; slow costs risk. The entire model is the search for the schedule that **balances these two**, governed by a single risk-aversion dial.

---

## Stage 2 — The three forces at work

1. **Volatility ($\sigma$)** — the price moves randomly regardless of what you do; the longer you hold, the more this can hurt.
2. **Temporary impact ($\eta$)** — trading *fast* worsens your fill *now*, but the price rebounds once you stop. The price of demanding immediacy.
3. **Permanent impact ($\gamma$)** — your trading also nudges the "true" price, and it *stays* nudged.

$\sigma$ drives risk; $\eta$ and $\gamma$ drive cost.

---

## Stage 3 — Building the cost function

Chop $T$ into $N$ chunks of length $\tau = T/N$. Let $x_k$ = shares **still held** after chunk $k$, with $x_0 = X$ (hold everything) and $x_N = 0$ (fully out). Let $n_k = x_{k-1} - x_k$ = shares traded in chunk $k$.

> **Why $n_k = x_{k-1} - x_k$ and not the reverse?** $n_k$ is meant to count *shares sold*, a positive number. Selling means the earlier holding $x_{k-1}$ is the larger one, so $x_{k-1}-x_k > 0$. The reverse, $x_k - x_{k-1}$, is the *change in holdings* (negative when selling). The choice is pure bookkeeping cosmetics: $n_k$ only ever appears **squared** in the objective, and $(x_{k-1}-x_k)^2 = (x_k-x_{k-1})^2$, so the sign washes out and the final formula is identical either way. (Sign would only matter if impact were modeled with an *odd* power of $n_k$; here it is quadratic.)

The two cost pieces:

- **Permanent impact** contributes $\tfrac{1}{2}\gamma X^2$ — depends only on *total* size, shaped like the area of a triangle (each share nudges price by $\gamma$, so the average share pays $\tfrac12\gamma X$).
- **Temporary impact** contributes $\dfrac{\eta}{\tau}\sum_k n_k^2$ — cost = (concession per share $\eta\, n_k/\tau$) × (shares $n_k$). Spreading the same trade over a longer $\tau$ shrinks it: *that* is why slow trading is cheap.

The **risk** (variance of cost): during chunk $k$ you hold $x_k$ shares through a random move $\sigma\sqrt{\tau}\,\xi_k$; the variance of that dollar swing is $x_k^2\,\sigma^2\tau$. Summed:

$$\mathbb{V}[\text{cost}] = \sigma^2 \sum_k \tau\, x_k^2.$$

($x_k^2$ because variance scales with the square of exposure; $\tau$ because in a random walk variance grows linearly with time — independent steps, so variances add.)

---

## Stage 4 — The objective, and why permanent impact disappears

Minimize expected cost **plus** a penalty on risk:

$$\min_{x_1,\dots,x_{N-1}} \;\; \underbrace{\tfrac{1}{2}\gamma X^2 + \frac{\eta}{\tau}\sum_{k=1}^{N} n_k^2}_{\mathbb{E}[\text{cost}]} \;\;+\;\; \lambda\,\underbrace{\sigma^2 \sum_{k=1}^{N} \tau\, x_k^2}_{\mathbb{V}[\text{cost}]}$$

- **$\lambda$ is the one dial you set** — your risk aversion. Large $\lambda$ = "get me out fast"; small $\lambda$ = "take your time." It's the extra expected cost you'll pay to remove one unit of variance.
- **We add, not subtract**, because $\mathbb{E}$ and $\mathbb{V}$ are *both bad* and we're minimizing total unhappiness. (The familiar minus sign belongs to the *maximization* form $\max(\text{return} - \lambda V)$.)
- **Permanent impact drops out.** $\tfrac12\gamma X^2$ depends only on total size $X$, which every schedule shares. It's a constant added to the objective — a real, unavoidable cost, but it can't be *reduced* by scheduling, so it doesn't affect the minimizer.

Strip the constant and name the two coefficients:

$$F = a\sum_{k=1}^{N}(x_{k-1}-x_k)^2 + b\sum_{k=1}^{N-1}x_k^2, \qquad a = \frac{\eta}{\tau}, \quad b = \lambda\sigma^2\tau.$$

The free variables are the interior holdings $x_1,\dots,x_{N-1}$; the endpoints $x_0=X$ and $x_N=0$ are locked.

---

## Stage 5 — Solving it (the discrete grind)

$F$ is a sum of squares — a convex bowl with one lowest point, where the surface is flat in every direction. So the recipe is: **differentiate with respect to each free $x_j$, set to zero, solve.**

**Differentiate w.r.t. one interior $x_j$.** The only terms containing $x_j$ are: $(x_{j-1}-x_j)^2$ and $(x_j-x_{j+1})^2$ in the first sum, and $x_j^2$ in the second. Everything else is constant in $x_j$.

$$\frac{\partial F}{\partial x_j} = a\big[-2(x_{j-1}-x_j) + 2(x_j-x_{j+1})\big] + 2b\,x_j = 0.$$

Collect and cancel the 2:

$$a\,(2x_j - x_{j-1} - x_{j+1}) + b\,x_j = 0 \;\;\Longrightarrow\;\; x_{j+1} - 2x_j + x_{j-1} = \frac{b}{a}\,x_j = \frac{\lambda\sigma^2\tau^2}{\eta}\,x_j.$$

This is a recurrence linking each holding to its two neighbors.

---

## Stage 6 — The key recognition: it's secretly a differential equation

The left-hand side $x_{j+1} - 2x_j + x_{j-1}$ is exactly the **discrete second derivative** — the "$+1,-2,+1$" second-difference stencil you learned alongside the forward/backward/central *first* differences. It's a difference *of the differences*:

$$\frac{1}{\tau}\!\left[\underbrace{\frac{x_{j+1}-x_j}{\tau}}_{\text{slope ahead}} - \underbrace{\frac{x_j-x_{j-1}}{\tau}}_{\text{slope behind}}\right] = \frac{x_{j+1}-2x_j+x_{j-1}}{\tau^2} \approx x''(t_j).$$

So divide the recurrence by $\tau^2$:

$$\underbrace{\frac{x_{j+1}-2x_j+x_{j-1}}{\tau^2}}_{\approx\, x''(t_j)} = \frac{\lambda\sigma^2}{\eta}\,x_j \;\;\Longrightarrow\;\; \boxed{\,x''(t) = \kappa^2\, x(t)\,}, \qquad \kappa^2 = \frac{\lambda\sigma^2}{\eta}.$$

The discrete optimality condition **is** the continuous Euler–Lagrange equation, just sampled on a grid. This is why "bending proportional to height" kept coming up — the bending was the second derivative all along. And it means we can skip the recurrence gymnastics and solve the clean ODE instead.

---

## Stage 7 — Solving the ODE cleanly

*Find a function whose second derivative is itself, scaled by $\kappa^2$.* The exponential is the natural candidate. Try $x = e^{rt}$:

$$r^2 e^{rt} = \kappa^2 e^{rt} \;\Longrightarrow\; r^2 = \kappa^2 \;\Longrightarrow\; r = \pm\kappa.$$

No messy quadratic, no reciprocal roots — two roots immediately. The general solution is any weighted blend:

$$x(t) = A\,e^{\kappa t} + B\,e^{-\kappa t}.$$

**Impose the two endpoints** (a 2nd-order equation needs exactly two facts). For **selling**, $x(0)=X$ and $x(T)=0$:

$$A + B = X, \qquad A\,e^{\kappa T} + B\,e^{-\kappa T} = 0.$$

Solving gives $B = \dfrac{X}{1-e^{-2\kappa T}}$, $A = \dfrac{-X e^{-2\kappa T}}{1-e^{-2\kappa T}}$. Substitute, multiply top and bottom by $e^{\kappa T}$ so the exponentials fold into hyperbolic sines ($\sinh z = \tfrac12(e^z-e^{-z})$), and:

$$\boxed{\,x(t) = X\,\frac{\sinh\!\big(\kappa(T-t)\big)}{\sinh(\kappa T)}\,}$$

Same answer as the discrete grind, a fraction of the labor. **$\sinh$ appears** because it's precisely the exponential blend that is **zero at one end** and grows toward the other — exactly what the boundary condition $x(T)=0$ selects.

> **On the two symbols $t$ and $T$:** $T$ is a *fixed number* (the total horizon), baked into the constants $A,B$ along with $\kappa$ and $X$. $t$ is the *moving clock* that sweeps $0\to T$ and lives only in the exponentials. The final formula is "a constant (built from $T$) times a function of $t$." The second $T$ that appears inside $\sinh(\kappa(T-t))$ is just the $e^{-2\kappa T}$ from $A$ merging into the same exponential as $e^{\kappa t}$ — nothing new was introduced.

---

## Stage 8 — The shape of the answer

Everything hinges on **one number**:

$$\kappa = \sqrt{\frac{\lambda\sigma^2}{\eta}}.$$

It's a tug-of-war: urgency ($\lambda,\sigma$) in the numerator pushes $\kappa$ up; patience/impact-cost ($\eta$) in the denominator pulls it down. $1/\kappa$ is the unwind timescale, so **big $\kappa$ = short, aggressive unwind**. It is built entirely from constants — *not* a function of time.

- **$\lambda \to 0$ (risk-neutral):** you can't plug in $\kappa=0$ directly ($0/0$), so take the limit using $\sinh(z)\approx z$: the curve becomes the **straight line** $x(t) = X(1 - t/T)$ — a constant selling rate $X/T$ (TWAP-like, minimum impact). Note "constant rate" is a straight-line *holdings* curve, not a flat one.
- **$\lambda$ large (risk-averse):** $\kappa$ grows, the curve **bends** — dump a lot early, taper off.

---

## Stage 9 — Buying is the mirror image

Accumulating $0 \to X$ leaves the differential equation *untouched* (the trade term is squared, so cost is direction-blind). Only the endpoints flip: $x(0)=0$, $x(T)=X$. Now $A=-B$, and:

$$\boxed{\,x(t) = X\,\frac{\sinh(\kappa t)}{\sinh(\kappa T)}\,}$$

The two schedules are exact **time-reversals**:

$$\text{Sell: } X\,\frac{\sinh(\kappa(T-t))}{\sinh(\kappa T)} \qquad\qquad \text{Buy: } X\,\frac{\sinh(\kappa t)}{\sinh(\kappa T)}.$$

Replace $t \leftrightarrow T-t$ in one to get the other. (In the idealized linear model impact is symmetric; in reality short-sale constraints and order-flow imbalance can break that — verify before assuming.)

---

## Stage 10 — The efficient frontier

Sweep $\lambda$ from $0$ upward. Each value changes $\kappa$, hence the whole schedule, hence a different $(\text{risk}, \text{expected cost})$ pair:

- Small $\lambda$ → slow, even → low cost $\mathbb{E}$, high risk $\mathbb{V}$.
- Large $\lambda$ → fast dump → high cost $\mathbb{E}$, low risk $\mathbb{V}$.

You can't make both small at once. The traced-out curve is the **efficient frontier** — the lowest expected cost achievable at each risk level. You choose where on it to sit.

---

## Stage 11 — Calibrating with real data

Four numbers feed the model: **$\sigma$** (easy — historical returns, in *dollars* per share per $\sqrt{\text{time}}$, not a percentage), **$\eta$** and **$\gamma$** (fit from data), and **$\lambda$** (a *choice*, not a measurement). Then $\kappa = \sqrt{\lambda\sigma^2/\eta}$ drops into the trajectory formula.

**Separating $\gamma$ from $\eta$** uses three prices per historical parent order: arrival $P_0$, average execution $\bar P$, and post-trade $P_\infty$.

$$\text{permanent} = P_\infty - P_0, \qquad \text{temporary} = (\bar P - P_0) - \tfrac{1}{2}(P_\infty - P_0)$$

(the $\tfrac12$ because while you were executing, the permanent shift was only *half* built). Normalize both by $\sigma\,P_0$ into volatility units, then run two regressions **through the origin** (a zero order moves nothing):

$$y^{\text{perm}} = \gamma\,\frac{X}{V} \quad(\text{total size}), \qquad\qquad y^{\text{temp}} = \eta\,\frac{X}{V\,T} \quad(\text{participation rate}).$$

Fit $\gamma$ first, use it to build $y^{\text{temp}}$, then fit $\eta$. In practice: fit **coefficients across the whole universe** using liquidity variables (volume, volatility, spread), then plug in a stock's numbers — the *formula* is universal, the *values* are stock-specific. Bin noisy data, weight by precision, and choose the reversion window carefully.

---

## Stage 12 — Honest caveats

The **linear** model is the clean teaching version. Almgren et al. (2005) let the exponents float (log–log regression) and found permanent impact ≈ linear ($\alpha\approx1$) but temporary impact **sublinear** ($\beta\approx0.6$) — the origin of the **square-root law** (doubling the rate raises temporary cost by only $2^{0.6}\approx1.5\times$). The model also assumes $T,\sigma,\eta,\gamma$ are fixed through the day, which markets don't quite honor. But the core insight stands: **a measurable tradeoff between impact and risk, navigated by one dial $\lambda$.**

---

## The whole flow in one breath

> Impact vs. risk → weigh them with $\lambda$ → permanent impact is a constant and drops out → minimize the rest → the optimality condition is the discrete second derivative $=\kappa^2 x$ → i.e. $x''=\kappa^2 x$ → solved by exponentials → boundary conditions carve out $\sinh$ → **$x(t)=X\,\sinh(\kappa(T-t))/\sinh(\kappa T)$**, with $\kappa=\sqrt{\lambda\sigma^2/\eta}$ setting how hard you front-load → buying is its time-reversal → sweeping $\lambda$ traces the efficient frontier → calibrate $\sigma,\eta,\gamma$ from data (three-price trick, regress through the origin), choose $\lambda$ yourself.

---

## Key formulas at a glance

| Quantity | Formula |
|---|---|
| Objective | $\min\; \mathbb{E}[\text{cost}] + \lambda\,\mathbb{V}[\text{cost}]$ |
| Expected cost | $\tfrac{1}{2}\gamma X^2 + \dfrac{\eta}{\tau}\sum n_k^2$ |
| Variance of cost | $\sigma^2 \sum \tau\, x_k^2$ |
| Optimality condition | $x''(t) = \kappa^2 x(t)$ |
| Decay parameter | $\kappa = \sqrt{\lambda\sigma^2/\eta}$ |
| Optimal holdings (sell) | $x(t) = X\,\dfrac{\sinh(\kappa(T-t))}{\sinh(\kappa T)}$ |
| Optimal holdings (buy) | $x(t) = X\,\dfrac{\sinh(\kappa t)}{\sinh(\kappa T)}$ |
| Risk-neutral limit | $x(t) = X(1 - t/T)$ |
| Permanent regression | $y^{\text{perm}} = \gamma\,(X/V)$ |
| Temporary regression | $y^{\text{temp}} = \eta\,\big(X/(V T)\big)$ |

---

## References

- R. Almgren and N. Chriss, "Optimal execution of portfolio transactions," *Journal of Risk*, 2000.
- R. Almgren, C. Thum, E. Hauptmann, H. Li, "Direct estimation of equity market impact," *Risk*, 2005.

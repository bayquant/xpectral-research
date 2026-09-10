# The Almgren–Chriss Impact Model — A Plain-Language Walkthrough

*A conversational explanation of the Almgren–Chriss optimal execution model, its derivation, and how to calibrate it with real data.*

---

## Part 1 — The model from scratch

The model here is the **Almgren–Chriss model** of optimal trade execution (Robert Almgren and Neil Chriss, 2000), often shortened to "the Almgren impact model."

### The problem it solves

Imagine you run a fund and need to sell 1,000,000 shares of a stock today. You face two bad extremes:

- **Sell everything instantly.** Your own selling floods the market and pushes the price down, so you get lousy prices. This is *market impact*.
- **Sell very slowly.** Now you're holding the position for hours while the market drifts randomly — maybe against you. This is *timing risk* (volatility).

The whole model is about the tension between these two. Sell fast and you pay impact; sell slow and you take on risk. Almgren and Chriss found the schedule that balances them optimally.

### Three forces

1. **Volatility (σ):** the price wanders randomly, up or down, no matter what you do. The longer you hold shares, the more this randomness can hurt you.
2. **Temporary impact (η):** trading *fast* gets you a worse price right now, but the market bounces back after you stop. Think of it as the price of demanding immediacy.
3. **Permanent impact (γ):** your trading also nudges the "true" market price and it *stays* nudged (the market infers you know something).

### Building the cost, piece by piece

Chop the day into small chunks. Let $x_k$ = shares you still hold after chunk $k$. You start with $x_0 = X$ (all of them) and must end with $x_N = 0$ (all sold). Let $n_k$ = shares sold during chunk $k$.

**Expected cost:**

- Permanent impact contributes about $\frac{1}{2}\gamma X^2$. This depends only on the *total* size $X$, not on the schedule. You can't dodge it, so it drops out of the optimization.
- Temporary impact contributes roughly $\eta \sum \frac{n_k^2}{\tau}$ (where $\tau$ is the chunk length). The square is the key: trading twice as fast in a chunk costs *four* times as much.

**Risk (variance of the cost):**

$$\sigma^2 \sum \tau\, x_k^2$$

The more shares you're still holding ($x_k$ large) and the longer you hold them, the more volatility risk you carry.

### The optimization

You minimize a weighted sum:

$$\text{Expected cost} \;+\; \lambda \times \text{Risk}$$

Here **λ (lambda) is your risk aversion** — a dial you set. Large λ means "get me out fast." Small λ means "take your time."

### The answer

$$x(t) = X \cdot \frac{\sinh\!\big(\kappa (T - t)\big)}{\sinh(\kappa T)}$$

The one number that matters is

$$\kappa = \sqrt{\frac{\lambda \sigma^2}{\eta}}$$

- **λ = 0 (risk-neutral):** κ → 0 and the curve becomes a **straight line** — sell at a constant rate (VWAP-like, minimum impact).
- **λ large (risk-averse):** κ grows, the curve bends — you **dump a lot early** and taper off.

A useful reading: $1/\kappa$ is the "half-life" of your position.

### Optimal selling trajectories (shares remaining over the window)

| Fraction of time elapsed | Risk-neutral (λ=0) | Moderate (κ=2) | Aggressive (κ=5) |
|:---:|:---:|:---:|:---:|
| 0.0 | 1.000 | 1.000 | 1.000 |
| 0.1 | 0.900 | 0.811 | 0.607 |
| 0.2 | 0.800 | 0.655 | 0.368 |
| 0.3 | 0.700 | 0.525 | 0.223 |
| 0.4 | 0.600 | 0.416 | 0.135 |
| 0.5 | 0.500 | 0.324 | 0.082 |
| 0.6 | 0.400 | 0.245 | 0.049 |
| 0.7 | 0.300 | 0.176 | 0.029 |
| 0.8 | 0.200 | 0.113 | 0.016 |
| 0.9 | 0.100 | 0.056 | 0.007 |
| 1.0 | 0.000 | 0.000 | 0.000 |

The aggressive trader (κ=5) is already ~90% done by the halfway point; the risk-neutral one is exactly 50% done.

### The efficient frontier

Sweep λ from 0 upward, and each value gives a (risk, expected cost) pair. Together they trace the **efficient frontier** — the lowest possible expected cost for each level of risk. You pick where on it you want to sit.

### Using it with real data — the four numbers

- **σ — volatility (easy):** from historical returns, scaled to your horizon.
- **η — temporary impact (harder):** regress observed slippage against trading speed.
- **γ — permanent impact (hardest):** regress the lasting price shift against total quantity.
- **λ — risk aversion (a choice, not a measurement):** encodes your preferences.

Then compute $\kappa = \sqrt{\lambda\sigma^2/\eta}$, drop it into the trajectory formula, and read off the schedule.

### Two honest caveats

The linear model is the clean teaching version. Almgren's later empirical work (2005) found impact grows more like the **square root** of size, not linearly. And the model assumes T, σ, η, γ are fixed through the day, which real markets don't quite honor. But the core insight — a measurable tradeoff between impact and risk, navigated by one dial (λ) — is exactly right.

---

## Part 2 — Understanding the shapes of the formulas

### 1. Why does permanent impact drop out of the optimization?

Its total cost is $\frac{1}{2}\gamma X^2$, which depends only on total size $X$. Every schedule starts holding $X$ and ends at $0$, so every schedule pays this same amount. It's a constant added to the objective, and minimizing $f(\text{schedule}) + \text{constant}$ picks the same winner as minimizing $f$ alone. It's still a real cost — it just can't be *reduced* by scheduling.

### 2. Why is permanent impact the square of total size?

Think of a triangle. Each share you sell nudges the price down by a fixed step $\gamma$. So the first share suffers almost no depression; the last suffers the full $\gamma X$. On average each share pays about $\frac{1}{2}\gamma X$.

$$\text{Total} = X \times \tfrac{1}{2}\gamma X = \tfrac{1}{2}\gamma X^2.$$

Geometrically, it's the area of a triangle: $\frac{1}{2}\cdot\text{base}\cdot\text{height} = \frac{1}{2} X \cdot \gamma X$. The square comes from "quantity times a depression that is itself proportional to quantity."

### 3. Temporary impact: why divide by τ?

Temporary impact depends on how *fast* you trade. The thing that matters is the trading *rate*: $v_k = n_k / \tau$. The cost of a chunk is (concession per share) × (shares):

$$\underbrace{\eta \cdot \frac{n_k}{\tau}}_{\text{concession per share}} \times \underbrace{n_k}_{\text{shares}} = \frac{\eta\, n_k^2}{\tau}.$$

Spreading the same $n_k$ over a longer $\tau$ shrinks the cost — that's *why* slow trading is cheap.

### 4. Risk: why $x_k^2$ times τ?

During chunk $k$ you hold $x_k$ shares and the price makes a random move of size $\sigma\sqrt{\tau}\,\xi_k$. Your dollar swing is $x_k \times \sigma\sqrt{\tau}\,\xi_k$, whose variance is $x_k^2 \cdot \sigma^2 \tau$.

- **$x_k^2$** — variance scales with the square of exposure ($\text{Var}(a\xi) = a^2\text{Var}(\xi)$).
- **$\tau$** — in a random walk, variance grows linearly with time.

Sum over chunks: $\sigma^2 \sum \tau\, x_k^2$.

### 5. Why large λ = get out fast, small λ = take your time?

In $E + \lambda V$, $\lambda$ is the weight on risk.

- Large $\lambda$: the $\lambda V$ term dominates, so the optimizer minimizes $V$ — hold few shares early, i.e. dump fast.
- Small $\lambda$: the $E$ term dominates, so the optimizer minimizes impact — trade evenly and slowly.

$\lambda$ = how many dollars of extra expected cost you'll pay to remove one unit of variance.

### 6. Why $E + \lambda V$ and not minus?

Both $E$ and $V$ are *bad*, and you're **minimizing** total unhappiness, so they add. With a minus, the optimizer would try to *increase* variance — backwards. (The minus you may recall comes from the *maximization* form $\max(\text{return} - \lambda V)$, where you subtract risk from a *good*.)

### 7. Why does κ mean "how aggressively you front-load"?

$\kappa = \sqrt{\lambda\sigma^2/\eta}$ is a tug-of-war:

- $\lambda, \sigma$ in the numerator = urgency → bigger κ.
- $\eta$ in the denominator = patience (rushing is costly) → smaller κ.

Bigger κ makes the liquidation curve plunge earlier. $1/\kappa$ is the unwind timescale, so big κ = short unwind = aggressive.

### 8. The λ = 0 puzzle

You can't substitute $\kappa = 0$ directly — you get $\sinh(0)/\sinh(0) = 0/0$, undefined. Take the **limit**. For tiny inputs, $\sinh(z)\approx z$:

$$\frac{\sinh(\kappa(T-t))}{\sinh(\kappa T)} \;\xrightarrow[\kappa\to 0]{}\; \frac{\kappa(T-t)}{\kappa T} = \frac{T-t}{T}.$$

So

$$x(t) = X\left(1 - \frac{t}{T}\right),$$

a **straight line** from $X$ down to $0$. Since $x(t)$ is *shares still held*, a straight-line decline means equal amounts sold each step — the selling rate $-\frac{dx}{dt} = X/T$ is constant. "Constant rate" shows up as a straight-line *holdings* curve, not $x(t)=X$.

### 9. Isn't κ a function of time?

No. $\kappa = \sqrt{\lambda\sigma^2/\eta}$ is built entirely from constants, so it's a fixed number. Only $t$ varies in $x(t)$; $\kappa$ just multiplies it — like the constant decay rate in $e^{-\kappa t}$.

### 10. Why a different (cost, risk) pair for each λ?

Changing $\lambda$ changes $\kappa$, changing the whole schedule:

- Small λ → slow, even trading → low cost $E$, high risk $V$.
- Large λ → fast dumping → high cost $E$, low risk $V$.

You can't get both low at once, so sweeping λ slides you along the tradeoff — the efficient frontier.

### 11. Is volatility in dollars?

Yes — $\sigma$ is an *absolute* volatility in **dollars per share per $\sqrt{\text{time}}$**, not a percentage. That's why 30% relative vol on a \$50 stock became ≈ \$0.94/share/√day. Check the units:

$$\underbrace{\sigma^2}_{\$^2/\text{sh}^2/\text{time}} \times \underbrace{\tau}_{\text{time}} \times \underbrace{x_k^2}_{\text{sh}^2} = \$^2.\;\checkmark$$

---

## Part 3 — Deeper mechanics

### 1. Are γ and η one number for the whole fund, or per stock?

Per stock, fundamentally, because impact is about *liquidity*, which varies wildly. But you rarely fit an independent γ, η per ticker (too noisy). Desks fit a **cross-sectional** model: express impact via liquidity variables (average daily volume, volatility, spread, market cap) and estimate *universal coefficients* across the universe. Then plug in a given stock's volume and volatility to get its effective γ and η. The *formula* is fit across the universe; the *numbers* are stock-specific.

### 2. The optimization in full mathematical terms

Setup:

$$X = \text{initial shares}, \quad T = \text{horizon}, \quad N = \text{steps}, \quad \tau = T/N$$
$$x_k = \text{shares held after step } k, \qquad x_0 = X, \quad x_N = 0$$
$$n_k = x_{k-1} - x_k = \text{shares traded in step } k$$

The optimization:

$$\min_{x_1,\, \dots,\, x_{N-1}} \;\; \underbrace{\frac{1}{2}\gamma X^2 + \frac{\eta}{\tau}\sum_{k=1}^{N} n_k^2}_{\mathbb{E}[\text{cost}]} \;\; + \;\; \lambda\, \underbrace{\sigma^2 \sum_{k=1}^{N} \tau\, x_k^2}_{\mathbb{V}[\text{cost}]}$$

Sorting the symbols:

- **Fixed parameters:** $X,\, T,\, N,\, \tau,\, \gamma,\, \eta,\, \sigma,\, \lambda$.
- **Decision variables:** the holdings $x_1, \dots, x_{N-1}$ (equivalently trades $n_1, \dots, n_N$). This *is* the schedule.
- **An index, not a variable:** $k$ — it just labels the step.

Continuous limit ($N\to\infty$): minimize $\int_0^T \big[\eta\, x'(t)^2 + \lambda\sigma^2 x(t)^2\big]\,dt$ with $x(0)=X, x(T)=0$. The solution satisfies $x'' = \kappa^2 x$ with $\kappa^2 = \lambda\sigma^2/\eta$ — showing κ is assembled from fixed parameters only; $t$ is the sole mover.

### 3. Does buying (0 → X) work too?

Yes — a mirror image. Buying pushes the price *up* against you; the optimal accumulation schedule has the identical $\sinh$ shape, read as "shares acquired so far."

Separate γ, η for buys vs sells? In the idealized linear model, no (impact is assumed symmetric). In reality it often isn't — short-sale constraints, order-flow imbalance, and microstructure can make the two sides differ. Baseline: symmetric. Real world: verify before assuming.

### 4. Is "each share nudges price by γ" from the regression?

Two layers:

- The **linear form** ("impact ∝ quantity, constant γ") is a *modeling assumption* imposed before touching data.
- The **regression** estimates the *value* of γ — the slope of lasting price change vs quantity.

The regression doesn't tell you impact is linear; you assumed that and asked for the slope. Its residuals reveal how badly linearity fits — which is why square-root refinements exist.

### 5. "Each share moves price by γ" vs "the last share suffers γX"

Both are true — they describe different quantities:

- **Marginal move** — how much a share *causes* the price to drop: the constant γ. Every share moves it by γ. ✓
- **Depression suffered** — the price *level* a given share executes at, already pushed down by earlier trades.

The $j$-th share executes ≈ $\gamma(j-1)$ below start; the last executes ≈ $\gamma X$ below. So $\gamma X$ is the accumulated depression the last share *experiences*, not how much it *moves* the price. Total cost:

$$0 + \gamma + 2\gamma + \dots + (X-1)\gamma = \gamma\cdot\frac{(X-1)X}{2} \approx \frac{1}{2}\gamma X^2.$$

### 6. Why does variance grow linearly with time in a random walk?

A random walk is a *sum of independent steps*, and for independent variables, **variances add**. If each step has variance $\nu$ and there are $n$ steps:

$$\text{Var}(\text{total}) = \underbrace{\nu + \dots + \nu}_{n} = n\nu,$$

and $n \propto t$, so variance $\propto t$. The standard deviation is $\sqrt{n\nu} \propto \sqrt{t}$ — which is why volatility enters as $\sigma\sqrt{\tau}$ per step. The key is *independence*: cancellation of independent ups and downs gives the slower $\sqrt{t}$ spread. (Perfectly correlated steps would give variance $\propto t^2$.)

---

## Part 4 — The regressions for γ and η

The trick that makes the two regressions *separable* is measuring prices at three moments per order.

### What you record per historical order

For each parent order $i$ (a "metaorder"):

- $P_0^i$ — **arrival price** (mid-quote when the order started).
- $\bar P^i$ — **average execution price** (your realized VWAP).
- $P_\infty^i$ — **post-trade price** (mid-quote after the market settles).
- $X_i$ — signed order size (+ buys, − sells).
- $T_i$ — execution duration (fraction of a day).
- $V_i$ — average daily volume (trailing window).
- $\sigma_i$ — daily volatility (trailing window).

### Isolating the two impacts

$$\underbrace{P_\infty^i - P_0^i}_{\text{permanent: lasting shift}} \qquad\qquad \underbrace{\bar P^i - P_0^i}_{\text{total shortfall paid}}$$

While executing, the permanent shift was still building, so your fills only felt about **half** of the final permanent move. The pure temporary piece:

$$\text{temporary}_i = \big(\bar P^i - P_0^i\big) - \tfrac{1}{2}\big(P_\infty^i - P_0^i\big).$$

Normalize by $\sigma_i P_0^i$ (turning everything into dimensionless "daily-volatility units"):

$$y^{\text{perm}}_i = \frac{P_\infty^i - P_0^i}{\sigma_i\, P_0^i}, \qquad y^{\text{temp}}_i = \frac{\big(\bar P^i - P_0^i\big) - \tfrac12\big(P_\infty^i - P_0^i\big)}{\sigma_i\, P_0^i}.$$

### Regression 1 — permanent impact (γ)

Driven by total size relative to volume, $X_i/V_i$. Fit through the origin:

$$y^{\text{perm}}_i = \gamma\,\frac{X_i}{V_i} + \varepsilon_i$$

The OLS slope is $\gamma$.

### Regression 2 — temporary impact (η)

Driven by the trading *rate* (participation rate), $X_i/(V_i T_i)$. Through the origin:

$$y^{\text{temp}}_i = \eta\,\frac{X_i}{V_i\, T_i} + \varepsilon_i$$

The slope is $\eta$. Run Regression 1 first, build $y^{\text{temp}}$ with $\hat\gamma$, then run Regression 2. Multiply back through the $\sigma$/volume normalizations to recover raw dollar coefficients.

### The practical upgrade: power laws

Let the exponents float instead of forcing 1:

$$y^{\text{perm}}_i = \gamma \left(\frac{X_i}{V_i}\right)^{\!\alpha}, \qquad y^{\text{temp}}_i = \eta \left|\frac{X_i}{V_i T_i}\right|^{\beta}\!\text{sign}(X_i).$$

Estimate exponents in **log–log form**, which linearizes a power law:

$$\log\big|y^{\text{perm}}_i\big| = \log\gamma + \alpha \,\log\left|\frac{X_i}{V_i}\right| + \varepsilon_i.$$

The log–log slope *is* the exponent. Almgren et al. (2005) found permanent essentially linear ($\alpha \approx 1$), but temporary **sublinear** ($\beta \approx 0.6$) — the origin of the "square-root law." Doubling the rate raises temporary cost by only $2^{0.6} \approx 1.5\times$.

### Practical disciplines

Impact data is very noisy, so:

- **Bin the data** — group orders by similar participation, regress on bucket averages.
- **Weight by precision** — down-weight noisier observations (short durations, illiquid names).
- **Choose the reversion window carefully** — too short and temporary hasn't decayed; too long and drift creeps in.
- **Always force zero intercept** — a zero order moves nothing.

---

## Key formulas at a glance

| Quantity | Formula |
|---|---|
| Optimal holdings | $x(t) = X \cdot \dfrac{\sinh(\kappa(T-t))}{\sinh(\kappa T)}$ |
| Decay parameter | $\kappa = \sqrt{\lambda\sigma^2/\eta}$ |
| Risk-neutral limit | $x(t) = X(1 - t/T)$ |
| Expected cost | $\frac{1}{2}\gamma X^2 + \frac{\eta}{\tau}\sum n_k^2$ |
| Variance of cost | $\sigma^2 \sum \tau\, x_k^2$ |
| Objective | $\min\; \mathbb{E}[\text{cost}] + \lambda\,\mathbb{V}[\text{cost}]$ |
| Permanent regression | $y^{\text{perm}} = \gamma\,(X/V)$ |
| Temporary regression | $y^{\text{temp}} = \eta\,\big(X/(V T)\big)$ |

---

## References

- R. Almgren and N. Chriss, "Optimal execution of portfolio transactions," *Journal of Risk*, 2000.
- R. Almgren, C. Thum, E. Hauptmann, H. Li, "Direct estimation of equity market impact," *Risk*, 2005.

# Overbid Probability from Option Prices — Implementation Guide

A practical recipe for estimating the market-implied probability of an **overbid** (a competing or sweetened offer above the current cash bid) from traded options, building on Bester, Martinez & Roșu (2023, JFEC). The core move: fit their two-state merger model on the liquid part of the chain, then read the overbid signal off the residual on strikes above the offer price — always judged against the bid–ask spread.

---

## 1. The baseline model (what we build on)

Bester, Martinez & Roșu (BMR) model a cash-merger target as sitting between two outcomes at a known **effective date** T_e:

- **B₁** — the **offer price**: the fixed cash per share shareholders receive if the deal succeeds. Treated as known and essentially constant.
- **B₂(t)** — the **fallback price**: what the stock is worth if the deal fails and the firm stays independent. Random, modeled log-normally. Crucially, B₂ already absorbs "other potential merger offers" — this is where an overbid currently hides.
- **q(t)** — the risk-neutral **success probability**, a stochastic process constrained to [0,1].

The observed stock price is the probability-weighted blend of the two outcomes:

```
B(t) = q(t)·B₁·e^(−r(T_e − t)) + (1 − q(t))·B₂(t)
```

And the price of a European call with strike K and expiration T ≥ T_e is the matching blend — a claim on the fixed cash outcome plus a Black–Scholes call on the fallback:

```
C(K,t) = q(t)·(B₁ − K)⁺·e^(−r(T_e − t)) + (1 − q(t))·C_BS(B₂(t), K, T−t)
```

Two structural facts drive everything downstream:

1. **The kink.** Because the success term carries (B₁ − K)⁺, the call-price curve (and the implied-vol curve) bends sharply at K = B₁, with kink magnitude equal to the discounted success probability. This is the model's signature.
2. **Above B₁ the success term vanishes.** For K > B₁, (B₁ − K)⁺ = 0, so *all* value on high strikes comes from the fallback term alone. The two-state model structurally assigns almost nothing to deep-above-offer strikes — which is exactly why an overbid shows up there as something the model cannot explain.

Calls only: the clean blended formula is valid for European calls expiring after T_e (the American-call early-exercise argument holds for calls, not puts).

---

## 2. Where an overbid hides — and the core idea

The two-state model has no slot for an overbid. A competing or sweetened bid is currently split across two places:

- Inside **B₂**, because the fallback is defined to include the value from "other potential merger offers."
- As **offer-price changes** (sweetenings), which BMR treat as unanticipated jumps in B₁.

Neither gives you a clean, separately-identified overbid probability. The goal of this method is to pull that out and give it its own state.

**The signature to exploit.** When the market prices meaningful overbid probability, the payoff is no longer capped at B₁ — there is a chance of receiving *more*. So the cap softens, and that shows up precisely on strikes **above B₁**:

- OTM calls struck above B₁ trade **richer** than the two-state model predicts (the model says they are worth almost nothing except via the fallback).
- Equivalently, the kink at B₁ is **shallower**, and there is excess implied vol on the K > B₁ wing.

**Core idea in one line:** fit the two-state model where it is valid and liquid (strikes at/below B₁), then treat the *pricing residual on strikes above B₁* — observed minus model, scaled by the bid–ask spread — as the options-based overbid signal.

Why a residual rather than a direct fit: the one-option-per-day estimation reproduces the whole cross-section the two-state model is *capable* of representing. An overbid is the one feature it structurally cannot represent. So a persistent, spread-exceeding gap on the upper wing is a clean signal rather than ordinary fitting error.

---

## 3. The illiquidity problem (why the upper wing is hard)

The overbid signal lives exactly where options are thinnest. During a live deal the stock trades *below* the offer, so B₁ sits above the current price — meaning strikes at and above B₁ are OTM to deep-OTM, the widest-spread, highest-error part of the chain. The liquid, trustworthy region (deep-ITM, low strikes) sits *below* B₁.

BMR's own sample numbers, by moneyness (call relative spread, and their two-state model's pricing error):

| Moneyness bucket (K/S) | Region vs. B₁ | Rel. bid–ask spread | BMR call pricing error |
| --- | --- | --- | --- |
| Deep-ITM (K/S < 0.9) | well below | ~17% | ~2.6% |
| ITM (0.9–0.95) | below | ~29% | ~7.0% |
| Near-ITM (0.95–1.0) | near | ~41% | ~13% |
| Near-OTM (1.0–1.05) | near/above | ~75% | ~41% |
| OTM (1.05–1.1) | above | ~85% | ~42% |
| Deep-OTM (K/S > 1.1) | well above | ~95% | ~67% |

Two takeaways that shape the whole design:

1. **Do not estimate a precise overbid *level* from a few stale above-offer quotes.** The identification isn't there day-by-day. Extract something coarser and more robust: whether meaningful overbid probability is being priced, pooled over the deal.
2. **The bid–ask spread is your significance bar, not noise to ignore.** BMR validate their model by asking whether pricing errors fall *inside* the spread (~97% of calls do). Invert that: an overbid signal is only credible when the above-offer richness *exceeds* the spread.

---

## 4. The procedure (four steps)

The philosophy: let the liquid part of the chain do the hard identification, and use the illiquid upper wing only for a simple, spread-normalized comparison. Gate the expensive model behind a cheap screen.

**Step 1 — Fit the two-state model on strikes at/below B₁.**
Run the BMR model as published, but feed it only strikes at and below the offer price (the valid, more liquid region). This yields the clean latent paths q(t) and B₂(t) for each day. Deliberately exclude above-offer strikes here — they are contaminated by exactly the effect you're hunting, so letting them in would pollute the no-overbid baseline. You're building the counterfactual: what the surface *should* look like if the only outcomes are success or failure.

**Step 2 — Compute the standardized residual on strikes above B₁.**
For each K > B₁ option on each day, compute the two-state model price from Step 1's q(t), B₂(t), and compare to market. Then normalize by the spread:

```
resid(K,t) = [ C_mkt(K,t) − C_2state(K,t) ] / spread(K,t)
```

A no-overbid world says these high-strike calls are nearly worthless (fallback only). If the market pays meaningfully more, the standardized excess is your overbid signal. It counts only when it is comfortably **above 1** — below that, overbid pricing is indistinguishable from quote noise.

**Step 3 — Screen by sign, persistence, and size-vs-spread.**
Never read a single day. Require three things, pooled across the deal's life:

- **Sign:** residual consistently *positive* (market richer than no-overbid).
- **Persistence:** stays positive across many days, not one print — this is where pooling over time rescues you from day-level illiquidity.
- **Size:** standardized residual repeatedly above 1.

If you want a number, back out an implied overbid probability only at the **deal level** (from the time-averaged above-offer richness), never daily.

**Step 4 — Only for deals that pass, fit the full three-state model.**
Reserve the heavy MCMC (Section 5) for deals the screen flags. This puts a *magnitude* on the overbid probability. Gating matters: a third latent probability is weakly identified from thin data — BMR couldn't even identify a single correlation parameter and it slowed estimation ~100× — so you don't throw every deal at an expensive, poorly-identified model.

**Why this ordering is trustworthy:** the fragile step (reading the upper wing) is used only for a robust residual *comparison against the spread*, not to identify a latent process from scratch. Every judgment is made relative to the spread, so illiquidity is built into the significance bar.

---

## 5. The three-state extension (for Step 4)

Add a third terminal outcome — **overbid** — paying B₃ > B₁, where B₃ may itself be random. Three probabilities now sum to 1:

```
q_s(t) + q_o(t) + q_f(t) = 1
```

with q_s = success at the original offer, q_o = overbid (success at a higher price), q_f = failure. The stock price becomes a three-way blend:

```
B(t) = q_s(t)·B₁·e^(−r(T_e−t)) + q_o(t)·E_t[B₃·e^(−r(T_e−t))] + q_f(t)·B₂(t)
```

and the call gets a third term — the overbid state contributes a claim on (B₃ − K)⁺:

```
C(K,t) = q_s(t)·(B₁−K)⁺·e^(−r(T_e−t))
       + q_o(t)·E_t[(B₃−K)⁺]·e^(−r(T_e−t))
       + q_f(t)·C_BS(B₂(t), K, T−t)
```

Modeling choices for B₃, from simplest to richest:

- **Fixed premium:** B₃ = (1 + δ)·B₁ for a constant δ (e.g. a typical topping-bid premium). Cheapest; adds one parameter. The overbid term becomes a second digital-style kink at K = B₃.
- **Random B₃:** B₃ log-normal with its own mean/vol. Smooths the second kink into a bump; adds two parameters but better matches a smeared upper wing.

Identification notes:

- You now have **three latent processes** (q_s or q_o, plus B₂, plus possibly B₃). Expect to need the **full cross-section** of above-offer strikes, not one option per day — the single-option trick won't pin a third state.
- Keep the probabilities on the simplex with a softmax-style transform (generalize BMR's logistic q to two free latent processes X₁, X₂ mapped to (q_s, q_o, q_f)).
- Let the MCMC **smoother** do the work: a few informative above-offer quotes scattered across the deal can identify the overbid process even if no single day is informative — because smoothing conditions on the whole series at once.

---

## 6. Estimation details (state-space / MCMC)

The model is a **discrete-time state-space model**, fit per deal:

- **State equations** (latent dynamics, constant coefficients):

```
dq / [q(1−q)] = μ₁ dt + σ₁ dW₁
dB₂ / B₂      = μ₂ dt + σ₂ dW₂
```

- **Observation equations** (prices as functions of latents, with IID normal pricing errors ε_B, ε_C): the stock and call formulas from Section 1, each plus an error term.

What gets estimated: parameters (μ₁, σ₁, μ₂, σ₂), the error variances, *and* the full latent paths q(t), B₂(t). Known inputs: T_e, r, B₁, and each option's K and T.

**Why MCMC:** the observation equation is nonlinear in the latents (Black–Scholes in B₂), so no plain Kalman filter. Use Bayesian MCMC with flat priors (Metropolis–Hastings within Gibbs). Note it does **smoothing** (conditions on the whole series), not filtering — which is what lets scattered informative quotes identify the state.

BMR's own settings, as a starting point:

- ~400,000 iterations, ~200,000 burn-in; ~1 day of compute per firm.
- Keep Metropolis–Hastings acceptance ratios roughly in [0.04, 0.96]; tune the random-walk step otherwise.
- A convenient reparametrization (their Appendix D): q = logistic(X₁), B₂ = exp(X₂), with dX_i = μ_i dt + σ_i dW_i — differs from the SDE form only by a drift term.

**Option selection (baseline, two-state fit in Step 1):**

1. Each day, among calls expiring after T_e, pick the single call with **max trading volume**.
2. If all volumes are zero that day, use the strike **closest to the most recently traded max-volume strike**.
3. If neither applies, use the **at-the-money** option.

For the three-state fit (Step 4) and for the residual test (Step 2), do **not** restrict to one option — use all quoted above-offer strikes; widen the maturity pool beyond the shortest expiry (BMR note longer maturities don't change core results).

**Missing-data discipline:** require enough quotes before using a day (BMR use ≥2 options per moneyness bucket, ≥6 for "all calls"); drop zero-bid and zero-spread entries. A sparse clean panel beats a dense stale one. Multiple options per day just make the observed price vector multi-dimensional — the error structure handles it.

---

## 7. Pitfalls and caveats

- **Risk-neutral ≠ physical.** Everything options-implied here is a *risk-neutral* overbid probability — what the market is pricing, not the real-world frequency of overbids. BMR flag that the two coincide only if merger risk is idiosyncratic. If you ultimately want a predictive (physical) probability, you must take that wedge seriously, or pair the options signal with a deal-fundamentals model.
- **The strikes may not exist.** For high-premium deals the stock may already be near B₁ at announcement, so strikes above B₁ were often never listed. No listed above-offer strikes → Steps 2–4 have no data, and that deal simply can't be assessed this way. Check strike availability per deal before committing.
- **B₂ vs. overbid confound.** Because B₂ already contains "other potential offers," a rising fallback and a rising overbid probability can look similar in the data. Fitting B₂ only on at/below-B₁ strikes (Step 1) helps separate them, but watch for cases where B₂ drifts up toward B₁ — identification degrades there.
- **Linear-kink bias.** Estimating the kink as a simple slope difference over-states it when the price curve is concave on both sides of B₁ (BMR note this). A spline estimate reduces the bias but needs ≥2 extra strikes either side — often unavailable.
- **Offer-price changes.** A sweetening *is* a (realized) overbid. Decide whether you're predicting it ex-ante (then stop the sample before the change) or treating it as a B₁ jump (BMR's approach). Don't accidentally let a realized sweetening leak into your "predicted" signal.
- **Define "overbid" first.** Third-party competing bid vs. incumbent sweetening vs. stock simply trading above offer are different events needing different handling. Keep the definition fixed across the sample.
- **Weak identification of the third state.** Expect flat posteriors for q_o on thin deals. Treat Step 4 estimates with wide credibility bands; report the band, not just the median.

---

## 8. Data and build checklist

**Data you need (mirrors BMR's sources):**

- Deal data — offer price B₁, announcement & effective dates, status, any offer-price/effective-date changes (SDC Platinum or equivalent).
- Option data — daily closing bid/ask by strike and maturity, volume (OptionMetrics). You specifically need the **full chain including strikes above B₁**.
- Daily closing stock prices; risk-free curve for r (interpolated to each horizon).

**Build order:**

- [ ] Assemble the deal panel; fix your definition of "overbid."
- [ ] For each deal, flag whether above-offer strikes were ever listed (drop or set aside those without).
- [ ] Implement the two-state BMR MCMC; validate by reproducing their result that one option/day recovers the cross-section and the kink ≈ discounted q.
- [ ] Step 1: refit using only at/below-B₁ strikes → clean q(t), B₂(t).
- [ ] Step 2: compute spread-normalized residuals on K > B₁ strikes.
- [ ] Step 3: screen deals on sign + persistence + size-vs-spread; produce deal-level overbid indicators.
- [ ] Step 4: for flagged deals, run the three-state model; report q_o with credibility bands.
- [ ] Validate: do flagged deals actually see more competing/sweetened bids than unflagged? (physical check on the risk-neutral signal.)

**Sanity checks to keep running:**

- Residuals should be ~zero on at/below-B₁ strikes (that's where you fit) — if not, the two-state fit is off.
- The overbid signal should strengthen, not vanish, as you add above-offer strikes.
- Compare flagged vs. unflagged deals on realized outcomes before trusting any probability number.

**Primary reference:** Bester, C. A., V. H. Martinez, and I. Roșu (2023), "Option Prices and the Probability of Success of Cash Mergers," *Journal of Financial Econometrics* 21(1), 145–186.

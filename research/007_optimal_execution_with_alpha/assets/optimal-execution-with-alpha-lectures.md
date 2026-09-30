# Optimal Execution with Alpha: Lectures

Source notes for the report. The book is Paleologo, *Advanced Portfolio Management* (2021).

## The book's model, mapped across

The book's model is the same one we've been working with, so everything maps across directly. It is Paleologo's formulation restricted to a round trip (X = 0), without an event-variance term.

**Dictionary.** My η corresponds to the book's κ²/2, my λσ² to its ρσ²/2, my rate κ to its b, and my α to its α. With these substitutions my ODE $\ddot x-\kappa^2x=-\alpha/2\eta$ becomes the book's $\kappa^2\ddot x=-\alpha+\rho\sigma^2x$ exactly.

**Boundary conditions.** The book imposes $x(0)=x(T)=0$: start flat, build a position to capture the alpha, and unwind it. My $x(0)=X$ added the $\sinh$ liquidation curve on top. With X = 0 that base term disappears, and the book's solution is only the Green's-function term.

**F and G are the Green's function in disguise.** The book solves by variation of parameters. $F(t)$ and $G(t)$ are the two running integrals of $\alpha e^{\pm b\zeta}$, and the constant $c$ enforces $x(T)=0$. Put together, that is exactly $\int_0^T G(t,s)\,\alpha(s)/\kappa^2\,ds$. You can check this on its long-horizon result. As $T\to\infty$, $\sinh b(T-t_>)/\sinh bT\to e^{-bt_>}$, so

$$x(t)=\frac{\alpha_0}{\kappa^2}\,\frac{\sinh(bt_<)\,e^{-bt_>}}{b},$$

which is the book's two-case formula. Setting $t=t_0$ gives its $x(t_0)=\frac{\alpha_0}{2b\kappa^2}(1-e^{-2bt_0})$. Its "trading rate reverses at the event" statement is the kink we derived: $\kappa^2[\dot x]=-\alpha_0$.

**Volume time.** The book simply declares time to be volume time and keeps κ and σ constant. That silently assumes the $\sigma^2\eta=\text{const}$ condition, meaning variance and impact both scale with volume. The footnote defines the clock but never justifies why σ should be constant in it.

**What the book leaves out, and it admits this.** It notes that conviction is stronger on the earnings date, but its risk term uses the same σ everywhere. So the position it carries through the print ignores the print's own variance, which is the largest risk in the trade. Adding $\tfrac\rho2\sigma_J^2x(t_0)^2$ gives, in the book's units,

$$x(t_0)=\frac{(\alpha_0/\kappa^2)\,G_{00}}{1+(\rho\sigma_J^2/\kappa^2)\,G_{00}}\;\xrightarrow{\ \sigma_J\to\infty\ }\;\frac{\alpha_0}{\rho\sigma_J^2},$$

which caps the book's position at the Merton size for the jump.

**Two things in the scan to double-check:**

- **ρ versus ρ².** The problem statement uses $\rho\sigma^2/2$, but the Lagrangian and $b=\rho\sigma/\kappa$ use $\rho^2\sigma^2$. Pick one convention. With $\rho\sigma^2$, the rate is $b=\sigma\sqrt\rho/\kappa$.
- **Eq. (11.9) looks wrong.** Its two branches don't match at $t_0$: the left gives $\alpha_0t_0/\kappa^2$ and the right gives $\alpha_0t_0(1-t_0)/\kappa^2$. It also mixes $T\to\infty$ with $T=1$. Taking the $\rho\to0$ limit of the finite-T Green's function, $G\to t_<(T-t_>)/T$, gives a continuous tent:

  $$x(t)=\frac{\alpha_0}{\kappa^2}\cdot\frac{t_<(T-t_>)}{T}.$$

  With $T=1$, the left branch is $\alpha_0(1-t_0)\,t/\kappa^2$, not $\alpha_0 t/\kappa^2$. If $T\to\infty$ instead, the position after $t_0$ is flat: a risk-neutral trader never unwinds.

## Notation for the lectures

$X$ is the starting position, $\eta$ the impact coefficient, $\lambda\sigma^2$ the risk term, $\kappa^2=\lambda\sigma^2/\eta$, and the event alpha is $a$ at time $t_e$. The book appears only at the end, translated into these symbols.

## Lecture 1: The problem in words

You hold $x(t)$ shares and must go from $x(0)=X$ to $x(T)=0$. At every instant three things are happening:

- Trading costs you $\eta\,\dot x^2$. The cost is quadratic in speed, so trading twice as fast costs four times as much. That is what makes you spread trades out.
- Holding costs you risk $\lambda\sigma^2x^2$. The more you hold, the more exposure you carry.
- Holding earns you alpha $\alpha(t)\,x$, if you have a view.

You choose the whole path to minimize

$$J[x]=\int_0^T\big[\eta\,\dot x^2+\lambda\sigma^2x^2-\alpha(t)\,x\big]\,dt.$$

You are choosing a whole function rather than a few numbers, and the tool for that is the calculus of variations.

## Lecture 2: The optimality equation

Suppose $x(t)$ is the best path. Nudge it to $x+\varepsilon h$, where $h$ is any bump with $h(0)=h(T)=0$, so the endpoints stay fixed. If $x$ is optimal, no nudge can lower $J$ to first order. The first-order change is

$$\varepsilon\int_0^T\big[2\eta\,\dot x\,\dot h+2\lambda\sigma^2x\,h-\alpha\,h\big]dt.$$

The first term involves $\dot h$, the bump's speed. Integration by parts moves the derivative onto $x$, and because $h$ vanishes at both ends, $\int\dot x\,\dot h=-\int\ddot x\,h$:

$$\varepsilon\int_0^T\big[-2\eta\,\ddot x+2\lambda\sigma^2x-\alpha\big]\,h\,dt=0\quad\text{for every }h.$$

An integral that is zero against every possible bump forces the bracket itself to be zero. Dividing by $2\eta$ gives

$$\boxed{\ddot x-\kappa^2x=-\frac{\alpha(t)}{2\eta}}$$

This is a balance of forces. Risk ($\kappa^2x$) pushes you to sell, alpha ($\alpha/2\eta$) pushes you to hold, and $\ddot x$, how quickly your trading speed changes, absorbs the difference.

### Lecture 2 in discrete time

The same equation falls out of ordinary calculus in discrete time.

**Step 1.** To minimize a function of one variable, set its derivative to zero. With many variables, set each partial derivative to zero.

**Step 2.** Split $[0,T]$ into buckets of length $\tau$. You choose holdings $x_1,\dots,x_{N-1}$; the endpoints $x_0=X$ and $x_N=0$ are fixed. The total cost is

$$J=\sum_k\Big[\frac{\eta}{\tau}(x_{k-1}-x_k)^2+\lambda\sigma^2\tau\,x_k^2-\alpha_k\tau\,x_k\Big].$$

The primer's $\bar\eta$ is a small discrete correction to $\eta$ and is ignored here.

**Step 3.** $x_k$ shows up in exactly four places: the trade into bucket $k$, $\frac{\eta}{\tau}(x_{k-1}-x_k)^2$; the trade out of bucket $k$, $\frac{\eta}{\tau}(x_k-x_{k+1})^2$; its own risk, $\lambda\sigma^2\tau\,x_k^2$; and its own alpha, $-\alpha_k\tau\,x_k$. Differentiate each piece and set the total to zero:

$$\frac{2\eta}{\tau}\big(2x_k-x_{k-1}-x_{k+1}\big)+2\lambda\sigma^2\tau\,x_k-\alpha_k\tau=0.$$

**Step 4.** Divide by $2\eta\tau$ and use $\kappa^2=\lambda\sigma^2/\eta$:

$$\frac{x_{k+1}-2x_k+x_{k-1}}{\tau^2}=\kappa^2x_k-\frac{\alpha_k}{2\eta}.$$

$(x_k-x_{k-1})/\tau$ is the trading speed into bucket $k$, $(x_{k+1}-x_k)/\tau$ the speed out, and their difference over $\tau$ is a discrete acceleration. As $\tau\to0$ this becomes $\ddot x-\kappa^2x=-\alpha/2\eta$. Each equation links only $x_{k-1}$, $x_k$ and $x_{k+1}$, which is why the discrete problem is a tridiagonal system.

**Step 5.** Think of each $x_k$ as a knob. Turning one up changes the trade into that bucket, the trade out of it, the risk carried and the alpha earned. At the optimum these effects cancel, so no single knob can be turned to improve the total. The quadratic cost smooths neighboring trades, the risk term pushes $x_k$ toward zero, and the alpha term pulls it up. Integration by parts in the continuous version plays the role of noticing that $x_k$ appears in two neighboring trades.

## Lecture 3: No alpha gives the liquidation curve

With $\alpha=0$ the equation is $\ddot x=\kappa^2x$, so we need a function whose second derivative is proportional to itself. Trying $e^{rt}$ gives $r^2=\kappa^2$, so every solution has the form $Ae^{\kappa t}+Be^{-\kappa t}$.

The combination with $x(T)=0$ is $\sinh\kappa(T-t)$, and scaling it so that $x(0)=X$ gives

$$x_{\text{base}}(t)=X\,\frac{\sinh\kappa(T-t)}{\sinh\kappa T}.$$

$1/\kappa=\sqrt{\eta/\lambda\sigma^2}$ is the natural time scale: high risk aversion or cheap trading means you liquidate fast, and the opposite means slowly. In the discrete version, $\kappa$ becomes $\theta$ and $\eta$ becomes $\bar\eta$.

## Lecture 4: What a delta does to the equation

Let the alpha be $\alpha(t)=a\,\delta(t-t_e)$. All of it arrives in one instant, and you earn $a\,x(t_e)$ for whatever you hold at the print.

Integrate the equation over a tiny window around $t_e$ and shrink the window to zero:

- The integral of $\ddot x$ is the change in speed across the window, $\dot x(t_e^+)-\dot x(t_e^-)$.
- The integral of $\kappa^2x$ vanishes, because a finite quantity integrated over zero width is zero.
- The integral of the delta is exactly $a$.

So

$$\dot x(t_e^+)-\dot x(t_e^-)=-\frac{a}{2\eta}.$$

The position is continuous. A jump would mean infinite speed and infinite cost. Only the trading rate jumps: after the event you sell faster by $a/2\eta$, so the path has a corner at $t_e$.

## Lecture 5: Building the response by gluing (the Green's function)

Define $G(t,s)$ as the path's response to a unit impulse at time $s$, with both endpoints held at zero. Away from $s$ there is no forcing, so on each side use the solution that already satisfies that side's boundary condition:

$$G=A\sinh\kappa t\quad(t<s),\qquad G=B\sinh\kappa(T-t)\quad(t>s).$$

Two glue conditions at $s$ determine $A$ and $B$:

- Continuity: $A\sinh\kappa s=B\sinh\kappa(T-s)$.
- Kink of size $-1$: $-B\kappa\cosh\kappa(T-s)-A\kappa\cosh\kappa s=-1$.

Substitute $A$ from the first condition into the second, then use $\sinh u\cosh w+\cosh u\sinh w=\sinh(u+w)$. The bracket collapses to $\sinh\kappa T$, and

$$A=\frac{\sinh\kappa(T-s)}{\kappa\sinh\kappa T},\qquad B=\frac{\sinh\kappa s}{\kappa\sinh\kappa T},$$

$$\boxed{G(t,s)=\frac{\sinh(\kappa\,t_<)\,\sinh\big(\kappa(T-t_>)\big)}{\kappa\sinh\kappa T}}$$

where $t_<$ is the smaller of $t$ and $s$, and $t_>$ the larger.

**Superposition.** The equation is linear, so solutions add. The base curve handles the boundary conditions; the Green's term handles the event and is zero at both ends:

$$x(t)=X\,\frac{\sinh\kappa(T-t)}{\sinh\kappa T}+\frac{a}{2\eta}\,G(t,t_e).$$

**How to read it.** For $a>0$ you hold extra inventory into the print, then sell it off faster afterward. For $a<0$ you sell ahead and arrive lighter. The bump reaches only about $1/\kappa$ in time: an event far away barely affects trading today. An event near either end has little effect, because $G$ vanishes there and there is no time to exploit it.

## Lecture 6: Adding event risk

Earnings also carries jump variance $\sigma_J^2$, so add $\lambda\sigma_J^2\,x(t_e)^2$ to the cost. Repeating Lecture 4, the jump condition picks up a second term:

$$\dot x(t_e^+)-\dot x(t_e^-)=\rho\,x_e-\frac{a}{2\eta},\qquad \rho=\frac{\lambda\sigma_J^2}{\eta},\quad x_e=x(t_e).$$

It is the same kind of impulse, but its size depends on $x_e$. Superposition still works:

$$x(t)=x_{\text{base}}(t)+G(t,t_e)\Big(\frac{a}{2\eta}-\rho\,x_e\Big).$$

Set $t=t_e$ and solve for $x_e$:

$$x_e=\frac{x_{\text{base}}(t_e)+G_{ee}\,\frac{a}{2\eta}}{1+\rho\,G_{ee}}=w\,x_{\text{base}}(t_e)+(1-w)\,x^*,$$

$$w=\frac{1}{1+\rho G_{ee}},\qquad x^*=\frac{a}{2\lambda\sigma_J^2}.$$

$x^*$ is the position you would choose if the event were your only concern: minimizing $\lambda\sigma_J^2x^2-ax$ gives $x=a/(2\lambda\sigma_J^2)$. Your actual position at the print is a blend of where the liquidation would put you and what the event alone would want. The larger the jump risk, the more the event wins.

## Lecture 7: The book, translated

The book's model is this one with $X=0$ (start flat, capture the alpha, unwind) and no event-variance term. Its symbols map into ours as $\tfrac{\kappa^2}{2}\to\eta$, $\tfrac{\rho\sigma^2}{2}\to\lambda\sigma^2$, $b\to\kappa$, and $\alpha_0\to a$. Its $F$, $G$, $c$ machinery is variation of parameters, a longer route to the same Green's function.

Taking $T\to\infty$, $\sinh\kappa(T-t_>)/\sinh\kappa T\to e^{-\kappa t_>}$, so

$$x(t)=\frac{a}{2\eta\kappa}\,\sinh(\kappa t_<)\,e^{-\kappa t_>},\qquad x(t_e)=\frac{a}{4\eta\kappa}\big(1-e^{-2\kappa t_e}\big).$$

These are the book's long-horizon results. Before the event you buy faster and faster (the rate grows like $\cosh\kappa t$). After it you unwind along $e^{-\kappa t}$: quickly at first, then slowly.

Differentiating this solution exposes a slip in the text. Just before the event the rate is $\frac{a}{4\eta}(1+e^{-2\kappa t_e})$, and just after it is $-\frac{a}{4\eta}(1-e^{-2\kappa t_e})$. These differ by exactly the kink $a/2\eta$. The book says they are equal in size, which would contradict its own jump condition. They become nearly equal only when the event is far away ($\kappa t_e\gg1$).

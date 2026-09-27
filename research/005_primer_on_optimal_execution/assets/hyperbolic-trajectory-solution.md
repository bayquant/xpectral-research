# Solving the Optimal-Execution Trajectory (Almgren–Chriss)

**Two-point boundary value problem for a linear second-order difference equation**

## Notation (fixed up front)

- **$\theta$** — the decay rate (the unknown we solve for). Distinct from $\kappa/\tilde\kappa$; "θ for a rate inside a hyperbolic function" is a common convention.
- **$X_0$ and $X_T$** — the two boundary values (holdings at the start $t=0$ and end $t=T$). Subscripting by the *time* each value is attached to makes it self-documenting.
- **$\tilde\kappa^2 = \lambda\sigma^2/\tilde\eta$** — known input (with the $\tilde\eta$ correction).
- **$\kappa = \sqrt{\lambda\sigma^2/\eta}$** — its continuum shortcut.

---

## The problem

Solve the difference equation (the paper's optimality condition (16))

$$\frac{1}{\tau^2}\big(x_{j-1} - 2x_j + x_{j+1}\big) = \tilde\kappa^2\, x_j, \qquad t_j = j\tau,$$

subject to the two boundary values

$$x_0 = X_0 \ (\text{at } t=0), \qquad x_N = X_T \ (\text{at } t=T).$$

*Machinery: this is a linear, constant-coefficient, second-order **difference equation** with a **two-point boundary value problem**. Order 2 ⟹ a 2-dimensional solution space ⟹ general solution is a combination of two independent pieces, with two free constants pinned by the two boundary values.*

---

## Step 1 — Characteristic step: find the allowed rate $\theta$

*Machinery: for a linear constant-coefficient equation, try an exponential $x_j = e^{\pm\theta t_j}$ and see which $\theta$ the equation permits.*

Plug $x_j = e^{\theta j\tau}$ in. The shifted terms are $x_{j\pm1} = e^{\theta j\tau}e^{\pm\theta\tau}$, so the left side becomes

$$\frac{1}{\tau^2}\,e^{\theta j\tau}\big(e^{-\theta\tau} - 2 + e^{\theta\tau}\big).$$

*Machinery: fold the symmetric sum into cosh, using the definition $\cosh u = \tfrac12(e^u + e^{-u})$ read backwards, i.e. $e^{\theta\tau}+e^{-\theta\tau} = 2\cosh(\theta\tau)$.*

$$\frac{1}{\tau^2}\big(e^{\theta\tau} - 2 + e^{-\theta\tau}\big) = \frac{2}{\tau^2}\big(\cosh(\theta\tau) - 1\big).$$

The $x_j = e^{\theta j\tau}$ cancels off both sides, leaving the **dispersion relation** — the condition $\theta$ must satisfy:

$$\frac{2}{\tau^2}\big(\cosh(\theta\tau) - 1\big) = \tilde\kappa^2 \quad\Longrightarrow\quad \theta = \frac{1}{\tau}\operatorname{arccosh}\!\Big(1 + \tfrac12\tilde\kappa^2\tau^2\Big).$$

Here $\tilde\kappa^2$ (right side) is the **known input**; $\theta$ (inside the cosh) is the **unknown output**. Because $\cosh$ is even, both $e^{+\theta t_j}$ and $e^{-\theta t_j}$ satisfy this — those are our two independent building blocks. *(Small-$\tau$ shortcut: $\theta \to \sqrt{\tilde\kappa^2} \to \kappa = \sqrt{\lambda\sigma^2/\eta}$.)*

---

## Step 2 — General solution, in a smart basis

*Machinery: the general solution is any combination of the two building blocks. Instead of raw $e^{\pm\theta t_j}$, choose a basis where **each block vanishes at one endpoint**, so the boundary conditions will decouple. Both shifted sinh's below are just constant combinations of $e^{\pm\theta t_j}$ (via $\sinh u = \tfrac12(e^u - e^{-u})$), so they're legitimate solutions.*

$$x_j = P\,\sinh\!\big(\theta(T - t_j)\big) + Q\,\sinh(\theta t_j).$$

The design: $\sinh(\theta t_j)$ is zero at $t=0$; $\sinh(\theta(T-t_j))$ is zero at $t=T$. So $P$ will answer only to the left end, $Q$ only to the right.

---

## Step 3 — Apply the boundary conditions

*Machinery: impose the two given values; using $\sinh 0 = 0$, one term drops at each end, so each constant reads off directly (no $2\times2$ system).*

**Left, $t=0$:** the $Q$ term vanishes ($\sinh 0 = 0$):

$$X_0 = P\,\sinh(\theta T) \;\Longrightarrow\; P = \frac{X_0}{\sinh(\theta T)}.$$

**Right, $t=T$:** the $P$ term vanishes ($\sinh(\theta(T-T)) = \sinh 0 = 0$):

$$X_T = Q\,\sinh(\theta T) \;\Longrightarrow\; Q = \frac{X_T}{\sinh(\theta T)}.$$

---

## Step 4 — Assemble

$$\boxed{\;x_j = \frac{X_0\,\sinh\!\big(\theta(T - t_j)\big) + X_T\,\sinh(\theta t_j)}{\sinh(\theta T)}\;}$$

A **hyperbolic interpolation** between the two endpoint holdings: $X_0$ weights the block that's large near the start, $X_T$ the block that's large near the end, and $\sinh(\theta T)$ normalizes both.

---

## Checks

*Machinery: verify the boundary values and known limits.*

- $t=0$: numerator $= X_0\sinh(\theta T) + X_T\cdot 0$, so $x_0 = X_0$. ✓
- $t=T$: numerator $= X_0\cdot 0 + X_T\sinh(\theta T)$, so $x_N = X_T$. ✓
- $X_T = 0$: recovers the paper's (17), $x_j = \dfrac{\sinh(\theta(T-t_j))}{\sinh(\theta T)}X_0$. ✓
- $\theta \to 0$: since $\sinh(\theta s)\approx\theta s$, it collapses to straight-line interpolation $x_j \approx \dfrac{X_0(T-t_j) + X_T\,t_j}{T}$. ✓ *(The rate $\theta$ measures how much the path bows away from that line.)*
- **Monotonic** from $X_0$ to $X_T$ whenever both are the same sign and $\theta > 0$, because $\sinh/\cosh$ are monotonic on $[0,\infty)$ — so holdings move steadily one direction, never reversing.

---

## The reusable skeleton

1. Recognize linear constant-coefficient difference equation ⟹ try $x_j = e^{\theta t_j}$.
2. Characteristic step ⟹ dispersion relation ⟹ solve for the rate $\theta$.
3. General solution = combination of the two blocks; **pick a basis that's zero at the boundaries you're fitting.**
4. Apply the two boundary conditions ⟹ read off the two constants.
5. Assemble, then sanity-check endpoints and the $\theta\to0$ / limiting cases.

Same five moves work for any second-order linear difference (or differential) equation with values fixed at two ends — only the characteristic equation and the specific numbers change.

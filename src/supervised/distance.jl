doc"""
    LPDistLoss{P} <: DistanceLoss

The P-th power absolute distance loss. It is Lipschitz continuous
iff `P == 1`, convex if and only if `P >= 1`, and strictly convex
iff `P > 1`.

``L(y, ŷ) = |ŷ - y|^P``
"""
immutable LPDistLoss{P} <: DistanceLoss
    LPDistLoss() = typeof(P) <: Number ? new() : error()
end

LPDistLoss(p::Number) = LPDistLoss{p}()

value{P}(loss::LPDistLoss{P}, difference::Number) = abs(difference)^P
function deriv{P,T<:Number}(loss::LPDistLoss{P}, difference::T)
    if difference == 0
        zero(difference)
    else
        P * difference * abs(difference)^(P-convert(typeof(P), 2))
    end
end
function deriv2{P,T<:Number}(loss::LPDistLoss{P}, difference::T)
    if difference == 0
        zero(difference)
    else
        (abs2(P)-P) * abs(difference)^P / abs2(difference)
    end
end
value_deriv{P}(loss::LPDistLoss{P}, difference::Number) = (value(loss,difference), deriv(loss,difference))

isminimizable{P}(::LPDistLoss{P}) = true
issymmetric{P}(::LPDistLoss{P}) = true
isdifferentiable{P}(::LPDistLoss{P}) = P > 1
isdifferentiable{P}(::LPDistLoss{P}, at) = P > 1 || at != 0
istwicedifferentiable{P}(::LPDistLoss{P}) = P > 1
istwicedifferentiable{P}(::LPDistLoss{P}, at) = P > 1 || at != 0
islipschitzcont{P}(::LPDistLoss{P}) = P == 1
islocallylipschitzcont{P}(::LPDistLoss{P}) = P >= 1
isconvex{P}(::LPDistLoss{P}) = P >= 1
isstrictlyconvex{P}(::LPDistLoss{P}) = P > 1
isstronglyconvex{P}(::LPDistLoss{P}) = P >= 2

# ===========================================================

doc"""
    L1DistLoss <: DistanceLoss

The absolute distance loss. Special case of the `LPDistLoss` with `P=1`.
It is Lipshitz continuous and convex, but not strictly convex.

``L(y, ŷ) = |ŷ - y|``

```
          Lossfunction                     Derivative
  ┌────────────┬────────────┐      ┌────────────┬────────────┐
3 │\.                     ./│    1 │            ┌------------│
  │ '\.                 ./' │      │            |            │
  │   \.               ./   │      │            |            │
  │    '\.           ./'    │      │_           |           _│
L │      \.         ./      │   L' │            |            │
  │       '\.     ./'       │      │            |            │
  │         \.   ./         │      │            |            │
0 │          '\./'          │   -1 │------------┘            │
  └────────────┴────────────┘      └────────────┴────────────┘
  -3                        3      -3                        3
             ŷ - y                            ŷ - y
```
"""
typealias L1DistLoss LPDistLoss{1}

sumvalue(loss::L1DistLoss, difference::AbstractArray) = sumabs(difference)
value(loss::L1DistLoss, difference::Number) = abs(difference)
deriv{T<:Number}(loss::L1DistLoss, difference::T) = convert(T, sign(difference))
deriv2{T<:Number}(loss::L1DistLoss, difference::T) = zero(T)
value_deriv(loss::L1DistLoss, difference::Number) = (abs(difference), sign(difference))

isdifferentiable(::L1DistLoss) = false
isdifferentiable(::L1DistLoss, at) = at != 0
istwicedifferentiable(::L1DistLoss) = false
istwicedifferentiable(::L1DistLoss, at) = at != 0
islipschitzcont(::L1DistLoss) = true
isconvex(::L1DistLoss) = true
isstrictlyconvex(::L1DistLoss) = false
isstronglyconvex(::L1DistLoss) = false

# ===========================================================

doc"""
    L2DistLoss <: DistanceLoss

The least squares loss. Special case of the `LPDistLoss` with `P=2`.
It is strictly convex.

``L(y, ŷ) = |ŷ - y|²``

```
          Lossfunction                     Derivative
  ┌────────────┬────────────┐      ┌────────────┬────────────┐
9 │\                       /│    3 │                   .r/   │
  │".                     ."│      │                 .r'     │
  │ ".                   ." │      │              _./'       │
  │  ".                 ."  │      │_           .r/         _│
L │   ".               ."   │   L' │         _:/'            │
  │    '\.           ./'    │      │       .r'               │
  │      \.         ./      │      │     .r'                 │
0 │        "-.___.-"        │   -3 │  _/r'                   │
  └────────────┴────────────┘      └────────────┴────────────┘
  -3                        3      -2                        2
             ŷ - y                            ŷ - y
```
"""
typealias L2DistLoss LPDistLoss{2}

sumvalue(loss::L2DistLoss, difference::AbstractArray) = sumabs2(difference)
value(loss::L2DistLoss, difference::Number) = abs2(difference)
deriv{T<:Number}(loss::L2DistLoss, difference::T) = T(2) * difference
deriv2{T<:Number}(loss::L2DistLoss, difference::T) = T(2)
value_deriv{T<:Number}(loss::L2DistLoss, difference::T) = (abs2(difference), T(2) * difference)

isdifferentiable(::L2DistLoss) = true
isdifferentiable(::L2DistLoss, at) = true
istwicedifferentiable(::L2DistLoss) = true
istwicedifferentiable(::L2DistLoss, at) = true
islipschitzcont(::L2DistLoss) = false
isconvex(::L2DistLoss) = true
isstrictlyconvex(::L2DistLoss) = true
isstronglyconvex(::L2DistLoss) = true


# ===========================================================

doc"""
    PeriodicLoss <: DistanceLoss

Measures distance on a circle of specified circumference `c`.

``L(y, ŷ) = 1 - cos((ŷ - y) * 2π / c)``
"""
immutable PeriodicLoss{T<:AbstractFloat} <: DistanceLoss
    k::T   # k = 2π/circumference
    function PeriodicLoss(circ::T)
        circ > 0 || error("circumference should be strictly positive")
        new(convert(T, 2π/circ))
    end
end
PeriodicLoss{T<:AbstractFloat}(circ::T=1.0) = PeriodicLoss{T}(circ)
PeriodicLoss(circ) = PeriodicLoss{Float64}(Float64(circ))

value{T<:Number}(loss::PeriodicLoss, difference::T) = 1 - cos(difference*loss.k)
deriv{T<:Number}(loss::PeriodicLoss, difference::T) = loss.k * sin(difference*loss.k)
deriv2{T<:Number}(loss::PeriodicLoss, difference::T) = abs2(loss.k) * cos(difference*loss.k)
function value_deriv{T<:Number}(loss::PeriodicLoss, difference::T)
    dk = difference*loss.k
    return 1-cos(dk), loss.k*sin(dk)
end

isdifferentiable(::PeriodicLoss) = true
isdifferentiable(::PeriodicLoss, at) = true
istwicedifferentiable(::PeriodicLoss) = true
istwicedifferentiable(::PeriodicLoss, at) = true
islipschitzcont(::PeriodicLoss) = true
isconvex(::PeriodicLoss) = false
isstrictlyconvex(::PeriodicLoss) = false
isstronglyconvex(::PeriodicLoss) = false


# ===========================================================

doc"""
    HuberLoss <: DistanceLoss

Loss function commonly used for robustness to outliers.
For large values of `d` it becomes close to the `L1DistLoss`,
while for small values of `d` it resembles the `L2DistLoss`.
It is Lipshitz continuous and convex, but not strictly convex.

``L(y, ŷ) =  1/2 ⋅ (ŷ-y)²    , if |ŷ-y| < d``
``L(y, ŷ) =  d⋅(|ŷ-y| - d/2) , otherwise``

```
          Lossfunction (d=1)               Derivative
  ┌────────────┬────────────┐      ┌────────────┬────────────┐
2 │                         │    1 │                .+-------│
  │                         │      │              ./'        │
  │\.                     ./│      │             ./          │
  │ '.                   .' │      │_           ./          _│
L │   \.               ./   │   L' │           /'            │
  │     \.           ./     │      │          /'             │
  │      '.         .'      │      │        ./'              │
0 │        '-.___.-'        │   -1 │-------+'                │
  └────────────┴────────────┘      └────────────┴────────────┘
  -2                        2      -2                        2
             ŷ - y                            ŷ - y
```
"""
type HuberLoss{T<:AbstractFloat} <: DistanceLoss
    d::T   # boundary between quadratic and linear loss
    function HuberLoss(d::T)
        d > 0 || error("Huber crossover parameter must be strictly positive.")
        new(d)
    end
end
HuberLoss{T<:AbstractFloat}(d::T=1.0) = HuberLoss{T}(d)
HuberLoss(d) = HuberLoss{Float64}(Float64(d))

function value{T1,T2<:Number}(loss::HuberLoss{T1}, difference::T2)
    T = promote_type(T1,T2)
    abs_diff = abs(difference)
    if abs_diff <= loss.d
        return T(0.5)*abs2(difference)   # quadratic
    else
        return (loss.d*abs_diff) - T(0.5)*abs2(loss.d)   # linear
    end
end
function deriv{T1,T2<:Number}(loss::HuberLoss{T1}, difference::T2)
    T = promote_type(T1,T2)
    if abs(difference) <= loss.d
        return T(difference)   # quadratic
    else
        return loss.d*T(sign(difference))   # linear
    end
end
function deriv2{T1,T2<:Number}(loss::HuberLoss{T1}, difference::T2)
    T = promote_type(T1,T2)
    abs(difference) <= loss.d ? one(T) : zero(T)
end
function value_deriv{T1,T2<:Number}(loss::HuberLoss{T1}, difference::T2)
    T = promote_type(T1,T2)
    abs_diff = abs(difference)
    if abs_diff <= loss.d
        val = T(0.5)*abs2(difference)
        der = T(difference)
    else
        val = (loss.d*abs_diff) - T(0.5)*abs2(loss.d)
        der = loss.d*T(sign(difference))
    end
    return val,der
end

isdifferentiable(::HuberLoss) = true
isdifferentiable(l::HuberLoss, at) = true
istwicedifferentiable(::HuberLoss) = false
istwicedifferentiable(l::HuberLoss, at) = at != abs(l.d)
islipschitzcont(::HuberLoss) = true
isconvex(::HuberLoss) = true
isstrictlyconvex(::HuberLoss) = false
isstronglyconvex(::HuberLoss) = false
issymmetric(::HuberLoss) = true

# ===========================================================

doc"""
    L1EpsilonInsLoss <: DistanceLoss

The `ϵ`-insensitive loss. Typically used in linear support vector
regression. It ignores deviances smaller than `ϵ`, but penalizes
larger deviances linarily.
It is Lipshitz continuous and convex, but not strictly convex.

``L(y, ŷ) = max(0, |ŷ - y| - ɛ)``

```
          Lossfunction (ɛ=1)               Derivative
  ┌────────────┬────────────┐      ┌────────────┬────────────┐
2 │\                       /│    1 │                  ┌------│
  │ \                     / │      │                  |      │
  │  \                   /  │      │                  |      │
  │   \                 /   │      │_      ___________!     _│
L │    \               /    │   L' │      |                  │
  │     \             /     │      │      |                  │
  │      \           /      │      │      |                  │
0 │       \_________/       │   -1 │------┘                  │
  └────────────┴────────────┘      └────────────┴────────────┘
  -3                        3      -2                        2
             ŷ - y                            ŷ - y
```
"""
immutable L1EpsilonInsLoss{T<:AbstractFloat} <: DistanceLoss
    ε::T

    function L1EpsilonInsLoss(ɛ::Number)
        ɛ > 0 || error("ɛ must be strictly positive")
        new(convert(Float64, ɛ))
    end
end
typealias EpsilonInsLoss L1EpsilonInsLoss
L1EpsilonInsLoss{T<:AbstractFloat}(ε::T) = L1EpsilonInsLoss{T}(ε)
L1EpsilonInsLoss(ε) = L1EpsilonInsLoss{Float64}(Float64(ε))

function L1EpsilonInsLoss{T<:Number}(ε::T)
    if T <: AbstractFloat
        L1EpsilonInsLoss{T}(ε)
    else # cast to Float64
        L1EpsilonInsLoss{Float64}(Float64(ε))
    end
end

function value{T1,T2<:Number}(loss::L1EpsilonInsLoss{T1}, difference::T2)
    T = promote_type(T1,T2)
    max(zero(T), abs(difference) - loss.ε)
end
function deriv{T1,T2<:Number}(loss::L1EpsilonInsLoss{T1}, difference::T2)
    T = promote_type(T1,T2)
    abs(difference) <= loss.ε ? zero(T) : sign(difference)
end
deriv2{T1,T2<:Number}(loss::L1EpsilonInsLoss{T1}, difference::T2) = zero(promote_type(T1,T2))
function value_deriv{T1,T2<:Number}(loss::L1EpsilonInsLoss{T1}, difference::T2)
    T = promote_type(T1,T2)
    absr = abs(difference)
    absr <= loss.ε ? (zero(T), zero(T)) : (absr - loss.ε, sign(difference))
end

issymmetric(::L1EpsilonInsLoss) = true
isdifferentiable(::L1EpsilonInsLoss) = false
isdifferentiable(loss::L1EpsilonInsLoss, at) = abs(at) != loss.ε
istwicedifferentiable(::L1EpsilonInsLoss) = false
istwicedifferentiable(loss::L1EpsilonInsLoss, at) = abs(at) != loss.ε
islipschitzcont(::L1EpsilonInsLoss) = true
isconvex(::L1EpsilonInsLoss) = true
isstrictlyconvex(::L1EpsilonInsLoss) = false
isstronglyconvex(::L1EpsilonInsLoss) = false

# ===========================================================

doc"""
    L2EpsilonInsLoss <: DistanceLoss

The `ϵ`-insensitive loss. Typically used in linear support vector
regression. It ignores deviances smaller than `ϵ`, but penalizes
larger deviances quadratically. It is convex, but not strictly convex.

``L(y, ŷ) = max(0, |ŷ - y| - ɛ)²``

```
          Lossfunction (ɛ=0.5)             Derivative
  ┌────────────┬────────────┐      ┌────────────┬────────────┐
8 │                         │    1 │                  /      │
  │:                       :│      │                 /       │
  │'.                     .'│      │                /        │
  │ \.                   ./ │      │_         _____/        _│
L │  \.                 ./  │   L' │         /               │
  │   \.               ./   │      │        /                │
  │    '\.           ./'    │      │       /                 │
0 │      '-._______.-'      │   -1 │      /                  │
  └────────────┴────────────┘      └────────────┴────────────┘
  -3                        3      -2                        2
             ŷ - y                            ŷ - y
```
"""
immutable L2EpsilonInsLoss{T<:AbstractFloat} <: DistanceLoss
    ε::T

    function L2EpsilonInsLoss(ɛ::Number)
        ɛ > 0 || error("ɛ must be strictly positive")
        new(convert(T, ɛ))
    end
end
L2EpsilonInsLoss{T<:AbstractFloat}(ε::T) = L2EpsilonInsLoss{T}(ε)
L2EpsilonInsLoss(ε) = L2EpsilonInsLoss{Float64}(Float64(ε))

function value{T1,T2<:Number}(loss::L2EpsilonInsLoss{T1}, difference::T2)
    T = promote_type(T1,T2)
    abs2(max(zero(T), abs(difference) - loss.ε))
end
function deriv{T1,T2<:Number}(loss::L2EpsilonInsLoss{T1}, difference::T2)
    T = promote_type(T1,T2)
    absr = abs(difference)
    absr <= loss.ε ? zero(T) : T(2)*sign(difference)*(absr - loss.ε)
end
function deriv2{T1,T2<:Number}(loss::L2EpsilonInsLoss{T1}, difference::T2)
    T = promote_type(T1,T2)
    abs(difference) <= loss.ε ? zero(T) : T(2)
end
function value_deriv{T}(loss::L2EpsilonInsLoss{T}, difference::Number)
    absr = abs(difference)
    diff = absr - loss.ε
    absr <= loss.ε ? (zero(T), zero(T)) : (abs2(diff), T(2)*sign(difference)*diff)
end

issymmetric(::L2EpsilonInsLoss) = true
isdifferentiable(::L2EpsilonInsLoss) = true
isdifferentiable(::L2EpsilonInsLoss, at) = true
istwicedifferentiable(::L2EpsilonInsLoss) = false
istwicedifferentiable(loss::L2EpsilonInsLoss, at) = abs(at) != loss.ε
islipschitzcont(::L2EpsilonInsLoss) = false
isconvex(::L2EpsilonInsLoss) = true
isstrictlyconvex(::L2EpsilonInsLoss) = true
isstronglyconvex(::L2EpsilonInsLoss) = true

# ===========================================================

doc"""
    LogitDistLoss <: DistanceLoss

The distance-based logistic loss for regression.
It is strictly convex and Lipshitz continuous.

``L(y, ŷ) = -ln(4 ⋅ exp(ŷ - y) / (1 + exp(ŷ - y))²)``

```
          Lossfunction                     Derivative
  ┌────────────┬────────────┐      ┌────────────┬────────────┐
2 │                         │    1 │                   _--'''│
  │\                       /│      │                ./'      │
  │ \.                   ./ │      │              ./         │
  │  '.                 .'  │      │_           ./          _│
L │   '.               .'   │   L' │           ./            │
  │     \.           ./     │      │         ./              │
  │      '.         .'      │      │       ./                │
0 │        '-.___.-'        │   -1 │___.-''                  │
  └────────────┴────────────┘      └────────────┴────────────┘
  -3                        3      -4                        4
             ŷ - y                            ŷ - y
```
"""
immutable LogitDistLoss <: DistanceLoss end

function value(loss::LogitDistLoss, difference::Number)
    er = exp(difference)
    T = typeof(er)
    -log(T(4) * er / abs2(one(T) + er))
end
function deriv{T<:Number}(loss::LogitDistLoss, difference::T)
    tanh(difference / T(2))
end
function deriv2(loss::LogitDistLoss, difference::Number)
    er = exp(difference)
    T = typeof(er)
    T(2)*er / abs2(one(T) + er)
end
function value_deriv(loss::LogitDistLoss, difference::Number)
    er = exp(difference)
    T = typeof(er)
    er1 = one(T) + er
    -log(T(4) * er / abs2(er1)), (er - one(T)) / (er1)
end

issymmetric(::LogitDistLoss) = true
isdifferentiable(::LogitDistLoss) = true
isdifferentiable(::LogitDistLoss, at) = true
istwicedifferentiable(::LogitDistLoss) = true
istwicedifferentiable(::LogitDistLoss, at) = true
islipschitzcont(::LogitDistLoss) = true
isconvex(::LogitDistLoss) = true
isstrictlyconvex(::LogitDistLoss) = true
isstronglyconvex(::LogitDistLoss) = false



# ===========================================================
immutable QuantileLoss{T <: Number} <: DistanceLoss
    τ::T
end
value{T <: Number}(loss::QuantileLoss{T}, diff::T) = diff * (T(0 < diff) - loss.τ)
deriv{T <: Number}(loss::QuantileLoss{T}, diff::T) = (loss.τ - T(0 > diff))
deriv2{T <: Number}(::QuantileLoss{T}, diff::T) = zero(T)
function value_deriv{T <: Number}(loss::QuantileLoss{T}, diff::T)
    value(loss,diff), deriv(loss, diff)
end

issymmetric(loss::QuantileLoss) = loss.τ == 0.5
isdifferentiable(::QuantileLoss) = false
isdifferentiable(::QuantileLoss, at) = at != 0
istwicedifferentiable(::QuantileLoss) = false
istwicedifferentiable(::QuantileLoss, at) = at != 0
islipschitzcont(::QuantileLoss) = true
islipschitzcont_deriv(::QuantileLoss) = true
isconvex(::QuantileLoss) = true
isstrictlyconvex(::QuantileLoss) = true
isstronglyconvex(::QuantileLoss) = false

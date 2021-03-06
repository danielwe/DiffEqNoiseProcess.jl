const one_over_sqrt2 = 1/sqrt(2)
@inline wiener_randn(rng,::Type{T}) where T = randn(rng,T)
@inline wiener_randn(x,y) = randn(x,y)
@inline wiener_randn!(rng,rand_vec) = randn!(rng,rand_vec)
@inline wiener_randn(y::AbstractRNG,::Type{Complex{T}}) where T = one_over_sqrt2*(randn(y,T)+im*randn(y,T))

@inline function wiener_randn!{T<:Number}(y::AbstractRNG,x::AbstractArray{<:Complex{T}})
  @inbounds for i in eachindex(x)
    x[i] = one_over_sqrt2*(randn(y,T)+im*randn(y,T))
  end
end

@inline function WHITE_NOISE_DIST(W,dt,rng)
  if typeof(W.dW) <: AbstractArray && !(typeof(W.dW) <: SArray)
    return @fastmath sqrt(abs(dt))*wiener_randn(rng,size(W.dW))
  else
    return @fastmath sqrt(abs(dt))*wiener_randn(rng,typeof(W.dW))
  end
end

function WHITE_NOISE_BRIDGE(W,W0,Wh,q,h,rng)
  if typeof(W.dW) <: AbstractArray
    return @fastmath sqrt((1-q)*q*abs(h))*wiener_randn(rng,size(W.dW))+q*Wh
  else
    return @fastmath sqrt((1-q)*q*abs(h))*wiener_randn(rng,typeof(W.dW))+q*Wh
  end

end
WienerProcess(t0,W0,Z0=nothing;kwargs...) = NoiseProcess{false}(t0,W0,Z0,WHITE_NOISE_DIST,WHITE_NOISE_BRIDGE;kwargs...)

function INPLACE_WHITE_NOISE_DIST(rand_vec,W,dt,rng)
  wiener_randn!(rng,rand_vec)
  sqrtabsdt = @fastmath sqrt(abs(dt))
  @inbounds for i in eachindex(rand_vec)
    rand_vec[i] *= sqrtabsdt
  end
  #rand_vec .*= sqrt(abs(dt))
end
function INPLACE_WHITE_NOISE_BRIDGE(rand_vec,W,W0,Wh,q,h,rng)
  wiener_randn!(rng,rand_vec)
  #rand_vec .= sqrt((1.-q).*q.*abs(h)).*rand_vec.+q.*Wh
  sqrtcoeff = @fastmath sqrt((1.-q)*q*abs(h))
  @inbounds for i in eachindex(rand_vec)
    rand_vec[i] = sqrtcoeff*rand_vec[i]+q*Wh[i]
  end
end
WienerProcess!(t0,W0,Z0=nothing;kwargs...) = NoiseProcess{true}(t0,W0,Z0,INPLACE_WHITE_NOISE_DIST,INPLACE_WHITE_NOISE_BRIDGE;kwargs...)



#### Real Valued Wiener Process. Ignores complex and the like
function REAL_WHITE_NOISE_DIST(W,dt,rng)
  if typeof(W.dW) <: AbstractArray
    return @fastmath sqrt(abs(dt))*randn(rng,size(W.dW))
  else
    return @fastmath sqrt(abs(dt))*randn(rng)
  end
end
function REAL_WHITE_NOISE_BRIDGE(W,W0,Wh,q,h,rng)
  if typeof(W.dW) <: AbstractArray
    return @fastmath sqrt((1-q)*q*abs(h))*randn(rng,size(W.dW))+q*Wh
  else
    return @fastmath sqrt((1-q)*q*abs(h))*randn(rng)+q*Wh
  end
end
RealWienerProcess(t0,W0,Z0=nothing;kwargs...) = NoiseProcess{false}(t0,W0,Z0,REAL_WHITE_NOISE_DIST,REAL_WHITE_NOISE_BRIDGE;kwargs...)

function REAL_INPLACE_WHITE_NOISE_DIST(rand_vec,W,dt,rng)
  sqabsdt = @fastmath sqrt(abs(dt))
  @inbounds for i in eachindex(rand_vec)
    rand_vec[i] = randn(rng)*sqabsdt
  end
  #rand_vec .*= sqrt(abs(dt))
end
function REAL_INPLACE_WHITE_NOISE_BRIDGE(rand_vec,W,W0,Wh,q,h,rng)
  @inbounds for i in eachindex(rand_vec)
    rand_vec[i] = randn(rng)
  end
  #rand_vec .= sqrt((1.-q).*q.*abs(h)).*rand_vec.+q.*Wh
  @inbounds for i in eachindex(rand_vec)
    rand_vec[i] = @fastmath sqrt((1.-q)*q*abs(h))*rand_vec[i]+q*Wh[i]
  end
end
RealWienerProcess!(t0,W0,Z0=nothing;kwargs...) = NoiseProcess{true}(t0,W0,Z0,REAL_INPLACE_WHITE_NOISE_DIST,REAL_INPLACE_WHITE_NOISE_BRIDGE;kwargs...)

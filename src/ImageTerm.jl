#Plot a 2D-array as an image to the terminal
#Needs xterm-256color to run properly
#try to add export TERM=xterm-256color to your .bashrc
module ImageTerm
using Colors
using Images
export imageterm,sethd
const use_hd=Bool[false]

sethd(hd::Bool)=use_hd[1]=hd

function colstr(r::Integer,g::Integer,b::Integer)
  #r,g,b should be between 1 and 6
  r=min(r,6);r=max(r,1)
  g=min(g,6);g=max(g,1)
  b=min(b,6);b=max(b,1)
  return(36*(r-1)+6*(g-1)+b+15)
end
function colstr(c::AbstractRGB)
  return(colstr(ceil(Int,red(c)*6),ceil(Int,green(c)*6),ceil(Int,blue(c)*6)))
end

function stringfull(c)
  return(string("\e[48;5;",c,"m  "))
end

function stringtd(ct,cb)
  return(string("\e[48;5;",ct,"m\e[38;5;",cb,"m\u2584"))
end


abstract Normalization{T}
immutable LinearNormalization{T} <: Normalization{T}
  missval::T
  minval::T
  maxval::T
end

type ColorMapMiss{T,K}
  colors::Vector{RGB{T}}
  misscolor::RGB{T}
  missval::K
end
ColorMapMiss{T,V}(colors::Vector{RGB{T}},misscolor::RGB{V},missval)=ColorMapMiss(colors,convert(RGB{T},misscolor),missval)

getColor(c::ColorMapMiss,x::Number)=(x==c.missval) ? c.misscolor : c.colors[round(Int,x*(length(c.colors)-1))+1]
normalize(n::LinearNormalization,x::Number)= x==n.missval ? x : (x-n.minval)/(n.maxval-n.minval)
normalize!(n::LinearNormalization,x::Array)=for i in eachindex(x) x[i]=normalize(n,x[i]) end

function getPlotArray(a,npc,npl,transpose)
  mout=zeros(eltype(a),npl,npc)
  if transpose
    f1=(size(a,1)-1)/(npc-1)
    f2=(size(a,2)-1)/(npl-1)
    for i=1:npc,j=1:npl
      mout[j,i]=a[min(round(Int,(i-1)*f1)+1,size(a,1)),min(round(Int,(j-1)*f2)+1,size(a,2))]
    end
  else
    f1=(size(a,1)-1)/(npl-1)
    f2=(size(a,2)-1)/(npc-1)
    for i=1:npc,j=1:npl
      mout[j,i]=a[min(round(Int,(j-1)*f1)+1,size(a,1)),min(round(Int,(i-1)*f2)+1,size(a,2))]
    end
  end

  mout
end

function getMinMax(x,missval)
  mi=typemax(eltype(x))
  ma=typemin(eltype(x))
  for ix in x
    if ix!=missval
      if ix<mi mi=ix end
      if ix>ma ma=ix end
    end
  end
  mi,ma
end

Base.one(x::UTF8String)=""

function imageterm(io,a::AbstractMatrix;col::Vector=colormap("Blues"),missval::Number=1.0e32,misscol=colorant"black",hd::Bool=use_hd[1],title::AbstractString="",subtitle::AbstractString="",transpose=false)
  ldim=size(a)
  l,c=Base.tty_size()
  legendwidth = 15
  titleheight = title=="" ? 0 : 1
  # Determine size available for the plot
  npc = div(c-legendwidth,hd ? 1 : 2)
  npl = (l-titleheight)*(hd ? 2 : 1)
  #Determine final plotsize
  npl,npc=getPlotsize(ldim[1],ldim[2],npl,npc,transpose)
  #Get the data necessary for plotting from input
  pa=getPlotArray(a,npc,npl,transpose)
  #Normalize plotting data to 0..1
  no=LinearNormalization(pa,convert(eltype(pa),missval))
  normalize!(no,pa)
  #
  cm=ColorMapMiss(col,misscol,missval)
  #
  rgbar = pa2rgb(pa,cm)
  #
  sa=rgbar2sa(rgbar,hd=hd)
  #Make the legend
  sl=get_legend(cm,size(sa,1),no)
  #Concatenate with plot
  s=reducedim(string,hcat(sa,sl),2,UTF8String(""))
  #Join title and subtitle
  vcat(get_title(title,npc),s,get_subtitle(subtitle,cm))
  print(io,join(s),"\n")
end
imageterm(a::AbstractMatrix;col::Vector=colormap("Blues"),missval::Number=1.0e32,misscol=colorant"black",hd::Bool=use_hd[1],title::AbstractString="",subtitle::AbstractString="",transpose=false)=
imageterm(STDOUT,a,col=col,missval=missval,misscol=misscol,hd=hd,title=title,subtitle=subtitle,transpose=transpose)

function imageterm(io,img::AbstractImageDirect;hd::Bool=use_hd[1])
  title=string(colorspace(img), " ", typeof(img).name)
  subtitle=string("data: ", summary(img.data))
  transpose=img.properties["spatialorder"][1]=="x" ? true : false
  imageterm(io,img.data,hd=hd,title=title,transpose=transpose)
end
imageterm(img::AbstractImageDirect;hd::Bool=use_hd[1])=imageterm(STDOUT,img,hd=hd)

function imageterm{T<:AbstractRGB}(io,a::AbstractMatrix{T};hd::Bool=use_hd[1],title::AbstractString="",subtitle::AbstractString="",transpose=false)
  ldim=size(a)
  l,c=Base.tty_size()
  titleheight = title=="" ? 0 : 1
  # Determine size available for the plot
  npc = div(c,hd ? 1 : 2)
  npl = (l-titleheight)*(hd ? 2 : 1)
  #Determine final plotsize
  npl,npc=getPlotsize(ldim[1],ldim[2],npl,npc,transpose)
  #Get the data necessary for plotting from input
  pa=getPlotArray(a,npc,npl,transpose)
  # Convert to STring representation
  sa=rgbar2sa(pa,hd=hd)
  s=reducedim(string,hcat(sa,UTF8String["\e[0m\n" for i=1:size(sa,1), j=1]),2,UTF8String(""))
  #Join title and subtitle
  vcat(get_title(title,npc),s,subtitle)
  print(io,join(s),"\n")
end
imageterm{T<:AbstractRGB}(a::AbstractMatrix{T};hd::Bool=false,title::AbstractString="",subtitle::AbstractString="",transpose=false)=
imageterm{T<:AbstractRGB}(STDOUT,a;hd=hd,title=title,subtitle=subtitle,transpose=transpose)

pa2rgb(pa,cm)=[getColor(cm,pa[irowpa,icol]) for irowpa=1:size(pa,1), icol=1:size(pa,2)]

#Convert values to String Array
function rgbar2sa(rgbar;hd=false)
  if hd==false
    sa=Array(UTF8String,size(rgbar))
    for i in eachindex(sa)
      sa[i]=stringfull(colstr(rgbar[i]))
    end
  else
    sa=Array(UTF8String,ceil(Int,size(rgbar,1)/2),size(rgbar,2))
    irowpa=1
    for irow=1:size(sa,1)
      for icol=1:size(sa,2)
        if irowpa<size(rgbar,2)
          sa[irow,icol]=stringtd(colstr(rgbar[irowpa,icol]),colstr(rgbar[irowpa+1,icol]))
        else
          sa[irow,icol]=stringtd(colstr(rgbar[irowpa,icol]),colstr(rgbar[irowpa,icol]))
        end
      end
      irowpa+=2
    end
  end
  sa
end

LinearNormalization(pa,missval)=LinearNormalization(missval,getMinMax(pa,missval)...)
get_legend(cm,npl,no::Normalization)=UTF8String[string("\e[0m ",repeat(stringfull(colstr(getColor(cm,(npl-iline)/(npl-1)))),2),"\e[0m",@sprintf("%10.2e",no.minval+(npl-iline)/(npl-1)*(no.maxval-no.minval)),"\n") for iline=1:npl]

get_title(title,npc)= title!="" ? string("\n\e[1m",^(" ",round(Int64,(npc-length(title))/2)),title,"\e[0m\n\n") : title
get_subtitle(subtitle,cm)= subtitle!="" ? "\e[0m; min=$(cm.norm.minval); max=$(cm.norm.maxval)" : subtitle


function getPlotsize(slines,scol,l,c,transpose)
  if transpose slines,scol = scol,slines end
  asprat=slines/scol
  if slines>l
    slines=l
    scol=round(Int,slines/asprat)
  end
  if scol>c
    scol=c
    slines=round(Int,scol*asprat)
  end
  return slines,scol
end

# Overwrite writemime for Images
Base.writemime(io::IO, ::MIME"text/plain", img::AbstractImageDirect) = imageterm(io, img)

#haskey(Pkg.installed(),"NetCDF") ? include("ncplot.jl") : nothing
end

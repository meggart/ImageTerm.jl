#Plot a 2D-array as an image to the terminal
#Needs xterm-256color to run properly
#try to add export TERM=xterm-256color to your .bashrc

function colstr(r::Integer,g::Integer,b::Integer)
  #r,g,b should be between 1 and 6
  r=min(r,6);r=max(r,1)
  g=min(g,6);g=max(g,1)
  b=min(b,6);b=max(b,1)
  return(36*(r-1)+6*(g-1)+b+15)
end
function colstr(r::Real,g::Real,b::Real)
  return(colstr(iceil(r*6),iceil(g*6),iceil(b*6)))
end

function stringfull(c)
  return("\e[48;5;$(c)m  ")
end

function stringtd(ct,cb)
  return("\e[48;5;$(ct)m\e[38;5;$(cb)m\u2584")
end

function greystr(r::Integer)
  #value should be between 1 and 24
  r=min(r,24);r=max(r,1)
  return(r+231)
end
greystr(r::Real)=greystr(iceil(r*24))

function factorstr(r::Integer)
  #value should be between 1 and 16
  r=min(r,16);r=max(r,1)
  return(r-1)
end

function rbramp(v::Real)
  return colstr(v,0,1-v)
end

function rwbramp(v::Real)
  return(v < 0.5 ? colstr(2.0*v,2.0*v,1.0) : colstr(1.0,2.0*(1.0-v),2.0*(1.0-v)))
end

function byrramp(v::Real)
  try
    return(v < 0.5 ? colstr(2.0*v,2.0*v,0.0) : colstr(1.0,2.0*(1.0-v),0.0))
  catch
    println("An error v=$v")
    return(colstr(0.0,0.0,0.0))
  end
end

type MapCols
  colfunc::Function
  missval
  normfunc::Function
  center::Bool
end

function normcol(x,missval,center)
  x=float64(x)
  dmin=min(x[x.!=missval])
  dmax=max(x[x.!=missval])
  if (center)
    m=max(abs(dmin),abs(dmax))
    dmax=m
    dmin=-m
  end
  if (dmax>dmin)
    x[x.!=missval]=(x[x.!=missval]-dmin)./(dmax-dmin)
  else
    warn("Empty data range!")
    x[x.!=missval]=0.5
  end
  return(x,dmax,dmin)
end

MapCols(colfunc::Function,missval)=MapCols(colfunc,missval,normcol,false)
MapCols(colfunc::Function)=MapCols(colfunc,greystr(10))
heatscale=MapCols(byrramp)
bluescale=MapCols(v->colstr(1.0-v,1.0-v,1.0))
greenscale=MapCols(v->colstr(1.0-v,1.0,1.0-v))
redscale=MapCols(v->colstr(1.0,1.0-v,1.0-v),)
diffscale=MapCols(rwbramp,greystr(10),normcol,true)
greyscale=MapCols(greystr,greystr(1))


function imageterm(a::Array;col::MapCols=heatscale,missval::Number=1.0e32,hd::Bool=false,title::String="",subtitle::String="")
  ldim=size(a)
  length(ldim)==2 ? nothing : error("Input data must be 2D array")
  (l,c)=termsize()
  hdfac = hd ? 2 : 1
  rfac = ldim[1]>(hdfac*l) ? iceil(ldim[1]/l/hdfac) : 1
  rfac = ldim[2]>((hdfac*c-15)/2) ? max(rfac,iceil(ldim[2]/(hdfac*c-15)*2)) : rfac
  (anorm,dmax,dmin)=col.normfunc(a,missval,col.center)
  nlines=length(1:(rfac*hdfac):ldim[1])
  iline=1
  if (title!="")
    framewidth=length(1:rfac:ldim[2])*2/hdfac
    print(string("\n\e[1m",^(" ",int64((framewidth-length(title))/2))),title,"\e[0m\n\n")
  end
  for i=1:(hdfac*rfac):ldim[1]
    for j=1:rfac:ldim[2]
      subartop=anorm[i:min((i+rfac-1),end),j:min((j+rfac-1),end)]
      if (sum(subartop.==missval)<0.5*length(subartop))
        mtop=mean(subartop[subartop.!=missval])
        ctop=col.colfunc(mtop)
      else
        ctop=col.missval
      end
      if (hdfac > 1)
        subarbot = ((i+rfac)<= size(anorm)[1]) ? anorm[(i+rfac):min((i+2*rfac-1),end),j:min((j+rfac-1),end)] : missval
        if (sum(subarbot.==missval)<0.5*length(subarbot))
          mbot=mean(subarbot[subarbot.!=missval])
          cbot=col.colfunc(mbot)
        else
          cbot=col.missval
        end
      end
      hdfac>1 ? print(stringtd(ctop,cbot)) : print(stringfull(ctop))
    end
    print("\e[0m ")
    for ileg=1:2 print(stringfull(col.colfunc((nlines-iline)/(nlines-1)))) end
    print("\e[0m")
    @printf("%10.2e",dmin+(nlines-iline)/(nlines-1)*(dmax-dmin))
    print("\n")
    iline=iline+1
  end
  print("\e[0m")
  if (subtitle!="")
    println(subtitle,"; min=$(dmin); max=$(dmax)")
  end
end

function imageterm(ar::Array,ag::Array,ab::Array;hd=false)
  @assert begin size(ar)==size(ag); size(ar)==size(ab) end
  if (typeof(ar)<:Integer)
    ar=ar/255.0;ag=ag/255.0;ab=ab/255.0
  end
  ar=squeeze(ar);ag=squeeze(ag);ab=squeeze(ab)
  ldim=size(ar)
  length(ldim)==2 ? nothing : error("Input data must be 2D array")
  (l,c)=termsize()
  hdfac = hd ? 2 : 1
  rfac = ldim[1]>(hdfac*l) ? iceil(ldim[1]/l/hdfac) : 1
  rfac = ldim[2]>((hdfac*c)/2) ? max(rfac,iceil(ldim[2]/(hdfac*c)*2)) : rfac
  nlines=length(1:(rfac*hdfac):ldim[1])
  iline=1
  for i=1:(hdfac*rfac):ldim[1]
    for j=1:rfac:ldim[2]
      subartopr=ar[i:min((i+rfac-1),end),j:min((j+rfac-1),end)]
      subartopg=ag[i:min((i+rfac-1),end),j:min((j+rfac-1),end)]
      subartopb=ab[i:min((i+rfac-1),end),j:min((j+rfac-1),end)]
      mtopr=mean(subartopr)
      mtopg=mean(subartopg)
      mtopb=mean(subartopb)
      ctop=colstr(mtopr,mtopg,mtopb)
      if (hdfac > 1)
        subarbotr = ((i+rfac) <= size(ar)[1]) ? ar[(i+rfac):min((i+2*rfac-1),end),j:min((j+rfac-1),end)] : 0.0
        subarbotg = ((i+rfac) <= size(ag)[1]) ? ag[(i+rfac):min((i+2*rfac-1),end),j:min((j+rfac-1),end)] : 0.0
        subarbotb = ((i+rfac) <= size(ab)[1]) ? ab[(i+rfac):min((i+2*rfac-1),end),j:min((j+rfac-1),end)] : 0.0
        mbotr=mean(subarbotr)
        mbotg=mean(subarbotg)
        mbotb=mean(subarbotb)
        cbot=colstr(mtopr,mtopg,mtopb)
      end
      hdfac>1 ? print(stringtd(ctop,cbot)) : print(stringfull(ctop))
    end
    print("\e[0m ")
    print("\n")
    iline=iline+1
  end
end

function termsize()

  if (haskey(ENV,"LINES") & haskey(ENV,"COLUMNS"))
    l=int64(ENV["LINES"])
    c=int64(ENV["COLUMNS"])
  else
    if (isfile("/Net/Groups/BGI/code/julia/tools/ncplot/getcl.so"))
      l=ccall((:getlines,"/Net/Groups/BGI/code/julia/tools/ncplot/getcl"),Int32,())
      c=ccall((:getcolumns,"/Net/Groups/BGI/code/julia/tools/ncplot/getcl"),Int32,())
    else
      warn("Your terminal size could not be detected. Please run \e[1mexport LINES COLUMNS\e0m")
      l=20
      c=40
    end
  end
  return(l,c)
end



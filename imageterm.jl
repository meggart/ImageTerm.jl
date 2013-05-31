#Plot a 2D-array as an image to the terminal
#Needs xterm to runs properly
#try to add export TERM=xterm-256color to your .bashrc

function colspace(r::Integer,g::Integer,b::Integer)
  #r,g,b should be between 1 and 6
  r=min(r,6);r=max(r,1)
  g=min(g,6);g=max(g,1)
  b=min(b,6);b=max(b,1)
  return("\e[48;5;$(36*(r-1)+6*(g-1)+b+15)m \e[0m")
end
function colspace(r::Real,g::Real,b::Real)
  return(colspace(iceil(r*6),iceil(g*6),iceil(b*6)))
end

function greyspace(r::Integer)
  #value should be between 1 and 24
  r=min(r,24);r=max(r,1)
  return("\e[48;5;$(r+231)m \e[0m")
end

function factorspace(r::Integer)
  #value should be between 1 and 16
  r=min(r,16);r=max(r,1)
  return("\e[48;5;$(r-1)m \e[0m")
end

function rbramp(v::Real)
  return colspace(v,0,1-v)
end

function rwbramp(v::Real)
  return(v < 0.5 ? colspace(2.0*v,2.0*v,1.0) : colspace(1.0,2.0*(1.0-v),2.0*(1.0-v)))
end

function byrramp(v::Real)
  return(v < 0.5 ? colspace(2.0*v,2.0*v,0.0) : colspace(1.0,2.0*(1.0-v),0.0))
end

type MapCols
  colfunc::Function
  missval::String
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

MapCols(colfunc::Function,missval::String)=MapCols(colfunc,missval,normcol,false)
MapCols(colfunc::Function)=MapCols(colfunc,greyspace(10))
heat=MapCols(byrramp)
bluescale=MapCols(v->colspace(1.0-v,1.0-v,1.0))
greenscale=MapCols(v->colspace(1.0-v,1.0-v,1.0))
redscale=MapCols(v->colspace(1.0-v,1.0-v,1.0))
diffscale=MapCols(rwbramp,greyspace(10),normcol,true)


function imageterm(a::Array;col::MapCols=heat,missval=1.0e32)
  ldim=size(a)
  length(ldim)==2 ? nothing : error("Input data must be 2D array")
  (l,c)=termsize()
  rfac = ldim[1]>l ? iceil(ldim[1]/l) : 1
  rfac = ldim[2]>(2*c-14) ? max(rfac,iceil(ldim[2]/2.0/c)) : rfac
  (anorm,dmax,dmin)=col.normfunc(a,missval,col.center)
  nlines=length(1:rfac:ldim[1])
  iline=1
  for i=1:rfac:ldim[1]
    for j=1:rfac:ldim[2]
      subar=anorm[i:min((i+rfac-1),end),j:min((j+rfac-1),end)]
      if (sum(subar.==missval)<0.5*length(subar))
        m=mean(subar[subar!=missval])
        print(col.colfunc(m))
        print(col.colfunc(m))
      else
        print(col.missval)
        print(col.missval)
      end
    end
    print(" ")
    print(col.colfunc((nlines-iline)/(nlines-1)))
    print(col.colfunc((nlines-iline)/(nlines-1)))
    print(col.colfunc((nlines-iline)/(nlines-1)))
    print(col.colfunc((nlines-iline)/(nlines-1)))
    @printf("%10.2e",dmin+(nlines-iline)/(nlines-1)*(dmax-dmin))
    print("\n")
    iline=iline+1
  end
end

function termsize()
  slines = ccall( (:getenv, "libc"), Ptr{Uint8}, (Ptr{Uint8},), "LINES")
  scols = ccall( (:getenv, "libc"), Ptr{Uint8}, (Ptr{Uint8},), "COLUMNS")
  l=int64(bytestring(slines))
  c=int64(bytestring(slines))
  return(l,c)
end



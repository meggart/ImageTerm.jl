using NetCDF
using ImageTerm

function ncplot(fn::String;hd=false,col::MapCols=heatscale,timavg=true)
  nc = NetCDF.open(fn)
  for va in nc.vars
    v=va[2]
    totranspose=(lowercase(v.dim[1].name)[1:3]=="lon")
    if ((v.ndim==3) && (timavg==false))
      ncplotallsteps(nc,v,hd,col,totranspose)
    else
      if ((v.ndim>1) && (v.ndim<4))
        if v.ndim==2
          a=NetCDF.readvar(nc,v,[1,1],[-1,-1])
        elseif v.ndim==3
          a = readtimavg(nc,v)
        end
        # Transpose if lon is first dimension
        if (totranspose)
          a=transpose(a)
        end
        missval = haskey(v.atts,"missing_value") ? v.atts["missing_value"] : 1.0e32
        su=haskey(v.atts,"units") ? v.atts["units"] : ""
        su="units = $(su)"
        ti = haskey(v.atts,"long_name") ? v.atts["long_name"] : v.name
        imageterm(a,missval=missval,hd=hd,col=col,title=ti,subtitle=su)
      end
    end
  end
end

function ncplotallsteps(nc,v,hd,col,totranspose)
  missval = has(v.atts,"missing_value") ? v.atts["missing_value"] : 1.0e32
  for i in 1:v.dim[3].dimlen
    a=NetCDF.readvar(nc,v,[1,1,i],[-1,-1,1])[:,:,1]
    if (totranspose)
      a=transpose(a)
    end
    println("Time step $i of $(v.dim[3].dimlen):")
    imageterm(a,missval=missval,hd=hd,col=col)
  end
end

function readtimavg(nc::NcFile,v::NcVar)
  #Average over all time steps
        missval = haskey(v.atts,"missing_value") ? v.atts["missing_value"] : 1.0e32
        ntime=v.dim[3].dimlen
        a=NetCDF.readvar(nc,v,[1,1,1],[-1,-1,1])
        ncount=(a.!=missval)*1
        if ntime>1
          a[a.==missval]=zero(a[1,1,1])
          for i=2:ntime
            ar=NetCDF.readvar(nc,v,[1,1,i],[-1,-1,1])
            ncount=ncount+(ar.!=missval)*1
            ar[ar.==missval]=zero(ar[1,1,1])
            a=a+ar
          end
          a=(a./ncount)[:,:,1]
          a[isnan(a)]=missval
        else
          a=a[:,:,1]
        end
      return(a)
end

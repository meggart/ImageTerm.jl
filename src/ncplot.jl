using NetCDF

function ncplot(fn::String;hd=false,col::Vector=colormap("Blues"),timavg=true)
  nc = NetCDF.open(fn)
  for va in nc.vars
    v=va[2]
    totranspose=(lowercase(v.dim[1].name)[1:3]=="lon")
    if ((v.ndim==3) && (timavg==false))
      ncplotallsteps(nc,v,hd,col,totranspose)
    else
      if (v.ndim==2)
        missval = haskey(v.atts,"missing_value") ? v.atts["missing_value"] : haskey(v.atts,"_FillValue") ? v.atts["missing_value"] : typemax(eltype(v))
        su=haskey(v.atts,"units") ? v.atts["units"] : ""
        su="units = $(su)"
        ti = haskey(v.atts,"long_name") ? v.atts["long_name"] : v.name
        imageterm(v,missval=missval,hd=hd,col=col,title=ti,subtitle=su,transpose=totranspose)
      end
    end
  end
end

function ncplotallsteps(nc,v,hd,col,totranspose)
  missval = haskey(v.atts,"missing_value") ? v.atts["missing_value"] : haskey(v.atts,"_FillValue") ? v.atts["missing_value"] : typemax(eltype(v))
  for i in 1:v.dim[3].dimlen
    a=NetCDF.readvar(nc,v,[1,1,i],[-1,-1,1])[:,:,1]
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

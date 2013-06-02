using NetCDF
include("imageterm.jl")
function ncplot(fn::String)
  
  nc = NetCDF.open(fn)
  for va in nc.vars
    v=va[2]
    if ((v.ndim>1) && (v.ndim<4))
      if v.ndim==2
        a=nc.readvar(nc,v,[1,1],[-1,-1])
      elseif v.ndim==3
        #Average over all time steps
        ntime=v.dim[3].dimlen
        a=NetCDF.readvar(nc,v,[1,1,1],[-1,-1,1])
        if ntime>1
          for i=2:ntime
            a=a+NetCDF.readvar(nc,v,[1,1,i],[-1,-1,1])
          end
          a=(a./ntime)[:,:,1]
        end
      end
      missval = has(v.atts,"missing_value") ? v.atts["missing_value"] : 1.0e32
      imageterm(a,missval=missval)
    end
  end
end
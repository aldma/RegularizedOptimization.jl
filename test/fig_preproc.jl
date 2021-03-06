
function fig_preproc(f_obj, h_obj, xvars,xlabs,hist, Comp, A, λ, folder, tabname)

    ftab = zeros(length(xvars))
    htab = zeros(length(xvars))
    objtab = zeros(length(xvars))
    partab = zeros(length(xvars))
    numtab = zeros(length(xvars))
    for i = 1:length(xvars)
        ftab[i] = f_obj(xvars[i])[1] 
        htab[i] = h_obj(xvars[i])
        objtab[i] = ftab[i] + λ*htab[i]
        if isa(A, Array)
            partab[i] = norm(xvars[1] - xvars[i])/opnorm(A)
        else
            partab[i] = norm(xvars[1] - xvars[i])
        end
        if i==1
            numtab[i] = 0
        elseif i>1 && occursin("ZFP", xlabs[i])
            numtab[i] = length(hist[i-1])*20
        else

            numtab[i] = length(hist[i-1])
        end
    end
    if isa(A, Array)
        objtest = abs(objtab[2] - objtab[1])/opnorm(A)
    else 
        objtest = abs(objtab[2] - objtab[1])
    end
    
    partest = partab[2]



    vals = vcat(objtab', ftab', htab', partab', numtab')
    pars = hcat(xvars)

    

    if isa(A, Array)
        bvars = fill(Float64[], length(xvars))
        figen(xvars, xlabs, string(folder,"xcomp"), [" ", "x - index", "  "], 1, 1)
        for i = 1:length(xvars) 
            bvars[i] = A*xvars[i]
        end
        figen(bvars, xlabs, string(folder,"bcomp"), [" ", "b - index", " "], 1, 1)
    else
        bvars = fill(Float64[], length(xvars)*2+2)
        sol = A(xvars[1], 0)
        bvars[1], bvars[2] = sol[1,:], sol[2,:]
        tvars = 0 #just initialize
        newlabs = ["Data-V", "Data-W"]
        for i = 1:length(xvars)
            sol = A(xvars[i], i)
            if i==1
                tvars = fill(sol.t, 2*length(xvars)+2)
            end
            solx = hcat(sol.u...)
            bvars[2*i+1], bvars[2*i+2] = solx[1,:], solx[2,:]
            push!(newlabs, string(xlabs[i], "-V"))
            push!(newlabs, string(xlabs[i], "-W"))
        end

	# yvars = [sol[1,:], sol[2,:], solx[1,:], solx[2,:], solp[1,:], solp[2,:], data[1,:], data[2,:]]
	# xvars = [t, t, t, t, t, t, t, t]
	# labs = ["True-V", "True-W", "TR-V", "TR-W", "PANOC-V", "PANOC-W", "Data-V", "Data-W"]
	# figen_non(xvars, yvars, labs, string(folder, "xcomp"), [" ", "Time", "Voltage"],2, 1)
        figen_non(tvars, bvars, newlabs, string(folder, "xcomp"), [" ", "Time", "Voltage"], 1)
    end
    


    histx =  fill(Float64[], length(hist))
    for i = 1:length(hist)
        if occursin("ZFP", xlabs[i+1])
            histx[i] = Array(1:20:length(hist[i])*20)
        else
            histx[i] = Array(1:length(hist[i]))
        end
    end
    figen_non(histx, hist, xlabs[2:end], string(folder,"objcomp"), [" ", "kth Objective Evaluation", "Value "], 0)
    figen(Comp, xlabs[2:2+length(Comp)], string(folder,"complexity"), [" ", "kth Iteration", " Inner Prox Evaluations "], 1, 1)

    dp, df = show_table(pars, vals, xlabs)
    _ = write_table(dp, df, string(folder,tabname))


    return partest, objtest
end
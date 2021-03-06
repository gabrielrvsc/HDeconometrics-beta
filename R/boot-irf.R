
boot.irf=function (model, ident, h, M, unity.shock = TRUE, m.type = "ols") 
{
  Y = as.matrix(model$Y)
  N = model$N
  p = model$p
  nvar = ncol(model$residuals)
  save.irf = list()
  aux1 = list()
  aux = matrix(NA, h + 1, M)
  for (i in 1:ncol(Y)) {
    aux1[[i]] = aux
  }
  names(aux1) = colnames(Y)
  for (i in 1:ncol(Y)) {
    save.irf[[i]] = aux1
  }
  names(save.irf) = colnames(Y)
  invA = solve(ident$A)
  u = t(ident$A %*% t(model$residuals))
  for (m in 1:M) {
    resamp = sample(1:nrow(u), nrow(u), replace = TRUE)
    uboot = u[resamp, ]
    Yboot = Y
    for (i in (p + 1):(N + p)) {
      using = Yboot[(i - p):(i - 1), ]
      using = using[nrow(using):1, ]
      res = rep(0, length(nvar))
      for (j in 1:p) {
        res = res + as.vector(model$coef.by.block[[j + 
                                                     1]] %*% using[j, ])
      }
      Yboot[i, ] = res + model$coef.by.block[[1]] + invA %*% 
        uboot[i - p, ]
    }
    if (m.type == "lasso") {
      modelboot = fitvar(Yboot, p, m.type = "lasso")
    }
    if (m.type == "adalasso") {
      modelboot = fitvar(Yboot, p, m.type = "lasso")
      aux = abs(modelboot$coef.by.equation[, -1]) + (1/sqrt(modelboot$N))
      penalty = aux^(-0.5)
      modelboot = fitvar(Y, p, m.type = "lasso", penalty.factor = penalty)
    }
    if (m.type == "ols") {
      modelboot = fitvar(Yboot, p, m.type = "ols")
    }
    if(m.type=="lbvar"){
      modelboot = lbvar(Y,p)
    }
    identboot = identification(modelboot)
    irfboot = irf(modelboot, identboot, h = h, unity.shock = unity.shock)
    for (i in 1:nvar) {
      for (j in 1:nvar) {
        save.irf[[i]][[j]][, m] = irfboot[[i]][, j]
      }
    }
  }
  for (i in 1:nvar) {
    for (j in 1:nvar) {
      save.irf[[i]][[j]] = t(apply(save.irf[[i]][[j]], 
                                   1, sort))
    }
  }
  aux = irf(model, ident, h, unity.shock)
  return(list(point.irf = aux, density = save.irf))
}


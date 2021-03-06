library(diversitree);

add.alpha <- function(col, alpha=.5) {
    tmp <- col2rgb(col)/255
    rgb(tmp[1,], tmp[2,], tmp[3,], alpha=alpha)
}

phy <- read.tree("genus.tree");
new.phy <- multi2di(phy);
phy <- new.phy;


# Process data on using **Solanaceae** as hostplant
data <- read.csv("states.csv", sep="\t", header=T, row.names=1);
data <- data[order(order(phy$tip.label)),]

# Column 2 is the data for **Solanaceae**
# Column 1 is for Apocynaceae (data not used in this analysis)
data.v <- data[,2]

names(data.v) <- row.names(data)

phy$tip.state<-data.v

##################
# get sampling values. Propotion of extant species in our tree that have state 0 and state 1
# in relation with the total 
richness <- read.csv("richness.csv")
richness <- richness[order(order(phy$tip.label)),]

richness_cero <- c();
richness_one <- c();
for(i in 1:length(names(data.v))) {
  x <- match(names(data.v)[i], richness$taxon)
  x.state <- data.v[i]
  
  if( is.na(x.state) == FALSE) {
    if( x.state == 0) {
      richness_cero <- c(richness_cero, richness$n.taxa[i])
    }
    if( x.state == 1) {
      richness_one <- c(richness_one, richness$n.taxa[i])
    }
  }
}

total_richness_state_cero <- sum(richness_cero);
total_richness_state_one <- sum(richness_one);

sampling.f <- c(length(richness_cero)/total_richness_state_cero, length(richness_one)/total_richness_state_one)
##################

lik <- make.bisse(tree=phy, states=phy$tip.state, sampling.f=sampling.f);


p <- starting.point.bisse(phy);
fit <- find.mle(lik, p);
fit$lnLik; # -1612.288

# > round(coef(fit),3)
# lambda0 lambda1     mu0     mu1     q01     q10 
# 0.104   0.157   0.000   0.000   0.000   0.006 

prior <- make.prior.exponential(1 / (2 * (p[1] - p[3])));
set.seed(1);

tmp <- mcmc(lik, fit$par, nsteps=1000, prior=prior, lower=0, w=rep(1,6));

save(tmp, file="tmp.txt");

#w <- diff(sapply(tmp[2:7], range));
w <- diff(sapply(tmp[2:7], quantile, c(0.05, 0.95)));


# this runs the markov chain
samples <- mcmc(lik, fit$par, nsteps=10000, w=w, lower=0, prior=prior, save.every=1000, save.file="bisse_solanaceae_01.csv");

# read markov chain from saved data file
samples <- read.csv("bisse_mcmc_run.csv")

# do burnin
samples <- subset(samples, i > 7500)

## get diversification rate values = r:
diversification0 = c();
diversification1 = c();

for (i in 1:length(samples$lambda0)) { 
    r0 = samples$lambda0[[i]] - samples$mu0[[i]];
    r1 = samples$lambda1[[i]] - samples$mu1[[i]];
    
    diversification0 = c(r0, diversification0)
    diversification1 = c(r1, diversification1)
}

diversification0 = as.data.frame(diversification0);
diversification1 = as.data.frame(diversification1);

col <- c("#004165", "#eaab00", "#03253f", "#8e6803");
col.fill <- add.alpha(col, 0.5)
legend <- c(expression(paste(lambda[0],"\tnon-Solanaceae feeders")), 
            expression(paste(lambda[1],"\tSolanaceae feeders")),
            expression(paste('r'[0],"\tnon-Solanaceae feeders")), 
            expression(paste('r'[1],"\tSolanaceae feeders"))
                       );

# plot diversification rate of taxa not using and using solanaceae as hostplants
profiles.plot(c(samples[2], samples[3], diversification0, diversification1),
              col.line=col, las=1, ylab="Posterior probability density", 
              xlab="Speciation/Diversification rate", legend.pos="");
legend("topright", legend=legend, fill=col.fill, border=col, bty="n")

## Now we can examine the 95% credible intervals of the posterior samples for each parameter.
## If the intervals do not overlap, then we have posterior Bayesian support for a difference in rates
x <- sapply(samples[,2:7],quantile,c(0.025,0.975))

boxplot(x);

####
# do a likelihood ratio test of forcing equal speciation rates lambda0 = lambda1
samples <- read.csv("bisse_mcmc_run.csv")
samples2 <- subset(samples, i > 7500);
x <- sapply(samples2[,2:7],quantile,c(0.025,0.975))

# ---------------------
# do a likelihood ratio test of forcing equal speciation rates lambda0 = lambda1
# now using the mean of the 95% confidence intervals
pars <- c(mean(x[,1]), mean(x[,2]), mean(x[,3]), mean(x[,4]), mean(x[,5]), mean(x[,6]))
fit <- find.mle(lik, pars)
logLik(fit)  #'log Lik.' -1612.288 (df=6)
AIC(fit)     # 3236.577

lik.l <- constrain(lik, lambda0 ~ lambda1)
fit.l <- find.mle(lik.l, pars[-2])
logLik(fit.l)  #'log Lik.' -1619.4 (df=5)
AIC(fit.l)     # 3248.8

anova(fit, equal.lambda=fit.l)
# Df   lnLik    AIC  ChiSq Pr(>|Chi|)    
# full          6 -1612.3 3236.6                      
# equal.lambda  5 -1619.4 3248.8 14.223  0.0001624 ***
# ---
# Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

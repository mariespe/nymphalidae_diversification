# This code plots for each of the set of 1000 trees:
# * the percentage of node splits with hight posterior probability (> 0.95)
# * the number of nodes consistenly recovered across the set of 1000 trees, which 
#   is the number of node splits found in more than 950 trees.
library(ggplot2)

multimedusa <- read.csv("ancillary/supp_mat_14-consistently_recovered_splits_multimedusa_variable_topology.csv", header=FALSE)
medusa      <- read.csv("ancillary/supp_mat_15-percentage_nodes_high_post_prob.csv", header=FALSE)

#png(filename="figures/plot_medusa_multimedusa_tests.png")
par(bty="l", cex.main=2, cex.lab=2)
par(mar=c(5,7,4,6)+0.1)

plot(multimedusa$V1, multimedusa$V2, col="red", type="l", xlab="set of 1000 trees",
      ylab="number of consistently\n recovered nodes")

par(new=TRUE)
plot(medusa$V1, medusa$V2, col="blue", type="l", xaxt="n", yaxt="n", xlab="", ylab="")
axis(4)
mtext("percentage of nodes with\n high posterior probability", side=4, line=3, cex=2)
legend("topleft", legend=c("MEDUSA","multiMEDUSA"), lty=1, pch=1, col=c("blue","red"), inset=0.2)

#dev.off()


## plot percentage of good nodes versus consistently recovered nodes
par(new=TRUE)
svg(filename="ancillary/fig05.svg")
data <- as.data.frame(cbind(medusa$V2, multimedusa$V2))
p <- qplot(data$V1, data$V2, geom="point")
p + geom_smooth(method="lm", se=FALSE, aes(data$V1))    + 
    scale_y_continuous(breaks=c(5, 7.5, 10, 12.5, 15), 
    labels=c("5", "7.5", "10", "12.5", "15"))           + 
    labs(title="Effect of percentage of \n nodes with high posterior probability on multiMEDUSA results") +
    xlab("percentage of nodes with post. prob. > 0.95") +
    ylab("number of nodes consistenly recovered from the \n multiMEDUSA analyses") +
    theme_bw()
dev.off()


## plot width of confidence intervals for estimated ages versus consistently recovered nodes
multimedusa <- read.csv("output/multimedusa_output.csv", header=FALSE)
par(new=TRUE)
#png(filename="figures/plot_multimedusa_tests_on_confidence_intervals.png")
p <- qplot(multimedusa$V1, multimedusa$V2, geom="line",  size=I(1),
            main="Effect of confidence interval width of estimated ages
            on multiMEDUSA results",
            xlab="sets of trees with decreasing width of confidence intervals",
            ylab="number of nodes consistenly recovered from the
            multiMEDUSA analyses")
p + scale_y_continuous(breaks=c(5, 7.5, 10, 12.5, 15), 
                       labels=c("5", "7.5", "10", "12.5", "15")) + theme_bw()
#dev.off()

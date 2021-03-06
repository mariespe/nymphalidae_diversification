#install.packages("auteur_0.12.1010.tar.gz", repos=NULL, type="source")
library(turboMEDUSA)
library(ape)
library(auteur)
library(phytools)
library(reshape)

rm(list=ls())

# This script should be invoked from the command line
# Input data should be entered as arguments
# for example:
#     Rscript supp_mat_06_multiMEDUSA.R data/set_1000_trees.nex data/mct.tree output/raw_data_set_1000_summary.csv output/raw_data_set_1000.csv
args <- commandArgs(trailingOnly = TRUE)


# clear workspace


# read in trees

dfg <- read.nexus(file=as.character(args[1])); # tree from MrBayes run
tax <- read.csv(file="data/supp_mat_03_richness.csv"); # two column dataframe of genera (match tip.lables) and species richness
mct <- read.nexus(as.character(args[2])); # mct is the maximum credibility tree
tips <- c("Achlyodes", "Graphium", "Parnassius", "Baronia", "Troides", "Papilio1", "Papilio2", "Pieris", "Aporia", "Styx", "Hamearis", "Euselasia", "Nymphidium", "Emesis", "Crocozona", "Riodina", "Amarynthis", "Baliochila", "Poritia", "Miletus", "Liphyra", "Lycaena", "Celastrina", "Thecla", "Lucia", "Curetis", "Eurema", "Colias", "Leptidea", "Pseudopontia", "Libyt");
mct  <- drop.tip(mct, tips)

# subset dfg for testing purposes, replace with
# dfg <- dfg[1:1000]

dfg <- dfg[1:1000]

# get list of all clades in mct

mct.clades.names <- list()
mct.clades.nums <- prop.part(mct)
for (i in 1:length(mct.clades.nums)) {
  mct.clades.names[[i]] <- mct$tip.label[unlist(mct.clades.nums[i])]
}

# number of models to consider

model.limit <- 25

# these matrices 'hold' the results

tip.dataset <- matrix(ncol=5)
colnames(tip.dataset) <- c("tree.rep", "index", "r", "epsilon", "lnLik.part")
tip.row <- matrix(ncol=5)
colnames(tip.row) <- c("tree.rep", "index", "r", "epsilon", "lnLik.part")
clade.dataset <- matrix(ncol=5)
colnames(clade.dataset) <- c("tree.rep", "index", "r", "epsilon", "lnLik.part")
clade.row <- matrix(ncol=5)
colnames(clade.row) <- c("tree.rep", "index", "r", "epsilon", "lnLik.part")

# loop through all 1000 trees

for (tree.rep in 1:length(dfg)) {
  
  phy <- dfg[[tree.rep]]
  
  cat("
\n##############################################
## Now analyzing tree ", tree.rep, "of", length(dfg), "total trees
##############################################\n
      ")
  
  res <- runTurboMEDUSA(phy = phy,
                 richness = tax,
                 model.limit = model.limit,
                 mc = TRUE,
                 num.cores=4,
                 stop = "model.limit",
                 initial.r = 0.05,
                 initial.e = 0.5)
  
  # need to find cutoff for each model to determine the number of split.at clades
 
  model.aicc <- c()
  for (i in 1:model.limit) {
    model.aicc[i] <- res$models[[i]]$aicc
  }
  
  arbitrary.threshold <- -7.803831 # decrease in information theoretic score (see suppl. of Alfaro et al. in PNAS)
  model.num <- min(c(1:model.limit)[diff(model.aicc) > arbitrary.threshold]) # select model using 'threshold' index from above

  # get data for 
  
  model.data <- res$models[[model.num]]
  
  # get descendants of each split.node
  
  split.tip.labels <- c()
  
  for (i in 1:model.num) { # the first split is actually the whole tree
    node <- model.data$split.at[i]
    if (node < 399) { # if the node subtends a terminal tip
      split.tips <- node
      
      # the clade exists in MCT since it is a single lineage
      index <- match(phy$tip.label[split.tips], mct$tip)
      tip.row[1,1] <- tree.rep
      tip.row[1,2] <- index # this number is the index for mct$tp
      tip.row[1,3] <- model.data$par[i, 1]
      tip.row[1,4] <- model.data$par[i, 2]
      tip.row[1,5] <- model.data$lnLik.part[i]
      tip.dataset <- rbind(tip.row, tip.dataset)
    }
    
    else {
      split.descendants <- getDescendants(phy, node = node) # get the descendants of the split node
      split.tips <- c(split.descendants)[split.descendants < 399] # select only the tips
      split.tip.labels <- phy$tip.label[split.tips] # convert the numerical tip names to tip labels
      
      # test whether the split clade exists in the mct
      for (j in 1:length(mct.clades.names)) { # see mct.clades.names above
        if (identical(sort(split.tip.labels), sort(mct.clades.names[[j]]))) {
          clade.row[1,1] <- tree.rep
          clade.row[1,2] <- j # this number is the index for mct.clades.names
          clade.row[1,3] <- model.data$par[i, 1]
          clade.row[1,4] <- model.data$par[i, 2]
          clade.row[1,5] <- model.data$lnLik.part[i]
          clade.dataset <- rbind(clade.row, clade.dataset)
        }
      }     
    }
  }
}
tip.dataset <- as.data.frame(tip.dataset)
clade.dataset <- as.data.frame(clade.dataset)

tip.dataset <- tip.dataset[1:nrow(tip.dataset)-1,]
clade.dataset <- clade.dataset[1:nrow(clade.dataset)-1,]

# combine the datsets and add a column indicating whether the clade is a tip

tip.dataset$tip <- "y"
clade.dataset$tip <- "n"

d <- rbind(tip.dataset, clade.dataset)
d.m <- melt(d, id=c("index", "tip"))
d.c.length <- cast(d.m, index + tip ~ variable, length)
d.c.mean <- cast(d.m, index + tip ~ variable, mean)
d.c.sd <- cast(d.m, index + tip ~ variable, sd)

output <- cbind(d.c.length[1:3], d.c.mean[4], d.c.sd[4], d.c.mean[5], d.c.sd[5], d.c.mean[6], d.c.sd[6])
names(output) <- c("index", "tip", "sample size (N)", "r (mean)", "r (sd)", "epsilon (mean)", "epsilon (sd)","lnlik (mean)","lnlik (sd)")

output
write.table(output, file=as.character(args[3]), row.names=FALSE)
cat(paste("\n\nThe output variable contains a summary of the statistics from 
      turboMEDUSA on the processed trees. It was saved into file", args[3], sep=" "))

cat(paste("\n\nThe raw data was written to the file", args[4], sep=" "))
write.table(d, file=as.character(args[4]), row.names=FALSE)

cat("\n
##############################################
## Use the index number to identify the taxa in each clade.
##
## If the clade is a tip (i.e., tip = y),
## type:  mct$tip['insert index value here']
##
## If the clade is not a tip (i.e., tip = n),
## type:  mct.clades.names[['insert index value here']]
##
## In both cases, a string of taxon names will be returned.
##############################################\n
    ")

################################
# save some statistics to file
file_conn <- file("output/multimedusa_output.csv", open="at");

# calculate number of consistently recovered split nodes across the
# set of 1000 trees (those found in more than 95% of the sampled trees)
n <- length(which(output$"sample size (N)" > 950))
writeLines(c(paste(args[1], n, sep=",")), file_conn)
close(file_conn);


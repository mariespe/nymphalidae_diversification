library(ape)
library(multicore)

## Generate a set of 1000 trees
# each set will be the random 1000 trees minus one,
# that should be replaced by the MCT tree.
# The idea is incrementally "improve" the set of trees,
# so that the nodes with high posterior probabilities will 
# increase in number in the MCT tree of each set.

# In this way, we can test whether the failure to recover
# most of the splits of the MCT on more than 95% of the trees
# from the posterior is due to having nodes with low 
# posterior probability.
# This will be useful for answering the Asociate Editor and Reviewer 3 in part.

## TODO:
# get mct for each set
# test if the percentage of nodes recovered in set improves
# test if this might also be influenced by having narrower confidence intervals
# but how???

# read the mcc tree from the 1000 random trees from the original BEAST run 
# variable topology
mct <- read.nexus("data/supp_mat_04_1000_random_trees_no_outgroups_mct.nex")
# remove outgroups from our tree
#tips <- c("Achlyodes", "Graphium", "Parnassius", "Baronia", "Troides", "Papilio1", "Papilio2", "Pieris", "Aporia", "Styx", "Hamearis", "Euselasia", "Nymphidium", "Emesis", "Crocozona", "Riodina", "Amarynthis", "Baliochila", "Poritia", "Miletus", "Liphyra", "Lycaena", "Celastrina", "Thecla", "Lucia", "Curetis", "Eurema", "Colias", "Leptidea", "Pseudopontia", "Libyt");
#mct <- drop.tip(mct, tips)
#mct <- read.nexus("data/supp_mat_1000_trees_fixed_topology_mct.nex")
orig_set <- read.nexus("data/supp_mat_02_1000_random_trees_no_outgroups.nex")
#orig_set <- read.nexus("data/supp_mat_1000_trees_fixed_topology.nex")

write.nexus(orig_set, file="output/variable_topology/set_1.nex")

create_set <- function(i) {
    # var i should be from 1 to 999
    # drop i
    j <- i + 1
    set <- orig_set[j:1000]
    
    # append mct
    k <- i
    while( k > 0 ) {
        end <- 1001 - k
        set[[end]] <- mct
        k <- k - 1
    }
    
    # save set as set_i.nex
    write.nexus(set, file=paste0("output/variable_topology/set_", j, ".nex", sep=""));
}

mclapply(1:999, create_set);


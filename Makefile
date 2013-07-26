TREEANNOTATOR = /home/carlosp420/Desktop/phylo_software/BEASTv1.7.5/bin/treeannotator

####################################################################
# Create a set of 1000 trees that have each of the trees
# replaced with the MCT
tree_sets: output/set_1000.nex output/set_1000.nex_mct.nex
	
output/set_1000.nex: code/create_sets_of_1000_trees.R data/supp_mat01_genus.nex data/supp_mat_02_1000_random_trees_no_outgroups.nex
	R --save < code/create_sets_of_1000_trees.R
	# correct start of tree so that it can be read by BEAST
	sed -i 's/TREE\s\*\s*[tree]*\s*/tree /g' output/set_*nex

# use Treeannotator to get MCT for each set of 1000 trees
output/set_1000.nex_mct.nex: output/set_1000.nex
	ls output/set_*.nex | parallel $(TREEANNOTATOR) -burnin 0 -heights mean {} {}_mct.nex; done
	


####################################################################
# Run MEDUSA on our MCT tree
#
medusa_run: output/medusa_on_mct.txt output/medusa_on_mct.pdf

output/medusa_on_mct.txt output/medusa_on_mct.pdf: code/run_medusa_on_mct.R data/supp_mat01_genus.nex data/supp_mat_03_richness.csv
	Rscript code/run_medusa_on_mct.R data/supp_mat01_genus.nex output/medusa_on_mct.txt output/medusa_on_mct.pdf



####################################################################
# Run multiMEDUSA on our data
#
multiMEDUSA_run: output/raw_data.csv output/raw_data_summary.csv

output/raw_data.csv output/raw_data_summary.csv: data/supp_mat_02_1000_random_trees_no_outgroups.nex data/supp_mat01_genus.nex code/supp_mat_06_multiMEDUSA.R
	Rscript code/supp_mat_06_multiMEDUSA.R data/supp_mat_02_1000_random_trees_no_outgroups.nex data/supp_mat01_genus.nex output/raw_data_summary.csv output/raw_data.csv



####################################################################
# run MEDUSA on each of the 1000 MCTs and save some statistics
# * % high posterior probabilities
# * % low posterior probabilities
# breaks in mct
#
# run multiMEDUSA on the set for that mct and save some stats
# number of breaks found in more than 95% of the trees
1000_medusa_runs: output/set_9.nex_mct.nex_medusa.txt output/set_9.nex_mct.nex_medusa.pdf

output/set_9.nex_mct.nex_medusa.txt output/set_9.nex_mct.nex_medusa.pdf: code/run_medusa_on_mct.R output/set_9.nex_mct.nex data/supp_mat_03_richness.csv
	for f in output/*_mct.nex; do Rscript code/run_medusa_on_mct.R $$f "$$f""_medusa.txt" "$$f""_medusa.pdf"; done

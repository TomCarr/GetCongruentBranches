#' gets branch length estimates from congruent branches
#' @export

GetCongruentBranches <- function(species_tree_name, gene_trees_direc, zero_sample_overrule, loci_lengths, output_tree_name){

###get trees###
###############

gene_trees <- list.files(gene_trees_direc)
species_tree <- read.tree(species_tree_name)

###get locus length###
######################

if (length(loci_lengths) == 1){
loci_lengths <- rep(1, length(gene_trees))
names(loci_lengths) <- gene_trees
} 

###useful functions for getting names and clades###
###################################################

extract_names <- function(tree, nodes){
if (nodes > length(tree$tip.label)){
extract.clade(tree, nodes)$tip.label
} else {
tree$tip.label[nodes]
}
}

extract_clades <- function(tree, nodes){
if (nodes > length(tree$tip.label)){
extract.clade(tree, nodes)
} else {
tree$tip.label[nodes]
}
}

###get information about species tree###
########################################

message("getting species tree information...")
node_numbers <- species_tree[[1]][,2]
clades <- lapply(node_numbers, function(n) extract_clades(species_tree, n))
clades_names <- lapply(node_numbers, function(n) extract_names(species_tree, n))
clades_names_strings <- lapply(lapply(clades_names, sort), paste, collapse=" ")
message("got species tree information!")

##############################
######do the calculation######
##############################

branch_lengths <- vector("list", length(clades_names)) ### this is going to store branch length information across all the gene trees
loci_lengths_for_calc <- vector("list", length(clades_names))
message("now going to check each gene tree")
for (a in 1:length(gene_trees)){

###get gene tree and relevent information###
############################################
message(paste("working on gene tree ", gene_trees[[a]], sep=""))  
gene_tree <- read.tree(paste(gene_trees_direc, "/", gene_trees[[a]], sep=""))
gene_tree_node_numbers <- gene_tree[[1]][,2]
gene_tree_clades <- lapply(gene_tree_node_numbers, function(n) extract_clades(gene_tree, n))
gene_tree_clades_names <- lapply(gene_tree_node_numbers, function(n) extract_names(gene_tree, n))
gene_tree_clades_names_strings <- lapply(lapply(gene_tree_clades_names, sort), paste, collapse=" ")

###get information in species tree trimmed to gene tree sampling###
clades_names_strings_trimmed <- vector("list", length(clades_names))
for (b in 1:length(clades_names_strings_trimmed)){
test_names <- unlist(strsplit(clades_names_strings[[b]], split=" "))
if (length(which(test_names %in% gene_tree$tip.label == FALSE)) > 0){
clades_names_strings_trimmed[[b]] <- paste(sort(test_names[-which(test_names %in% gene_tree$tip.label == FALSE)]), collapse=" ")
} else {
clades_names_strings_trimmed[[b]] <- clades_names_strings[[b]]
}
}


###get branch length information when its just  tip###
######################################################
for (b in 1:length(branch_lengths)){
###if you are just dealing with a tip###
if (length(clades_names[[b]]) == 1){
###check if that tip is actually in the gene tree###
if (clades_names[[b]] %in% gene_tree$tip.label){
###check it doesn't branch from the root in the species tree (if it does we have a slightly different way of doing things)###
if (species_tree[[1]][,1][[b]] %in% species_tree[[1]][,2]){
###same check as above for the gene tree tip###
if (gene_tree[[1]][,1][which(gene_tree_clades_names_strings == clades_names_strings[[b]])] %in% gene_tree[[1]][,2]){
###is the ancestral clade identical###
if (clades_names_strings_trimmed[[which(species_tree[[1]][,2] == species_tree[[1]][,1][[b]])]] == gene_tree_clades_names_strings[[which(gene_tree[[1]][,2] == gene_tree[[1]][,1][which(gene_tree_clades_names_strings == clades_names_strings_trimmed[[b]])])]]){ # is the tip and its sister ###need a provision for root
###add the relevent branch to the branch length storer
branch_lengths[[b]] <- append(branch_lengths[[b]], gene_tree$edge.length[[which(gene_tree[[1]][,2] == which(gene_tree$tip.label == clades_names_strings_trimmed[[b]]))]])
loci_lengths_for_calc[[b]] <- append(loci_lengths_for_calc[[b]], loci_lengths[[which(names(loci_lengths) == gene_trees[[a]])]]) 
}
}
###check on if they both branch from the root
} else if ((species_tree[[1]][,1][which(species_tree[[1]][,2] == which(species_tree$tip.label == clades_names_strings_trimmed[[b]]))] == length(species_tree$tip.label)+1) & (gene_tree[[1]][,1][which(gene_tree[[1]][,2] == which(gene_tree$tip.label == clades_names_strings_trimmed[[b]]))] == length(gene_tree$tip.label)+1)){
###add the relevent branch to the branch length storer
branch_lengths[[b]] <- append(branch_lengths[[b]], gene_tree$edge.length[which(gene_tree[[1]][,2] == which(gene_tree$tip.label == clades_names_strings[[b]]))])
loci_lengths_for_calc[[b]] <- append(loci_lengths_for_calc[[b]], loci_lengths[[which(names(loci_lengths) == gene_trees[[a]])]])
} 
}
} else {
###if you are dealing with an internal branch###
################################################
###if the descendant clade is actually in the gene tree
if (clades_names_strings_trimmed[[b]] %in% gene_tree_clades_names_strings){
###get the two sides of the descendant clade - we need the descendant clade to define the same node
if (length(clades[[b]]$tip.label) > 2){ 
side_one <- extract.clade(clades[[b]], length(clades_names[[b]])+2)$tip.label
side_two <- clades_names[[b]][-which(clades_names[[b]] %in% side_one)]
} else {
side_one <- clades[[b]]$tip.label[[1]]
side_two <- clades[[b]]$tip.label[[2]]
}
###get the two reduced sides of the clade
if (length(which(side_one %in% gene_tree$tip.label == FALSE)) > 0){
reduced_side_one <- side_one[-which(side_one %in% gene_tree$tip.label == FALSE)]
} else {
reduced_side_one <- side_one
}
if (length(which(side_two %in% gene_tree$tip.label == FALSE)) > 0){
reduced_side_two <- side_two[-which(side_two %in% gene_tree$tip.label == FALSE)]
} else {
reduced_side_two <- side_two
}
###if the sampling reduced sides are in the gene tree
reduced_side_one_string <- paste(sort(reduced_side_one), collapse=" ")
reduced_side_two_string <- paste(sort(reduced_side_two), collapse=" ")
if ((reduced_side_one_string %in% gene_tree_clades_names_strings) & (reduced_side_two_string %in% gene_tree_clades_names_strings)){
###and if they form a single clade in the gene tree too
if (paste(sort(c(reduced_side_one, reduced_side_two)), collapse=" ") %in% gene_tree_clades_names_strings){      
###have to ensure anc node is not the root node
if ((species_tree[[1]][,1][[b]] %in% species_tree[[1]][,2]) & (gene_tree[[1]][,1][[which(gene_tree_clades_names_strings == clades_names_strings_trimmed[[b]])]] %in% gene_tree[[1]][,2])){
###now working on sister clade/tip
anc_clade_names <- clades_names[[which(species_tree[[1]][,2] == species_tree[[1]][,1][[b]])]]
alt_clade_names <- anc_clade_names[-which(anc_clade_names %in% clades_names[[b]])]
if (length(which(alt_clade_names %in% gene_tree$tip.label == FALSE)) > 0){
alt_clade_names_reduced <- alt_clade_names[-which(alt_clade_names %in% gene_tree$tip.label == FALSE)]
} else {
alt_clade_names_reduced <- alt_clade_names
}
######
if (length(alt_clade_names_reduced) > 0){
###do a check if we have the same ancestral clade
if (paste(sort(c(alt_clade_names_reduced, reduced_side_one, reduced_side_two)), collapse=" ") == gene_tree_clades_names_strings[[which(gene_tree[[1]][,2] == gene_tree[[1]][,1][[which(gene_tree_clades_names_strings == clades_names_strings_trimmed[[b]])]])]]){
###now add
branch_lengths[[b]] <- append(branch_lengths[[b]], gene_tree$edge.length[which(gene_tree_clades_names_strings == paste(sort(c(reduced_side_one, reduced_side_two)), collapse=" "))])
loci_lengths_for_calc[[b]] <- append(loci_lengths_for_calc[[b]], loci_lengths[[which(names(loci_lengths) == gene_trees[[a]])]])
}
}
} else if ((species_tree[[1]][,1][[b]] == length(species_tree$tip.label)+1) & (gene_tree[[1]][,1][[which(gene_tree_clades_names_strings == clades_names_strings_trimmed[[b]])]] == length(gene_tree$tip.label)+1)){
branch_lengths[[b]] <- append(branch_lengths[[b]], gene_tree$edge.length[[which(gene_tree_clades_names_strings == clades_names_strings_trimmed[[b]])]])
loci_lengths_for_calc[[b]] <- append(loci_lengths_for_calc[[b]], loci_lengths[[which(names(loci_lengths) == gene_trees[[a]])]])
}
}
}
}
}
}
}

if (zero_sample_overrule == FALSE){
if (length(which(unlist(lapply(branch_lengths, length)) == 0)) > 0){
message("zero sampling on some branches")
stop()
}
} else {
if (length(which(unlist(lapply(branch_lengths, length)) == 0)) > 0){
branch_lengths[which(unlist(lapply(branch_lengths, length)) == 0)] <- 0
loci_lengths_for_calc[which(unlist(lapply(loci_lengths_for_calc, length)) == 0)] <- 1 
}
}

information_tree <- species_tree
final_tree <- species_tree

###do weighted edge lengths###
##############################

for (a in 1:length(branch_lengths)){
branch_lengths[[a]] <- branch_lengths[[a]] * loci_lengths_for_calc[[a]]
branch_lengths[[a]] <- sum(branch_lengths[[a]])/sum(loci_lengths_for_calc[[a]])
}

final_tree$edge.length <- unlist(branch_lengths)
information_tree$edge.length <- unlist(lapply(loci_lengths_for_calc, sum))
write.tree(final_tree, output_tree_name)
write.tree(information_tree, paste("information_tree_", output_tree_name, sep=""))
}

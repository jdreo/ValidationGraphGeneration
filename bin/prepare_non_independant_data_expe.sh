#!/bin/bash
# /// script
# dependencies = [
#    "pooch<2.0.0,>=1.7.0",
#    "pandas<3.0.0,>=2.3.1",
#    "numpy<3.0.0,>=2.2.4",
#    "owlready2<1.0,>=0.49",
#    "jsonargparse<5.0,>=4.39",
#    "xdg-base-dirs<7.0.0,>=6.0.2",
#    "pandera[io]<1.0.0,>=0.27.0",
#    "alive-progress<4.0,>=3.2",
#    "fsspec<2026.0.0,>=2025.10.0",
#    "natsort>5.0.0",
#    "lxml>6.0.0",
#    "jmespath>=1.0.1",
#    "faker",
#    "pandas",
#    "petname",
#    "ontoweaver",
# ]
# ///

set -ex
set -o pipefail

NAME_OF_SCENARIO=$1
NUMBER_OF_LEARNING_DATA=$2
NUMBER_OF_VALIDATION_DATA=$3
NUMBER_OF_TEST_DATA=$4
EDGE_TO_LEARN=$5
NUMBER_OF_ABLATION=$6
SEED=$7
FIXED_EXPE=$8

PATH_TO_EXPE="${NAME_OF_SCENARIO}/${NUMBER_OF_LEARNING_DATA}/${NUMBER_OF_VALIDATION_DATA}/${NUMBER_OF_TEST_DATA}/${EDGE_TO_LEARN}/${NUMBER_OF_ABLATION}"

if [ $# -ne 6 ] ; then
echo "Usage: $0 <name_of_scenario> <nb_of_persons_in_learning_data> <nb_of_persons_in_validation_graph> <nb_of_persons_in_test_graph> <edge_to_learn> <nb_of_ablation_in_test_graph> " 1>&2
  exit 2
fi


BIN_DIR=$(realpath $(dirname $0))

EXPE=experiments/${NAME_OF_SCENARIO}/$(date -Iseconds|sed "s/:/_/g")
#EXPE=experiments/xxx
mkdir -p $EXPE
cd $EXPE


#git clone $BIN_DIR/.. graphGeneration
#git clone $BIN_DIR/../../biocypher biocypher

#uv sync

#Generate the independant learning, validation and test skgs
$BIN_DIR/prepare_expe.sh ${NAME_OF_SCENARIO} ${NUMBER_OF_LEARNING_DATA} ${NUMBER_OF_VALIDATION_DATA} ${NUMBER_OF_TEST_DATA} ${EDGE_TO_LEARN} ${NUMBER_OF_ABLATION}

# Add the lines of graph_validation.txt that contain ${EDGE_TO_PREDICT} in edges_for_validation.txt
# And the other ones in graph_learning_with_validation_and_test.txt
# And add all the validation graph to the ground truth graph
# grep "${EDGE_TO_LEARN}" "output/${PATH_TO_EXPE}/graph_validation.txt" >> "output/${PATH_TO_EXPE}/edges_for_validation.txt"
# grep -v "${EDGE_TO_LEARN}" "output/${PATH_TO_EXPE}/graph_validation.txt" > "output/${PATH_TO_EXPE}/graph_learning_dup.txt"
# cat "output/${PATH_TO_EXPE}/graph_learning.txt" >> "output/${PATH_TO_EXPE}/graph_learning_dup.txt" 
# cat "output/${PATH_TO_EXPE}/graph_learning.txt" "output/${PATH_TO_EXPE}/graph_validation.txt" > "output/${PATH_TO_EXPE}/ground_truth_dup.txt"
 

# Add the nodes and edges of the test graph EXCEPT THE EDGES TO BE PREDICTED to the ground truth graph
# cat "output/${PATH_TO_EXPE}/graph_test.txt" >> "output/${PATH_TO_EXPE}/graph_learning_dup.txt"
# Add the nodes and edges of the test graph to the ground truth graph
# cat "output/${PATH_TO_EXPE}/graph_test_gt.txt" >> "output/${PATH_TO_EXPE}/ground_truth_dup.txt"

# And add the edges to be queried in a edges_to_predict.txt file for BioPathNet
# $BIN_DIR/../src/generation/generate_edges_to_predict.py ${EDGE_TO_LEARN} "output/${PATH_TO_EXPE}/graph_test_gt.txt" "output/${PATH_TO_EXPE}/edges_to_predict.txt" 

# Remove duplicates
# sort -u "output/${PATH_TO_EXPE}/ground_truth_dup.txt" > "output/${PATH_TO_EXPE}/ground_truth.txt"
# sort -u "output/${PATH_TO_EXPE}/graph_learning_dup.txt" > "output/${PATH_TO_EXPE}/graph_learning_with_validation_and_test.txt"
# rm "output/${PATH_TO_EXPE}/ground_truth_dup.txt"
# rm "output/${PATH_TO_EXPE}/graph_learning_dup.txt"


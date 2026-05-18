#!/bin/sh

CONTAINER="../generate_BPN_dataset.sif"

if [[ ! -f $CONTAINER ]] ; then
    echo "ERROR: I do not see the apptainer container: generate_BPN_dataset.sif, please build it here before running this script." >&2
    exit 1
fi

if [ $# -ne 6 ] ; then
echo "Usage: $0 <name_of_scenario> <nb_of_persons_in_learning_data> <nb_of_persons_in_validation_graph> <nb_of_persons_in_test_graph> <edge_to_learn> <nb_of_ablation_in_test_graph>" 1>&2
  exit 2
else  
  NAME_OF_SCENARIO=$1
  NUMBER_OF_LEARNING_DATA=$2
  NUMBER_OF_VALIDATION_DATA=$3
  NUMBER_OF_TEST_DATA=$4
  EDGE_TO_LEARN=$5
  NUMBER_OF_ABLATION=$6
fi

module load apptainer

export APPTAINER_BINDPATH=$(pwd):/output/

apptainer run $CONTAINER ${NAME_OF_SCENARIO} ${NUMBER_OF_LEARNING_DATA} ${NUMBER_OF_VALIDATION_DATA} ${NUMBER_OF_TEST_DATA} ${EDGE_TO_LEARN} ${NUMBER_OF_ABLATION}


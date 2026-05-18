#!/bin/sh
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

NAME_OF_SCENARIO=$1
NUMBER_OF_LEARNING_DATA=$2
NUMBER_OF_VALIDATION_DATA=$3
NUMBER_OF_TEST_DATA=$4
EDGE_TO_LEARN=$5
NUMBER_OF_ABLATION=$6

PATH_TO_EXPE="${NAME_OF_SCENARIO}/${NUMBER_OF_LEARNING_DATA}/${NUMBER_OF_VALIDATION_DATA}/${NUMBER_OF_TEST_DATA}/${EDGE_TO_LEARN}/${NUMBER_OF_ABLATION}"

if [ $# -ne 6 ] ; then
echo "Usage: $0 <name_of_scenario> <nb_of_persons_in_learning_data> <nb_of_persons_in_validation_graph> <nb_of_persons_in_test_graph> <edge_to_learn> <nb_of_ablation_in_test_graph>" 1>&2
  exit 2
fi

BIN_DIR=$(realpath $(dirname $0))

#EXPE=experiments/$(date -Iseconds|sed "s/:/_/g")
# EXPE=experiments/xxx
# mkdir -p $EXPE
# cd $EXPE

# uv sync


#Generate learning data and skg
echo "Generate CSV data for learning skg" 1>&2
$BIN_DIR/../src/generation/generate_full_data.py ${NUMBER_OF_LEARNING_DATA} "output/${PATH_TO_EXPE}/data_learning.csv"
echo "Generate learning skg" 1>&2
$BIN_DIR/generate_one_skg.sh ${NAME_OF_SCENARIO} ${PATH_TO_EXPE} "learning" ${EDGE_TO_LEARN}


#Generate validation data and skg
echo "Generate CSV data for validation skg" 1>&2
$BIN_DIR/../src/generation/generate_full_data.py ${NUMBER_OF_VALIDATION_DATA} "output/${PATH_TO_EXPE}/data_validation.csv"
echo "Generate validation skg" 1>&2
$BIN_DIR/generate_one_skg.sh ${NAME_OF_SCENARIO} ${PATH_TO_EXPE} "validation" ${EDGE_TO_LEARN}

#Generate test data and skg
echo "Generate CSV data for test skg" 1>&2
$BIN_DIR/../src/generation/generate_full_data.py ${NUMBER_OF_TEST_DATA} "output/${PATH_TO_EXPE}/data_test.csv"
echo "Generate ground truth for test skg" 1>&2
$BIN_DIR/generate_one_skg.sh ${NAME_OF_SCENARIO} ${PATH_TO_EXPE} "test" ${EDGE_TO_LEARN}
mv "output/${PATH_TO_EXPE}/graph_test.txt" "output/${PATH_TO_EXPE}/graph_test_gt.txt"
 
echo "** Ablation of data in the test skg" 1>&2
$BIN_DIR/../src/generation/data_ablation.py $EDGE_TO_LEARN $NUMBER_OF_ABLATION "output/${PATH_TO_EXPE}/graph_test_gt.txt" "output/${PATH_TO_EXPE}/graph_test.txt" "output/${PATH_TO_EXPE}/test_relations.txt"

#Remove duplicates in brg.txt entity_types.txt and entity_names.txt

sort -u "output/${PATH_TO_EXPE}/brg.txt" > "output/${PATH_TO_EXPE}/brg_no_duplicates.txt"
rm "output/${PATH_TO_EXPE}/brg.txt" 
mv "output/${PATH_TO_EXPE}/brg_no_duplicates.txt" "output/${PATH_TO_EXPE}/brg.txt"

sort -u "output/${PATH_TO_EXPE}/entity_types.txt" > "output/${PATH_TO_EXPE}/entity_types_no_duplicates.txt"
rm "output/${PATH_TO_EXPE}/entity_types.txt" 
mv "output/${PATH_TO_EXPE}/entity_types_no_duplicates.txt" "output/${PATH_TO_EXPE}/entity_types.txt"

sort -u "output/${PATH_TO_EXPE}/entity_names.txt" > "output/${PATH_TO_EXPE}/entity_names_no_duplicates.txt"
rm "output/${PATH_TO_EXPE}/entity_names.txt" 
mv "output/${PATH_TO_EXPE}/entity_names_no_duplicates.txt" "output/${PATH_TO_EXPE}/entity_names.txt"




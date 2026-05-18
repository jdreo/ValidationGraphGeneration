#!/bin/sh
# To be ran from the experiment directory.
# Not from the source repository.

EXPE=$(date -Iseconds | sed s/:/_/g)
if [[ -n "$1" ]] ; then
    EXPE=$1
fi
mkdir -p $EXPE
echo "Output directory: $EXPE" >&2
cd $EXPE

VGG_BIN="../$(dirname $0)"

declare -A scenario
scenario['relatives_complex']='siblingOf'
# scenario['simplest']='childOf'
# scenario['parent_has_role']='hasRole'
# scenario['relatives_has_role']='hasRole'

#scenario['dataproperties_has_role']='hasRole'
#scenario['parent_class']='is_a'
#scenario['relatives_class']='is_a'
#scenario['dtaproperties_class']='is_a'

NUMBER_OF_LEARNING_DATA=50
NUMBER_OF_VALIDATION_DATA=5
NUMBER_OF_TEST_DATA=2
#EDGE_TO_LEARN=hasChild
NUMBER_OF_ABLATION=0

for SCENARIO in "${!scenario[@]}"
do
    EDGE_TO_LEARN=${scenario["$SCENARIO"]}
    sbatch --job-name=gBPN_${SCENARIO} \
    	--error=gBPN_n${s}_s%j.log \
    	--output=gBPN_n${s}_s%j.out \
    	$VGG_BIN/run_generate_BPN_dataset.sh ${SCENARIO} ${NUMBER_OF_LEARNING_DATA} ${NUMBER_OF_VALIDATION_DATA} ${NUMBER_OF_TEST_DATA} ${EDGE_TO_LEARN} ${NUMBER_OF_ABLATION} 
done


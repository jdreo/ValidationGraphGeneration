#!/usr/bin/env -S uv run --script
# /// script
# dependencies = [
#    "biocypher<1.0.0,>=0.11.0",
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
#    "neo4j_utils",
#    "faker",
#    "petname",
#    "ontoweaver",
# ]
# ///

import argparse
import re
import logging

# Cleaning of the graph before testing with BioPathNet.
# This post processing is temporally needed because the reasonner generates too many links.
# This is due to the fact that individuals with difefrent IRIs are considere to be potentially the
# same by the reasonner, unless the axiom differentFrom is stated in the ontology.
# This issue in the reasonning should be fixed either in the OWL writer of Biocypher or by using
# some tricks in the reasonning rules.
# 
# Takes:
#   - a (path to) tsv file representing a sematic network that can be given as input to BioPathNet;
#   - the path to the output skg file
# Produces:
#   - a new tsv training file for BioPathNet with unwanted edges from the initial network removed;


if __name__ == "__main__":

    parser= argparse.ArgumentParser()
    parser.add_argument("initial_file")
    parser.add_argument("output_graph_file")
    asked = parser.parse_args()

    logger = logging.getLogger()
    
    output_lines = []
    
    with open(asked.initial_file, 'r') as fin:
        with open(asked.output_graph_file, 'w') as fout:
            input_lines = fin.readlines()

            exp = re.compile(r'(?P<source>.*)[ \t]+(?P<relation>.*)[ \t]+(?P<target>.*)\n')
            for line in input_lines:
                match = exp.search(line)
                if match:
                    s = match.group("source")
                    t = match.group("target")
                    if s!=t:
                        logger.debug(f"adding {line}")
                        output_lines.append(line)                
                else:
                    logger.debug(f"adding {line} with no match")
                    output_lines.append(line)                
                        
            for line in output_lines:
                fout.write(f"{line}")

#!/usr/bin/env -S uv run --script
# /// script
# dependencies = [
#    "jsonargparse<5.0,>=4.39",
#    "neo4j>=5.8.0",
# ]
# ///

import os
import sys
import time
# import toml
import neo4j
import logging
import argparse
from neo4j.debug import watch

logging.getLogger().setLevel(logging.DEBUG)

neo4j_host = "neo4j://localhost:7687"
config = {
    "neo4j": {
        "uri": neo4j_host,
        "user": "neo4j",
        "database": "neo4j",
    }
}


#with open("neo4j.pass") as fd:
#    config["neo4j"]["passwd"] = fd.readline().strip()y
# config["neo4j"]["passwd"] = "neo4j"
# config["neo4j"]["auth"] = (config["neo4j"]["user"], config["neo4j"]["passwd"])


find_couples_query = "MATCH (p1:Person)-[SiblingOf]->(p2:Person)" \
                    "RETURN p1,p2"
queries = {
    "siblingOf": "MATCH (p2:Person)<-[:ParentOf]-(parent:Person)-[:ParentOf]->(p1:Person) " \
                 "WHERE (p1:Person)-[:SiblingOf]->(p2:Person) " \
                 "AND p1<>p2 " \
                 "RETURN DISTINCT p1, p2, parent",
}

explanations_template = {
    # "siblingOf": "(parent:Person)-[parentOf]->({{p1}}:Person) AND ({{parent}}:Person)-[parentOf]->({{p2}}:Person)", 
    "siblingOf": {
        "concepts": {
            "{p1_id}": {
                "ctype": "Person",
                "weigth": None,
            },
            "{p2_id}": {
                "ctype": "Person",
                "weigth": None,
            },
            "{parent_id}": {
                "ctype": "Person",
                "weigth": None,
            },
        },
        "relations": {
            "r1": {
                "rtype": "parentOf",
                "args": ["{parent_id}", "{p1_id}"],
                "weigth": None,
            },
            "r2": {
                "rtype": "parentOf",
                "args": ["{parent_id}", "{p2_id}"],
                "weigth": None,
            },
        },
    },
}


def instantiate_dict(input_dict, variables):
    result = {}
    for key, value in input_dict.items():
        key = key.format(**variables)
        if isinstance(value, dict):
            result[key] = instantiate_dict(value, variables)
        elif isinstance(value, str):
            result[key] = value.format(**variables)
        elif isinstance(value, list):
            result[key] = []
            for i, val in enumerate(value):
                result[key].append(val.format(**variables))
        else:
            result[key] = None
    return result


def query(link, output_file):
    """execute the query for explanations and construct the list of conceptual graph"""
#    watch("neo4j", out=sys.stdout)
    explanations = {}
    
    with neo4j.GraphDatabase.driver(config["neo4j"]["uri"]) as db:
        connected = False
        while not connected:
            connected = verify_connectivity(db)

        query = queries[link]
        records, _, keys = db.execute_query(
            query,
            name=config["neo4j"]["user"], database_ = config["neo4j"]["database"])

        for r in records:
            variables = {}
            for k in keys:
                variables[f"{k}_id"] = r[k]["id"]
            # explanation = instantiate_dict(explanations_template[link], {"parent_id": r["parent"]["id"], "p1_id": r["p1"]["id"], "p2_id": r["p2"]["id"]})
            explanation = instantiate_dict(explanations_template[link], variables)
            explanations[f"({r["p1"]["id"]}:Person)-[{link}]->({r["p2"]["id"]}:Person)"] = explanation

        with open(output_file, 'w') as out:
            print(explanations, file=out)
        

def verify_connectivity(db):
        try:
            db.verify_connectivity()
            logging.debug("Connection to DB OK")
            return True
        except neo4j.exceptions.ServiceUnavailable:
            logging.debug("Checking connection to DB")
            time.sleep(3)
            return False
        
            
    

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("link_to_predict")
    parser.add_argument("output")
    args = parser.parse_args()

    query(args.link_to_predict, args.output)
    

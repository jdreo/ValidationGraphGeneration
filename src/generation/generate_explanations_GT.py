#!/usr/bin/env -S uv run --script
# /// script
# dependencies = [
#    "jsonargparse<5.0,>=4.39",
#    "neo4j_utils",
# ]
# ///

import os
import toml
import neo4j
import logging
import argparse

logging.getLogger().setLevel(logging.DEBUG)

neo4j_host = "neo4j://localhost:7687"
config = {
    "neo4j": {
        "uri": neo4j_host,
        "user": "neo4j",
        # "base": "explanations_GT",
    }
}


#with open("neo4j.pass") as fd:
#    config["neo4j"]["passwd"] = fd.readline().strip()y
# config["neo4j"]["passwd"] = "neo4j"
# config["neo4j"]["auth"] = (config["neo4j"]["user"], config["neo4j"]["passwd"])


find_couples_query = "MATCH (p1:Person)-[siblingOf]->(p2:Person)" \
                    "RETURN p1,p2"
queries = {
    "siblingOf": "MATCH (parent:Person)-[parentOf]->({{p1}}:Person) AND (parent:Person)-[parentOf]->({{p2}}:Person)" \
                 "RETRUN parent, {{p1}}, {{p2}}"
}



def query(link, output_file):
    
    """execute the query for explanations and construct the list of conceptual graph"""
#    with neo4j.GraphDatabase.driver(config["neo4j"]["uri"]) as db:
#    with neo4j.GraphDatabase.driver(config["neo4j"]["uri"], auth=config["neo4j"]["auth"]) as db:
    with neo4j.GraphDatabase.driver(config["neo4j"]["uri"], encrypted=True, trust='TRUST_SYSTEM_CA_SIGNED_CERTIFICATES') as db:
        db.verify_connectivity()
        logging.debug(f"{find_couples_query}")
        couples, _, _ = db.execute_query(
            find_couples_query,
            name=config["neo4j"]["user"], database_ = config["neo4j"]["database"])

        explanations = {}
        app.logging.debug(f"│ {len(couples)} couples of nodes")
        for c in couples:
            p1 = c["p1"]
            p2 = c["p2"]
            query = queries[link].replace("{{p1}}", p1).replace("{{p2}}", p2)
            records, _, _ = db.execute_query(
                query,
                name=config["neo4j"]["user"], database_ = config["neo4j"]["database"])

            for r in records:
                explanation = r["query"].replace("parent", r["parent"])
                explanations[f"({p1}:Person)-[{link}]->({p2}:Person)"] = explanation

        with open(output_file, 'w') as out:
            print(explanations, file=out)
        

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("link_to_predict")
    parser.add_argument("output")
    args = parser.parse_args()

    query(args.link_to_predict, args.output)
    

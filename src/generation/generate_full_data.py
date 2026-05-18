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
#    "faker",
#    "petname",
#    "ontoweaver",
# ]
# ///

import argparse
import os
import sys
import pandas as pd

import logging
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

import random
from faker import Faker
from faker.providers import person

import petname
import itertools
getid = itertools.count().__next__

def generate_person(
	fake,
	df_data:pd.DataFrame ,
	accept_partner:bool ,
	age_min:int ,
	age_max:int ,
	last_name:str ,
	incr:str,
	) -> (dict, pd.DataFrame):

	suffix = '_'+incr

	if age_max > 0 :
		age_min=max(age_min, 0)
		try:
			id = str(fake.unique.random_int(min=11111111, max=99999999))+suffix
		except faker.exception.UniquenessException:
			fake.unique.clear()
			incr = str(int(incr)+1)
			suffix = '_'+incr
			id = str(fake.unique.random_int(min=11111111, max=99999999))+suffix

		#generate name, age, genre:
		age = random.randint(age_min, age_max)
		genre = "male" if random.choice([True, False]) else "female"
		first_name = fake.first_name_male() if genre=="male" else fake.first_name_female()
		if not last_name:
			last_name = fake.last_name()

		children = []
		pets = []
		partner = None

		tenant = True if random.choice([True, False]) and age > 18 else False
		owner = True if random.choice([True, False]) and age > 30 else False

		#Does the person has a partner ?
		if age>15 and accept_partner and random.choice([True, False]):
			p_last_name = fake.last_name()
			partner, df_data, incr = generate_person(fake=fake, df_data=df_data, accept_partner=False,
			                                         age_min=age_min, age_max = age_max,
			                                         last_name=p_last_name, incr=incr)

		#randomly decide if the individual (aged more than 20) has child
		if age > 20 and random.choice(range(2)):
			#randomly decide how many children he has
			nb_children = random.choice(range(4))

			for new_child in range(nb_children):
				new_child = None
				if genre == "male" or partner is None:
					new_child, df_data, incr= generate_person(fake=fake, df_data=df_data, accept_partner=True,
					                                          age_min=age-60, age_max = age-20,
					                                          last_name = last_name, incr=incr)
				else:
					new_child, df_data, incr = generate_person(fake=fake, df_data=df_data, accept_partner=True,
					                                           age_min=age-60, age_max = age-20,
					                                           last_name = partner["last_name"], incr=incr)
				if new_child is not None:
					children.append(new_child["id"])


		#randomly decide if the person has pets
		if random.choice([True, False]):
			nb_pets = random.choice(range(3))
			for p in range(nb_pets):
				pets.append(''.join([petname.Generate(2, '_'), str(getid()), "(", random.choice(["cat", "dog"]), ")"]))

		person = {"id": id ,
				"first_name": first_name ,
				"last_name": last_name ,
				"age": age ,
				"genre": genre ,
				"children" : ";".join(children) ,
				"partner" : partner['id'] if partner is not None else None ,
				"tenant" : tenant ,
				"owner" : owner ,
				"pets" : ";".join(pets) ,
				}

		df_data = pd.concat([df_data, pd.DataFrame([person])], ignore_index=True)
		return person, df_data, incr
	return None, df_data, incr

if __name__ == "__main__":

	parser = argparse.ArgumentParser()
	parser.add_argument("nb_persons")
	parser.add_argument("output_file_name")
	parser.add_argument("-s", "--seed", type=int, default=0, metavar="INT",
	    help="Pseudo-random generator seed (0 = epoch, the default).")
	args = parser.parse_args()
	logger.info(f"args = {args}")

	random.seed(args.seed)

	fake = Faker()
	fake.add_provider(person)

	#Data to be exported
	df = pd.DataFrame(columns=["first_name", "last_name", "genre", "age", "partner", "children", "pets",
	                  "tenant", "owner"])

	p=None

	# create nb of persons to be first level individuals.
	# Other individuals (partners, children and grand-children) are created recursively from them.
	incr = '0'
	for n in range(int(args.nb_persons)):
		p, df, incr = generate_person(fake = fake, df_data = df, accept_partner = True, age_min=10, age_max=100,
		                              last_name=None, incr=incr)

	logger.info(f"Generated dataset = {df}")
	dir = os.path.dirname(args.output_file_name)
	if not str(dir)=="" and not os.path.exists(dir):
		os.makedirs(dir)

	df.to_csv(args.output_file_name, sep=',')

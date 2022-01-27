
from subprocess import check_call
import os

import requests
import click


@click.command()
@click.argument('output_dir')
def download_genomes(output_dir):
    location_url = 'http://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/genome_locations.txt'
    location_of_genomes = requests.get(location_url).text.strip().split("\n")
    location_dna_genomes = [path for path in location_of_genomes if "Bisulfite" not in path]
    if len(location_dna_genomes) > 1:
        raise Exception(f"Found too many genome locations: {location_dna_genomes}")

    check_call(['wget', '-r', '--no-parent', '-R', 'index.html*',
                '--no-host-directories', '--cut-dirs=1',
                '--directory-prefix', output_dir,
                location_dna_genomes[0]])


if __name__ == "__main__":
    download_genomes()

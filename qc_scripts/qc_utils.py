import argparse
import subprocess


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Processing script for all subjects in the OSIPI ASL Challenge submission.")
    parser.add_argument("--challenge_dir",
                        help="OSIPI directory which contains the `Population_based` and "
                             + "`synthetic` directories.",
                        required=True)
    parser.add_argument("--intermediate",
                        help="Provide the name of an intermediate results directory. "
                             + "By providing a different value for this argument on each "
                             + "run you can avoid overwriting the results from other runs.",
                        default="")
    parser.add_argument("--quiet",
                        help="If provided, the pipeline won't print as much infomation "
                             + "on what the pipeline is doing to the command line.",
                        action="store_true")
    parser.add_argument("--debug",
                        help="If provided, the pipeline will retain intermediate "
                             + "for inpsection. If not, only the files required for "
                             + "OSIPI submission will be retained.",
                        action="store_true")
    args = parser.parse_args()

    osipi_dir = Path(args.challenge_dir).resolve(strict=True)
    population_dir = (osipi_dir / "Population_based").resolve(strict=True)
    synthetic_dir = (osipi_dir / "synthetic").resolve(strict=True)
import argparse
import subprocess
from pathlib import Path
import preprocess
"""
module load fsl-img
module load conda-img/python3.7
source activate toblerone
"""
# python cal_IQMs.py --oxasl_dir /gpfs01/imgshare/TILDA/test_pipeline/DATA/sub-1267031/oxasl_vol --pvc --reg  --rois_dir /gpfs01/imgshare/TILDA/test_pipeline/scripts/ASL_QC_package/rois.txt  --verbose
# python cal_IQMs.py --oxasl_dir /gpfs01/imgshare/TILDA/test_pipeline/DATA/sub-1267031/oxasl_vol --pvc --rois_dir /gpfs01/imgshare/TILDA/test_pipeline/scripts/ASL_QC_package/rois.txt  --verbose
# python cal_IQMs.py --oxasl_dir /gpfs01/imgshare/TILDA/test_pipeline/DATA/sub-1267031/oxasl_vol  --rois_dir /gpfs01/imgshare/TILDA/test_pipeline/scripts/ASL_QC_package/rois.txt  --verbose
# python cal_IQMs.py --oxasl_dir /gpfs01/imgshare/TILDA/test_pipeline/DATA/sub-1267031/oxasl_vol
if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="ASL quality control package")

    parser.add_argument("--oxasl_dir",
                        help="Path to oxasl output directory",
                        required=True)

    parser.add_argument("--pvc",
                        help="Partial Volume Effects Correction was performed or not",
                        action="store_true",
                        required=False
                        )

    parser.add_argument("--reg",
                        help="Measure the quality of registration to standard space",
                        action="store_true",
                        required=False
                        )

    parser.add_argument("--rois_dir",
                        help="A text file containing the region analysis",
                        required=False
                        )

    parser.add_argument("--verbose",
                        help="Print logs",
                        action="store_true",
                        required=False
                        )


    args = parser.parse_args()

    oxasl_dir = Path(args.oxasl_dir).resolve(strict=True)


    if args.rois_dir is not None:
        rois_dir = Path(args.rois_dir).resolve(strict=True)
        preprocess.preprocess(wsp=oxasl_dir, pvc=args.pvc, rois_dir=rois_dir, reg = args.reg, verbose=args.verbose)
    else:
        preprocess.preprocess(wsp=oxasl_dir, pvc=args.pvc, reg = args.reg, verbose=args.verbose)



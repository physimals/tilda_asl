# TILDA_ASL
Analysis pipeline code for ASL data from The Irish Longitudinal study on Ageing.


## Data Characterics

474 subjects (T1+pcASL) were available after preprocessing, and 423 subjects were used for this study, details were explained in the derived paper [1].

## Pre-Processing pipeline

All related processing scripts are located in the script folder.

### T1w images

T1 images were processed using HCP pipeline on High Performance Computer Ada of University of Nottingham.

## ASL images

Oxasl [2] was used to process the ASL data. Partial Volumes (PVs) from FAST were used for the volumetric pipeline, while PVs from Toblerone were used for the surface-based pipeline. Multimodel Suface Matching (MSM) from HCP workbench was used to project ASL images onto the cortical surface. 


## Statistical Analysis


## Quality Control Report



[1] Hu, J., Craig, M. S., Knight, S. P., De Looze, C., Meaney, J. F., Kenny, R. A., Chen, X., & Chappell, M. A. (2024). Regional changes in cerebral perfusion with age when accounting for changes in gray-matter volume. Magnetic resonance in medicine, 10.1002/mrm.30376. Advance online publication. https://doi.org/10.1002/mrm.30376

[2] https://github.com/physimals/oxasl


Continuous update of the egocentric view via self-motion is beneficial to allocentric representations in ageing
======

## Description 
This repository contains the full dataset and the scripts for generating the analysis and the figures from _"Continuous updating via self-motion compensates for weak allocentric spatial  memory in ageing"_[^1].

## Task Demonstration Video

[![Watch the video](https://github.com/Lenakeiz/Allocentric-VR-Analysis/blob/Review/Video/QueenSquareVRScreenshot.png)](https://github.com/Lenakeiz/Allocentric-VR-Analysis/raw/Review/Video/QueenSquareVR_MovementConditions_Video.mp4)

Click the image above to download the video showcasing the Queen Square VR task.

## Installation
Clone the repository anywhere in your machine using `git clone` command. 
Open the folder in Matlab by making sure to add folders and subfolders to the path.

## Package dependency
Developed using Matlab R2024a.

Requires the following MATLAB toolboxes:

- [Statistics and machine learning](https://uk.mathworks.com/products/statistics.html)

The project also contains a copy of the following additional packages:

- [Ahmed BenSaïda (2025). Shapiro-Wilk and Shapiro-Francia normality tests.](https://www.mathworks.com/matlabcentral/fileexchange/13964-shapiro-wilk-and-shapiro-francia-normality-tests)
- [xml2struct](https://github.com/joe-of-all-trades/xml2struct)

## Usage
To reproduce the analysis, first run `QSVR_LoadData.m`, which loads the data, performs preprocessing, and extracts all of the key metrics.

Subsequent analysis scripts are located in the **Analysis** folder. These scripts generate the analyses and the figures presented in the paper. Note that script filenames describe the analyses they perform, rather than corresponding directly to specific figure numbers.

Plots will be displayed in MATLAB and also saved in the **Output** folder, which will be created automatically if it does not already exist.

SPSS analysis results are provided in the **SPSS_Output** folder.

For further details on preprocessing and analysis, please refer to the Methods section of the main article and the supplementary information.

---
[^1]: Andrea Castegnaro✉️, Alex Dior, Neil Burgess, John King        ✉️ andrea.castegnaro.15@ucl.ac.uk

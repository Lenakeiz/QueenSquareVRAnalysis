Continuous update of the egocentric view via self-motion is beneficial to allocentric representations in ageing
======

![Figure 1](https://github.com/Lenakeiz/Allocentric-VR-Analysis/blob/main/Images/Fig1_smallSelection.png)

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
Start by running `QSVR_LoadData.m` to load, preprocess, and extract key metrics from the data.
To generate figures from the paper, run the scripts in the **Analysis** folder. 
Script names relate to the analyses they perform rather than to the specific figuer numbers. 
preprocess and extract the metrcis of interest.
Plots will be displayed in MATLAB but will also be saved in the **Output** folder.
SPSS results can be found in the **SPSS_Output** folder.

For details on preprocessing and analysis, refer to the Methods section of the paper.

---
[^1]: Andrea Castegnaro✉️, Alex Dior, Neil Burgess, John King        ✉️ andrea.castegnaro.15@ucl.ac.uk
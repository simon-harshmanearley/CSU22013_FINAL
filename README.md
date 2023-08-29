Design and implement a dashboard to visualise and compare commit
activity for trending repositories on GitHub
================

- [:blue_book: Overview](#blue_book-overview)
- [:heavy_exclamation_mark:
  Requirements](#heavy_exclamation_mark-requirements)
  - [R / R-Studio](#r--r-studio)
  - [Shiny](#shiny)
- [:heavy_exclamation_mark: APIs](#heavy_exclamation_mark-apis)
  - [github-trending-api](#github-trending-api)
  - [GitHub REST API](#github-rest-api)
- [:floppy_disk: Scripts](#floppy_disk-scripts)
  - [CSU22013_SHE_FINAL](#csu22013_she_final)
- [Contributors](#contributors)

# :blue_book: Overview

A HR recruitment tool for tech companies looking to hire motivated
developers based on top trending GitHub repositories. Items on dashboard
include   
- A percentage stacked bar plot  
- A grouped bar plot  
- An information table

# :heavy_exclamation_mark: Requirements

The software packages below must be installed a prerequisite to viewing
the code

### R / R-Studio

R-Studio is required in order to review the code  
Installation guide:
<https://rstudio-education.github.io/hopr/starting.html>

### Shiny

Shiny is used to build and deploy the project web app, and must be
installed within R-Studio in order to run the code  
Installation guide:
<https://shiny.posit.co/r/getstarted/shiny-basics/lesson1/index.html>

# :heavy_exclamation_mark: APIs

#### github-trending-api

This API is used to fetch the URLs of each trending repository  
<https://github.com/alisoft/github-trending-api>

### GitHub REST API

This API utilises the URLs fetched from github-trending-api in order to
fetch the commit data. A GitHub token is required in order to call to
the API  
<https://docs.github.com/en/rest/quickstart?apiVersion=2022-11-28>

Paste your own access token into API_PAT in the code.  
From here all of the functions are available to call. See the code
comments for more details.

# :floppy_disk: Scripts

### CSU22013_SHE_FINAL

Primary RMD file used

# Contributors

Simon Harshman-Earley <harshmas@tcd.ie>

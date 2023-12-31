# Libraries
library(httr)
library(jsonlite)
library(furrr)
library(shiny)
library(shinyjs)
library(plotly)
library(dplyr)
library(tidyr)
library(scales)
library(ggplot2)
library(DT)
library(shinycssloaders)

# Shiny hosting token
#rsconnect::setAccountInfo(name='sihaea', token='A383C1C26BF2056798E8574E2D9327BA', secret='z6Z3Fyk079C+RdqJuVyqKFj6Oi49NNdmyOEaudeo')
rsconnect::setAccountInfo(name='tcdsihaea', token='072B94F9254E28B9FEECBB25F3E8205F', secret='eoF3vHnO6SPDntLQjvv6FWVt2JViyZhE/M1X39cN')

# Shiny hosting library
library(rsconnect)
rsconnect::deployApp(forceUpdate = TRUE, appName="githubrecruitment")
#rsconnect::showLogs(appName="githubrecruitment",streaming=TRUE)

# Personal Access Token for GitHub API1
API_PAT <<- c(Authorization = paste("Bearer", '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'))
PAGE_LIMITS <<- 5

# default values for selections in left menu
# daterange = 'daily'
# language = 'all'

# Function: Get list of base URLs for trending repositories
API_1_create_urls <- function(date_range){
  #print('###################### API_1 ######################')
  # Call to MIT GitHub API to get information on current top trending repositories
  url <- "https://api.gitterapp.com/repositories?since=daily"
  response <- GET(url, query = list(since = date_range))
  repo_data <- content(response)
  
  # Retrieve list of trending authors
  repo_author <- lapply(repo_data, "[[", 1)
  
  # Retrieve list of trending repository names
  repo_name <- lapply(repo_data, "[[", 2)
  
  # Function: Manually create base URL to repository
  create_url <- function(repo_author, repo_name) {
    url <- paste0("https://api.github.com/repos/", repo_author, "/", repo_name)
    return(url)
  }
  
  # Create list of URLs to top repositories
  url <- mapply(create_url, repo_author, repo_name, SIMPLIFY = FALSE)
  url_list <- as.character(url)
  
  return(url_list)
}

# languageDataFrame
# Function to fetch language percentages per repository
create_language_dataframe <- function() {
  #print('###################### API_2 ######################')
  # Initialise list
  language_data_list <- list()
  
  # Loop through each URL
  for (url in GIT_URLS) {
    
    repo_name <- strsplit(url, "/")[[1]][6]  # Get repository name from URL
    url <- paste0(url, "/languages")         # Append /languages to base URL
    
    response <- GET(url, add_headers(API_PAT))
    language_data <- content(response)
    
    if(length(language_data) == 0){
      GIT_URLS = GIT_URLS[-which(GIT_URLS == url)]
      next
    }
    
    # Convert language_data into a data frame
    language_df <- data.frame(
      repository = repo_name,
      language = names(language_data),
      percentage = unlist(language_data)
    )
    
    language_data_list[[repo_name]] <- language_df
  }
  
  # Combine all language dataframes into a single dataframe
  language_table <- bind_rows(language_data_list)
  
  # Pivot the data into wide format
  language_table <- language_table %>%
    pivot_wider(
      names_from = language,
      values_from = percentage,
      values_fill = 0
    )
  
  # Tibble -> df
  language_table = as.data.frame(language_table)
  # Colnames
  rownames(language_table) = language_table$repository
  language_table$repository <- NULL
  
  # Calculate the row sums
  row_sums <- rowSums(language_table)
  
  # Calculate the percentage of each column by row to 2 decimal places
  language_table <- round(language_table / row_sums, 2)
  
  #Remove languages that contribute less than 1% of the code
  language_table <- language_table[,colSums(language_table != 0) > 0]
  
  return(language_table)
}

# filteredLanguageDataFrame
# Function: Create data frame to display the top 5 trending repositories, filtering by programming language. "All" returns top 5 generally
create_filtered_top_n_language_dataframe <- function(language, language_df, n = 5) {
  # print('create_filtered_top_n_language_dataframe')
  if (language == "All") {
    # Select the top n repositories based on trendiness
    return(head(language_df, n))
  }
  
  # Get the index of the chosen language in the data frame
  language_index <- which(colnames(language_df) == language)
  
  # Filter out repositories with zero% of chosen language
  filtered_repositories <- language_df[language_df[, language_index] > 0, ]
  
  # Select repositories, considering the case of less than n repositories
  num_repositories <- min(nrow(filtered_repositories), n)
  top_repositories <- filtered_repositories[1:num_repositories, ]
  
  return(top_repositories)
}

# commitDataFrame
# Function: Get the entire commit history of n number of repositories from top trending
create_commits_dataframe <- function() {
  #print('create_commits_dataframe')
  # Initialize an empty data frame to store the commit information
  cols = c('repo','dev_name','email','datetime')
  data_table = data.frame(matrix(nrow = 0, ncol = length(cols))) 
  colnames(data_table) = cols
  
  # Loop through each commit activity URL
  for (url in GIT_URLS_FILTERED) {
    
    # Append /commits to base URL
    url <- paste0(url, "/commits")
    
    page <- 1
    
    while (page <= PAGE_LIMITS) {
      page_url <- paste0(url, "?per_page=100&page=", page)
      response <- GET(page_url, add_headers(API_PAT))
      commit_data <- content(response)
      
      # Break if no more commits
      if (length(commit_data) == 0) {
        break  
      }
      
      df <- data.frame(
        repo = c(strsplit(unlist(lapply(commit_data, function (x) x$commit$tree$url)), "/")[[1]][6]),
        dev_name = c(unlist(lapply(commit_data, function (x) x$commit$author$name))),
        email = c(unlist(lapply(commit_data, function (x) x$commit$author$email))),
        datetime = c(unlist(lapply(commit_data, function (x) x$commit$author$date)))
      )
      
      # Add commit data to main data frame
      data_table <- rbind(data_table, df) 
      page <- page + 1
    }
    
  }
  
  return(data_table)
}

# Function: Retrieve a list of all of the languages used in top repositories
get_list_of_languages <- function(language_df){
  #print('get_list_of_languages')
  return(colnames(language_df))
  
}

# Function: Get the URLs from list of repositories
get_urls_from_list_of_repo_names  = function(language_df){
  #print('get_urls_from_list_of_repo_names')
  filtered_urls <- list()
  for(url in GIT_URLS){
    name <- strsplit(url, "/")[[1]][6]
    if(name %in% rownames(language_df)){
      filtered_urls[name] <- url
    }
  }  
  
  return(filtered_urls)
}

# Function: Count of all commits grouped by repo and then developer. Email for each developer included
count_commits_by_DevRepo <- function(commits_df){
  #print('count_commits_by_DevRepo')
  aggregatedDataFrame = aggregate(email ~ dev_name + repo, data = commits_df, FUN = length)
  aggregatedDataFrame = setNames(aggregatedDataFrame, c('dev_name', 'repo', 'count'))
  aggregatedDataFrame = merge(x = aggregatedDataFrame, y = commits_df[,c('dev_name','email')], by = 'dev_name')
  
  aggregatedDataFrame <- aggregatedDataFrame[!duplicated(aggregatedDataFrame[c("dev_name", "repo", "count", "email")]), ]
  
  aggregatedDataFrame <- aggregatedDataFrame[order(aggregatedDataFrame$repo, -aggregatedDataFrame$count),]
  
  return(aggregatedDataFrame)
}

# Function: Get the top n developers, per top n repository
top_n_commiters_per_repo <- function(commits_count, n = 5) {
  #print('top_n_commiters_per_repo')
  # Get unique repos 
  unique_repos <- unique(commits_count$repo)
  
  # Create new data frame to store top n data
  result_df <- data.frame(dev = character(0), repo = character(0), counts = numeric(0))
  
  # Loop through each repository
  for (repo in unique_repos) {
    repo_data <- commits_count[commits_count$repo == repo, ]  # Get rows for each repo
    top_devs <- repo_data[order(-repo_data$count), ][1:min(dim(repo_data)[1],n), ] # Order by count and get top n devs
    result_df <- rbind(result_df, top_devs) # Add results to new data frame
  }
  
  row.names(result_df) <- 1:nrow(result_df)
  
  
  
  return(result_df)
}

# Function: Create a percentage stacked bar plot for total languages used within top n repositories
graph_languages <- function(df){
  
  # print('graph_languages')
  # Find columns where all values are 0
  cols_to_remove <- colnames(df)[apply(df, 2, function(col) all(col == 0))]
  
  # Remove zero value columns
  df_filtered <- df[, !(colnames(df) %in% cols_to_remove)]
  
  language_matrix <- t(as.matrix(df_filtered))
  
  # Get remaining repository names
  repo_names <- rownames(df_filtered)
  
  stacked_barplot <- plot_ly()
  
  # Add a trace for each programming language
  for (i in 1:nrow(language_matrix)) {
    stacked_barplot <- stacked_barplot %>%
      add_trace(
        x = repo_names,
        y = language_matrix[i, ],
        type = "bar",
        name = rownames(language_matrix)[i]
      )
  }
  
  # Generate bar plot
  stacked_barplot <- stacked_barplot %>%
    layout(
      title = "Programming Languages Used in Trending Projects",
      xaxis = list(title = "Repository"),
      yaxis = list(title = "Percentage"),
      barmode = "stack"
    )
  
  return(stacked_barplot)
}

# Function: Create a grouped barplot of top n developers for top n repos, commit counts

graph_commits <- function(df) {
  # print('graph_commits')
  plot <- plot_ly(df, 
                  x = ~repo, 
                  y = ~count, 
                  text = ~paste("Developer: ", dev_name, "<br>No. Commits: ", count), 
                  hoverinfo = 'text', 
                  type = 'bar', 
                  split = ~dev_name) %>%
    layout(
      title = 'Most Active Developers',
      xaxis = list(title = 'Repository'),
      yaxis = list(title = 'Number of Commits'),
      barmode = 'group'
    )
  return(plot)
}

# Function: Create an information table to display referenced developers information - name, repository, email address

create_dev_info_table <- function(df){
  
  return(datatable(df[, -which(names(df) == "count")],options = list(scrollY = "300px")))
  
}

# Function: Retrieves data for programming languages percentage stacked bar chart
stackedLanguageBarplot <- function(language_df_filtered) {
  
  return(graph_languages(language_df_filtered)) 
  
}

# Function: Retrieves data for developer information table
dev_info_table <- function(commits_count) {
  
  return(create_dev_info_table(commits_count))
  
}

# Function: Retrieves data for commit count bar plot graph
groupedCommitsBarplot <- function(commits_count) {
  
  return(graph_commits(commits_count))
  
}

date_range_event <- function(date_range){
  GIT_URLS <<- API_1_create_urls(date_range)
  # Create data frame of repositories, programming languages, and language percentages
  LANGUAGE_DF <<- create_language_dataframe()
}

language_event <- function(input, output, language){
  
  print(language)
  
  language_df_filtered = create_filtered_top_n_language_dataframe(language, LANGUAGE_DF)
  
  GIT_URLS_FILTERED <<- get_urls_from_list_of_repo_names(language_df_filtered)
  
  commits_df = create_commits_dataframe()
  
  # Count number of commits for each developer
  commits_count = count_commits_by_DevRepo(commits_df)
  
  # Calculate top 5 developers for each repo, based on number of commits
  commits_count = top_n_commiters_per_repo(commits_count)
  
  # Display stacked language bar plot
  output$stackedBarplot <- renderPlotly({
    stackedLanguageBarplot(language_df_filtered)
  })
  
  # Display developer info table 
  output$table <- renderDT({
    dev_info_table(commits_count)
  })
  
  # Display grouped commits bar plot
  output$groupedBarplot <- renderPlotly({
    groupedCommitsBarplot(commits_count)
  })
  
  return(output)
}

# Function: Populates drop-down list
getLanguages <- function() {
  
  dropdown_list <- sort(get_list_of_languages(LANGUAGE_DF))
  dropdown_list <- c("All", dropdown_list)
  
  return(dropdown_list)
}

date_range_event('daily')

# Run the Shiny app
shinyApp(ui, server)
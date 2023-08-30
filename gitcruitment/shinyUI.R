ui <- shinyUI(fluidPage(
  
  titlePanel("Developer Recruitment Tool"),
  
  sidebarLayout(
    # Date range drop-down menu
    sidebarPanel(width = 2, selectInput(
      "date_range_dropdown",
      "GitHub Date Range:",
      choices = c("Daily", "Weekly", "Monthly")
    ),
    selectInput(
      # Language drop-down menu
      "language_dropdown",
      "Programming Language:",
      choices = getLanguages()
    )),
    mainPanel(
      withSpinner(plotlyOutput("groupedBarplot")),
      withSpinner(plotlyOutput("stackedBarplot")),
      withSpinner(dataTableOutput("table"))
    )
  )
))
# Define server function
server <- shinyServer(function(input, output, session) {
  
  observeEvent(input$date_range_dropdown, {
    
    # Update data from GitHub
    date_range_event(input$date_range_dropdown)
    
    # Update language input with new languages
    updateSelectInput(session, "language_dropdown", choices = getLanguages())
  })
  
  observeEvent(input$language_dropdown,{
    output <- language_event(input, output, input$language_dropdown)
    
  })
  
})
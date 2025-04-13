# Install required packages if not already installed
repo_url <- "https://cloud.r-project.org/"
if (!require("DT")) install.packages("DT", repos = repo_url)
if (!require("shiny")) install.packages("shiny", repos = repo_url)
if (!require("ggplot2")) install.packages("ggplot2", repos = repo_url)
if (!require("shinychat")) install.packages("shinychat", repos = repo_url)
if (!require("ellmer")) install.packages("ellmer", repos = repo_url)

library(shiny)
library(ggplot2)
library(DT)
library(ellmer)
library(shinychat)

ui <- fluidPage(
  titlePanel("Exploratory Data Analysis"),
  sidebarLayout(
    sidebarPanel(
      selectInput("dataset", "Choose Dataset", choices = c("Upload CSV", "mtcars", "iris")),
      conditionalPanel(
        condition = "input.dataset == 'Upload CSV'",
        fileInput("file", "Upload CSV File", accept = ".csv")
      ),
      uiOutput("var_select"),
      uiOutput("bin_slider"),  # Dynamic bin width control
      actionButton("submit", "Generate Plot/Table", class = "btn-primary"),
      hr(),
      h4("AI Assistant Settings"),
      selectInput("llm_provider", "Choose LLM Provider",
                  choices = c("Anthropic Claude", "OpenAI GPT")),
      conditionalPanel(
        condition = "input.llm_provider == 'Anthropic Claude'",
        passwordInput("claude_api_key", "Enter Anthropic API Key")
      ),
      conditionalPanel(
        condition = "input.llm_provider == 'OpenAI GPT'",
        passwordInput("openai_api_key", "Enter OpenAI API Key"),
        selectInput("openai_model", "Select GPT Model",
                   choices = c("gpt-4", "gpt-3.5-turbo"))
      ),
      actionButton("submit_api", "Submit API Key", class = "btn-info"),
      textOutput("api_status")
    ),
    mainPanel(
      plotOutput("plot"),
      DT::dataTableOutput("summary_table"),
      hr(),
      chat_ui("chat")
    )
  )
)

server <- function(input, output, session) {
  data <- reactive({
    if (input$dataset == "Upload CSV") {
      req(input$file)
      read.csv(input$file$datapath)
    } else if (input$dataset == "mtcars") {
      mtcars
    } else if (input$dataset == "iris") {
      iris
    }
  })
  
  output$var_select <- renderUI({
    req(data())
    selectInput(
      "variable", 
      "Select Variable", 
      choices = names(data()),
      selected = names(data())[1]
    )
  })
  
  # Dynamic bin width slider based on the selected variable
  output$bin_slider <- renderUI({
    req(data(), input$variable)
    if (is.numeric(data()[[input$variable]])) {
      var_range <- diff(range(data()[[input$variable]], na.rm = TRUE))
      default_bins <- min(30, max(10, floor(sqrt(length(data()[[input$variable]])))))
      default_binwidth <- var_range / default_bins
      
      sliderInput(
        "binwidth",
        "Bin Width:",
        min = default_binwidth / 5,
        max = default_binwidth * 5,
        value = default_binwidth,
        step = default_binwidth / 10
      )
    }
  })
  
  output$plot <- renderPlot({
    req(input$submit, input$variable)
    isolate({
      if (is.numeric(data()[[input$variable]])) {
        ggplot(data(), aes_string(x = input$variable)) +
          geom_histogram(binwidth = input$binwidth, fill = "blue", color = "white", alpha = 0.7) +
          theme_minimal() +
          labs(title = paste("Histogram of", input$variable), x = input$variable, y = "Frequency")
      } else {
        showNotification("Selected variable is not continuous.", type = "error")
        return(NULL)
      }
    })
  })
  
  output$summary_table <- DT::renderDT({
    req(input$submit, input$variable)
    isolate({
      if (!is.numeric(data()[[input$variable]])) {
        table_data <- as.data.frame(table(data()[[input$variable]]))
        colnames(table_data) <- c("Category", "Count")
        datatable(table_data)
      } else {
        return(NULL)
      }
    })
  })
  
  # Store chat object and API status
  chat_obj <- reactiveVal(NULL)
  api_status <- reactiveVal("Please enter and submit your Anthropic API key")
  
  # Handle API key submission
  observeEvent(input$submit_api, {
    if (input$llm_provider == "Anthropic Claude") {
      req(input$claude_api_key)
      api_key <- input$claude_api_key
    } else {
      req(input$openai_api_key)
      api_key <- input$openai_api_key
    }
    
    tryCatch({
      # Try to create a chat object based on selected provider
      chat <- if (input$llm_provider == "Anthropic Claude") {
        chat_claude(
          system_prompt = "You are a helpful data analyst. Analyze the current data and answer questions about statistical patterns and distributions.",
          api_key = api_key
        )
      } else {
        chat_openai(
          model = input$openai_model,
          system_prompt = "You are a helpful data analyst. Analyze the current data and answer questions about statistical patterns and distributions.",
          api_key = api_key
        )
      }
      
      # Test the API key with a simple query
      test_response <- chat$chat("Hi")
      
      # If successful, store the chat object and update status
      chat_obj(chat)
      api_status("API key verified and ready to use!")
    }, error = function(e) {
      # If there's an error, update status
      api_status(paste("Error:", e$message))
      chat_obj(NULL)
    })
  })
  
  # Display API status
  output$api_status <- renderText({
    api_status()
  })
  
  # Handle chat messages
  observeEvent(input$chat_user_input, {
    if (is.null(chat_obj())) {
      chat_append("chat", "Please enter a valid API key first.")
      return()
    }
    
    # Get current variable statistics to provide context
    selected_var <- input$variable
    if (!is.null(selected_var)) {
      var_data <- data()[[selected_var]]
      if (is.numeric(var_data)) {
        context <- sprintf(
          "Currently analyzing: %s (numeric variable)\nSummary stats: Mean=%.2f, Median=%.2f, SD=%.2f\n\n",
          selected_var,
          mean(var_data, na.rm = TRUE),
          median(var_data, na.rm = TRUE),
          sd(var_data, na.rm = TRUE)
        )
      } else {
        freq_table <- table(var_data)
        context <- sprintf(
          "Currently analyzing: %s (categorical variable)\nCategories: %s\n\n",
          selected_var,
          paste(names(freq_table), collapse = ", ")
        )
      }
      prompt <- paste(context, input$chat_user_input)
    } else {
      prompt <- input$chat_user_input
    }
    
    # Stream the response
    stream <- chat_obj()$stream_async(prompt)
    chat_append("chat", stream)
  })
}

shinyApp(ui, server)

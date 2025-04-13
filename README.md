# Shinyapp_LLM

This Shiny app demonstrates the integration of large language models (LLMs) with Shiny for interactive data analysis. It allows users to upload a dataset, visualize it, and ask questions about the data using LLMs. The app supports both OpenAI and Anthropic Claude models.

## Features

### Data Visualization
- Choose from built-in datasets (mtcars, iris) or upload custom CSV files
- Generate histograms for numerical variables with adjustable bin widths
- Create frequency tables for categorical variables
- Interactive variable selection and visualization controls

### LLM Integration
- Support for multiple LLM providers:
  - Anthropic Claude
  - OpenAI GPT
- Secure API key management
- Context-aware responses incorporating current data statistics

## How to Use

### Setting Up
1. Install required R packages:
```r
install.packages(c("shiny", "ggplot2", "DT", "ellmer", "shinychat"))
```

2. Launch the app and choose:
   - Dataset (built-in or upload)
   - Variables to analyze
   - LLM provider

3. Configure LLM:
   - Select your preferred provider
   - Enter your API key
   - Click "Submit API Key"
   - Wait for verification message

### Analyzing Data
1. **Variable Selection**:
   - Choose variables from the dropdown menu
   - Click "Generate Plot/Table" to visualize

2. **Visualizations**:
   - Numerical variables: Interactive histograms with adjustable bins
   - Categorical variables: Frequency tables

3. **AI Interaction**:
   - Type questions in the chat interface
   - The LLM automatically receives context about:
     - Currently selected variable
     - Variable type and statistics
     - Visual representation

### Example Questions
- "What's the distribution pattern of this variable?"
- "Are there any outliers in this data?"
- "What insights can you share about the frequency distribution?"
- "How does this compare to a normal distribution?"

## Requirements
- R version 4.0 or higher
- Valid API key for either:
  - Anthropic Claude
  - OpenAI GPT
- Required R packages (listed above)

## Note
API keys are not stored permanently and need to be re-entered if the app is refreshed.
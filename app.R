library(shiny)
library(ggplot2)
library(dplyr)

source("R/data_access.R")

safe_read <- function(filename) {
  tryCatch(
    read_dashboard_csv(filename, check.names = FALSE),
    error = function(e) {
      structure(data.frame(), rccdas_error = conditionMessage(e))
    }
  )
}

data_status <- function(x) {
  err <- attr(x, "rccdas_error")
  if (is.null(err)) NULL else err
}

region_file <- function(prefix, region) {
  paste0(prefix, "_", region, ".csv")
}

ui <- navbarPage(
  title = "RCCDAS · Climate Risk & Adaptation",
  header = tags$head(includeCSS("www/aiam-modern.css")),

  tabPanel(
    "Home",
    div(
      class = "app-shell",
      div(
        class = "app-hero",
        div(class = "app-kicker", "Regional climate-risk decision support"),
        h1("Regional Climate Risk & Adaptation Decision Support"),
        p("Explore climate conditions, sector-specific damages, economy-wide impacts and adaptation pathways across Beijing, Tianjin and Hebei under SSP scenarios."),
        div(
          class = "hero-links",
          tags$a(
            class = "hero-button primary",
            href = "https://k12gy8-song-ariel0yu.shinyapps.io/multi_page/",
            target = "_blank",
            "Launch live dashboard ↗"
          ),
          tags$a(
            class = "hero-button",
            href = "https://github.com/ys30/RCCDAS-Climate-Risk-Platform",
            target = "_blank",
            "View source ↗"
          )
        )
      ),

      fluidRow(
        column(
          3,
          div(class = "workflow-card",
              div(class = "num", "01 · CLIMATE"),
              h3("Climate conditions"),
              p("Temperature, precipitation, heat stress and related indicators across future scenarios."))
        ),
        column(
          3,
          div(class = "workflow-card",
              div(class = "num", "02 · PHYSICAL RISK"),
              h3("Sector impacts"),
              p("Translate climate hazards into infrastructure, production, labor and consumption-related losses."))
        ),
        column(
          3,
          div(class = "workflow-card",
              div(class = "num", "03 · ECONOMY"),
              h3("Economic impacts"),
              p("Trace direct climate shocks through regional macroeconomic and CGE-based outcomes."))
        ),
        column(
          3,
          div(class = "workflow-card",
              div(class = "num", "04 · ADAPTATION"),
              h3("Adaptation pathways"),
              p("Compare policy and management strategies for reducing climate-related losses by 2050."))
        )
      ),

      div(
        class = "architecture-panel",
        h2("From climate scenarios to decisions"),
        p("RCCDAS connects climate scenarios → physical damage functions → regional economic impacts → adaptation strategy assessment."),
        p(class = "muted",
          "Public code is stored on GitHub. Full model outputs and credentials remain outside the repository and can be served from a private PostgreSQL database.")
      )
    )
  ),

  tabPanel(
    "Climate Conditions",
    div(
      class = "app-shell",
      div(class = "page-heading",
          div(class = "app-kicker", "01 · CLIMATE"),
          h1("Climate conditions"),
          p("Explore regional climate trajectories under SSP scenarios.")
      ),
      sidebarLayout(
        sidebarPanel(
          selectInput("climate_region", "Region",
                      c("Beijing", "Tianjin", "Hebei")),
          selectInput("climate_metric", "Indicator",
                      c("Temperature", "Precipitation", "Radiation",
                        "Humidity", "WBGT", "HDD", "CDD", "CO2")),
          width = 3
        ),
        mainPanel(
          uiOutput("climate_status"),
          plotOutput("climate_plot", height = 480),
          width = 9
        )
      )
    )
  ),

  tabPanel(
    "Sector Impacts",
    div(
      class = "app-shell",
      div(class = "page-heading",
          div(class = "app-kicker", "02 · PHYSICAL RISK"),
          h1("Sector-specific climate impacts"),
          p("Inspect modeled physical-damage channels across production, infrastructure, labor and consumption.")
      ),
      sidebarLayout(
        sidebarPanel(
          selectInput("damage_region", "Region",
                      c("Beijing", "Tianjin", "Hebei")),
          uiOutput("damage_metric_ui"),
          width = 3
        ),
        mainPanel(
          uiOutput("damage_status"),
          plotOutput("damage_plot", height = 480),
          width = 9
        )
      )
    )
  ),

  tabPanel(
    "Economic Impacts",
    div(
      class = "app-shell",
      div(class = "page-heading",
          div(class = "app-kicker", "03 · ECONOMY"),
          h1("Economy-wide impacts"),
          p("Compare modeled changes in GDP, household income and public-sector outcomes.")
      ),
      sidebarLayout(
        sidebarPanel(
          selectInput("macro_region", "Region",
                      c("Beijing", "Tianjin", "Hebei")),
          selectInput("macro_metric", "Indicator",
                      c("GDP", "HouseholdIncome", "GovernmentIncome",
                        "GovernmentConsumption", "HouseholdsTotalConsumption")),
          width = 3
        ),
        mainPanel(
          uiOutput("macro_status"),
          plotOutput("macro_plot", height = 480),
          width = 9
        )
      )
    )
  ),

  tabPanel(
    "Adaptation",
    div(
      class = "app-shell",
      div(class = "page-heading",
          div(class = "app-kicker", "04 · ADAPTATION"),
          h1("Adaptation pathways"),
          p("Compare modeled policy strategies and economic outcomes by 2050.")
      ),
      sidebarLayout(
        sidebarPanel(
          selectInput("adapt_region", "Region",
                      c("Beijing", "Tianjin", "Hebei")),
          selectInput("adapt_metric", "Indicator",
                      c("GDP", "HouseholdIncome", "GovernmentIncome",
                        "HouseholdsTotalConsumption", "ValueofGovernmentConsumption")),
          numericInput("adapt_year", "Year", 2050, min = 2020, max = 2100),
          width = 3
        ),
        mainPanel(
          uiOutput("adapt_status"),
          plotOutput("adapt_plot", height = 500),
          width = 9
        )
      )
    )
  )
)

server <- function(input, output, session) {

  climate_data <- reactive({
    safe_read(region_file("climate_conditions", input$climate_region))
  })

  output$climate_status <- renderUI({
    err <- data_status(climate_data())
    if (!is.null(err)) div(class = "data-note",
      strong("Private data not connected in this public build."),
      p(err)
    )
  })

  output$climate_plot <- renderPlot({
    x <- climate_data()
    req(nrow(x) > 0, input$climate_metric %in% names(x))
    ggplot(x, aes(x = year, y = .data[[input$climate_metric]],
                  colour = Scenario, group = Scenario)) +
      geom_line(linewidth = 1.1) +
      geom_point(size = 1.5, alpha = .7) +
      labs(x = NULL, y = input$climate_metric,
           title = paste(input$climate_region, input$climate_metric)) +
      theme_minimal(base_size = 13) +
      theme(legend.position = "top")
  })

  damage_data <- reactive({
    safe_read(region_file("climate_damage", input$damage_region))
  })

  output$damage_metric_ui <- renderUI({
    x <- damage_data()
    if (!nrow(x)) return(NULL)
    exclude <- c("year", "Scenario", "Unnamed: 0")
    vars <- setdiff(names(x), exclude)
    selectInput("damage_metric", "Impact channel", vars,
                selected = vars[[1]])
  })

  output$damage_status <- renderUI({
    err <- data_status(damage_data())
    if (!is.null(err)) div(class = "data-note",
      strong("Private data not connected in this public build."),
      p(err)
    )
  })

  output$damage_plot <- renderPlot({
    x <- damage_data()
    req(nrow(x) > 0, !is.null(input$damage_metric),
        input$damage_metric %in% names(x))
    ggplot(x, aes(x = year, y = .data[[input$damage_metric]],
                  colour = Scenario, group = Scenario)) +
      geom_line(linewidth = 1.05) +
      labs(x = NULL, y = input$damage_metric,
           title = paste(input$damage_region, input$damage_metric)) +
      theme_minimal(base_size = 13) +
      theme(legend.position = "top")
  })

  macro_data <- reactive({
    safe_read(region_file("climate_macro_damage", input$macro_region))
  })

  output$macro_status <- renderUI({
    err <- data_status(macro_data())
    if (!is.null(err)) div(class = "data-note",
      strong("Private data not connected in this public build."),
      p(err)
    )
  })

  output$macro_plot <- renderPlot({
    x <- macro_data()
    req(nrow(x) > 0, input$macro_metric %in% names(x))
    ggplot(x, aes(x = year, y = .data[[input$macro_metric]],
                  colour = Scenario, group = Scenario)) +
      geom_hline(yintercept = 0, linewidth = .4, colour = "grey70") +
      geom_line(linewidth = 1.1) +
      labs(x = NULL, y = input$macro_metric,
           title = paste(input$macro_region, input$macro_metric)) +
      theme_minimal(base_size = 13) +
      theme(legend.position = "top")
  })

  adapt_file <- reactive({
    switch(input$adapt_region,
           Beijing = "adapation_bj.csv",
           Tianjin = "adapation_tj.csv",
           Hebei = "adapation_hb.csv")
  })

  adapt_data <- reactive({
    safe_read(adapt_file())
  })

  output$adapt_status <- renderUI({
    err <- data_status(adapt_data())
    if (!is.null(err)) div(class = "data-note",
      strong("Private data not connected in this public build."),
      p(err)
    )
  })

  output$adapt_plot <- renderPlot({
    x <- adapt_data()
    req(nrow(x) > 0, input$adapt_metric %in% names(x))
    x <- x[x$year == input$adapt_year, , drop = FALSE]
    req(nrow(x) > 0)

    ggplot(x, aes(x = factor(type), y = .data[[input$adapt_metric]],
                  colour = policy, shape = Scenario)) +
      geom_point(size = 2.5, alpha = .85,
                 position = position_jitter(width = .08, height = 0)) +
      labs(x = "Adaptation case", y = input$adapt_metric,
           title = paste(input$adapt_region, input$adapt_year,
                         "adaptation comparison")) +
      theme_minimal(base_size = 13) +
      theme(legend.position = "right")
  })
}

shinyApp(ui, server)

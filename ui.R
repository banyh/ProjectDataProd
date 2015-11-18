require(shiny)

shinyUI(navbarPage(
		title = "Stock Charts",
		id = "navbar",
		position = "static-top",
		tabPanel("Charts",
			sidebarLayout(
				sidebarPanel(
					h3("Select Chart Source and Range"),
					textInput("symbol",
						"Input Stock Symbol:",
						value = "AAPL"
					),
					dateRangeInput("date",
								   "Date Range",
								   start = "2015-01-01",
								   end = "2015-12-31"),
					submitButton("Apply"),
					hr(),
					h3("Indicators"),
					checkboxInput("ma20",  "[MA20] 20 days moving average", value = FALSE),
					checkboxInput("ma60",  "[MA60] 60 days moving average", value = FALSE),
					checkboxInput("ma240", "[MA240] 240 days moving average", value = FALSE),
					checkboxInput("macd",  "[MACD] Moving Average Convergence / Divergence", value = FALSE),
					checkboxInput("bband", "[BBands] Bollinger Bands", value = FALSE)
				),
				mainPanel(
					plotOutput("chart",
							   height = "600px")
				)
			)
		),
		tabPanel("Documentation",
			h2("What this App for?"),
			h4("This App is a stock price predictor. This App is also a ",
			  "course project of Developing Data Products on Coursera."),
			
			h2("How to use this App?"),
			h4("1. Type the symbol name of a stock you want to predict, like ",
			  "GOOG(Google) or AAPL(Apple). Then press ENTER."),
			h4("2. Choose the range of starting/ending dates. After the dates ",
			   "have been updated, you should click 'Apply' to refresh the ",
			   "stock chart."),
			h4("3. Select one or more indicators by check boxes below. Then ",
			   "click 'Apply' to refresh the stock chart.")
		)
	)
)

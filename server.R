require(quantmod)
require(TTR)
require(caret)
require(kernlab)

#
# How many days in a traning example. (Default = 30)
# In default, the close prices of previous 30 days are used as training data to
# predict today's close price.
#
How_Many_Days_in_Training = 30

#
# How many training samples to train our neural networks. (Default = 300)
# Each training sample contains an desired output value (the close price of
# day T) and an input vector (the close price of day T-30 to T-1).
#
How_Many_Training_Samples = 300

#
# How many future days to predict. (Default = 10)
# Close prices of today and previous 29 days are used to predict the close
# price of tomorrow.
# Close prices of tomorrow, today, and previous 28 days are used to predict
# the close price of the day after tomorrow, and so on.
#
How_Many_Days_to_Predict = 10

#
# For saving user's time, we only fetch stock data and train neural networks
# if the input symbol is changed.
#
Cache_Symbol = ""

#
# Cached prediction is used for caching data during the same session.
#
Cache_Prediction = NULL

#
# Cached stock price data from getSymbol
#
Stock = NULL

#
# System locale setting affects the text of x-axis.
#
Sys.setlocale(locale = "English")

shinyServer(function(input, output) {
	output$chart <- renderPlot({

		# Only fetch data if the symbol is changed
		if (Cache_Symbol != input$symbol) {
			Stock <<- getSymbols(input$symbol, auto.assign = FALSE)
			Cache_Prediction <<- NULL
		}

		# myStock only contains the range of dates assigned by the user
		minDate <- ifelse(start(Stock) > input$date[1], start(Stock), input$date[1])
		maxDate <- ifelse(end(Stock) < input$date[2], end(Stock), input$date[2])
		minDate <- as.character(as.Date(minDate))
		maxDate <- as.character(as.Date(maxDate))
		myStock <- Stock[paste0(minDate,"/",maxDate)]
		nday <- ndays(myStock)

		# Only re-train neural networks if cached prediction is null
		if (is.null(Cache_Prediction))
		{
			# prepare an empty XTS object
			futureDate <- as.Date((end(Stock)+1):(end(Stock)+How_Many_Days_to_Predict))
			predx <- matrix(0, nrow=How_Many_Days_to_Predict, ncol=6)
			colnames(predx) <- c("Open","High","Low","Close","Volume","Adjusted")
			rownames(predx) <- as.character(futureDate)
			predxts <- as.xts(predx)

			# if we use M days to train and prepare N samples,
			# we should prepare M+N days of data
			startIndex <- nrow(Stock) - How_Many_Training_Samples - How_Many_Days_in_Training
			lagData <- Stock[startIndex:nrow(Stock),4]
			trainData <- sapply(0:How_Many_Days_in_Training,
							  function(k) Lag(as.vector(lagData),k))
			# column names are "x1",...,"x30"
			colnames(trainData) <- c("y", paste0("x", 1:How_Many_Days_in_Training))
			# discards NA rows
			trainData <- as.data.frame(trainData[-(1:How_Many_Days_in_Training),])
			fit <- train(y ~ ., data=trainData, method="svmLinear", linout=TRUE, trace=FALSE)
			testData <- t(as.vector(
				Stock[(nrow(Stock)-How_Many_Days_in_Training+1):nrow(Stock),4]
			))
			colnames(testData) <- paste0("x", 1:How_Many_Days_in_Training)
			for (i in 1:How_Many_Days_to_Predict) {
				newPrice <- predict(fit, testData)
				predxts[i,4] <- newPrice
				testData <- t(c(testData[2:How_Many_Days_in_Training], newPrice))
				colnames(testData) <- paste0("x", 1:How_Many_Days_in_Training)
			}
			print(predxts[,4])
			Cache_Prediction <<- predxts
		}

		TAlist <- "addVo()"
		if (input$macd & nday > 31)
			TAlist <- paste0(TAlist, ";addMACD()")
		if (input$bband & nday > 25)
			TAlist <- paste0(TAlist, ";addBBands()")
		if (input$ma20 & nday > 25)
			TAlist <- paste0(TAlist, ";addSMA(20, col='brown')")
		if (input$ma60 & nday > 65)
			TAlist <- paste0(TAlist, ";addSMA(60, col='green')")
		if (input$ma240 & nday > 300)
			TAlist <- paste0(TAlist, ";addSMA(240, col='blue')")

		Cache_Symbol <<- input$symbol
		myStock <- rbind.xts(Cache_Prediction, myStock)
		chartSeries(myStock, type = "line", TA = TAlist, TAsep = ";",
					theme = chartTheme("white", up.col="red", dn.col="green"))
	})
})

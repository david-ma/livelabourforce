library(devtools)
#install_github("rsdmx","opensdmx")
library(rsdmx)
library(RJSONIO)
library(forecast)

#function to pull last value
last <- function(x) { tail(x, n = 1) }

# set working directory (Nick's PC)
setwd("C:/Users/Nicholas/Dropbox/GovHack (1)")

# read in data from ABS.Stat API...
#Have to pull in series one at a time due to R/metadata constraints

# unemployment rate - for Hugh starting from 1990
ur <- "http://stat.abs.gov.au/restsdmx/sdmx.ashx/GetData/LF/0.14.3.1599.30.M/ABS?startTime=1990&endTime=2020"
ur <- readSDMX(ur)
ur <- as.data.frame(ur)

# employed people
jobs <- "http://stat.abs.gov.au/restsdmx/sdmx.ashx/GetData/LF/0.4.3.1599.30.M/ABS?startTime=2000&endTime=2020"
jobs <- readSDMX(jobs)
jobs <- as.data.frame(jobs)
jobs_current <- last(jobs$obsValue)
jobs_prior <- jobs$obsValue[length(jobs$obsValue)-1]
#jobs added this month
jobs_change <- jobs_current - jobs_prior
#avg number of jobs added last 12 months, rounded
jobs_change_avg <- round(ave(jobs$obsValue[(length(jobs$obsValue)-12):length(jobs$obsValue)])[1],0)

# unemployed persons
ue <- "http://stat.abs.gov.au/restsdmx/sdmx.ashx/GetData/LF/0.13.3.1599.30.M/ABS?startTime=2000&endTime=2020"
ue <- readSDMX(ue)
ue <- as.data.frame(ue)
ue_current <- last(ue$obsValue)
ue_prior <- ue$obsValue[length(ue$obsValue)-1]

# labour force
lf <- "http://stat.abs.gov.au/restsdmx/sdmx.ashx/GetData/LF/0.6.3.1599.30.M/ABS?startTime=2000&endTime=2020"
lf <- readSDMX(lf)
lf <- as.data.frame(lf)
lf_current <- last(lf$obsValue)
lf_prior <- lf$obsValue[length(lf$obsValue)-1]

# civilian population
pop <- "http://stat.abs.gov.au/restsdmx/sdmx.ashx/GetData/LF/0.1.3+1+2.1599.10.M/ABS?startTime=2000&endTime=2020"
pop <- readSDMX(pop)
pop <- as.data.frame(pop)
pop_current <- last(pop$obsValue)
pop_prior <- pop$obsValue[length(pop$obsValue)-1]

# participation rate
#part <- "http://stat.abs.gov.au/restsdmx/sdmx.ashx/GetData/LF/0.10.3.1599.30.M/ABS?startTime=2000&endTime=2020"
#part <- readSDMX(part)
#part <- as.data.frame(part)
#part_current <- last(part$obsValue)
#part_prior <- part$obsValue[length(part$obsValue)-1]
part_current <- lf_current / pop_current
part_prior <- lf_prior / pop_prior


# unemployment rate to two decimal places (use lf and ue instead of standard ABS metric for more detail)
ur_current <- round(ue$obsValue[length(ue$obsValue)]/lf$obsValue[length(lf$obsValue)],6)
ur_prior <- round(ue$obsValue[length(ue$obsValue)-1]/lf$obsValue[length(lf$obsValue)-1],6)

# old waterfall calcs
# jobs_impact <- - (jobs_current / (pop_current * part_prior) - jobs_prior / (pop_prior * part_prior))
# part_impact <- part_current / part_prior - 1 + ue_current/(pop_current * part_current) - ue_current / (pop_current * part_prior)

# waterfall calcs
pop_impact <- jobs_prior / (pop_prior * part_prior) - jobs_prior / (pop_current * part_prior)
part_impact <- jobs_prior / (pop_current * part_prior) - jobs_prior / (pop_current * part_current)
jobs_impact <- jobs_prior / (pop_current * part_current) - jobs_current / (pop_current * part_current)

# other key metrics
pop_growth <- pop_current / pop_prior - 1
part_change <- part_current - part_prior

# round for JSON
pop_impact <- round(pop_impact, 6)
part_impact <- round(part_impact, 6)
jobs_impact <- round(jobs_impact, 6)
pop_growth <- round(pop_impact, 6)
part_change <- round(part_change, 6)
jobs_change <- round(jobs_change, 6)

# Put the key numbers into a single data frame
data <- data.frame(ur_prior, pop_impact, part_impact, jobs_impact, ur_current, pop_growth, part_change, jobs_change)

writeLines(toJSON(data), "JunWaterfallData2.json")

# Data for jobs added breakdown - hard coded for now (ABS state, sex and age breakdown is inconsistent with trend total - all values scaled to match total)

Jobs_added <- 10.6

Jobs_impact <- 0.0016

NSW_change <- 1.9
Vic_change <- 0.9
Qld_change <- 4.2
SA_change <- 1.0
WA_change <- 2.3
Tas_change <- 0.4
NT_change <- 0.1
ACT_change <- -0.1

NSW_growth <- 0.001
Vic_growth <- 0.000
Qld_growth <- 0.002
SA_growth <- 0.001
WA_growth <- 0.002
Tas_growth <- 0.002
NT_growth <- 0.001
ACT_growth <- - 0.001

Male_change <- 4.3
Female_change <- 6.3

Male_growth <- 0.001
Female_growth <- 0.001

Youth_change <- 1.0
Old_change <- 9.6

Youth_growth <- 0.001
Old_growth <- 0.001

dataJobsAdded <- data.frame(Jobs_added, Jobs_impact, NSW_change, Vic_change, Qld_change, SA_change, WA_change, Tas_change, NT_change, ACT_change, NSW_growth, Vic_growth, Qld_growth, SA_growth, WA_growth, Tas_growth, NT_growth, ACT_growth, Male_change, Female_change, Male_growth, Female_growth, Youth_change, Old_change, Youth_growth, Old_growth)

writeLines(toJSON(dataJobsAdded), "JobsAddedData.json")


    
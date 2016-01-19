## Load packages
library(dplyr)
library(magrittr)

## Set survey name
#   Season: Autumn, Spring
se <- "Autumn"
yr <- 2015

### Read in data
lw <- read.csv("data/WB_lw.csv",header=T) %>% 
  filter(species != "Unidentified Species",year==yr,season==se) %>% 
  droplevels()
catch <- read.csv("data/WB_catch.csv",header=T) %>% 
  filter(species != "Unidentified Species",year==yr,season==se) %>% 
  droplevels()

########################################################################################
## Set TL variable as a numeric and round the final counts to a whole number
catch$count_final <- round(catch$count_final,digits=0)

## Create a factor of species names
spec_list <- unique(lw$species)

## Start loop
samplesize_final <- do.call(rbind,lapply(spec_list,function(i) {
  ## Filter out size modes from length data
  df <- filter(lw,species == i & tl != "NA" & !is.na(size))
  df_xs <- filter(df,size == "XS")
  df_sm <- filter(df,size=="S")
  df_md <- filter(df,size=="M")
  df_lg <- filter(df,size=="L")
  df_xl <- filter(df,size == "XL")
  df_all <- filter(df,size == "ALL")
  
  ## Filter out size modes from catch data
  df2 <- filter(catch,species == i & !is.na(size))
  df3_xs <- filter(df2,size == "XS")
  df3_sm <- filter(df2,size=="S")
  df3_md <- filter(df2,size=="M")
  df3_lg <- filter(df2,size=="L")
  df3_xl <- filter(df2,size == "XL")
  df3_all <- filter(df2,size == "ALL")
  
  ## Determine sample size of total catch in each size mode. Subtract the number of
  ##  measured lengths from total catch to prevent overestimating the total number 
  ##  of fish caught.
  n_xs <- (sum(df3_xs$count_final))-(nrow(df_xs))
  n_sm <- (sum(df3_sm$count_final))-(nrow(df_sm))
  n_md <- (sum(df3_md$count_final))-(nrow(df_md))
  n_lg <- (sum(df3_lg$count_final))-(nrow(df_lg))
  n_xl <- (sum(df3_xl$count_final))-(nrow(df_xl))
  n_all <- (sum(df3_all$count_final))-(nrow(df_all))
  samplesize <- data.frame(i,n_xs,n_sm,n_md,n_lg,n_xl,n_all)
  
  ## Logical test for negative values
  if((all(samplesize[2:7] >= 0)) == F) {
    samplesize$logical <- "contains negative element" } else {
      samplesize$logical <- "positive"
    }
  
  ## Combine all species samplesizes
  samplesize_comb <- if(exists("samplesize_comb")==F) {
    samplesize } else {
      rbind(samplesize_comb,samplesize)
    }
  colnames(samplesize_comb) <- c("Species","XS","S","M","L","XL","ALL","Logical Test")
  samplesize_comb
}))
## End Loop

## Any negative values in samplesize_final indicates a discrepancy between LW and Catch
View(samplesize_final)

## A negative value will not allow the bootstrap to run and needs to be corrected prior to running
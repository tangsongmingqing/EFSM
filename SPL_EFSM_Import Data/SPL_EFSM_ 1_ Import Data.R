###########Create custom functions and name variables##################################################
rm(list = ls(all = TRUE))
graphics.off()

#1 Load_data
load_data = function(path) {
  data = read.csv(path)
  colnames(data) = c("Date", "Variable")
  data$Date = as.Date(data$Date,"%d/%m/%Y")
  data = data[data$Date >= "1987-12-01" & data$Date <= "2017-10-15",]
  rownames(data)<-c(1:359)
  return(data)
}

#2 Give_return
give_return = function(object) {
  object = object %>%
    ts(frequency = 1) %>%
    Return.calculate() %>%
    round(digits = 4)
  return(object)
}

#3 Tidy
tidy = function(object, variable){
  object = add_column(object, EI$Date) #add "date" column
  object = object[, c(2,1)] #change order of both columns
  colnames(object) = c("Date", variable) #change column names
  path = paste("SPL_EFSM/SPL_EFSM_", variable, ".RDS", sep = "") #determine file path
  saveRDS(object, path) #save as a RDS file
  return(object)
}

title = c("Date", "Expected Inflation (EI)", "Inflation (I)", "High-Yield Bonds (HYB)", 
          "Longterm Goverment Bonds (LGB)", "Change in yearly Production (YP)", 
          "Change in monthly production (MP)", "Unexpected Inflation (UI)", 
          "Change in Expected Inflation (DEI)", "Unanticipated changes in risk premia (URP)", 
          "Unanticipated changes in term structure (UTS)", "Equally weighted equities (EWNY)", 
          "Oil prices (OG)", "Consumption (CG)", "Return (R)")

name = c("Date", "EI", "I", "HYB", "LGB", "YP", "MP", "UI", "DEI", 
         "URP", "UTS", "EWNY", "OG", "CG", "R")


###########Calculate variables#######################################################################


#1 Expected Inflation (EI)
EI = load_data("SPL_EFSM_Import data/raw data/exp.inf_UniMichigen.csv")
colnames(EI) = c("Date", "EI")  
EI$EI = ((1 + EI$EI/100)^(1/12)) - 1
EI$EI = round(EI$EI, 4)
saveRDS(EI,"SPL_EFSM/SPL_EFSM_EI.RDS")


#2 CPI and Inflation (I)
CPI = read.csv("SPL_EFSM_Import data/raw data/CPI1953_2017.csv")
CPI=CPI[35:65, 2:14] #choose data from 1987-2017 & first row is meaningless 
CPI=as.vector(t(CPI)) #break data.frame in order to transform into suitable shape
CPI=replace(CPI, CPI>1000, NA) #delete all entities that are "year"
CPI=CPI[!is.na(CPI)] #filter NA
CPI=CPI[12:370] #Start from Dec 1987
CPI=as.data.frame(CPI)

I = log(CPI$CPI) %>%
    diff(lag = 1) %>%
    append(0, 0)%>%
    as.data.frame()%>%
    round(digits = 4) %>%
    add_column(EI$Date) 
    
rm(CPI)
I = I[ ,c(2,1)] 
colnames(I) = c("Date", "I")
saveRDS(I, "SPL_EFSM/SPL_EFSM_I.RDS")


#4 Unexpected Inflation (UI)
UI=I$I-EI$EI
UI=as.data.frame(UI)
UI = tidy(UI, name [8])


#5 Change in Expected Inflation (DEI)
DEI = diff(EI$EI)
DEI = append(DEI, 0, 0)
DEI=as.data.frame(DEI)
DEI$DEI = round(DEI$DEI, 4)
DEI = tidy(DEI, name[9])


#6 High-yield Bonds (HYB)
HYB = load_data("SPL_EFSM_Import data/raw data/High_Yield_Bonds.csv")
colnames(HYB) = c("Date", "HYB")
HYB$HYB = HYB$HYB/100
saveRDS(HYB, "SPL_EFSM/SPL_EFSM_HYB.RDS")


#7 Long-term Goverment Bonds (LGB)
LGB = read.csv("~SPL_EFSM_Import data/raw data/Long_term_bonds.csv") 
#Due to different format unable to use function load_data
LGB$observation_date = as.Date(LGB$observation_date) 
colnames(LGB) = c("Date", "LGB")
LGB = LGB[LGB$Date >= "1987-12-01" & LGB$Date <= "2017-10-15",]
rownames(LGB) = c(1:359)
LGB$LGB = LGB$LGB/100
saveRDS(HYB, "SPL_EFSM/SPL_EFSM_LGB.RDS")


#8 Unanticipated changes in risk premia (URP)
URP = HYB$HYB - LGB$LGB
URP=as.data.frame(URP)
URP = tidy(URP, name[10])


#9 Equally-weighted New York Exchange Stock Index (EWNY)
EWNY_prep = read.csv("SPL_EFSM_Import data/raw data/Equally_Weighted_Equities.csv")
EWNY_prep$Date = as.Date(EWNY_prep$Date, format = "%d/%m/%Y") 
x = as.POSIXct(EWNY_prep$Date)
mo = strftime(x, "%m")
yr = strftime(x, "%Y")
dd = data.frame(mo, yr, EWNY_prep$Last.Price)

EWNY = aggregate(EWNY_prep$Last.Price ~ mo + yr, dd, FUN = first)
EWNY$date = as.POSIXct(paste(EWNY$yr, EWNY$mo, "01", sep = "-"))
EWNY$mo = NULL
EWNY$yr = NULL

rm(dd, EWNY_prep, mo, yr, x)
colnames(EWNY) = c("EWNY", "Date")
EWNY=EWNY[ ,c(2,1)]
EWNY$EWNY = round(EWNY$EWNY, digits = 2)
EWNY = EWNY[EWNY$Date >= "1987-12-01" & EWNY$Date <= "2017-10-15",]
rownames(EWNY)=c(1:359)
EWNY$EWNY = give_return(EWNY$EWNY)
saveRDS(EWNY,"SPL_EFSM/SPL_EFSM_EWNY.RDS")


#10 Unanticipated changes in term structure (UTS)
TB = read_csv("SPL_EFSM_Import data/raw data/Treasury Bill Rate.csv")
#Due to different format unable to use function load_data
colnames(TB)=c("Date", "TB")
TB$TB = TB$TB/100
saveRDS(TB, "SPL_EFSM/SPL_EFSM_TB.RDS")

UTS=LGB$LGB-TB$TB
UTS=as.data.frame(UTS)
UTS = tidy(UTS, name[11])


#11 Creating variables Industrial Production and Crude Oil Price
table = read.csv("SPL_EFSM_Import data/raw data/Industrial Production, Crude, CPI, Treasury Bill.csv", header = TRUE)
names(table) = c("Date","IP","OG","US Treasury Yield (20 Y)","US CPI")
table$Date = as.Date(table$Date, '%d/%m/%Y')
table = table[table$Date >= "1987-12-01" & table$Date <= "2017-10-15", 1:3]

IP = table[,1:2] #Create table for industrial production
OG = table[,c(1,3)] #Create table for Crude Oil Price
OG$OG = give_return(OG$OG)

rm(table)
saveRDS(IP, "SPL_EFSM/SPL_EFSM_IP.rds")
saveRDS(OG, "SPL_EFSM/SPL_EFSM_OG.rds")


#12 Create variable MP - monthly growth in industrial production
lg_ip = log(IP$IP) # logrithmus of Industrial Production (IP)
MP = diff(lg_ip, lag = 1) 
MP = c(0, MP) %>% as.data.frame()
MP = tidy(MP, name[7])
MP$MP = round(MP$MP, 4)
saveRDS(MP, "SPL_EFSM/SPL_EFSM_MP.RDS")


#13 Create variable YP - annual growth in industrial production
#We already have the log of monthly production
YP = diff(lg_ip, lag = 12) 
#Calculate diff between the month of one year and the month of previous year
YP = append(YP, rep(NA, 12), 0) %>% as.data.frame()
#Diff doesn't calculate the first 12 values. You have to add NAs manually
YP = tidy(YP, name[6])
YP$YP = round(YP$YP, 4)
#The table shows the increase of YP compared to twelve months ago for every month
rm(lg_ip)
saveRDS(YP, "SPL_EFSM/SPL_EFSM_YP.RDS")


#14 Consumption (CG)
CG = load_data("SPL_EFSM_Import data/raw data/Consumption Monthly.csv")
colnames(CG)=c("Date", "CG")
CG$CG = give_return(CG$CG)
saveRDS(CG, "SPL_EFSM/SPL_EFSM_CG.RDS")


#15 Creating the dependant variable R - Return Portfolio
R1 =read.csv("SPL_EFSM_Import data/raw data/WILL5000INDFC.csv",header = TRUE,stringsAsFactors = FALSE)
names(R1) = c("Date","R")
R1$Date = as.Date(R1$Date, format = "%d/%m/%Y") 
R1 = R1[R1$Date >= "1987-12-01" & R1$Date <= "2017-10-15",]
R1$R = as.numeric(R1$R)

x = as.POSIXct(R1$Date)
mo = strftime(x, "%m")
yr = strftime(x, "%Y")
dd = data.frame(mo, yr, R1$R)

R = aggregate(R1$R ~ mo + yr, dd, FUN = first)
R$Date = as.POSIXct(paste(R$yr, R$mo, "01", sep = "-"))
R$mo = NULL
R$yr = NULL
rm(dd, R1, mo, yr, x)

colnames(R) = c("R", "Date")
R=R[ ,c(2,1)]
R$R = give_return(R$R)
saveRDS(R, "SPL_EFSM/SPL_EFSM_R.RDS")


###########Creating dataframe for with all the variables#############################################
#The code assumes that all objects are in the environment

big_table = EI$Date
big_table = as.data.frame(big_table)
big_table = add_column(big_table, EI$EI, I$I, HYB$HYB, LGB$LGB, YP$YP, MP$MP, UI$UI, DEI$DEI, 
                       URP$URP, UTS$UTS, EWNY$EWNY, OG$OG, CG$CG, R$R)
names(big_table) = name
big_table = big_table[2:359, ] #We start our time series on Jan 1988
rownames(big_table) = c(1:358)
saveRDS(big_table, "SPL_EFSM/SPL_EFSM_big_table.RDS")

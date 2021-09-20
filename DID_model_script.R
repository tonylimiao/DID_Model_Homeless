library(bacondecomp)
library(tidyverse)
library(readstata13)
library(haven)
library(dplyr)

install.packages("did")
library(did)

grass <- read_dta("D:/Google Drive/My Teaching/Clemson/Independent_Studies/Austin_Sanderson/work_data_nomissing.dta")
View(grass)
sum(is.na(grass$jailrate))
sum(is.na(grass$prepost))

grass_rd <- grass %>% filter(state !="AK") %>% filter(is.na(grass$prepost)==FALSE) %>% 
                    mutate(grp = replace_na(yearlegal, 0))  
#grass <- grass %>% filter(state !="AK") %>% filter(is.na(grass$prepost)==FALSE) %>% 
#                   mutate(grp = na_if(yearlegal, 0))        #reverse the previous step
View(grass_rd)
grass_rd$grp_f <- factor(grass_rd$grp)

data(mpdta)
View(mpdta)
# estimate group-time average treatment effects using att_gt method
out1 <- att_gt(yname="lemp",
               tname="year",
               idname="countyreal",
               gname="first.treat",
               xformla=~lpop,
               biters = 3000,
               control_group = c("nevertreated", "notyettreated"),
               data=mpdta)
summary(out1)               

aggte(
  out1,
  type = "dynamic",
  balance_e = NULL,
  min_e = -Inf,
  max_e = Inf,
  na.rm = FALSE,
  bstrap = NULL,
  biters = NULL,
  cband = NULL,
  alp = NULL,
  clustervars = NULL
)

  
# without covariates
out2 <- att_gt(yname="lemp",
               tname="year",
               idname="countyreal",
               gname="first.treat",
               xformla=NULL,
               data=mpdta)
summary(out2)

aggte(
  out2,
  type = "simple"
)
  
  

# get twfe estimate
two_way_fe = lm(jailrate ~ prepost + factor(state_FIPS) + factor(year), data = grass)

# view the estimates, coefficient on post is the effect we're interested in
summary(two_way_fe)
# see that it's pretty much the -3.08 (s.e. = 1.13) from page 22

# run and save the decomposition without controls
bacon_jail= bacon(jailrate ~ prepost,
                      data = grass,
                      id_var = "state_FIPS",
                      time_var = "year")

# plot the estimates and weights (without controls)
# this is figure 6
ggplot(bacon_jail) +
  aes(x = weight, y = estimate, shape = factor(type)) +
  geom_point() +
  geom_hline(yintercept = 0) +
  labs(x = "Weight", y = "Estimate", shape = "Type")

# run and save the decomposition with controls (per capita income)
bacon_divorce_controls = bacon(asmrs ~ post + pcinc,
                               data = divorce,
                               id_var = "stfips",
                               time_var = "year")







# note the change in the output with controls
# the reason for this is explained on page 7 of the FAQ:
# "Why does the output of bacondecomp differ with and without controls?"

# plot the estimates and weights (with controls)
ggplot(bacon_divorce_controls$two_by_twos) +
  aes(x = weight, y = estimate, shape = factor(type)) +
  geom_point() +
  geom_hline(yintercept = 0) +
  labs(x = "Weight", y = "Estimate", shape = "Type")
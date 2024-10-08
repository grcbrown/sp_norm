library(tidyverse)
library(lme4)
library(lmerTest)
library(ggplot2)
library(MuMIn)

setwd("/Users/gracebrown/qp1_spk/sp_norm")

# color-blind-friendly palette
cbPalette <- c("#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7") 
theme_set(theme_bw())

# LOAD DATA
raw_data <- read.csv('./data/speaker_norming-merged.csv')
survey <- read.csv('./data/survey_post.csv')
data <- left_join(x=raw_data,y=survey,by="workerid")

# DATA SHAPING
## remove participants according to exclusion criteria 
## criteria 1 - failed audio check
exclude_audio <- data %>% filter(trial_type == "audio-button-response") %>% group_by(workerid) %>% filter(response != 2) 
print(exclude_audio$workerid)
data <- data[!(data$workerid %in% c(510, 453, 494, 435, 438, 467, 489)),]
## criteria 2 - responded to less than 80% of trials 
exclude_trial <- data %>% filter(!is.na(rt)) %>% filter(trial_type == "audio-slider-response") %>% group_by(workerid) %>% count(workerid)
exclude2 <- exclude_trial %>% filter(n < 4)
print(exclude2$workerid)
data <- data[!(data$workerid %in% c(449, 473, 478, 505, 512, 533, 545)),]
total_respondants <- n_distinct(data$workerid)

## separate numeric and string data
data$response_numeric <- ifelse(data$trial_type=="audio-slider-response" | data$trial_type=="html-slider-response", data$response, NA)
data$response_numeric <- as.double(data$response_numeric)

## unpack demographic data
political <- data %>% filter(trial_type == "survey-likert") %>% summarize("workerid" = workerid, "political" = response)
political$political <- str_replace(political$political, "\\{'Q0': ", "")
political$political <- str_replace(political$political, "\\}", "")
data <- left_join(x=data,y=political,by="workerid")
### gender breakdown 
gender_summary <- data %>% select(workerid,gender) %>% group_by(gender) %>% reframe("count" = n_distinct(workerid))
### age breakdown### age breakdowngender_summary
age_summary <- data %>% filter(!is.na(age)==T) %>% summarize("min_age" = min(age), "mean_age" = mean(age), "max_age" = max(age))
### region breakdown
region_summary <- data %>% select(workerid,region) %>% group_by(region) %>% reframe("count" = n_distinct(workerid))
### education breakdown
edu_summary <- data %>% select(workerid,education) %>% group_by(education) %>% reframe("count" = n_distinct(workerid))

## calculate SQR score and append it to main df 
data$coding[data$coding == ""] <- NA 
data$sqr_raw <- ifelse(data$trial_type == "html-slider-response" & is.na(data$coding) == FALSE,
                       data$response_numeric/100, NA)
data$gender_trans <- ifelse(data$trial_type == "html-slider-response" & is.na(data$coding) == FALSE & data$coding == "NEGATIVE",
                           (10000-data$sqr)/100, NA)
data$gender_link <- ifelse(data$trial_type == "html-slider-response" & is.na(data$coding) == FALSE & data$coding == "POSITIVE",
                          (data$sqr)/100, NA)
score_gender_link <- data %>% filter(!is.na(gender_link)) %>% group_by(workerid) %>% summarize("score_link" = mean(gender_link))
data <- merge(data, score_gender_link, by = "workerid", all.x = TRUE)
score_gender_trans <- data %>% filter(!is.na(gender_trans)) %>% group_by(workerid) %>% summarize("score_trans" = mean(gender_trans))
data <- merge(data, score_gender_trans, by = "workerid", all.x = TRUE)
srq_score <- data %>% group_by(workerid) %>% summarize("score" = (score_gender_trans+score_gender_link)/2)

### summarize numeric data 
exp_data <- data %>% 
  filter(!is.na(response)) %>% 
  group_by(coding) %>% 
  filter(coding == 193 | coding == 246 | coding == 340 | coding == 625 | coding == 723)

### rescale response data 
exp_data$response_numeric <- exp_data$response_numeric/100

exp_data <- filter(exp_data, is.na(response_numeric)==FALSE) 
exp_data %>% summarize(coding, response_numeric)
#### mean + variance 
exp_sub_1 <- subset(exp_data, select = -c(workerid)) 
exp_summary_1 <- summarize(exp_sub_1, "mean"=mean(response_numeric), "var" = var(response_numeric), "sd" = sd(response_numeric))
print(exp_summary_1)

# VISUALIZATIONS 
## gen distribution of ratings 
hist_all <- ggplot(exp_data, aes(x=response_numeric)) + 
  geom_histogram(bins=30) +
  xlab("Masculinity Rating") + 
  scale_fill_manual(values = cbPalette) + 
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
print(hist_all)

## overall distribution of ratings by speaker
hist_by_spk <- ggplot(exp_data,aes(x=response_numeric, fill = coding))+
  geom_histogram(bins=30)+
  facet_grid(.~coding) +
  xlab("Masculinity Rating") +
  scale_fill_manual(values = cbPalette, name = "Speaker ID")
print(hist_by_spk)
ggsave(file="./analysis/main/Graphs/hist_summary.pdf",width=7,height=4)
ggsave(file="./analysis/main/Graphs/hist_summary.png",width=,height=4)

##barplots

#box_all <- ggplot(exp_data,aes(y = response_numeric))+
#  geom_boxplot(aes(fill=expected))+ 
#  ylab("Masculinity Rating") +
#  scale_fill_manual("Expected Masculinity", values=cbPalette) 
#print(box_all)
#ggsave(file="./analysis/main_masc_lex/Graphs/box_all.pdf",width=6,height=4)
#ggsave(file="./analysis/main_masc_lex/Graphs/box_all.png",width=6,height=4)

#exp_data_bar <- exp_data %>%
#  group_by(expected) %>%
#  summarise( 
#    n=n(),
#    mean=mean(response_numeric),
#    sd=sd(response_numeric)
#  ) %>%
#  mutate( se=sd/sqrt(n))  %>%
#  mutate( ic=se * qt((1-0.05)/2 + .5, n-1))

#bar_all <- ggplot(exp_data_bar, aes(y = mean)) +
#  geom_bar(aes(x = expected, fill = expected), stat="identity", alpha=0.7) +
#  geom_errorbar(aes(x = expected, 
#                    ymin=mean-ic, 
#                    ymax=mean+ic), width=0.4, colour="black", alpha=0.9) + 
#  ylab("Masculinity Rating") +
#  xlab("Lexical Variant Type") +
#  scale_fill_manual(values = cbPalette)
#print(bar_all)
#ggsave(file="./analysis/main_masc_lex/Graphs/bar_all.pdf",width=4,height=4)
#ggsave(file="./analysis/main_masc_lex/Graphs/bar_all.png",width=4,height=4)
### by lexical_triplet
#exp_data_1 <- filter(exp_data, triplet_id < 9) %>%
#  group_by(triplet_id,expected) %>%
#  summarise( 
#    n=n(),
#    mean=mean(response_numeric),
#    sd=sd(response_numeric)
#  ) %>%
#  mutate( se=sd/sqrt(n))  %>%
#  mutate( ic=se * qt((1-0.05)/2 + .5, n-1))
#exp_data_2 <- filter(exp_data, triplet_id > 8 & triplet_id < 17)  %>%
#  group_by(triplet_id,expected) %>%
#  summarise( 
#    n=n(),
#    mean=mean(response_numeric),
#    sd=sd(response_numeric)
#  ) %>%
#  mutate( se=sd/sqrt(n))  %>%
#  mutate( ic=se * qt((1-0.05)/2 + .5, n-1))
#exp_data_3 <- filter(exp_data, triplet_id > 16)  %>%
#  group_by(triplet_id,expected) %>%
#  summarise( 
#    n=n(),
#    mean=mean(response_numeric),
#    sd=sd(response_numeric)
#  ) %>%
#  mutate( se=sd/sqrt(n))  %>%
#  mutate( ic=se * qt((1-0.05)/2 + .5, n-1))

#exp_data_1$triplet_id <- as.factor(exp_data_1$triplet_id)
#exp_data_2$triplet_id <- as.factor(exp_data_2$triplet_id)
#exp_data_3$triplet_id <- as.factor(exp_data_3$triplet_id)

#bar_1 <- ggplot(exp_data_1, aes(x = triplet_id, y = mean, fill = expected)) +
#  stat_summary(fun = mean, geom = "bar", position = position_dodge(width = .9),
#               size = 3) +
#  geom_errorbar(aes(ymin=mean-ic, 
#                    ymax=mean+ic), width=0.3, position = position_dodge(width = .9)) + 
#  ylab("Masculinity Rating") +
#  xlab("Sentence Frame") +
#  ylim(0, 1) + 
#  scale_fill_manual(values = cbPalette, name = "Lexical Variant Type")
#print(bar_1)
#ggsave(file="./analysis/main_masc_lex/Graphs/bar_1.pdf",width=8,height=5)
#ggsave(file="./analysis/main_masc_lex/Graphs/bar_1.png",width=8,height=5)

#bar_2 <- ggplot(exp_data_2, aes(x = triplet_id, y = mean, fill = expected)) +
#  stat_summary(fun = mean, geom = "bar", position = position_dodge(width = .9),
#               size = 3) +
  geom_errorbar(aes(ymin=mean-ic, 
                    ymax=mean+ic), width=0.3, position = position_dodge(width = .9)) + 
  ylab("Masculinity Rating") +
  xlab("Sentence Frame") +
  ylim(0, 1) + 
  scale_fill_manual(values = cbPalette, name = "Lexical Variant Type")
print(bar_2)
ggsave(file="./analysis/main_masc_lex/Graphs/bar_2.pdf",width=8,height=5)
ggsave(file="./analysis/main_masc_lex/Graphs/bar_2.png",width=8,height=5)

bar_3 <- ggplot(exp_data_3, aes(x = triplet_id, y = mean, fill = expected)) +
  stat_summary(fun = mean, geom = "bar", position = position_dodge(width = .9),
               size = 3) +
  geom_errorbar(aes(ymin=mean-ic, 
                    ymax=mean+ic), width=0.3, position = position_dodge(width = .9)) + 
  ylab("Masculinity Rating") +
  xlab("Sentence Frame") +
  ylim(0, 1) + 
  scale_fill_manual(values = cbPalette, name = "Lexical Variant Type")
print(bar_3)
ggsave(file="./analysis/main_masc_lex/Graphs/bar_3.pdf",width=8,height=5)
ggsave(file="./analysis/main_masc_lex/Graphs/bar_3.png",width=8,height=5)

### SQR 
gender_link <- ggplot(score_gender_link,aes(score_link))+geom_histogram(bins = 30)
print(gender_link)
gender_trans <- ggplot(score_gender_trans,aes(score_trans))+geom_histogram(bins = 30)
print(gender_trans)

# MODEL 
## linear mixed effects model
exp_data$triplet_id <- as.factor(exp_data$triplet_id)
exp_data$expected <- as.factor(exp_data$expected)
exp_data$participant_id <- as.factor(exp_data$participant_id)
exp_data$trial_index <- as.factor(exp_data$trial_index)
exp_data$score_link <- as.numeric(exp_data$score_link)
exp_data$score_trans <- as.numeric(exp_data$score_trans)

exp_data$expected <- relevel(exp_data$expected, ref = "neutral")
model_all <- lmer(response_numeric ~ expected + (1+expected|participant_id) + (1+expected|trial_index), data = exp_data)
summary(model_all)

r.squaredGLMM(model_all)

## interaction between expected (masc condition) and triplet_id
exp_data$triplet_id <- relevel(exp_data$triplet_id, ref = "18")
model_trip <- lmer(response_numeric ~ expected*triplet_id + (1+expected|participant_id) + (1+expected|trial_index), data = exp_data)
summary(model_trip)

r.squaredGLMM(model_trip)

#first install all packages needed
install.packages("tm")
install.packages("wordcloud")
install.packages("e1071")
install.packages("gmodels")
install.packages("wordnet")
install.packages("readxl")
library(tm)
library(wordcloud)
library(e1071)
library(gmodels)
library(wordnet)
library(readxl)

#need to put your file path in here
test <- read_excel("")

#my data contains dialogs. Since I only need A's Part I delete B's Part
for (i in 1:nrow(test)){
  test[i,5] <- gsub("B:.*?A:","",test[i,5], ignore.case=FALSE)
}



#Chance is the subjective variable (dummy)
#Stelle frei is the objective variable (dummy)
#transkript contains the text

test_ja <- test[which(test$Chance==1),]
test_nein <- test[which(test$Chance==0),]


test$Chance[test$Chance == 1]    <- "Ja"
test$Chance[test$Chance == 0]    <- "Nein"



table(test$`Stelle frei`)
table(test$Akzent)
table(test$Chance)

#preparing text data
#####################
transkript_corpus <- 
  VCorpus(VectorSource(test$transkript))



#Turn capital letters into lowercase#

transkript_corpus_clean <- tm_map(transkript_corpus,
                                  content_transformer(tolower))


#remove numbers#

transkript_corpus_clean <- tm_map(transkript_corpus_clean, removeNumbers)


#remove typical words without meaning#
transkript_corpus_clean <- tm_map(transkript_corpus_clean, 
                                  removeWords, stopwords("german"))

# remove punctuation'
replacePunctuation <- function(transkript_corpus_clean) {
  gsub ("[[:punct:]]+", " ", transkript_corpus_clean)
}

transkript_corpus_clean <- tm_map(transkript_corpus_clean, stripWhitespace)

#show new form#
as.character(transkript_corpus_clean [1])



#### defining synonyms

transkript_corpus_clean <- tm_map(transkript_corpus_clean, content_transformer(gsub), pattern = "\\b(?????h|???h|??hm|?h|?hm|aaaah|????hm|???h|???hm|??h|??hm|ehh|ehhh|ehhhh|ehm|ehmm|ehmmm|ehhmmmm)\\b", replacement = "?hm")
transkript_corpus_clean <- tm_map(transkript_corpus_clean, content_transformer(gsub), pattern = "\\b(hhhm|hhm|hmh|hmmm|hmm|hmmmmmm)\\b", replacement = "hm")
transkript_corpus_clean <- tm_map(transkript_corpus_clean, content_transformer(gsub), pattern = "\\b(jaa|jaaa|jaaaa|jaaaaa|jaaaaaaaaa|jaha|jja|jjja|joa|joaa|joah|jooo|joooaaaa)\\b", replacement = "jaa")
transkript_corpus_clean <- tm_map(transkript_corpus_clean, content_transformer(gsub), pattern = "\\b(puh|puhh|puhhh|puuh|poah|phh|phhh)\\b", replacement = "puh")
transkript_corpus_clean <- tm_map(transkript_corpus_clean, content_transformer(gsub), pattern = "\\b(ohg|ohh|?hh|oje|oooh|oooo)\\b", replacement = "oh")
transkript_corpus_clean <- tm_map(transkript_corpus_clean, content_transformer(gsub), pattern = "\\b(okaaay|okay|okaaaay|oook)\\b", replacement = "ok")
transkript_corpus_clean <- tm_map(transkript_corpus_clean, content_transformer(gsub), pattern = "\\b(nnein|nich|neein|neeeiiin)\\b", replacement = "nein")
transkript_corpus_clean <- tm_map(transkript_corpus_clean, content_transformer(gsub), pattern = "\\b(nenene|net|nee|neee|neeeee|neh|need|neeee)\\b", replacement = "neee")
transkript_corpus_clean <- tm_map(transkript_corpus_clean, content_transformer(gsub), pattern = "\\b(worden|wird|werde|wurde|w?rde|wurden|w?rden)\\b", replacement = "wurde")
transkript_corpus_clean <- tm_map(transkript_corpus_clean, content_transformer(gsub), pattern = "\\b(soll|sollen|sollte)\\b", replacement = "sollen")
as.character(transkript_corpus_clean[[1]])

# Stemming
require(SnowballC)

transkript_corpus_clean <- tm_map(transkript_corpus_clean, content_transformer(stemDocument), language="german")
as.character(transkript_corpus_clean[[1]])



#Turn text into DocumentTermMatrix

test_dtm <- DocumentTermMatrix(transkript_corpus_clean)

#divide data into training and testdata. here with 75% trainin
test_dtm_train <- test_dtm[1:832, ]
test_dtm_test <- test_dtm[833:1109, ]


test_train_labels <- test[1:832, ]$Chance
test_test_labels <- test[833:1109, ]$Chance


prop.table(table(test_train_labels))

prop.table(table(test_test_labels))


#finding frequent terms
findFreqTerms(test_dtm_train, 150)


test_freq_words <- findFreqTerms(test_dtm_train, 5)

str(test_freq_words)

#use whatever seed you want
set.seed(42)
test_dtm_freq_train <- test_dtm_train[ , test_freq_words]
test_dtm_freq_test <- test_dtm_test[ , test_freq_words]

convert_counts <- function(test_freq_words) {
  test_freq_words<-  ifelse(test_freq_words > 0, "yes" , "no")
}


test_train <- apply(test_dtm_freq_train, MARGIN = 2,convert_counts)
test_test <- apply(test_dtm_freq_test, MARGIN = 2,  convert_counts)


#Here the calssifier is being trained. 
set.seed(42)

test_classifier <- naiveBayes(test_train, test_train_labels)

test_test_pred <- predict(test_classifier, test_test)

#test: how reliable is the classifier?
CrossTable(test_test_pred, test_test_labels, 
           prod.chisq = FALSE, prod.t = FALSE,
           dnn = c('predicted', 'actual'))




#get the cases which were wrongly predicted
#optional
data <- cbind(test[833:1109,],test_test_pred )
str(post)
post <- which(test_test_pred == "Ja" & data$Chance=="Nein")
data2 <- data[post,]
table(data2$Typ)
table(data2$`Stelle frei`)
table(data2$Ubereinstimmung)



post2 <- which(test_test_pred == "Nein" & data$Chance=="Ja") 
data3 <- data[post2,]
table(data3$Typ)
table(data3$`Stelle frei`)
table(data3$Ubereinstimmung)
str(post2)

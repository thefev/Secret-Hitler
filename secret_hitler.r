library(gmailr)
library(dplyr)
library(data.table)

## To setup gmailr authentication, follow steps at: ##
## https://github.com/r-lib/gmailr ##

gm_auth_configure(path='credentials.json')
gm_auth(cache='.secret')

## This file contains a data.table of player names and emails, eg: ##
## players <- data.table(names=c('Test1','Test2'),email=c('test1@blah.com','test2@blah.com')) ##
source('players.r')

createRoles <- function(numberOfPlayers) {
	num_liberals <- (numberOfPlayers-numberOfPlayers%%2)/2+1
	num_fascists <- numberOfPlayers-num_liberals-1
	output <- c(rep('liberal',num_liberals),rep('fascist',num_fascists),'hitler')
	return(output)
}

assignRoles <- function(names) {
	current_game_players <- players[people%in%names]
	current_game_players[,role:=sample(createRoles(length(names)),replace=FALSE)]
	for(n in names) {
		if(current_game_players$role[current_game_players$people==n]!='fascist') {
			body_message <- paste('Your Secret Hitler Role is:',current_game_players$role[current_game_players$people==n])
		} else if(current_game_players$role[current_game_players$people==n]=='fascist') {
			body_message <- paste0('Your Secret Hitler Role is: ',current_game_players$role[current_game_players$people==n],'; your fellow fascists: ',paste(current_game_players$people[current_game_players$role=='fascist'&current_game_players$people!=n],collapse=', '),'; and Hitler is: ',current_game_players$people[current_game_players$role=='hitler'])
		}
		email <- gm_mime() %>%
			gm_to(current_game_players$email[current_game_players$people==n]) %>%
			gm_from('headisbagent@gmail.com') %>%
			gm_subject('Your Secret Hitler Role') %>%
			gm_html_body(body_message)
		gm_send_message(email)
	}
}

createPolicyTiles <- function(num_liberal_policies_left=6,num_fascist_policies_left=11,president) {
	policy_pool <- c(rep('Liberal Policy',num_liberal_policies_left),rep('Fascist Policy',num_fascist_policies_left))
	policy_select <- sample(policy_pool,3,replace=FALSE)
	email <- gm_mime() %>%
		gm_to(current_game_players$email[current_game_players$people==president]) %>%
		gm_from('headisbagent@gmail.com') %>%
		gm_subject('Secret Hitler: Selected policies for president') %>%
		gm_html_body(paste('Your randomly selected policies are:',paste(policy_select,collapse=', ')))
	gm_send_message(email)
}
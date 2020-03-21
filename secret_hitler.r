library(dplyr)
library(data.table)
library(gmailr)

## To setup gmailr authentication, follow steps at: ##
## https://github.com/r-lib/gmailr ##

# gm_auth_configure(path="credentials.json")
gm_auth_configure(path = 'D:/repos/secret-hitler-R/credentials.json')
gm_auth(cache=".secret")

# This file contains a data.table of player names and emails, and your email address from which you have GMail's API active on, eg: 
# players <- data.table(names=c("Test1","Test2"),email=c("test1@blah.com","test2@blah.com")) 
# admin_email <- "admin@site.com"
source('D:/repos/secret-hitler-R/players.r')

#   Creates tracker data.table to track game state
tracker <- data.table(liberal_tiles=6, fascist_tiles=11, num_lib_pol=0, num_fas_pol=0)

##  Generates list of roles determined by number of players. Called by assignRoles.
##    Args.:    number_of_players (int)   -   number of players in this game instance
##    Returns:  output (list of chr)    -   list of roles for players to assume
.CreateRoles <- function(number_of_players) {
	num_liberals <- (number_of_players-number_of_players%%2)/2+1
	num_fascists <- number_of_players-num_liberals-1
	output <- c(rep("liberal",num_liberals),rep("fascist",num_fascists),"Hitler")
	return(output)
}

##  Assigns roles to players based on number of players playing within the list of names in names
##    Args.:    names (list of chr)   -   list of players participating in this game session whose contact details are in players (Data)
AssignRoles <- function(current_players) {
	current_game_players <- players[names%in%current_players]
	current_game_players[,role:=sample(.CreateRoles(length(current_players)),replace=FALSE)] # randomly assigns roles to players
	for(n in current_players) {
	  players$role[players$names==n] <<- current_game_players$role[current_game_players$names==n]
		if(current_game_players$role[current_game_players$names==n]!="fascist") {
			body_message <- paste("Your Secret Hitler Role is:",
			                      current_game_players$role[current_game_players$names==n])
		} 
	  else if(current_game_players$role[current_game_players$names==n]=="fascist") {
			body_message <- paste0("Your Secret Hitler Role is: ", 
			                       current_game_players$role[current_game_players$names==n],
			                       "; your fellow fascists: ",
			                       paste(current_game_players$names[current_game_players$role=="fascist"&current_game_players$names!=n],collapse=", "),
			                       "; and Hitler is: ",
			                       current_game_players$names[current_game_players$role=="hitler"])
		}
		email <- gm_mime() %>%
			gm_to(current_game_players$email[current_game_players$names==n]) %>%
			gm_from(admin_email) %>%
			gm_subject("Your Secret Hitler Role") %>%
			gm_html_body(body_message)
		gm_send_message(email)
	}
}

## Creates policies and sends them to current president. If previous president enacted Policy Peek, then add previous president"s
## name to send them the generated policies as well.
##  Args.:    num_liberal_policies_left (int)   -   number of liberal policies left in the deck
##            num_fascist_policies_left (int)   -   number of fascist policies left in the deck
##            president (chr)                   -   the current president, to whom the generated policies will be emailed to
##            previous_president (chr)          -   the previous president under whom the fascist policy "Policy Peek" was enacted
CreatePolicyTiles <- function(president, 
                              previous_president=NULL, 
                              num_liberal_policies_left=tracker$liberal_tiles, 
                              num_fascist_policies_left=tracker$fascist_tiles) {
	.CheckTracker(3)
  policy_pool <- c(rep("Liberal Policy", num_liberal_policies_left), rep("Fascist Policy", num_fascist_policies_left))
	policy_select <- sample(policy_pool,3,replace=FALSE)
	for (p in policy_select) {
	  if (p == "Fascist Policy") {
	    tracker$fascist_tiles <<- tracker$fascist_tiles - 1
	  }
	  else if (p == "Liberal Policy") {
	    tracker$liberal_tiles <<- tracker$liberal_tiles - 1
	  }
	}
	email <- gm_mime() %>%
		gm_to(players$email[players$names==president]) %>%
		gm_from(admin_email) %>%
		gm_subject("Secret Hitler: Selected policies for president") %>%
		gm_html_body(paste("Your randomly selected policies are:", paste(policy_select,collapse=", ")))
	gm_send_message(email)
	if (!is.null(previous_president)) {
	  email <- gm_mime() %>%
	    gm_to(players$email[players$names==previous_president]) %>%
	    gm_from(admin_email) %>%
	    gm_subject("Secret Hitler: Selected policies for president") %>%
	    gm_html_body(paste("Your randomly selected policies are:", paste(policy_select,collapse=", ")))
	  gm_send_message(email)
	}
}

##  Takes in the policy that had just been implemented by the chancellor and removes that policy from the deck
##    Args.:    chosen_policy (chr)   -   the policy chosen by the chancellor to enact
ChoosePolicy <- function(chosen_policy) {
  if (chosen_policy == "Fascist Policy" || chosen_policy == "fas" || chosen_policy == "fascist") {
    tracker$num_fas_pol <<- tracker$num_fas_pol + 1
  }
  else if (chosen_policy == "Liberal Policy" || chosen_policy == "lib" || chosen_policy == "liberal") {
    tracker$num_lib_pol <<- tracker$num_lib_pol + 1
  }
}

##  Randomly selects one policy from the available deck to enact. Call this when 4 failed elections has passed. 
##  DO NOT use ChoosePolicy after executing this function
##    Args.:    num_liberal_policies_left (int)   -   number of liberal policies left in the deck
##              num_fascist_policies_left (int)   -   number of fascist policies left in the deck
##    Return:   policy_select (chr)               -   the randomly selected policy, so that players are informed
ChooseRandomPolicy <- function(num_liberal_policies_left=tracker$liberal_tiles,num_fascist_policies_left=tracker$fascist_tiles) {
  .CheckTracker(1)
  policy_pool <- c(rep("Liberal Policy",num_liberal_policies_left),rep("Fascist Policy",num_fascist_policies_left))
  policy_select <- sample(policy_pool,1,replace=FALSE)
  if (policy_select == "Liberal Policy") {
    tracker$num_lib_pol <<- tracker$num_lib_pol + 1
  }
  else if (policy_select == "Fascist Policy") {
    tracker$num_fas_pol <<- tracker$num_fas_pol + 1
  }
  return (policy_select)
}

## Sends email to the president of what role the investigatee is playing. If the investigated role is Hitler, then only returns the role as fascist, as 
## dictated in game rules. Call this function when the "Investigate Loyalty" policy has been implemented.
##  Args.:    president (chr)     -   current president under whom the policy was implemented
##            investigatee (chr)  -   the person that the president wants to investigate
Investigate <- function (president, investigatee) {
  investigated_role <- players$role[players$names==investigatee]
  if (investigated_role == "Hitler") {
    investigated_role <- "fascist"
  }
  email <- gm_mime() %>%
    gm_to(players$email[players$names==president]) %>%
    gm_from(admin_email) %>%
    gm_subject("Secret Hitler: Your investigated player.") %>%
    gm_html_body(paste("Your investigated player (", investigatee, ") is ", investigated_role))
  gm_send_message(email)
}

## Checks the tracker data.table to ensure that the deck has 3 or more tiles remaining in the Policy deck
##  Args.:    min_tiles_needed (int)    -   minimum tiles needed - 1 for random policy, 3 for creating policies to be picked by president
.CheckTracker <- function(min_tiles_needed) {
  if (tracker$liberal_tiles + tracker$fascist_tiles < min_tiles_needed) {
    tracker$liberal_tiles <<- 6 - tracker$num_lib_pol
    tracker$fascist_tiles <<- 11 - tracker$num_fas_pol
  }
}

## Resets game state by stripping player roles and resetting tracker
ResetGame <- function() {
  players$roles <<- NULL
  tracker <<- data.table(liberal_tiles=6, fascist_tiles=11, num_lib_pol=0, num_fas_pol=0)
}
# Secret-Hitler

Play Secret Hitler with friends online, this script helps to assign roles via e-mail and distribute policies to the President.

## Installation
Dependencies:
  - R packages:     gmailr, dplyr, data.table, httpuv (optional)
  - Python modules: google-api-python-client, google-auth-httplib2, google-auth-oauthlib
  
 Requirement:
  Have a gmail account.
  
Installation guide:
  1.  The R packages can all be found and installed through R. 
  2.  To use gmailr package, follow the Setup at the [gmailr Github](https://github.com/r-lib/gmailr). This will then send you to [Gmail API Python Quickstart page](https://developers.google.com/gmail/api/quickstart/python) where you will be needing those Python modules. 
  
Notes:
If you get a lexical error on calling `gm_auth_configure(path = "path/to/downloaded/json")`, you don't have the right path in the parameter. 

## Running the game.
1.  Create another file and call it `players.r`. Within it, have the code:

`players <- data.table(names=c("Test1","Test2"),email=c("test1@blah.com","test2@blah.com")) `

`admin_email <- "admin@site.com"`

2.  Start the game with `AssignRoles(current_players)` where `current_players` is a list of active players with the players data.table, e.g. `current_players = c("Jan", "Jane", "Jayne", "June")`

3.  Run each round with the following cycle:
  - `CreatePolicyTiles(president)` where `president` is the name of the current president, e.g. `president = "Damo"`. This will send 3 policies to the current president's email address, where she/he will select 2 and text/email/secretly-communicate it to the chancellor, who will then choose the policy to implement.
  - `ChoosePolicy(chosen_policy)` where `chosen_policy` is the policy that the chancellor chose to implement, e.g. `chosen_policy = "Fascist Policy"` or `chosen_policy = "Liberal Policy"`.
  
4.  Other actions include:
  - `Investigate(president, investigatee)` where both parameters are names, e.g. `president = "Jan", investigatee = "Jayne"`. This will send an email to the president about the role of the investigatee.
  - `ChooseRandomPolicy()` when 4 elections fail, it will select a random policy from the available deck and implement it. No need to use `ChoosePolicy()` if this has been executed.

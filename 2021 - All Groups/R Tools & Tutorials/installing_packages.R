# Some important notes:
#
# Windows Users: 
#
# 1.You may need to install RTools as well.
#
# 2. You may get stuck in a loop where RStudio asks if you
# want to restart R repeatedly. Try completely closing RStudio
# if you have this problem, or answering no in the prompt.
#
# 3. During the install_github() commands I found that updating rlang
# made a mess, so do not choose to update it when prompted.
#
# Linux users: Running this will make your computer very upset. Run it
# while you make breakfast or something.

install.packages('tidyverse')
install.packages('doParallel')
install.packages('DBI')
install.packages('RMySQL')
install.packages('latticeExtra')
install.packages('cli')
install.packages('gh')
install.packages('usethis')
install.packages('devtools')
install.packages('xml2')
install.packages('pitchRx')
install.packages('mlbgameday')
install.packages('Lahman')
devtools::install_github("BillPetti/baseballr")
devtools::install_github("keberwein/mlbgameday")
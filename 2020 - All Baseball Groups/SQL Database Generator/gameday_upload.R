library(RMySQL)
require(DBI)

gameday_upload <- function(year_list) {

  for (i in 1:(length(year_list)-1)){
    df <- get_payload(start = year_list[[i]], end = year_list[[i+1]])
    
    conn <- dbConnect(MySQL(), 
                      dbname = "gameday",
                      user = "r-user", 
                      password = "h2p@4031",
                      host = "saberbase.cn2snhhvsjfa.us-east-2.rds.amazonaws.com",
                      port = 3306)
    dbWriteTable(conn, name = 'atbat', value = df$atbat, append = TRUE, row.names = FALSE)
    dbWriteTable(conn, name = 'action', value = df$action, append = TRUE, row.names = FALSE)
    dbWriteTable(conn, name = 'pitch', value = df$pitch, append = TRUE, row.names = FALSE)
    dbWriteTable(conn, name = 'runner', value = df$runner, append = TRUE, row.names = FALSE)
    dbWriteTable(conn, name = 'po', value = df$po, append = TRUE, row.names = FALSE)
    dbDisconnect(conn)
  }
}
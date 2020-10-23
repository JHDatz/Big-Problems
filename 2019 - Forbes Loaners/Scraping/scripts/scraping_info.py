# ROTOWIRE INFORMATION

roto_injury_first_row = ['RotowireID', 'Name', 'Team', 'Position','Injury', 'Status', 'Est.Return']

roto_injury_list_url = 'https://www.rotowire.com/baseball/tables/injury-report.php?team=ALL&pos=ALL&league=ALL'

roto_player_first_row = ['PlayerID', 'fullName', 'League', 'Bats', 'Throws', '40Man', 'Height',
                      'Weight', 'DOB', 'PlaceOfBirth', 'College', 'Draft']

roto_ordered_keys = ['PlayerID', 'fullName', 'League', 'Bats', 'Throws', '40Man', 'Height', 'Weight', 'DOB',
                'PlaceOfBirth', 'College', 'Draft']

roto_inj_news_first_row = ['RotowireID', 'Source Name', 'Source Organization', 'Hyperlink', \
                           'Title', 'Injury', 'Date', 'News', 'Analysis']

roto_inj_news_subset = ['RotowireID', 'Title', 'Injury', 'Date', 'News']

# ROTOWORLD INFORMATION

rotow_inj_list_first_row = ['URLExtension', 'Name', 'Position', 'Status', 'DateOfInjury', 'InjuryLocation', 'Status']

rotow_inj_url = 'https://www.rotoworld.com/baseball/mlb/injury-report'

rotow_player_first_row = ['URLExtension', 'firstName', 'lastName', 'position', 'dateOfBirth', \
                                          'Height', 'Weight', 'Bats', 'Throws', 'College', 'Drafted']

rotoworld_player_first_row = ['uniqueidentifier', 'fullName', 'DOB', 'URLExtension', 'Birth City', 'Birth Country',
                          'Birth State', 'College', 'Debut Date', 'Draft Pick Overall', 'Draft Round',
                          'Draft Type', 'Draft Year', 'Bats', 'Throws', 'Height', 'Weight']

rotow_player_keys = ['name', 'birth_date', 'path', 'birth_city', 'birth_country', 'birth_state', 'college', 'debut_date',
               'draft_pick_overall', 'draft_round', 'draft_type', 'draft_year', 'handedness_batting',
               'handedness_throwing', 'height', 'weight']

rotow_playerAPI_url = 'https://www.rotoworld.com/api/player/baseball/'

rotow_injuryAPI_url = 'https://www.rotoworld.com/api/injury_type/'

rotow_injuryList_partUno = 'https://www.rotoworld.com/api/injury?sort=-start_date&filter%5Bplayer.team.meta.drupal_internal__id%5D='
rotow_injuryList_partDos = '&filter%5Bplayer.status.active%5D=1&filter%5Bactive%5D=1&include=injury_type,player,player.status,player.position'

rotow_injuryList_filters = ['501', '506', '511', '516', '521', '526', '531', '536', '541', '546', '551', '556',
                            '561', '566', '571', '576', '581', '586', '591', '596', '601', '606', '611', '616',
                            '621', '626', '631', '636', '641', '646']

rotow_injuryAPI_firstrow = ['uniqueidentifier', 'inj loc', 'status', 'createdate', 'lastupdate', 'outlook', 'est_return']

# MLB INFORMATION

mlb_api_keys = ['id', 'fullName', 'firstName', 'lastName', 'birthDate', 'currentAge',
        'birthCity', 'birthStateProvince', 'birthCountry', 'height', 'weight', 'draftYear']

mlb_league_keys = {'mlb': 1, 'aaa': 11, 'aa': 12, 'a+': 13, 'a': 14, 'a-': 15}

mlb_url = 'https://statsapi.mlb.com/api/v1/sports/'

mlb_injury_ordered_keys = ['player_id', 'name_first', 'name_last', 'team_name', 'league_id', \
                           'team_id', 'position', 'insert_ts', 'injury_desc', 'injury_update', \
                           'injury_status', 'due_back']

mlb_injury_url = 'http://mlb.mlb.com/fantasylookup/json/named.wsfb_news_injury.bam'
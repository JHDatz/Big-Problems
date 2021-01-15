import pandas as pd
import numpy as np

def update_playerxref():
    mlb_players = pd.read_csv('data/raw/mlb_dump.csv', header=0)
    rotowire_players = pd.read_csv('data/raw/rotowire_dump.csv', header=0)
    rotoworld_players = pd.read_csv('data/raw/rotoworld_dump.csv', header=0)
    playerxref = pd.read_csv('data/pipelined/playerxref.csv', header=0)

    mlb_players['birthDate'] = pd.to_datetime(mlb_players['birthDate'])
    rotowire_players['birthDate'] = pd.to_datetime(rotowire_players['DOB'])
    rotoworld_players['birthDate'] = pd.to_datetime(rotoworld_players['DOB'])
    rotowire_players['SourceSystem'] = 'ROTOWIRE'
    rotoworld_players['SourceSystem'] = 'ROTOWORLD'

    new_playerxref = mlb_players.merge(rotowire_players, how='inner', on=['fullName', 'birthDate'])
    new_playerxref = new_playerxref[['id', 'PlayerID', 'SourceSystem']]
    new_playerxref = new_playerxref.drop_duplicates(subset=['id', 'PlayerID'])
    new_playerxref = new_playerxref.rename(columns={'id': 'MLBAMID', 'PlayerID': 'Identifier'})
    playerxref = playerxref.append(new_playerxref)

    new_playerxref = mlb_players.merge(rotoworld_players, how='inner', on=['fullName', 'birthDate'])
    new_playerxref = new_playerxref[['id', 'uniqueidentifier', 'SourceSystem']]
    new_playerxref = new_playerxref.drop_duplicates(subset=['id', 'uniqueidentifier'])
    new_playerxref = new_playerxref.rename(columns={'id': 'MLBAMID', 'uniqueidentifier': 'Identifier'})
    playerxref = playerxref.append(new_playerxref)

    playerxref = playerxref.drop_duplicates(inplace=False)
    playerxref.to_csv('data/pipelined/playerxref.csv', index=False)
    playerxref = pd.read_csv('data/pipelined/playerxref.csv', header=0)
    playerxref = playerxref.drop_duplicates(inplace=False)
    playerxref.to_csv('data/pipelined/playerxref.csv', index=False)

def update_rotowire_hist_inj():
    hist_inj = pd.read_csv('data/pipelined/historical_rotowire_injury_list.csv', header=0)
    stated_inj = hist_inj.loc[hist_inj['Entry Type'] == 'Current']
    current_inj = pd.read_csv('data/raw/rotowire_injury_list.csv', header=0)
    current_inj['Current Date'] = pd.datetime.now()
    current_inj['Entry Type'] = 'Current'
    current_inj = current_inj[['RotowireID', 'Entry Type', 'Current Date', 'Injury', 'Status', 'Est.Return']]

    id_diff = set(stated_inj[stated_inj.columns[0]]).difference(current_inj[current_inj.columns[0]])
    removed_players = pd.DataFrame([{'player_id': playerID, 'Entry Type': 'Removed',
                                     'Current Date': pd.datetime.now()} for playerID in id_diff])
    hist_inj.loc[hist_inj[hist_inj.columns[0]].isin(id_diff), 'Entry Type'] = 'Added'
    hist_inj.append(removed_players, ignore_index=True, sort=False)

    id_diff = set(current_inj[current_inj.columns[0]]).difference(stated_inj[stated_inj.columns[0]])
    row_diff = current_inj[current_inj.columns[0]].isin(id_diff)
    hist_inj = hist_inj.append(current_inj[row_diff], ignore_index=True, sort=False)

    id_similar = set(current_inj[current_inj.columns[0]]).union(stated_inj[stated_inj.columns[0]])
    current_inj.loc[current_inj['RotowireID'].isin(id_similar), 'Entry Type'] = 'Update'
    hist_inj = hist_inj.append(current_inj.loc[current_inj['Entry Type'] == 'Update'], ignore_index=True, sort=False)
    hist_inj = hist_inj.drop_duplicates(subset=['RotowireID', 'Injury', 'Status', 'Est.Return'])

    hist_inj.to_csv('data/pipelined/historical_rotowire_injury_list.csv', index=False)

def update_rotoworld_hist_inj():
    hist_inj = pd.read_csv('data/pipelined/historical_rotoworld_injury_list.csv', header=0)
    stated_inj = hist_inj.loc[hist_inj['Entry Type'] == 'Current']
    current_inj = pd.read_csv('data/raw/rotoworld_injury_list.csv', header=0)
    current_inj['Current Date'] = pd.datetime.now()
    current_inj['Entry Type'] = 'Current'
    current_inj = current_inj[['uniqueidentifier', 'Entry Type', 'Current Date', 'inj loc', 'status', 'createdate',\
                               'lastupdate', 'est_return']]

    id_diff = set(stated_inj[stated_inj.columns[0]]).difference(current_inj[current_inj.columns[0]])
    removed_players = pd.DataFrame([{'player_id': playerID, 'Entry Type': 'Removed',
                                     'Current Date': pd.datetime.now()} for playerID in id_diff])
    hist_inj.loc[hist_inj[hist_inj.columns[0]].isin(id_diff), 'Entry Type'] = 'Added'
    hist_inj.append(removed_players, ignore_index=True, sort=False)

    id_diff = set(current_inj[current_inj.columns[0]]).difference(stated_inj[stated_inj.columns[0]])
    row_diff = current_inj[current_inj.columns[0]].isin(id_diff)
    hist_inj = hist_inj.append(current_inj[row_diff], ignore_index=True, sort=False)

    id_similar = set(current_inj[current_inj.columns[0]]).union(stated_inj[stated_inj.columns[0]])
    current_inj.loc[current_inj['uniqueidentifier'].isin(id_similar), 'Entry Type'] = 'Update'
    hist_inj = hist_inj.append(current_inj.loc[current_inj['Entry Type'] == 'Update'], ignore_index=True, sort=False)
    hist_inj = hist_inj.drop_duplicates(subset=['uniqueidentifier', 'inj loc', 'status', 'createdate',
                               'lastupdate', 'est_return'])

    hist_inj.to_csv('data/pipelined/historical_rotoworld_injury_list.csv', index=False)

def update_mlb_hist_inj():
    hist_inj = pd.read_csv('data/pipelined/historical_mlb_injury_list.csv', header=0)
    stated_inj = hist_inj.loc[hist_inj['Entry Type'] == 'Current']

    current_inj = pd.read_csv('data/raw/mlb_injury_list.csv', header=0)
    current_inj = current_inj[['player_id', 'injury_status', 'due_back', 'injury_desc', 'injury_update']]
    current_inj['Current Date'] = pd.datetime.now()
    current_inj['Entry Type'] = 'Current'

    id_diff = set(stated_inj[stated_inj.columns[0]]).difference(current_inj[current_inj.columns[0]])
    removed_players = pd.DataFrame([{'player_id': playerID, 'Entry Type': 'Removed',
                                     'Current Date': pd.datetime.now()} for playerID in id_diff])
    hist_inj.loc[hist_inj[hist_inj.columns[0]].isin(id_diff), 'Entry Type'] = 'Added'
    hist_inj = hist_inj.append(removed_players, ignore_index=True, sort=False)

    id_diff = set(current_inj[current_inj.columns[0]]).difference(stated_inj[stated_inj.columns[0]])
    row_diff = current_inj[current_inj.columns[0]].isin(id_diff)
    hist_inj = hist_inj.append(current_inj[row_diff], ignore_index=True, sort=False)

    id_similar = set(current_inj[current_inj.columns[0]]).union(stated_inj[stated_inj.columns[0]])
    update_diff = set(current_inj.injury_update).difference(set(stated_inj.injury_update))
    current_inj.loc[current_inj['injury_update'].isin(update_diff), 'Entry Type'] = 'Update'
    hist_inj = hist_inj.append(current_inj.loc[current_inj['Entry Type'] == 'Update'], ignore_index=True, sort=False)

    hist_inj.to_csv('data/pipelined/historical_mlb_injury_list.csv', index=False)

def update_histories():
    update_rotowire_hist_inj()
    update_rotoworld_hist_inj()
    update_mlb_hist_inj()

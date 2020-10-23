import requests, json, re, csv, os, time
import pandas as pd
from bs4 import BeautifulSoup
from urllib.request import urlopen
from scripts.scraping_info import *
from selenium import webdriver
from selenium.webdriver.firefox.options import Options
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.firefox.firefox_profile import FirefoxProfile

# GENERIC TOOLS

def filemerge(name, subset):
    master_table = pd.read_csv(name, header=0)
    staging_table = pd.read_csv(name.split('.')[0] + '(staging).csv', header=0)
    master_table = master_table.append(staging_table, sort=False)
    master_table = master_table.drop_duplicates(subset=subset)
    master_table.to_csv(name, index=False)
    os.remove(name.split('.')[0] + '(staging).csv')

def filewrite(name, rowNames, data):
    with open(name, 'w') as my_csv:
        writer = csv.writer(my_csv, delimiter=',')
        writer.writerow(rowNames)
        writer.writerows(data)

def writeAndMerge(name, rowNames, data, subset):
    filewrite(name + '(staging).csv', rowNames, data)
    filemerge(name + '.csv', subset)

def json_table_load(url): return json.loads(urlopen(url).read().decode('utf-8'))

# ROTOWIRE TOOLS

def injury_list_data_capture(player):
    data = requests.get('https://www.rotowire.com/baseball/player.php?id=' + player['ID'])
    soup = BeautifulSoup(data.text, 'html.parser')

    try:
        est_return = soup.find('div', {'class': 'p-card__injury-data'}).findNextSibling().getText()[12:]
    except AttributeError:
        est_return = 'NULL'

    return [player['ID'], player['player'],player['team'], player['position'], player['injury'],
                player['status'], est_return]

def update_rotowire_injury_list():
    table = json_table_load(roto_injury_list_url)
    data = [[str(data).replace(',', '') for data in injury_list_data_capture(players)] for players in table]
    filewrite('data/raw/rotowire_injury_list.csv', roto_injury_first_row, data)

def update_rotowire_player_list():
    json_file = json.load(open('spiders/roto/rotowire_data.json', 'r'))
    inj_data = [[players['PlayerID']] + rows for players in json_file for rows in players['Injury Reports'] \
                if players['Injury Reports'] != list()]
    player_data = [[data[keys] for keys in roto_ordered_keys] for data in json_file]

    writeAndMerge('data/raw/injury_news(test)', roto_inj_news_first_row, inj_data, roto_inj_news_subset)
    writeAndMerge('data/raw/rotowire_dump', roto_player_first_row, player_data, None)
    os.remove('spiders/roto/rotowire_data.json')

# ROTOWORLD TOOLS

def parse_injury_api(data_row):
    uniqueidentifier = data_row['relationships']['player']['data']['id']
    injury_uniqueidentifier = data_row['relationships']['injury_type']['data']['id']
    injury_name = fetch_inj_name(injury_uniqueidentifier)
    status = fetch_status(uniqueidentifier)
    create_date = data_row['attributes']['created']
    updated_on = data_row['attributes']['changed']
    outlook = data_row['attributes']['outlook']
    return_est = data_row['attributes']['return_estimate']

    return [uniqueidentifier, injury_name, status, create_date, updated_on, outlook, return_est]

def attrs_pickup(ID):
    player_base_url = 'https://www.rotoworld.com/api/player/baseball/' + ID
    player_table = json_table_load(player_base_url)['data']['attributes']
    player_attrs = []

    for keys in rotow_player_keys:
        try:
            if keys == 'path':
                player_attrs.append(player_table[keys]['alias'].split('/baseball/mlb/player/')[1])
            else:
                player_attrs.append(player_table[keys])
        except KeyError:
            player_attrs.append('NULL')

    return player_attrs

def rotow_parse_40man():
    teams = set(pd.read_csv('data/rotoworld/teams.csv', header=0).ID)
    player_list = list()

    for IDs in teams:
        url = 'https://www.rotoworld.com/api/team/depth_chart/' + IDs
        players = json_table_load(url)['categories'][0]['slots']

        for i in range(len(players)):
            for j in range(len(players[i]['players'])):
                uniqueidentifier = players[i]['players'][j]['uuid']
                player_list.append([uniqueidentifier] + attrs_pickup(uniqueidentifier))

    writeAndMerge('data/raw/rotoworld_dump', rotoworld_player_first_row, player_list, None)

def fetch_status(ID): return json_table_load(rotow_playerAPI_url + ID + '/status')['data']['attributes']['name']
def fetch_inj_name(ID): return json_table_load(rotow_injuryAPI_url + ID)['data']['attributes']['name']

def rotow_parse_injury_list():
    team_hyperlinks = [rotow_injuryList_partUno + teamID + rotow_injuryList_partDos for teamID in rotow_injuryList_filters]
    team_inj_data = [json_table_load(url) for url in team_hyperlinks]
    inj_data = [parse_injury_api(rows) for data in team_inj_data for rows in data['data']]

    filewrite('data/raw/rotoworld_injury_list.csv', rotow_injuryAPI_firstrow, inj_data)

    known_playerIDs = set(pd.read_csv('data/raw/rotoworld_dump.csv', header=0).uniqueidentifier)
    new_playerIDs = set(pd.read_csv('data/raw/rotoworld_injury_list.csv', header=0).uniqueidentifier)
    unknown_player_pickup = [[IDs] + attrs_pickup(IDs) for IDs in new_playerIDs.difference(known_playerIDs)]
    writeAndMerge('data/raw/rotoworld_dump', rotoworld_player_first_row, unknown_player_pickup, None)

# MLB TOOLS

def mlb_api_parse(player):

    def helper_function(player, key):
        if key not in player: return "NULL"
        else: return str(player[key]).replace(',', '')

    try:
        batSide = player['batSide']['code']
    except KeyError:
        batSide = 'NULL'

    try:
        pitchHand = player['pitchHand']['code']
    except KeyError:
        pitchHand = 'NULL'

    try:
        primaryPos = player['primaryPosition']['abbreviation']
    except KeyError:
        primaryPos = 'NULL'

    return [helper_function(player, key) for key in mlb_api_keys] + [primaryPos, batSide, pitchHand]

def mlbPlayerCollect():

    data = [[str(i)] + [str(info).replace(',', '') for info in mlb_api_parse(player)] + [mlbKey]
            for i in range(2000, 2020)
            for mlbKey in mlb_league_keys.keys()
            for player in json_table_load(mlb_url + str(mlb_league_keys[mlbKey]) + '/players?season=' + str(i))['people']]

    writeAndMerge('data/raw/mlb_dump', ['year'] + mlb_api_keys + ['position', 'bats', 'throws', 'league'], data, None)

def mlb_inj_collect():
    data = json_table_load(mlb_injury_url)['wsfb_news_injury']['queryResults']['row']
    data = [[row[key] for key in mlb_injury_ordered_keys] for row in data]
    filewrite('data/raw/mlb_injury_list.csv', mlb_injury_ordered_keys, data)

def gather_data():
    update_rotowire_injury_list()
    update_rotowire_player_list()
    rotow_parse_40man()
    rotow_parse_injury_list()
    mlb_inj_collect()
    # mlbPlayerCollect()
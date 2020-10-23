import requests, time
from bs4 import BeautifulSoup

# CoLab at our disposal! This is through google, acts as an online jupyter notebook.
# Can save .ipynb files on a google drive.
# Also handles pip installing libraries

# requests also handles changing user-agent, cookies, response code, etc.

#r = requests.get('https://api.github.com/user', auth=('user', 'pass'))
#r.status_code

# 403 - Forbidden
# 500 - Server error

#r.headers['content-type']
# Tells us the data type and the character set.

#r.encoding
#r.text
#r.json() # Gives us json back!

# Next example:

#response = requests.get('https://memory-alpha.fandom.com/wiki/Starfleet_casualties_(22nd_century)')
#soup = BeautifulSoup(response.text, 'html.parser')

#titles = soup.find_all(lambda tag: 'title' in tag.attrs and '21' in tag['title'])
#print(titles)
#print(titles[0])

for letters in ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', \
                'l', 'm', 'n', 'o', 'p', 'q' 'r', 's', 't', 'u', 'v',
                'w', 'x', 'y', 'z']:

    response = requests.get('https://mjlavin80.github.io/pseudonyms/pseud_' + letters + '.htm')
    time.sleep(2)
    soup = BeautifulSoup(response.text, 'html.parser')

    soupy = soup.find('span', {'class': 'PseudoName'})

    pseudoname =  letters.upper() + '.'

    while soupy.findNextSibling() is not None:
        if 'class' in soupy.findNextSibling().attrs:
            if ['mainlinks'] == soupy.findNextSibling()['class']:
                print(pseudoname + ' - ' + soupy.findNextSibling().getText().replace('\n', ''))
            if ['PseudoName'] == soupy.findNextSibling()['class']:
                pseudoname = soupy.findNextSibling().getText().replace('\n', '')
        if soupy is not None:
            soupy = soupy.findNextSibling()

"""Review additional Turkish-name candidates: python3 tool/content/resolve_remaining.py."""
import json
import urllib.parse
from fetch_wikidata import CACHE, fetch

QUERIES = {
    'arter': 'Arter', 'hisart': 'Hisart', 'adalar-museum': 'Adalar Müzesi',
    'florence-nightingale': 'Florence Nightingale', 'incegiz': 'İnceğiz Mağara',
    'sadabad': 'Sadabad Sarayı', 'grand-bazaar': 'Kapalıçarşı', 'karakoy': 'Karaköy',
    'tuzla': 'Tuzla', 'maltepe': 'Maltepe', 'golden-gate': 'Altınkapı',
    'mevlana-gate': 'Mevlanakapı', 'topkapi-gate': 'Topkapı', 'edirnekapi': 'Edirnekapı',
    'kerkoporta': 'Kerkoporta', 'mese': 'Mese', 'sinan-tomb': 'Mimar Sinan Türbesi',
    'suleyman-tomb': 'Kanuni Sultan Süleyman Türbesi', 'hurrem-tomb': 'Hürrem Sultan Türbesi',
    'gate-of-salutation': 'Babüsselam', 'baghdad-kiosk': 'Bağdat Köşkü', 'revan-kiosk': 'Revan Köşkü',
    'fatih-mosque': 'Fatih Camii', 'florence-museum': 'Florence Nightingale Müzesi',
    'golden-gate-en': 'Golden Gate Constantinople', 'pege-gate': 'Gate of Pege',
}
for key, query in QUERIES.items():
    params = urllib.parse.urlencode(dict(action='wbsearchentities', search=query, language='tr', format='json', limit=10))
    data = fetch('https://www.wikidata.org/w/api.php?' + params, CACHE / (key + '-tr-search.json'))
    print(key, [(x['id'], x.get('label'), x.get('description')) for x in data['search']], flush=True)

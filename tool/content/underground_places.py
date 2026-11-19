"""Usage: python3.11 tool/content/underground_places.py

Writes studio/underground/places.json, P14's eight places (the dig's dated
strata, newest first, and the remote review), from the research pass of
2026-11-19 (studio/cache/p14/research/claims.jsonl, gitignored). Kept as a
script so the EN and TR texts sit side by side; build_underground.py reads
the JSON it writes.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CHECKED = '2026-11-19'


def L(en, tr):
    return {'en': en, 'tr': tr}


def stratum(id_, from_, to, era, title, body, sources, anchor=None, media=()):
    s = {'id': id_, 'fromYear': from_, 'toYear': to, 'era': era, 'title': title,
         'body': body, 'media': list(media), 'sources': sources}
    if anchor is not None:
        s['anchorYear'] = anchor
    return s


def review(note, status, entrance, function, hook, entry, sources, visit_sources,
           hours=None, accessibility=None, etiquette=None, tags=('entrance-remote',)):
    return {
        'note': note,
        'review': 'reviewed',
        'entrance': {'lat': entrance[0], 'lng': entrance[1]},
        'status': {'value': status, 'checkedAt': CHECKED},
        'currentFunction': function,
        'hook': hook,
        'visit': {
            'checkedAt': CHECKED,
            'hours': hours,
            'hoursCheckedAt': CHECKED if hours else None,
            'entry': entry,
            'etiquette': etiquette,
            'accessibility': accessibility,
            'transit': [],
            'sources': visit_sources,
        },
        'tags': list(tags),
        'sources': sources,
    }


PLACES = [
    {
        'id': 'basilica-cistern',
        'strata': [
            stratum(
                'bc-restored', 2017, None, 'modern',
                L('Restored and contested, 2017–', 'Onarım ve tartışma, 2017–'),
                L('A restoration begun in 2017 became the most thorough in the cistern’s history: the columns were tied against earthquakes, the heavy 1980s concrete walkway gave way to a light steel deck, and cement render was stripped from the walls. It reopened on the evening of 22 July 2022, and has since shown contemporary art and light installations.\n\n'
                  'On 2 June 2026 the General Directorate of Foundations took the cistern over from the Istanbul municipality and reopened it four days later; the transfer is still being argued in court. Hours and prices have changed with it, so the visit card gives the date they were checked.',
                  '2017’de başlayan onarım, sarnıcın tarihindeki en kapsamlısı oldu: sütunlar depreme karşı bağlandı, 1980’lerin ağır beton yürüme yolunun yerini hafif bir çelik platform aldı ve duvarlardaki çimento sıva söküldü. Sarnıç 22 Temmuz 2022 akşamı yeniden açıldı; o günden beri çağdaş sanat ve ışık yerleştirmelerine ev sahipliği yapıyor.\n\n'
                  '2 Haziran 2026’da Vakıflar Genel Müdürlüğü sarnıcı İstanbul Büyükşehir Belediyesi’nden devraldı ve dört gün sonra yeniden açtı; devir hâlâ mahkemede tartışılıyor. Saatler ve ücretler de değişti; ziyaret kartı bunların hangi tarihte doğrulandığını gösterir.'),
                ['istsu-bc-2017', 'dha-bc-2022', 'cumhuriyet-bc-2022', 'euronews-bc-2024', 'ntv-bc-2026-06', 'milliyet-bc-2026-06', 'euronews-bc-2026-06'],
                anchor=2026),
            stratum(
                'bc-museum', 1985, 2017, 'modern',
                L('A museum, 1987', 'Bir müze, 1987'),
                L('In 1985–87 the city cleaned the cistern out, by one count some 50,000 tons of mud, and built walkways over the water. It opened to visitors in 1987, on 9 September by the press reports. The two Medusa heads in the north-west corner became a sight from then on.\n\n'
                  'By 2018 about 1.5 million people a year came down the steps, which made it the municipality’s most-visited museum.',
                  '1985–87’de belediye sarnıcı temizletti; bir hesaba göre yaklaşık 50.000 ton çamur çıkarıldı ve suyun üstüne yürüme yolları yapıldı. Sarnıç 1987’de, basına göre 9 Eylül’de, ziyarete açıldı. Kuzeybatı köşesindeki iki Medusa başı o zamandan beri görülmeye gelinen bir yer oldu.\n\n'
                  '2018’de yılda yaklaşık 1,5 milyon kişi merdivenlerden indi; burası belediyenin en çok ziyaret edilen müzesiydi.'),
                ['istsu-bc-1985', 'milliyet-sadic-2022', 'dha-bc-2022'],
                anchor=1987),
            stratum(
                'bc-ottoman', 1453, 1985, 'ottoman',
                L('Wells in the houses above, 1453–1985', 'Üstteki evlerin kuyuları, 1453–1985'),
                L('After 1453 the cistern was still full, and the people in the houses above drew water, and even fished, through wells in their floors. In the 1540s the French scholar Pierre Gilles was rowed between the columns by torchlight and wrote the first description of it; he wrote as if he had found it, though the neighbours used it every day.\n\n'
                  'It was repaired in 1723 under Ahmed III and again under Abdülhamid II in the late 19th century. In 1963 the James Bond film From Russia with Love rowed its heroes through it to spy on a consulate that never stood above.',
                  '1453’ten sonra da sarnıç doluydu; üstteki evlerde oturanlar zeminlerindeki kuyulardan su çekiyor, hatta balık tutuyordu. 1540’larda Fransız bilgin Pierre Gilles meşale ışığında sütunların arasında kayıkla gezdirildi ve ilk tanımı yazdı; kendini sarnıcın kâşifi saydı, oysa komşular onu her gün kullanıyordu.\n\n'
                  'Sarnıç 1723’te III. Ahmed döneminde, 19. yüzyılın sonunda da II. Abdülhamid döneminde onarıldı. 1963’te James Bond filmi Rusya’dan Sevgilerle, kahramanlarını kayıkla buradan geçirip üstünde hiç durmamış bir konsolosluğu gözetletti.'),
                ['istsu-bc-rediscovery', 'crow-bardill-bayliss-2008', 'gyllius-1561-pandektis', 'istsu-bc-1723', 'istsu-basilica-cistern'],
                anchor=1545),
            stratum(
                'bc-justinian', 528, 1453, 'byzantine',
                L('Justinian’s cistern, 6th century', 'Iustinianos’un sarnıcı, 6. yüzyıl'),
                L('Justinian I made the court of the Stoa Basilica, the law courts and library beside the Augustaion, into a cistern, which took its name. Work began around 528, among his first, and the prefect Longinus paved it over and rebuilt the colonnades above in 541–542. The year 532 often quoted is a guess from the Nika riot that burned the Basilica, not a date in the sources; that a smaller cistern of Constantine’s stood here first is a medieval legend.\n\n'
                  'It is about 138 by 65 metres and held about 80,000 cubic metres, fed by the water of Hadrian’s aqueduct. Brick cross vaults rest on 336 marble columns about 9 metres tall, in 12 rows of 28. Many columns and capitals were reused from older buildings: about a hundred carry carved Corinthian capitals and the rest plain blocks, two stand on Roman Medusa heads, and one, carved all over with knots like a hen’s eye, probably came from the arch of the Forum of Theodosius.',
                  'I. Iustinianos, Augustaion’un yanındaki mahkeme ve kütüphane yapısı Stoa Basilika’nın avlusunu bir sarnıca çevirdi; sarnıç adını ondan aldı. İş, ilk işlerinden biri olarak 528 dolaylarında başladı; vali Longinos 541–542’de üstünü döşetti ve sütunlu galerileri yeniden yaptırdı. Sık anılan 532 yılı, Basilika’yı yakan Nika ayaklanmasından çıkarılmış bir tahmindir, kaynaklardaki bir tarih değildir; önce burada Konstantin’in daha küçük bir sarnıcının durduğu ise bir Orta Çağ efsanesidir.\n\n'
                  'Sarnıç yaklaşık 138’e 65 metredir ve yaklaşık 80.000 metreküp su alırdı; Hadrianus su yolunun suyuyla beslenirdi. Tuğla çapraz tonozlar, 28’lik 12 sıra hâlinde dizilmiş, yaklaşık 9 metre boyunda 336 mermer sütuna oturur. Sütunların ve başlıkların çoğu eski yapılardan alınmıştır: yaklaşık yüzünde oymalı Korint başlığı, kalanında düz bloklar vardır; ikisi Roma döneminden Medusa başlarının üstünde durur; biri de tavuk gözüne benzeyen budaklarla baştan sona oyulmuştur ve büyük olasılıkla Theodosius Forumu’nun takından gelmiştir.'),
                ['crow-bardill-bayliss-2008', 'istsu-bc-construction', 'istsu-basilica-cistern', 'byzleg-basilica-cistern', 'onlu-2010-itu'],
                anchor=528, media=['ug-medusa-inverted-photo']),
        ],
        'review': review(
            'Basilica Cistern promoted to reviewed (P14), checked remotely on 2026-11-19. The entrance pin is OpenStreetMap’s main entrance at the corner of Yerebatan Caddesi and Alemdar Caddesi. The operator changed on 2 June 2026 and the transfer is in court; hours are from a November 2026 report and prices are not shown. A site visit stays open.',
            'open', (41.0084167, 28.9779664),
            L('A museum: the cistern seen from a steel walkway over shallow water, with art installations.', 'Bir müze: sarnıç, sığ suyun üstündeki çelik bir yürüme yolundan görülür; sanat yerleştirmeleri de vardır.'),
            L('Justinian’s flooded hall of 336 columns, with Medusa underfoot.', 'Iustinianos’un 336 sütunlu su salonu; Medusa ayakların altında.'),
            L('Enter from the small building at the corner of Yerebatan Caddesi and Alemdar Caddesi, opposite Hagia Sophia; you go down a long stair. Nearest tram stop: T1 Sultanahmet.', 'Ayasofya’nın karşısında, Yerebatan Caddesi ile Alemdar Caddesi’nin köşesindeki küçük binadan girilir; uzun bir merdivenle inilir. En yakın tramvay durağı: T1 Sultanahmet.'),
            ['istsu-basilica-cistern', 'byzleg-basilica-cistern', 'crow-bardill-bayliss-2008', 'ntv-bc-2026-06'],
            ['osm-node-1909688087', 'alomaliye-bc-hours-2026', 'ntv-bc-2026-06', 'metro-istanbul-t1'],
            hours=L('Daily; 09:00–18:00 in winter (from 15 November 2026) and 09:00–19:00 in summer, as reported in November 2026. The operator changed in June 2026: check before you go.', 'Her gün; kışın (15 Kasım 2026’dan itibaren) 09.00–18.00, yazın 09.00–19.00, Kasım 2026’daki habere göre. İşletmeci Haziran 2026’da değişti: gitmeden önce kontrol edin.')),
    },
    {
        'id': 'theodosius-cistern',
        'strata': [
            stratum(
                'tc-museum', 2010, None, 'modern',
                L('A museum with projections, 2018–', 'Projeksiyonlu bir müze, 2018–'),
                L('The municipality cleared the buildings over the cistern and restored it for about eight years; it opened as a museum in 2018.\n\nIts columns now carry 360-degree projection films, and it is run by the municipality’s Kültür AŞ. Since 17 September 2026 Turkish citizens pay 1 lira.',
                  'Belediye sarnıcın üstündeki yapıları kaldırdı ve onu yaklaşık sekiz yıl onardı; sarnıç 2018’de müze olarak açıldı.\n\nSütunları bugün 360 derecelik projeksiyon filmlerine perde oluyor; sarnıcı belediyenin Kültür AŞ’si işletiyor. 17 Eylül 2026’dan beri Türk vatandaşları 1 lira ödüyor.'),
                ['wp-theodosius-cistern-1365081953', 'istsu-theodosian-cistern', 'euronews-serefiye-2026'],
                anchor=2018),
            stratum(
                'tc-buried', 1453, 2010, 'ottoman',
                L('Under a mansion and a town hall', 'Bir konağın ve bir belediye binasının altında'),
                L('The Turkish name comes from the Şerefiye neighbourhood. Arif Paşa’s mansion was built over the cistern in the late 18th or early 19th century; from 1912 the estate held Istanbul municipal offices, and from 1930 to 1984 Eminönü’s municipal services building.\n\nScholars knew the cistern all along: Forchheimer and Strzygowski drew its plan in 1893.',
                  'Türkçe adı Şerefiye mahallesinden gelir. Sarnıcın üstüne 18. yüzyılın sonunda ya da 19. yüzyılın başında Arif Paşa’nın konağı yapıldı; 1912’den itibaren arazide İstanbul belediyesinin daireleri, 1930’dan 1984’e kadar da Eminönü Belediyesi’nin hizmet binası vardı.\n\nBilim insanları sarnıcı hep biliyordu: Forchheimer ile Strzygowski planını 1893’te çizdi.'),
                ['istsu-theodosian-cistern', 'wp-theodosius-cistern-1365081953'],
                anchor=1912),
            stratum(
                'tc-theodosius', 408, 1453, 'byzantine',
                L('A 5th-century cistern', 'Bir 5. yüzyıl sarnıcı'),
                L('The cistern has no building inscription; its architecture dates it to the first half of the 5th century, the reign of Theodosius II. The dates 428–443 often quoted rest on no early source. It may be the “Theodosian cistern” of the city’s register of about 425, but that one lay in another district, so the name is uncertain.\n\n'
                  'It is about 40 by 24 metres. Thirty-two marble columns in four rows of eight, with Corinthian capitals and impost blocks, carry brick sail vaults about 11 metres above the floor.',
                  'Sarnıcın bir yapım kitabesi yok; mimarisi onu 5. yüzyılın ilk yarısına, II. Theodosius dönemine tarihler. Sık anılan 428–443 tarihleri erken bir kaynağa dayanmaz. Şehrin yaklaşık 425 tarihli kaydındaki “Theodosius sarnıcı” bu olabilir, ama o başka bir semtteydi; bu yüzden ad kesin değil.\n\n'
                  'Sarnıç yaklaşık 40’a 24 metredir. Sekizli dört sıra hâlinde, Korint başlıklı ve yastıklı 32 mermer sütun, zeminden yaklaşık 11 metre yükseklikteki tuğla yelken tonozları taşır.'),
                ['istsu-theodosian-cistern', 'crow-bardill-bayliss-2008', 'byzleg-theodosius-cistern', 'euronews-serefiye-2026'],
                anchor=425),
        ],
        'review': review(
            'Theodosius (Şerefiye) Cistern promoted to reviewed (P14), checked remotely on 2026-11-19. The entrance pin is the door on OpenStreetMap’s outline at Piyer Loti Caddesi 4. Hours differ between OpenStreetMap (09:00–18:00) and a September 2026 report (10:00–18:00); prices are not shown. A site visit stays open.',
            'open', (41.0073528, 28.9724223),
            L('A museum run by the municipality’s Kültür AŞ, with projection films on the columns.', 'Belediyenin Kültür AŞ’sinin işlettiği bir müze; sütunlarda projeksiyon filmleri gösterilir.'),
            L('A 5th-century cistern that spent a century under a town hall.', 'Bir yüzyılını bir belediye binasının altında geçirmiş 5. yüzyıl sarnıcı.'),
            L('Enter at Piyer Loti Caddesi 4, a short walk west of the Hippodrome. Nearest tram stop: T1 Çemberlitaş.', 'Giriş Piyer Loti Caddesi 4’te, Hipodrom’un biraz batısında. En yakın tramvay durağı: T1 Çemberlitaş.'),
            ['istsu-theodosian-cistern', 'byzleg-theodosius-cistern', 'euronews-serefiye-2026'],
            ['osm-way-1154702450', 'euronews-serefiye-2026', 'metro-istanbul-t1'],
            hours=L('Daily; 10:00–18:00 by a September 2026 report (OpenStreetMap gives 09:00–18:00). Check before you go.', 'Her gün; Eylül 2026’daki habere göre 10.00–18.00 (OpenStreetMap’te 09.00–18.00). Gitmeden önce kontrol edin.')),
    },
    {
        'id': 'binbirdirek',
        'strata': [
            stratum(
                'bb-venue', 1900, None, 'modern',
                L('Warehouse, then venue, 20th century–', 'Depo, sonra etkinlik mekânı, 20. yüzyıl–'),
                L('In the 20th century the dry cistern served as a market warehouse and then as a museum office.\n\nRestored, it is now a cultural centre and events venue; whether it opens to walk-in visitors, and when, could not be confirmed from an official source.',
                  '20. yüzyılda kuru sarnıç önce bir pazar deposu, sonra bir müze bürosu olarak kullanıldı.\n\nOnarılan sarnıç bugün bir kültür merkezi ve etkinlik mekânı; kapısının herkese açık olup olmadığı, açıksa ne zaman açık olduğu resmî bir kaynaktan doğrulanamadı.'),
                ['istsu-binbirdirek'],
                anchor=2026),
            stratum(
                'bb-silk', 1453, 1900, 'ottoman',
                L('Silk spinners in the dry cistern', 'Kuru sarnıçta ipek bükücüler'),
                L('By the 16th century the cistern was dry. Pierre Gilles found it under İbrahim Paşa’s house in the 1540s and counted 424 pillars, 212 standing on 212. Silk spinners worked in it from the 16th century and again in the 19th, and rope makers too; in the mid-17th century the vizier Fazlı Paşa built a palace over it, and it was called Fazlı Paşa’s cellar.\n\n'
                  'A story says that Janissaries hid here in 1826 and drowned; it comes from a popular book and is a legend.',
                  '16. yüzyılda sarnıç artık kuruydu. Pierre Gilles onu 1540’larda İbrahim Paşa’nın evinin altında buldu ve 424 direk saydı: 212’si 212’sinin üstünde. 16. yüzyıldan itibaren, 19. yüzyılda yeniden, içinde ipek bükücüler, ayrıca ipçiler çalıştı; 17. yüzyılın ortasında vezir Fazlı Paşa üstüne bir saray yaptırdı ve sarnıca Fazlı Paşa bodrumu denildi.\n\n'
                  'Bir anlatıya göre 1826’da yeniçeriler buraya saklanıp boğuldu; bu, popüler bir kitaptan gelen bir efsanedir.'),
                ['istsu-binbirdirek', 'crow-bardill-bayliss-2008', 'wp-philoxenos-1365179166'],
                anchor=1545),
            stratum(
                'bb-philoxenos', 450, 1453, 'byzantine',
                L('A thousand and one columns', 'Bin bir direk'),
                L('Binbirdirek, “a thousand and one columns”, is a figure of speech: there are 224. Each is two marble shafts stacked and joined by a marble ring, 14–15 metres in all, most with Greek mason’s marks; the floor was later raised, so less of the lower shafts shows. At about 64 by 56 metres and 40,000 cubic metres it is the city’s second-largest covered cistern.\n\n'
                  'It is often called the Cistern of Philoxenos, after a senator of Constantine’s time, but its brick stamps point to the mid-5th or 6th century, and one study gives Philoxenos’ name to another cistern. Which one he built is disputed.',
                  'Binbirdirek bir söz sanatıdır: sütun sayısı 224’tür. Her biri bir mermer halkayla birleştirilmiş üst üste iki gövdeden oluşur, toplam 14–15 metredir ve çoğunda Rumca taşçı işaretleri vardır; zemin sonradan yükseltildiği için alt gövdelerin daha azı görünür. Yaklaşık 64’e 56 metre ve 40.000 metreküp ile şehrin ikinci büyük kapalı sarnıcıdır.\n\n'
                  'Sık sık, Konstantin döneminden bir senatörün adıyla Philoksenos Sarnıcı denir; ama tuğla damgaları 5. yüzyılın ortasını ya da 6. yüzyılı gösterir ve bir çalışma Philoksenos’un adını başka bir sarnıca verir. Onun hangisini yaptırdığı tartışmalıdır.'),
                ['istsu-binbirdirek', 'wp-philoxenos-1365179166', 'crow-bardill-bayliss-2008'],
                anchor=500),
        ],
        'review': review(
            'Binbirdirek promoted to reviewed (P14), checked remotely on 2026-11-19. The entrance pin is OpenStreetMap’s museum node; the door at İmran Öktem Sokak 4 is given only by Wikipedia without a source. Opening to walk-in visitors is not confirmed, so the status stays unknown. A site visit stays open.',
            'unknown', (41.007606, 28.9744173),
            L('A cultural centre and events venue; walk-in opening not confirmed.', 'Bir kültür merkezi ve etkinlik mekânı; herkese açık olup olmadığı doğrulanmadı.'),
            L('224 columns, each two shafts tall, in a cistern silk spinners once worked in.', 'Her biri iki gövde boyunda 224 sütun; bir zamanlar ipek bükücülerin çalıştığı bir sarnıçta.'),
            L('The door is said to be at İmran Öktem Sokak 4, near the Hippodrome; check that it is open before you go. Tram stops nearby: T1 Sultanahmet and Çemberlitaş.', 'Kapının Hipodrom’un yakınında, İmran Öktem Sokak 4’te olduğu söylenir; gitmeden önce açık olup olmadığını kontrol edin. Yakındaki tramvay durakları: T1 Sultanahmet ve Çemberlitaş.'),
            ['istsu-binbirdirek', 'wp-philoxenos-1365179166'],
            ['osm-node-2472730735', 'wp-philoxenos-1365179166', 'metro-istanbul-t1']),
    },
    {
        'id': 'aetius-cistern',
        'strata': [
            stratum(
                'ae-stadium', 1962, None, 'modern',
                L('A football stadium, 1962–', 'Bir futbol stadı, 1962–'),
                L('Since 1962 a football stadium has stood inside the reservoir’s walls at Karagümrük; the pitch and stands sit where the water was.\n\nThe Byzantine walls, 13–15 metres high, still close it in. Full, the reservoir held somewhere between 270,000 and 311,000 cubic metres.',
                  '1962’den beri Karagümrük’te haznenin duvarlarının içinde bir futbol stadı duruyor; saha ve tribünler suyun olduğu yerde.\n\n13–15 metre yükseklikteki Bizans duvarları hâlâ çevresini kapatıyor. Hazne doluyken 270.000 ile 311.000 metreküp arasında su alıyordu.'),
                ['istsu-aetius'],
                anchor=2026),
            stratum(
                'ae-garden', 1540, 1962, 'ottoman',
                L('A sunken garden', 'Bir çukurbostan'),
                L('By about 1540 the reservoir was dry.\n\nFor centuries its floor was a garden, a çukurbostan or “sunken garden”, like the floors of the city’s other open reservoirs, and in the 20th century a sports ground.',
                  'Hazne 1540 dolaylarında kurumuştu.\n\nYüzyıllar boyunca, şehrin öteki açık haznelerinde olduğu gibi, tabanı bir bostandı, bir çukurbostan; 20. yüzyılda da bir spor sahası oldu.'),
                ['istsu-aetius'],
                anchor=1540),
            stratum(
                'ae-reservoir', 421, 1540, 'byzantine',
                L('Aetius’ reservoir, 421', 'Aetius’un haznesi, 421'),
                L('Aetius, prefect of the city (not the famous general of the same name), built this open reservoir in 420–421: about 244 by 85 metres, walled in banded brick and rubble; the north wall is 5.2 metres thick. On 12 February 421 water was let into “the cistern of the lady Pulcheria” in the presence of Theodosius II; this was probably the same one.\n\n'
                  'When the Avars cut the aqueduct in 626 the great open reservoirs ran dry; they filled again after Constantine V repaired it in 766.',
                  'Şehrin valisi Aetius (aynı adı taşıyan ünlü general değil) bu açık hazneyi 420–421’de yaptırdı: yaklaşık 244’e 85 metre, kuşaklı tuğla ve moloz taş duvarlarla; kuzey duvarı 5,2 metre kalınlığındadır. 12 Şubat 421’de II. Theodosius’un önünde “Pulkheria hanımın sarnıcına” su verildi; büyük olasılıkla bu sarnıçtı.\n\n'
                  'Avarlar 626’da su yolunu kesince büyük açık hazneler kurudu; V. Konstantin onu 766’da onardıktan sonra yeniden doldular.'),
                ['crow-bardill-bayliss-2008', 'istsu-aetius', 'istsu-valens-system'],
                anchor=421),
        ],
        'review': review(
            'Cistern of Aetius promoted to reviewed (P14), checked remotely on 2026-11-19. The pin is the place’s own point: the walls are seen from the surrounding streets, and the inside is a stadium whose access was not checked. A site visit stays open.',
            'unknown', (41.0278, 28.9392),
            L('A football stadium inside the reservoir’s walls.', 'Haznenin duvarlarının içinde bir futbol stadı.'),
            L('A 5th-century reservoir with a football pitch where the water was.', 'Suyun yerinde futbol sahası olan bir 5. yüzyıl haznesi.'),
            L('The walls are seen from the streets around the stadium in Karagümrük; entry to the stadium itself was not checked.', 'Duvarlar Karagümrük’te stadın çevresindeki sokaklardan görülür; stadın kendisine giriş kontrol edilmedi.'),
            ['crow-bardill-bayliss-2008', 'istsu-aetius'],
            ['istsu-aetius']),
    },
    {
        'id': 'aspar-cistern',
        'strata': [
            stratum(
                'as-park', 2012, None, 'modern',
                L('A park, 2012–', 'Bir park, 2012–'),
                L('Since about 2012 the floor of the reservoir has been a public park.\n\nIt lies some ten metres below the streets around it: the depth the water once filled.',
                  '2012 dolaylarından beri haznenin tabanı halka açık bir park.\n\nPark, çevresindeki sokakların on metre kadar altında: bir zamanlar suyun doldurduğu derinlikte.'),
                ['istsu-aspar'],
                anchor=2026),
            stratum(
                'as-village', 1500, 2012, 'ottoman',
                L('A village in the hole', 'Çukurdaki köy'),
                L('By the 16th century the reservoir was dry. A small mosque was built in it under Süleyman.\n\nFor centuries it was a sunken market garden with a few houses: the Çukurbostan by the Sultan Selim Mosque.',
                  '16. yüzyılda hazne kurumuştu. Kanuni Süleyman döneminde içine küçük bir mescit yapıldı.\n\nYüzyıllar boyunca birkaç evle birlikte bir çukurbostan oldu: Yavuz Selim Camii’nin yanındaki Çukurbostan.'),
                ['istsu-aspar'],
                anchor=1550),
            stratum(
                'as-reservoir', 459, 1500, 'byzantine',
                L('Aspar’s reservoir, 459', 'Aspar’ın haznesi, 459'),
                L('In 459 the general Aspar began “the very large cistern near the old wall”. It is about 152 metres square and 10–11 metres deep, and held about 250,000 cubic metres. A 10th-century geometry manual uses it as a classroom problem: 70 by 70 fathoms, 12 deep; how much does it hold?\n\n'
                  'It ran dry when the Avars cut the aqueduct in 626 and was used again after the repair of 766.',
                  'General Aspar 459’da “eski surun yanındaki çok büyük sarnıcı” yaptırmaya başladı. Yaklaşık 152 metre karedir, 10–11 metre derinliktedir ve yaklaşık 250.000 metreküp su alırdı. 10. yüzyıldan bir geometri kitabı onu bir ders problemi olarak kullanır: 70’e 70 kulaç, derinliği 12; ne kadar su alır?\n\n'
                  'Avarlar 626’da su yolunu kesince kurudu, 766’daki onarımdan sonra yeniden kullanıldı.'),
                ['crow-bardill-bayliss-2008', 'istsu-aspar', 'istsu-valens-system'],
                anchor=459),
        ],
        'review': review(
            'Cistern of Aspar promoted to reviewed (P14), checked remotely on 2026-11-19. The pin is the place’s own point, the park in the reservoir’s floor; its gates and hours were not checked. A site visit stays open.',
            'open', (41.02595, 28.94986),
            L('A public park on the reservoir’s floor.', 'Haznenin tabanında halka açık bir park.'),
            L('A reservoir so big a geometry book used it as homework.', 'Bir geometri kitabının ödev yaptığı kadar büyük bir hazne.'),
            L('Go down into the park from the streets beside the Sultan Selim Mosque in Çarşamba.', 'Çarşamba’da Yavuz Selim Camii’nin yanındaki sokaklardan parka inilir.'),
            ['crow-bardill-bayliss-2008', 'istsu-aspar'],
            ['istsu-aspar']),
    },
    {
        'id': 'mocius-cistern',
        'strata': [
            stratum(
                'mc-park', 2012, None, 'modern',
                L('A park, 2012–', 'Bir park, 2012–'),
                L('The largest of the open reservoirs is now a park.\n\nIts use changed in about 2012, in the same years as Aspar’s reservoir.',
                  'Açık haznelerin en büyüğü bugün bir park.\n\nKullanımı 2012 dolaylarında, Aspar haznesiyle aynı yıllarda değişti.'),
                ['istsu-mocius'],
                anchor=2026),
            stratum(
                'mc-garden', 1500, 2012, 'ottoman',
                L('Gilles’ roofless garden', 'Gilles’in çatısız bostanı'),
                L('Pierre Gilles saw it in the 1540s as “Mocisia”: wholly unroofed, stripped of its pillars, 970 paces round.\n\nIts floor was a garden then, and it stayed one, the Altımermer çukurbostan, until it became a park.',
                  'Pierre Gilles onu 1540’larda “Mocisia” olarak gördü: tümüyle çatısız, direkleri sökülmüş, çevresi 970 adım.\n\nTabanı o zaman da bostandı ve park olana kadar öyle kaldı: Altımermer Çukurbostanı.'),
                ['crow-bardill-bayliss-2008', 'istsu-mocius'],
                anchor=1545),
            stratum(
                'mc-reservoir', 491, 1500, 'byzantine',
                L('The largest reservoir, probably Anastasius I', 'En büyük hazne, büyük olasılıkla I. Anastasios'),
                L('At about 170 by 147 metres and 12 deep, holding some 300,000 cubic metres, this was the city’s largest open reservoir.\n\nA 10th-century text says Anastasius I (491–518) built it during a famine, and its brickwork is like his land wall’s, so it is probably his. It takes its name from the nearby church of St Mokios.',
                  'Yaklaşık 170’e 147 metre ve 12 metre derinliğiyle, 300.000 metreküp kadar su alan bu hazne, şehrin en büyük açık haznesiydi.\n\n10. yüzyıldan bir metin onu I. Anastasios’un (491–518) bir kıtlık sırasında yaptırdığını söyler; tuğla işçiliği de onun kara suruna benzer, bu yüzden büyük olasılıkla onundur. Adını yakındaki Aziz Mokios kilisesinden alır.'),
                ['crow-bardill-bayliss-2008', 'istsu-mocius'],
                anchor=500),
        ],
        'review': review(
            'Cistern of Mocius promoted to reviewed (P14), checked remotely on 2026-11-19. The pin is the place’s own point; the park’s gates and hours were not checked. A site visit stays open.',
            'open', (41.0103, 28.9347),
            L('A park on the floor of the largest open reservoir.', 'En büyük açık haznenin tabanında bir park.'),
            L('The city’s biggest open reservoir, a garden for five centuries.', 'Şehrin en büyük açık haznesi; beş yüzyıl boyunca bir bostan.'),
            L('The park lies in Altımermer, Fatih; go down into it from the surrounding streets.', 'Park, Fatih’te, Altımermer’dedir; çevresindeki sokaklardan inilir.'),
            ['crow-bardill-bayliss-2008', 'istsu-mocius'],
            ['istsu-mocius']),
    },
    {
        'id': 'nakilbent',
        'strata': [
            stratum(
                'nk-shop', 2004, None, 'modern',
                L('Under a carpet shop', 'Bir halı dükkânının altında'),
                L('The cistern lies under the Nakkaş carpet shop on Nakilbent Sokak, about 100 metres south of the Hippodrome’s curved end.\n\nRestored, it holds a small exhibition on the Hippodrome; visitors are shown it on request, inside a private business whose terms can change.',
                  'Sarnıç, Hipodrom’un kavisli ucunun yaklaşık 100 metre güneyinde, Nakilbent Sokak’taki Nakkaş halı dükkânının altındadır.\n\nOnarılmıştır ve Hipodrom üzerine küçük bir sergiye ev sahipliği yapar; ziyaretçilere, koşulları değişebilecek özel bir işletmenin içinde, istek üzerine gösterilir.'),
                ['byzleg-nakilbent', 'istsu-nakilbent'],
                anchor=2026),
            stratum(
                'nk-byzantine', 400, 2004, 'byzantine',
                L('An early Byzantine cistern', 'Erken Bizans döneminden bir sarnıç'),
                L('Probably 5th or 6th century, it is about 9 by 34 metres and had two rows of nine columns.\n\nOttoman builders replaced several columns with brick and stone piers, repaired it with pointed arches and roofed it again; nine Corinthian capitals with impost blocks survive. It may have belonged to the Great Palace precinct.',
                  'Büyük olasılıkla 5. ya da 6. yüzyıldan olan sarnıç yaklaşık 9’a 34 metredir ve dokuzar sütunluk iki sırası vardı.\n\nOsmanlı ustaları birkaç sütunun yerine tuğla ve taş payeler koydu, sivri kemerlerle onardı ve yeniden örttü; yastıklı dokuz Korint başlığı ayakta kaldı. Büyük Saray’ın alanına ait olabilir.'),
                ['byzleg-nakilbent', 'istsu-nakilbent', 'crow-bardill-bayliss-2008'],
                anchor=500),
        ],
        'review': review(
            'Nakilbent Cistern promoted to reviewed (P14), checked remotely on 2026-11-19. It is inside a private shop and seen only on request, so the status stays unknown and the app does not route visitors to it as a sight. The pin is the place’s own point (no cistern on OpenStreetMap).',
            'unknown', (41.0041466, 28.975153),
            L('Inside a carpet shop, shown on request, with a small Hippodrome exhibition.', 'Bir halı dükkânının içinde, istek üzerine gösterilir; küçük bir Hipodrom sergisi vardır.'),
            L('A Byzantine cistern under a carpet shop, south of the Hippodrome.', 'Hipodrom’un güneyinde, bir halı dükkânının altında bir Bizans sarnıcı.'),
            L('Inside a private shop on Nakilbent Sokak; ask the staff. Access is at the shop’s discretion.', 'Nakilbent Sokak’ta özel bir dükkânın içinde; personele sorun. Giriş dükkânın takdirindedir.'),
            ['byzleg-nakilbent', 'istsu-nakilbent'],
            ['byzleg-nakilbent'],
            tags=('entrance-remote', 'private-access')),
    },
    {
        'id': 'yenikapi',
        'names': L('Theodosian Harbour (Yenikapı)', 'Theodosius Limanı (Yenikapı)'),
        'strata': [
            stratum(
                'yk-station', 2004, None, 'modern',
                L('Dug for the metro, 2004–2014', 'Metro için kazıldı, 2004–2014'),
                L('From 2004 to 2014 the Istanbul Archaeological Museums dug the site ahead of the Marmaray rail tunnel and the metro. In 2005 diggers hit worked wood and rope about a metre below sea level; the dig went on to find 37 ships and tens of thousands of objects. The finds delayed the station; Marmaray opened in 2013 and the metro lines reached Yenikapı in 2014, making it the city’s largest rail interchange.\n\n'
                  'A museum and archaeological park for the ships was designed and approved in 2015; as of January 2026 it had not been built.',
                  '2004’ten 2014’e kadar İstanbul Arkeoloji Müzeleri, Marmaray tüneli ile metrodan önce alanı kazdı. 2005’te kazıcılar deniz seviyesinin yaklaşık bir metre altında işlenmiş ahşaba ve halata rastladı; kazı sonunda 37 gemi ve on binlerce buluntu çıkardı. Buluntular istasyonu geciktirdi; Marmaray 2013’te açıldı, metro hatları 2014’te Yenikapı’ya ulaştı ve burası şehrin en büyük raylı aktarma merkezi oldu.\n\n'
                  'Gemiler için bir müze ve arkeopark tasarlandı ve 2015’te onaylandı; Ocak 2026 itibarıyla yapılmamıştı.'),
                ['kiziltan-2014', 'pulak-ingram-jones-2015', 'hdn-yenikapi-2013', 'dailysabah-yenikapi-2014', 'arkeolojisanat-yenikapi-2015', 'turizmgunlugu-yenikapi-2026'],
                anchor=2026),
            stratum(
                'yk-fill', 1453, 2004, 'ottoman',
                L('Filled in, and market gardens', 'Doldurulmuş, bostan olmuş'),
                L('In the 18th century the harbour basin was filled with debris from building the Laleli Mosque in the 1760s and sold off.\n\nIn the 19th century the railway cut through its walls, and until the 20th century the ground was market gardens.',
                  '18. yüzyılda liman havzası 1760’larda Laleli Camii yapılırken çıkan molozla dolduruldu ve satıldı.\n\n19. yüzyılda demiryolu duvarlarını kesti; 20. yüzyıla kadar arazi bostandı.'),
                ['kiziltan-2014', 'pulak-ingram-jones-2015'],
                anchor=1760),
            stratum(
                'yk-harbour', 379, 1453, 'byzantine',
                L('The Theodosian Harbour', 'Theodosius Limanı'),
                L('Under Theodosius I, late in the 4th century, a mole was thrown across the bay at the mouth of the Lykos stream to make a harbour on the Marmara shore. It is also called the Harbour of Kaisarios; that it was the Harbour of Eleutherios, as it is often named, is disputed.\n\n'
                  'Silt from the Lykos filled it from the west. By the late 12th century it was nearly full and used only by small boats. In its mud lay 37 wrecks of the 5th to early 11th centuries, among them six galleys, the first Byzantine galleys ever excavated. Many sank in storms and were buried quickly in sand.',
                  'I. Theodosius döneminde, 4. yüzyılın sonunda, Marmara kıyısında bir liman yapmak için Lykos deresinin ağzındaki koyun önüne bir mendirek atıldı. Kaisarios Limanı da denir; sık sık anıldığı gibi Eleutherios Limanı olduğu tartışmalıdır.\n\n'
                  'Lykos’un getirdiği alüvyon limanı batıdan doldurdu. 12. yüzyılın sonunda neredeyse dolmuştu ve yalnızca küçük teknelerce kullanılıyordu. Çamurunda 5. yüzyıldan 11. yüzyılın başına uzanan 37 batık yatıyordu; aralarında, ilk kez kazılan Bizans kadırgaları olan altı kadırga vardı. Birçoğu fırtınalarda battı ve çabucak kuma gömüldü.'),
                ['kiziltan-2014', 'pulak-ingram-jones-2015', 'kocabas-2015', 'akkemik-kocabas-galleys'],
                anchor=390),
            stratum(
                'yk-neolithic', -6500, -4800, 'ancient',
                L('A Neolithic village, about 6500 BC', 'Bir Neolitik köy, MÖ 6500 dolayları'),
                L('Below the harbour floor lies a village of the Fikirtepe culture, begun about 6500 BC, the oldest settlement found on the historic peninsula. Its people lived in small wattle-and-daub huts on posts and buried their dead in pits and, in seven urns, as cremations, the earliest known in Anatolia.\n\n'
                  'On an old stream bed about 2,080 footprints were pressed into wet clay and sealed by sand, about 8,000 years ago. Most were made by people wearing shoes.',
                  'Liman tabanının altında, MÖ 6500 dolaylarında kurulmuş bir Fikirtepe kültürü köyü yatar; tarihî yarımadada bulunan en eski yerleşimdir. İnsanları direkler üstündeki küçük çit örgülü, kerpiç sıvalı kulübelerde yaşadı; ölülerini çukurlara gömdü, yedisini de yakarak küplere koydu; bunlar Anadolu’da bilinen en eski ölü yakmalardır.\n\n'
                  'Eski bir dere yatağında yaklaşık 2.080 ayak izi, yaklaşık 8.000 yıl önce ıslak kile basılmış ve kumla örtülmüştür. Çoğu ayakkabılı insanların izleri.'),
                ['kiziltan-2014', 'yilmaz-2011-tubaar', 'hdn-yenikapi-2013'],
                anchor=-6500, media=['ug-yenikapi-footprints-photo']),
        ],
        'review': review(
            'Yenikapı promoted to reviewed (P14), checked remotely on 2026-11-19, and renamed the Theodosian Harbour (Yenikapı): the identification with the Harbour of Eleutherios is disputed. There is no visitor site: the excavation lies under and south of the station, and the ship museum is not built. The pin is the place’s own point.',
            'closed', (41.00466667, 28.95222222),
            L('A rail interchange; the excavation area lies under and south of the station, with no visitor site.', 'Bir raylı aktarma merkezi; kazı alanı istasyonun altında ve güneyindedir, ziyaretçi alanı yoktur.'),
            L('Under the metro: a Byzantine harbour with 37 ships, and Neolithic footprints below it.', 'Metronun altında: 37 gemili bir Bizans limanı, onun altında da Neolitik ayak izleri.'),
            L('Nothing of the dig is open to visit; Yenikapı station (Marmaray, M1, M2) stands on the site.', 'Kazıdan ziyarete açık bir şey yok; alanın üstünde Yenikapı istasyonu (Marmaray, M1, M2) duruyor.'),
            ['kiziltan-2014', 'pulak-ingram-jones-2015', 'turizmgunlugu-yenikapi-2026'],
            ['kiziltan-2014', 'dailysabah-yenikapi-2014', 'turizmgunlugu-yenikapi-2026']),
    },
]


def main():
    doc = {
        'note': 'P14: the eight underground places, reviewed remotely on 2026-11-19 from the research pass (written by tool/content/underground_places.py).',
        'records': PLACES,
    }
    out = ROOT / 'studio/underground/places.json'
    out.write_text(json.dumps(doc, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    print(f'{out.relative_to(ROOT)}: {len(PLACES)} places, '
          f'{sum(len(p["strata"]) for p in PLACES)} strata')


if __name__ == '__main__':
    main()
